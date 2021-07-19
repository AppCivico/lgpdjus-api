#<<<
use utf8;
package Lgpdjus::Schema::Result::Questionnaire;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("questionnaires");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "questionnaires_id_seq",
  },
  "created_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "modified_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "active",
  { data_type => "boolean", is_nullable => 0 },
  "code",
  {
    data_type => "varchar",
    default_value => "unset",
    is_nullable => 0,
    size => 2000,
  },
  "icon_href",
  {
    data_type => "varchar",
    default_value => "default.svg",
    is_nullable => 0,
    size => 2000,
  },
  "label",
  {
    data_type     => "text",
    default_value => "T\xEDtulo",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "short_text",
  {
    data_type => "varchar",
    default_value => "[% 1 %]",
    is_nullable => 0,
    size => 2000,
  },
  "is_test",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "due_days",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "sort",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "category_short",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "title",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "body",
  { data_type => "varchar", is_nullable => 1, size => 340 },
  "start_button",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "category_full",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "legal_info",
  { data_type => "varchar", is_nullable => 1, size => 340 },
  "requires_account_verification",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "clientes_quiz_sessions",
  "Lgpdjus::Schema::Result::ClientesQuizSession",
  { "foreign.questionnaire_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "quiz_config_button_change_questionnaires",
  "Lgpdjus::Schema::Result::QuizConfig",
  { "foreign.button_change_questionnaire" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "quiz_configs",
  "Lgpdjus::Schema::Result::QuizConfig",
  { "foreign.questionnaire_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "tickets",
  "Lgpdjus::Schema::Result::Ticket",
  { "foreign.questionnaire_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-07-19 11:39:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1sDcqCG+EckheBRh5x3OzQ

sub as_hashref {
    my $self = shift;
    return {
        map { $_ => $self->get_column($_) }
          qw/
          id
          created_on
          modified_on
          active
          code
          icon_href
          label
          short_text
          is_test
          due_days
          sort
          category_full
          category_short
          requires_account_verification
          /,
    };
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
