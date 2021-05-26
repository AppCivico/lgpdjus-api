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
  "condition",
  {
    data_type => "varchar",
    default_value => "[% 1 %]",
    is_nullable => 0,
    size => 2000,
  },
  "end_screen",
  {
    data_type => "varchar",
    default_value => "home",
    is_nullable => 0,
    size => 200,
  },
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
    data_type => "varchar",
    default_value => "[% 1 %]",
    is_nullable => 0,
    size => 2000,
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
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "clientes_quiz_sessions",
  "Lgpdjus::Schema::Result::ClientesQuizSession",
  { "foreign.questionnaire_id" => "self.id" },
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

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-12 18:31:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EH3H0IAhgZh8egcnnqrJGA

sub as_hashref {
    my $self = shift;
    return {
        map { $_ => $self->get_column($_) }
          qw/
          id
          created_on
          modified_on
          active
          condition
          end_screen
          code
          icon_href
          label
          short_text
          is_test
          due_days
          sort
          /,
    };
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
