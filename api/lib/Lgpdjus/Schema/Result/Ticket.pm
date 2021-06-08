#<<<
use utf8;
package Lgpdjus::Schema::Result::Ticket;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("tickets");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tickets_id_seq",
  },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "due_date",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "status",
  {
    data_type => "varchar",
    default_value => "pending",
    is_nullable => 0,
    size => 255,
  },
  "created_on",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "content",
  { data_type => "json", is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "content_hash256",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 255,
  },
  "questionnaire_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "cliente_pdf_media_upload_id",
  {
    data_type => "varchar",
    default_value => \"null",
    is_foreign_key => 1,
    is_nullable => 1,
    size => 255,
  },
  "user_pdf_media_upload_id",
  {
    data_type => "varchar",
    default_value => \"null",
    is_foreign_key => 1,
    is_nullable => 1,
    size => 255,
  },
  "protocol",
  { data_type => "bigint", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "blockchain_records",
  "Lgpdjus::Schema::Result::BlockchainRecord",
  { "foreign.ticket_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "cliente",
  "Lgpdjus::Schema::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "cliente_pdf_media_upload",
  "Lgpdjus::Schema::Result::MediaUpload",
  { id => "cliente_pdf_media_upload_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->has_many(
  "clientes_quiz_sessions",
  "Lgpdjus::Schema::Result::ClientesQuizSession",
  { "foreign.ticket_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "questionnaire",
  "Lgpdjus::Schema::Result::Questionnaire",
  { id => "questionnaire_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->has_many(
  "tickets_responses",
  "Lgpdjus::Schema::Result::TicketsResponse",
  { "foreign.ticket_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "user_pdf_media_upload",
  "Lgpdjus::Schema::Result::MediaUpload",
  { id => "user_pdf_media_upload_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 11:12:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7if3xLxC2iwZm3btFfFiOw

# ALTER TABLE tickets ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE tickets ADD FOREIGN KEY (questionnaire_id) REFERENCES questionnaires(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE tickets ADD FOREIGN KEY (cliente_pdf_media_upload_id) REFERENCES media_upload(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE tickets ADD FOREIGN KEY (user_pdf_media_upload_id) REFERENCES media_upload(id) ON DELETE CASCADE ON UPDATE cascade;

use JSON;

use Lgpdjus::Utils qw/pg_timestamp2human/;
use Carp qw/confess/;

sub html_preview {
    my ($self) = shift;
    my $tipo = $self->questionnaire->label;

    my $preview = '';
    $preview
      .= sprintf
      '<div style="color: #398FCE;"> <span font-family="Rubik" style="font-size: 18pt; line-height: 22pt; font-weight: 700">%s</span></div>',
      $self->questionnaire->category_full;
    $preview .= sprintf '<div style="color: #646464; font-size: 12pt"> Protocolo: %s</div>', $self->protocol;
    $preview .= sprintf '<div style="color: #646464; font-size: 12pt"> Data de abertura: %s</div>',
      $self->created_at_dmy;
    $preview .= sprintf '<div style="color: #646464; font-size: 12pt"> Situação: %s</div>', $self->status_human_html;

    if ($self->status eq 'wait-additional-info') {
        $preview =~ s/<br\/>$//;
        $preview .= sprintf
          '<div style="color: #646464; font-size: 12pt; padding: 12pt; text-align: center"> São necessárias mais informações para dar continuidade na solicitação. Clique aqui para responder.</div>';
    }
    elsif ($self->status eq 'done') {
        $preview =~ s/<br\/>$//;
        $preview .= sprintf
          '<div style="color: #646464; font-size: 12pt;padding: 12pt; text-align: center"> A solicitação foi respondida, clique aqui para visualizar a resposta.</div>';
    }
    elsif ($self->status eq 'pending') {
        $preview
          .= sprintf
          '<div style="color: #646464; font-size: 12pt; line-height: 12pt; font-weight: 700;"> Prazo: %s</div>',
          $self->due_date_dmy;

        $preview .= sprintf
          '<div style="color: #646464; font-size: 12pt; padding: 12pt; text-align: center"> Sua solicitação está em andamento, clique aqui para visualizar os detalhes da solicitação.</div>';
    }

    $preview =~ s/<br\/>$//;

    return $preview;
}

sub html_detail {
    my ($self, %opts) = @_;
    my $c        = $opts{c} or confess 'missing context';
    my $is_admin = $opts{admin};
    my $is_pdf   = $opts{pdf};

    my $tipo = $self->questionnaire->label;

    my $vars = {
        tipo               => $tipo,
        status_human       => $self->status_human(),
        status             => $self->status(),
        prazo              => $self->due_date_dmy(),
        created_at_dmy_hms => $self->created_at_dmy_hms(),
        is_admin           => $opts{admin},
    };

    my $user_obj = $self->cliente;
    my $content  = from_json($self->content);
    foreach my $quiz_item ($content->{quiz}->@*) {
        my $type     = $quiz_item->{type};
        my $response = $content->{responses}{$quiz_item->{code}};
        $response = $response eq 'N' ? 'Não' : 'Sim' if $type eq 'yesno';
        my $response_hd;

        if ($type eq 'photo_attachment') {
            my $media = $user_obj->cliente_get_media_by_id($response);
            if ($is_pdf) {
                $response = $media->media_generate_download_url_internal($c);
            }
            elsif ($is_admin) {
                $response    = $media->media_generate_download_url_admin($c);
                $response_hd = $media->media_generate_download_url_admin($c, 'hd');
            }
            else {
                $response = $media->media_generate_download_url($c);
            }
        }

        push $vars->{quiz}->@*, {
            type        => $quiz_item->{type},
            question    => $quiz_item->{content},
            response    => $response,
            response_hd => $response_hd,
        };
    }

    local $c->stash->{layout} = undef;
    my $detail = $c->render_to_string('parts/ticket_detail.api', format => 'html', %$vars);

    return $detail;
}

sub html_ticket_responses {
    my ($self, %opts) = @_;
    my $c = $opts{c} or confess 'missing context';

    my $is_pdf   = $opts{pdf};
    my $is_admin = $opts{admin};

    my $vars = {
        pg_timestamp2human => \&pg_timestamp2human,
        responses          => [
            $self->tickets_responses->search(
                undef,
                {
                    prefetch   => 'user',
                    '+columns' => [
                        {
                            user_name     => \'coalesce("user".first_name,"user".email)',
                            response_type => \q!case
                                when "me".type = 'reopen' then 'reabriu solicitação'
                                when "me".type = 'response' then 'concluiu solicitação'
                                when "me".type = 'due_change' then 'mudou o prazo'
                                when "me".type = 'verify_yes' then 'aprovou verificação da conta'
                                when "me".type = 'verify_no' then 'reprovou verificação da conta'
                                else 'pediu informação adicional'
                            end!,
                        }
                    ],
                    order_by     => 'me.created_on',
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                }
            )->all
        ],
    };
    local $c->stash->{layout} = undef;

    my $user_obj = $self->cliente;
    foreach my $response ($vars->{responses}->@*) {
        next if $response->{cliente_attachments} eq '[]';
        my ($attachment) = @{from_json($response->{cliente_attachments})};
        next unless $attachment;

        my $media = $user_obj->cliente_get_media_by_id($attachment);
        if ($is_pdf) {
            $response->{img_href} = $media->media_generate_download_url_internal($c);
        }
        elsif ($is_admin) {
            $response->{img_href}    = $media->media_generate_download_url_admin($c);
            $response->{img_href_hd} = $media->media_generate_download_url_admin($c, 'hd');
        }
        else {
            $response->{img_href} = $media->media_generate_download_url($c);
        }


    }

    return $c->render_to_string('parts/ticket_responses.api', format => 'html', %$vars);
}

sub status_human {
    my ($self) = shift;
    my $map = {
        'pending'              => 'Pendente',
        'done'                 => 'Finalizado',
        'wait-additional-info' => 'Aguardando informação adicional',
    };
    return $map->{$self->status()};
}

sub status_human_html {
    my ($self) = shift;
    my $map = {
        'pending'              => '<span style="color: #444444">⏰ Em andamento</span>',
        'done'                 => '<span style="color: #228C22">✔️ Finalizado</span>',
        'wait-additional-info' => '<span style="color: #E56717">⚠️ Aguardando informações adicionais</span>',
    };
    return $map->{$self->status()};
}

sub obtain_lock {
    my $self = shift;
    $self->result_source->schema->resultset('Ticket')->search({id => $self->id}, {for => 'update', columns => ['id']})
      ->next;
}

sub _generate_pdf {
    my ($self, $c, $helper, $helper_opts) = @_;

    $c->minion->enqueue(
        'generate_pdf_and_blockchain',
        ['ticket', $self->id, $helper, $helper_opts] => {attempts => 5, delay => 1}
    );
}

sub action_reopen {
    my ($self, $c) = @_;

    my $admin_user = $c->stash('admin_user') // confess 'missing stash.admin_user';
    my $success    = 0;
    $c->schema->txn_do(
        sub {
            $self->obtain_lock;
            $self->discard_changes;
            if ($self->status eq 'done') {
                $success = 1;
                $self->tickets_responses->create(
                    {
                        user_id       => $admin_user->id(),
                        cliente_id    => $self->cliente_id(),
                        reply_content => 'Reabrindo solicitação',
                        created_on    => \'now()',
                        type          => 'reopen'
                    }
                );
                $self->ticket_recalc_status_based_on_responses();
                $self->_generate_pdf(
                    $c, 'cliente_send_email',
                    {
                        template => 'ticket_reopen',
                    }
                );
            }
        }
    );

    return $success;
}

sub action_ask_add_info {
    my ($self, $c, %opts) = @_;

    my $message    = $opts{message}          // confess 'missing message';
    my $admin_user = $c->stash('admin_user') // confess 'missing stash.admin_user';


    my $success = 0;
    $c->schema->txn_do(
        sub {
            $self->obtain_lock;
            $self->discard_changes;
            if ($self->status ne 'done') {
                $success = 1;
                $self->tickets_responses->create(
                    {
                        user_id       => $admin_user->id(),
                        cliente_id    => $self->cliente_id(),
                        reply_content => $message,
                        created_on    => \'now()',
                        type          => 'request-additional-info'
                    }
                );
                $self->ticket_recalc_status_based_on_responses();
                $self->_generate_pdf(
                    $c, 'cliente_send_email',
                    {
                        template => 'ticket_request_additional_info',
                    }
                );
            }
        }
    );

    return $success;
}


sub action_verify_cliente {
    my ($self, $c, %opts) = @_;

    my $message    = $opts{message}          // confess 'missing message';
    my $verified   = $opts{verified}         // confess 'missing verified';
    my $admin_user = $c->stash('admin_user') // confess 'missing stash.admin_user';

    my $success = 0;
    $c->schema->txn_do(
        sub {
            $self->obtain_lock;
            $self->discard_changes;
            if ($self->status ne 'done') {
                $success = 1;
                my $type = 'verify_no';
                if ($verified) {
                    $type = 'verify_yes';
                    $self->cliente->update(
                        {
                            account_verified             => '1',
                            account_verification_pending => 0,
                            verified_account_at          => \'now()',
                            verified_account_info        => to_json(
                                {
                                    verified  => 1,
                                    ticket_id => $self->id,
                                    user_id   => $admin_user->id()
                                }
                            )
                        }
                    );
                }
                else {
                    $self->cliente->update(
                        {
                            # libera para que ele faça novamente
                            account_verification_pending => 0,
                            verified_account_info        => to_json(
                                {
                                    verified  => 0,
                                    ticket_id => $self->id,
                                    user_id   => $admin_user->id()
                                }
                            )
                        }
                    );
                }

                $self->tickets_responses->create(
                    {
                        user_id       => $admin_user->id(),
                        cliente_id    => $self->cliente_id(),
                        reply_content => $message,
                        created_on    => \'now()',
                        type          => $type,
                    }
                );

                $self->update(
                    {
                        updated_at => \'now()',
                        status     => 'done',
                    }
                );
                $self->_generate_pdf(
                    $c, 'cliente_send_email',
                    {
                        template => 'ticket_' . $type,
                    }
                );
            }
        }
    );

    return $success;
}

sub action_change_due {
    my ($self, $c, %opts) = @_;
    my $due_date   = $opts{due_date}         // confess 'missing due_date';
    my $admin_user = $c->stash('admin_user') // confess 'missing stash.admin_user';

    $c->reply_invalid_param('Data inválida') unless $due_date =~ /^\d{4}-\d{2}-\d{2}$/;

    my $success = 0;
    $c->schema->txn_do(
        sub {
            $self->obtain_lock;
            $self->discard_changes;
            if ($self->status ne 'done') {
                $success = 1;
                my $old_due = $self->due_date_dmy();

                $self->update(
                    {
                        updated_at => \'now()',
                        due_date   => $due_date . 'T12:00:00',
                    }
                );
                $self->discard_changes;

                if ($old_due eq $self->due_date_dmy()) {
                    $c->reply_invalid_param('Novo prazo não pode igual.');
                }

                $self->tickets_responses->create(
                    {
                        user_id       => $admin_user->id(),
                        cliente_id    => $self->cliente_id(),
                        reply_content => 'Prazo anterior: ' . $old_due . '. Novo prazo: ' . $self->due_date_dmy(),
                        created_on    => \'now()',
                        type          => 'due_change'
                    }
                );
                $self->_generate_pdf(
                    $c, 'cliente_send_email',
                    {
                        template => 'ticket_change_due',
                    }
                );
            }
        }
    );

    return $success;
}

sub action_close {
    my ($self, $c, %opts) = @_;
    my $message    = $opts{message}          // confess 'missing message';
    my $admin_user = $c->stash('admin_user') // confess 'missing stash.admin_user';

    my $success = 0;
    $c->schema->txn_do(
        sub {
            $self->obtain_lock;
            $self->discard_changes;
            if ($self->status ne 'done') {
                $success = 1;
                $self->tickets_responses->create(
                    {
                        user_id       => $admin_user->id(),
                        cliente_id    => $self->cliente_id(),
                        reply_content => $message,
                        created_on    => \'now()',
                        type          => 'response'
                    }
                );

                $self->update(
                    {
                        updated_at => \'now()',
                        status     => 'done',
                    }
                );
                $self->_generate_pdf(
                    $c, 'cliente_send_email',
                    {
                        template => 'ticket_close',
                    }
                );
            }
        }
    );

    return $success;
}

sub ticket_recalc_status_based_on_responses {
    my ($self) = @_;

    my $pending_reply = $self->tickets_responses->search(
        {
            cliente_reply => undef,
            type          => 'request-additional-info'
        }
    )->count > 0;

    $self->update(
        {
            updated_at => \'now()',
            status     => $pending_reply ? 'wait-additional-info' : 'pending'
        }
    );

}

sub due_date_ymd {
    my $self = shift();
    $self->due_date->set_time_zone('America/Sao_Paulo')->ymd();
}

sub due_date_dmy {
    my $self = shift();
    $self->due_date->set_time_zone('America/Sao_Paulo')->dmy('/');
}

sub created_at_dmy {
    my $self = shift();
    $self->created_on->set_time_zone('America/Sao_Paulo')->dmy('/');
}

sub created_at_dmy_hms {
    my $self = shift();
    my $dt   = $self->created_on->set_time_zone('America/Sao_Paulo');
    return $dt->dmy('/') . ' ' . $dt->hms;
}

sub as_hashref {
    my $self = shift;

    my $questionnaire = $self->questionnaire;

    return {
        questionnaire => $questionnaire->as_hashref(),
        map { $_ => $self->get_column($_) } qw/
          id
          cliente_id
          due_date
          status
          created_on
          content
          updated_at
          content_hash256
          questionnaire_id
          cliente_pdf_media_upload_id
          user_pdf_media_upload_id
          protocol
          /,
    };
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
