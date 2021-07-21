#<<<
use utf8;
package Lgpdjus::Schema::Result::TicketsResponse;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("tickets_responses");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tickets_responses_id_seq",
  },
  "user_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "reply_content",
  { data_type => "text", is_nullable => 0 },
  "cliente_reply",
  { data_type => "text", is_nullable => 1 },
  "ticket_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cliente_attachments",
  { data_type => "json", default_value => "[]", is_nullable => 0 },
  "created_on",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "type",
  {
    data_type => "varchar",
    default_value => "response",
    is_nullable => 0,
    size => 255,
  },
  "cliente_reply_created_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Lgpdjus::Schema::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "ticket",
  "Lgpdjus::Schema::Result::Ticket",
  { id => "ticket_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-26 11:26:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rl/TUysQ0e0T7xXp4eixSg

# ALTER TABLE tickets_responses ADD FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE tickets_responses ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE tickets_responses ADD FOREIGN KEY (user_id) REFERENCES directus_users(id) ON DELETE RESTRICT ON UPDATE RESTRICT;

use Lgpdjus::Utils qw/ticket_xml_escape/;
use JSON;

__PACKAGE__->belongs_to(
    "user",
    "Lgpdjus::Schema::Result::DirectusUser",
    {id            => "user_id"},
    {is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT",},
);

sub tr_detail_body {
    my ($self, $c) = @_;
    my $content = '';

    my $dt = $self->created_on->set_time_zone('America/Sao_Paulo');

    $content .= '<div style="border: 1px solid #eee; padding: 10px; color: #3C3C3BBF; font-weight: 300; line-height: 17pt; font-size: 14pt; margin: 0;">';
    if ($self->type eq 'request-additional-info') {
        $content .= sprintf '<strong>Informação adicional necessária:</strong><p>%s</p>',
          ticket_xml_escape($self->reply_content);
        if ($self->cliente_reply) {
            $content .= sprintf '<p>%s</p>', ticket_xml_escape($self->cliente_reply);
        }
    }
    elsif ($self->type eq 'response') {
        $content .= sprintf '<strong>Resposta da solicitação:</strong><p>%s</p>',
          ticket_xml_escape($self->reply_content);
    }
    elsif ($self->type eq 'verify_yes') {
        $content .= sprintf '<strong>Resposta da solicitação - Conta verificada:</strong><p>%s</p>',
          ticket_xml_escape($self->reply_content);
    }
    elsif ($self->type eq 'verify_no') {
        $content .= sprintf '<strong>Resposta da solicitação - Conta não verificada:</strong><p>%s</p>',
          ticket_xml_escape($self->reply_content);
    }
    elsif ($self->type eq 'reopen') {
        $content .= sprintf '<strong>Solicitação reaberta:</strong><p>%s</p>', ticket_xml_escape($self->reply_content);
    }
    elsif ($self->type eq 'due_change') {
        $content .= sprintf '<strong>Mudança de prazo:</strong><p>%s</p>', ticket_xml_escape($self->reply_content);
    }

    my $media = from_json($self->cliente_attachments);
    foreach my $media_id (@{$media}) {
        my $media = $self->cliente->cliente_get_media_by_id($media_id);

        if ($media) {
            my $src = $media->media_generate_download_url($c);
            $content .= sprintf '<img src="%s" />', ticket_xml_escape($src);
        }
        else {
            $content .= sprintf '<p>arquivo %s não encontrado</p>', $media_id;
        }
    }
    $content .= sprintf '<div style="text-align: right; display: block;">Horário: %s</div>',
      $dt->dmy('/') . ' ' . $dt->hms;

    $content .= '</div>';

    return $content;
}

sub tr_can_reply {
    my ($self) = @_;
    return $self->type eq 'request-additional-info' && !$self->cliente_reply ? 1 : 0;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
