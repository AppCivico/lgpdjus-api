package Lgpdjus::Controller::SobreLGPD;
use Mojo::Base 'Lgpdjus::Controller';
use Lgpdjus::Utils qw/is_test/;
use JSON;

sub apply_rps {
    my $c = shift;

    # limite de requests por segundo no IP
    # no maximo 100 request por hora
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => 'WEB' . substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(100, 3600);

    return 1;
}

sub sobrelgpd_index_get {
    my $c = shift;

    my @sobrelgpd = $c->schema->resultset('Sobrelgpd')->search(
        {
            'me.is_test' => is_test() ? 1 : 0,
        },
        {
            columns => [
                qw/
                  me.id
                  me.nome
                  me.descricao
                  me.link_imagem
                  /
            ],
            order_by     => ['me.sort'],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->all();

    for my $line (@sobrelgpd) {
        $line->{$_} ||= '' for qw/nome descricao link_imagem/;
    }

    return $c->render(
        json => {
            rows => \@sobrelgpd,
        }
    );
}

sub sobrelgpd_detail_get {
    my $c  = shift;
    my $id = $c->param('sobrelgpd_id');
    if ($id !~ /^\d+$/) {
        $c->reply_invalid_param('invalid sobrelgpd_id id');
    }

    my $sobrelgpd = $c->schema->resultset('Sobrelgpd')->search(
        {
            'me.id' => $id,
        },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns      => [
                qw/
                  me.id
                  me.introducao_linha_1
                  me.introducao_linha_2
                  me.perguntas
                  me.rodape
                  /
            ]
        }
    )->next();
    $c->reply_not_found() unless $sobrelgpd;
    $sobrelgpd->{perguntas} = from_json($sobrelgpd->{perguntas});
    $sobrelgpd->{$_} ||= '' for qw/introducao_linha_1 introducao_linha_2 rodape/;

    foreach my $pergunta (@{$sobrelgpd->{perguntas}}) {
        $pergunta->{pergunta} ||= '';
        $pergunta->{resposta} ||= '';
    }

    return $c->render(
        json => {
            sobrelgpd => $sobrelgpd,
        }
    );

    return $c->render(html => {});
}

1;