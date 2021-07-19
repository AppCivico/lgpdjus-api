#<<<
use utf8;
package Lgpdjus::Schema::Result::ClientesQuizSession;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("clientes_quiz_session");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "clientes_quiz_session_id_seq",
  },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "questionnaire_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "finished_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "stash",
  { data_type => "json", is_nullable => 1 },
  "responses",
  { data_type => "json", is_nullable => 1 },
  "deleted_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "deleted",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "ticket_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "can_delete",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Lgpdjus::Schema::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "questionnaire",
  "Lgpdjus::Schema::Result::Questionnaire",
  { id => "questionnaire_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "ticket",
  "Lgpdjus::Schema::Result::Ticket",
  { id => "ticket_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-27 13:41:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:prrFrxLz1J5OTgxgea7uZg

# ALTER TABLE clientes_quiz_session ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE clientes_quiz_session ADD FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE clientes_quiz_session ADD FOREIGN KEY (questionnaire_id) REFERENCES questionnaires(id) ON DELETE CASCADE ON UPDATE cascade;

use DateTime;
use Scope::OnExit;
use Digest::SHA qw/sha256_hex/;
use Encode qw/encode_utf8/;
use JSON;
use Lgpdjus::Utils qw/tt_render/;
use Lgpdjus::Logger;
use Mojo::DOM;

sub generate_ticket {
    my ($self, $c) = @_;

    my ($locked, $lock_key) = $c->kv->lock_and_wait("generate_ticket:user:" . $self->cliente_id);
    on_scope_exit { $c->kv->redis->del($lock_key) };
    return unless $locked;

    # se já existe, nao cria outro
    $self->discard_changes;
    if ($self->ticket_id) {
        log_trace(['generate_ticket:load', $self->ticket->id]);
        return $self->ticket;
    }
    my $content = to_json($self->build_questionnaire_questions_reply());

    my $ticket;
    my $try = 0;
  AGAIN:
    $try++;
    my $protocol = $self->_get_protocol_token($c);

    eval {
        $self->result_source->schema->txn_do(
            sub {
                $ticket = $self->cliente->tickets->create(
                    {
                        content          => $content,
                        content_hash256  => sha256_hex(encode_utf8($content)),
                        questionnaire_id => $self->questionnaire_id,
                        protocol         => $protocol,
                        status           => 'pending',
                        due_date         => \[
                            "now() + (?::text || ' days')::interval",
                            $self->search_related_rs('questionnaire')->get_column('due_days')->next()
                        ],
                        created_on => \'now()',
                        updated_at => \'now()',
                        started_at => \'now()',
                    }
                );
                $ticket->_generate_pdf(
                    $c, 'cliente_send_email',
                    {
                        template => 'ticket_created',
                    }
                );
                $self->update({ticket_id => $ticket->id, can_delete => 0});
                $c->dpo_send_email(ticket => $ticket, template => 'new_ticket');
            }
        );
    };
    if ($@ && $@ =~ /ticket_protocol_uniq_idx/) {
        log_error("Redis cache failed! $@");
        my $base         = &_get_protocol_prefix();
        my $max_protocol = $self->result_source->schema->resultset('Ticket')
          ->search({'-and' => [\["protocol::text like ? || '%'", $base]]})->get_column('protocol')->max();

        my $protocol_day = substr($max_protocol, 0, length($base));
        my $protocol_seq = substr($max_protocol, length($base));
        log_error(
            "max protocol is $max_protocol, protocol day is $protocol_day, protocol_seq is $protocol_seq. Updating redis"
        );
        $c->kv->redis->set($ENV{REDIS_NS} . 'protocol_seq' . $protocol_day, int($protocol_seq));
        goto AGAIN if $try < 10;
    }
    elsif ($@) {
        log_error("Try $try/10 - fatal error: $@");
        sleep 1;
        goto AGAIN if $try < 10;
        die $@;
    }

    log_trace(['generate_ticket:new', $ticket->id]);

    $ticket->discard_changes;
    return $ticket;
}

sub _get_protocol_prefix {
    my $now  = DateTime->now->set_time_zone('America/Sao_Paulo');
    my $base = substr($now->ymd(''), 2);

    return $base;
}

sub _get_protocol_token {
    my ($self, $c) = @_;

    # captura o horario atual, e depois, fazemos um contador unico (controlado pelo redis),
    # o redis lembra por 2 dias
    # tenha algum retry lentidao na rede e varios clientes tentando processar.

    my $base    = &_get_protocol_prefix();
    my $cur_seq = $c->kv->local_inc_then_expire(
        key     => 'protocol_seq' . $base,
        expires => 86400 * 2,
    );

    # permite até 99999 tickets em 1 dia, acho que ta ok pra este app!
    if ($cur_seq > 99999) {
        return $base . $cur_seq;
    }

    return $base . sprintf('%05d', $cur_seq);
}

sub build_questionnaire_questions_reply {
    my ($self) = @_;

    my @quiz;
    my $vars = from_json($self->responses);
    $vars->{cliente} = {$self->cliente->get_columns()};

    my $stash = from_json($self->stash);
    foreach my $message (@{$stash->{prev_msgs}}) {
        my $content = tt_render($message->{content}, $vars);
        # se o conteudo tiver "html" entao será removido tudo e extraido apenas o textos dos elementos

        push @quiz, {
            content => $content =~ /\</ ? Mojo::DOM->new($content)->all_text : $content,
            type    => $message->{type},
            (exists $message->{_code}      ? (code => $message->{_code})      : ()),
            (exists $message->{__sub}{ref} ? (code => $message->{__sub}{ref}) : ()),    # TROCA o valor quando
                                                                                        # eh grouped-yes-no
        };
    }

    return {
        responses  => from_json($self->responses),
        session_id => $self->id,
        quiz       => \@quiz,
    };
}

1;
