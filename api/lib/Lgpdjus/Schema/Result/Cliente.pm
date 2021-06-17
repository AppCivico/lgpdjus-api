#<<<
use utf8;
package Lgpdjus::Schema::Result::Cliente;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("clientes");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "clientes_id_seq",
  },
  "status",
  {
    data_type => "varchar",
    default_value => "setup",
    is_nullable => 0,
    size => 20,
  },
  "created_on",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "cpf",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 200,
  },
  "dt_nasc",
  { data_type => "date", is_nullable => 0 },
  "email",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 200,
  },
  "cep",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 8,
  },
  "cep_cidade",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "cep_estado",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "genero",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 100,
  },
  "nome_completo",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 200,
  },
  "login_status",
  { data_type => "varchar", default_value => "OK", is_nullable => 1, size => 20 },
  "login_status_last_blocked_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "senha_sha256",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 200,
  },
  "qtde_login_senha_normal",
  { data_type => "bigint", default_value => 1, is_nullable => 0 },
  "apelido",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 200,
  },
  "upload_status",
  { data_type => "varchar", default_value => "ok", is_nullable => 1, size => 20 },
  "perform_delete_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "deleted_scheduled_meta",
  { data_type => "text", is_nullable => 1 },
  "deletion_started_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "account_verified",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "verified_account_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "verified_account_info",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
  "account_verification_pending",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("idx_219091_email", ["email"]);
__PACKAGE__->has_many(
  "blockchain_records",
  "Lgpdjus::Schema::Result::BlockchainRecord",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "clientes_active_sessions",
  "Lgpdjus::Schema::Result::ClientesActiveSession",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->might_have(
  "clientes_app_activity",
  "Lgpdjus::Schema::Result::ClientesAppActivity",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "clientes_app_notifications",
  "Lgpdjus::Schema::Result::ClientesAppNotification",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "clientes_preferences",
  "Lgpdjus::Schema::Result::ClientesPreference",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "clientes_quiz_sessions",
  "Lgpdjus::Schema::Result::ClientesQuizSession",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "clientes_reset_passwords",
  "Lgpdjus::Schema::Result::ClientesResetPassword",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "login_erros",
  "Lgpdjus::Schema::Result::LoginErro",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "login_logs",
  "Lgpdjus::Schema::Result::LoginLog",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "media_uploads",
  "Lgpdjus::Schema::Result::MediaUpload",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "noticias_aberturas",
  "Lgpdjus::Schema::Result::NoticiasAbertura",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "notification_logs",
  "Lgpdjus::Schema::Result::NotificationLog",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "tickets",
  "Lgpdjus::Schema::Result::Ticket",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "tickets_responses",
  "Lgpdjus::Schema::Result::TicketsResponse",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-06-08 19:06:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nMlSEFKpbyevv+hFN0wA5w

use Carp qw/confess/;
use Lgpdjus::Utils qw/is_uuid_v4/;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
use Scope::OnExit;
use Lgpdjus::KeyValueStorage;

has 'access_modules' => (is => 'rw', lazy => 1, builder => '_build_access_modules');

sub _build_access_modules {
    my $self = shift;

    my @modules;
    push @modules, qw/tickets noticias/;
    return {map { ($_ => {}) } @modules};
}

sub access_modules_as_config {
    my $meta = {tickets => {reply_max_length => $ENV{TICKET_CONTENT_MAX_LENGTH}}};
    return [map { +{code => $_, meta => $meta->{$_} || {}} } keys $_[0]->access_modules->%*];
}

sub access_modules_str {
    return ',' . join(',', keys $_[0]->access_modules->%*) . ',';
}

sub has_module {
    my $self   = shift;
    my $module = shift || confess 'missing module name';

    return $self->access_modules_str() =~ /,$module,/;
}

# retorna o string para ser usada em FK composta
sub id_composed_fk {
    return shift()->id . ':' . shift;
}

sub cep_formmated {
    my ($self) = @_;
    my $cep = $self->cep;
    $cep =~ s/(.{5})(.{3})/$1-$2/;
    return $cep;
}

sub update_activity {
    my ($self, $is_timeline) = @_;

    return if $ENV{SUPPRESS_USER_ACTIVITY};
    my $key = "ua" . ($is_timeline ? 't:' : ':') . $self->id;

    my $kv = Lgpdjus::KeyValueStorage->instance;

    # atualiza de 5 em 5min o banco
    my $recent_activities = $kv->redis->get($ENV{REDIS_NS} . $key);
    return if $recent_activities;
    $kv->redis->setex($ENV{REDIS_NS} . $key, 60 * 5, 1);

    my $lock = "update_activity:user:" . $self->id;
    $kv->lock_and_wait($lock);
    on_scope_exit { $kv->unlock($lock) };

    my $activity = $self->clientes_app_activity;
    if ($activity) {
        $activity->update(
            {
                (
                    $is_timeline
                    ? (
                        last_tm_activity => \'now()',
                      )
                    : ()
                ),
                last_activity => \'now()',
            }
        );
    }
    else {
        $self->create_related(
            'clientes_app_activity',
            {
                last_activity    => \'now()',
                last_tm_activity => \'now()',
            }
        );
    }
}

sub assistant_session_id {
    return 'A' . substr($_[0]->cpf_hash, 0, 4);
}

sub name_for_admin {
    return $_[0]->apelido . ' (' . $_[0]->nome_completo . ')';
}

sub avatar_url_or_default {
    return $_[0]->avatar_url() || $ENV{AVATAR_PADRAO_URL};
}

sub reset_all_questionnaires {
    my ($self) = @_;

    $self->update(
        {
            quiz_assistant_yes_count => \'quiz_assistant_yes_count+1',
        }
    );
    $self->clientes_quiz_sessions->search({deleted_at => undef})->update(
        {
            deleted    => 1,
            deleted_at => \'NOW()',
        }
    );
}

sub cliente_get_media_by_id {
    my ($self, $id) = @_;
    return undef unless is_uuid_v4($id);
    return $self->media_uploads->search({'me.id' => $id})->next;
}

sub account_html {
    my ($self, %opts) = @_;
    my $c = $opts{c} or confess 'missing context';

    my $vars = {
        cliente => $self,
    };

    local $c->stash->{layout} = undef;
    my $detail = $c->render_to_string('parts/account_detail.api', format => 'html', %$vars);

    return $detail;
}

sub created_at_dmy {
    my $self = shift();
    $self->created_on->set_time_zone('America/Sao_Paulo')->dmy('/');
}

sub created_at_dmy_hms {
    my $self = shift();
    my $dt   = $self->created_on->set_time_zone('America/Sao_Paulo');
    return $dt->dmy('/') . ' ' . $dt->hms() . ' - Horario de Brasília';
}

sub as_hashref {
    my $self = shift;

    return {
        map { $_ => $self->get_column($_) }
          qw/
          id
          status
          created_on
          cpf
          dt_nasc
          email
          cep
          cep_cidade
          cep_estado
          genero
          nome_completo
          login_status
          login_status_last_blocked_at
          senha_sha256
          qtde_login_senha_normal
          apelido
          upload_status
          perform_delete_at
          deleted_scheduled_meta
          deletion_started_at
          account_verified
          verified_account_at
          verified_account_info
          /
    };
}

sub cpf_formatted {
    my $self = shift();
    my $cpf   = $self->cpf =~ /(...)(...)(...)(..)/;
    return "$1.$2.$3-$4";
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
