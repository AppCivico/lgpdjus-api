package Lgpdjus::Controller::Me_Media;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;
use JSON;
use Imager;
use DateTime;
use Digest::SHA1;
use Scope::OnExit;
use Lgpdjus::Types qw/UploadIntention/;
use Lgpdjus::Uploader;
use Lgpdjus::Utils qw/get_media_filepath random_string/;
use Lgpdjus::Logger;
use Lgpdjus::ImageUtils;

use File::Temp;
use Fcntl qw(SEEK_SET);
use Mojo::File;

has _uploader => sub { Lgpdjus::Uploader->instance() };

sub assert_user_perms {
    my $c = shift;

    die 'missing user' unless $c->stash('user');

    die {
        error   => 'upload_blocked',
        message => 'Upload está bloqueado para sua conta',
    } if $c->stash('user')->{upload_status} eq 'blocked_all';

    return 1;
}

sub mm_upload_post {
    my $c      = shift;
    my $params = $c->req->params->to_hash;

    $c->validate_request_params(
        intention => {max_length => 200, required => 1, type => UploadIntention},
    );

    die {
        error   => 'upload_blocked',
        message => 'Upload está bloqueado para sua conta',
    } if $c->stash('user')->{upload_status} ne 'ok';

    my $upload = $c->param('media');
    $c->log->info(sprintf 'file size is %s', $upload->size);
    if (!$upload) {
        die {
            error   => 'media_missing',
            message => 'Upload não foi enviado',
        };
    }
    elsif ($upload->size <= 2) {
        die {
            error   => 'media_invalid_size',
            message => 'Upload precisa ter mais do que 2 bytes',
        };
    }
    elsif ($upload->size > 10_000_000) {
        die {
            error   => 'media_too_big',
            message => 'Arquivo muito grande, precisa ser menor que 10 Megabytes',
        };
    }

    my $upload_asset = $upload->asset->to_file;
    my $sha1         = Digest::SHA1->new;
    $upload_asset->handle->sysseek(0, SEEK_SET);
    $sha1->addfile($upload_asset->handle);
    my $file_sha1 = $sha1->hexdigest;

    my $cliente_id = $c->stash('user')->{id};
    my $rs         = $c->schema->resultset('MediaUpload');

    # upload duplicado [por mesmo usuário], retorna o mesmo ID
    my ($ret, $existing) = $rs->search({cliente_id => $cliente_id, file_sha1 => $file_sha1})->next;
    if ($existing) {
        $ret = $existing;
        goto RENDER;
    }

    # Quando o upload é pequeno, o Mojo otimiza deixando tudo na RAM. Para fazer o upload pra S3, é necessário
    # mover para um arquivo em disco.
    my $ext = (split(m{\.}, $upload->filename))[-1];

    # Em caso de PNG, vamos mudar pra JPEG (pelo menos ate alguem reclamar de transparencia kk)
    my $convert_ext = $ext =~ /png/i ? 'jpg' : $ext;

    my $dbh_pg    = $c->schema->storage->dbh;
    my $now       = DateTime->now;
    my $id        = $dbh_pg->selectrow_arrayref("select uuid_generate_v4()", {Slice => {}})->[0];
    my $s3_prefix = sprintf(
        '%s/cliente_%d/%sT%s.%s',
        $params->{intention},
        $cliente_id,
        $now->date('-'),
        $now->hms(''),
        $id
    );

    my $media = get_media_filepath("$id.tmp-orig.$ext");
    $upload->move_to($media);
    on_scope_exit {
        unlink($media);
    };

    my $row;
    if ($ext =~ /(png|jpeg|jpg)/i) {
        my $media_sd = "$media.sd.$convert_ext";
        my $media_hd = "$media.hd.$convert_ext";
        on_scope_exit {
            unlink $media_hd;
            unlink $media_sd;
        };

        my $image = Imager->new;
        $image->set_file_limits(width => 10_000, height => 10_000, bytes => (10_000 * 10_000 * 4) * 1.2,);

        $image->read(file => $media);
        die {error => 'imager_error', message => "Erro ao processar imagem: " . $image->errstr}
          if $image->errstr;

        $image = Lgpdjus::ImageUtils::rotate_filepath($image, $media);

        my $max_xpixels_sd = $ENV{MAX_UPLOAD_SD_X_PIXELS} || 720;
        my $max_ypixels_sd = $ENV{MAX_UPLOAD_SD_Y_PIXELS} || 480;

        my $max_xpixels_hd = $ENV{MAX_UPLOAD_HD_X_PIXELS} || 3240;
        my $max_ypixels_hd = $ENV{MAX_UPLOAD_HD_Y_PIXELS} || 2160;

        my $image_sd = $image;

        # se altura ou largura passar, faz o resize
        if ($image->getwidth > $max_xpixels_sd || $image->getheight > $max_ypixels_sd) {
            $image_sd
              = $image->scale(xpixels => $max_xpixels_sd, ypixels => $max_ypixels_sd, qtype => 'mixing', type => 'min');
        }
        $image_sd->write(file => $media_sd) or die $image_sd->errstr;

        if ($image->getwidth > $max_xpixels_hd || $image->getheight > $max_ypixels_hd) {
            $image
              = $image->scale(xpixels => $max_xpixels_hd, ypixels => $max_ypixels_hd, qtype => 'mixing', type => 'min');
        }
        $image->write(file => $media_hd) or die $image->errstr;

        my $sd
          = $c->_uploader->upload({path => $s3_prefix . ".sd.$convert_ext", file => $media_sd, type => 'image/jpeg',});

        my ($hd, $uploaded) = ($sd, 0);

        # se a resolucao eh diferente, faz upload, caso contrario copia
        if (join('', $image_sd->getwidth, $image_sd->getheight) ne join('', $image->getwidth, $image->getheight)) {
            $uploaded++;
            $hd = $c->_uploader->upload(
                {path => $s3_prefix . ".hd.$convert_ext", file => $media_hd, type => 'image/jpeg',});
        }

        $row = {
            file_info => to_json(
                {
                    sd_dim => [$image_sd->getwidth, $image_sd->getheight],
                    hd_dim => [$image->getwidth,    $image->getheight],
                    o_ext  => $ext,
                }
            ),
            file_size        => $uploaded ? -s $media_hd : 0,
            file_size_avatar => -s $media_sd,
            s3_path          => $hd,
            s3_path_avatar   => $sd,
        };

    }
    else {
        die {
            error   => 'unsupported_media_type',
            message => 'Tipo de arquivo não é suportado.',
        };
    }

    $row->{id}         = $id;
    $row->{intention}  = $params->{intention};
    $row->{file_sha1}  = $file_sha1;
    $row->{cliente_id} = $cliente_id;
    $row->{created_at} = DateTime->now->datetime(' ');

    $ret = $rs->create($row);

    return $ret if $c->stash('return_upload');
  RENDER:

    return $c->render(
        json => {
            id => $ret->id,
        },
        status => 200,
    );
}

1;
