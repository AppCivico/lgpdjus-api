#<<<
use utf8;
package Lgpdjus::Schema::Result::QuizConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("quiz_config");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "quiz_config_id_seq",
  },
  "status",
  {
    data_type => "varchar",
    default_value => "draft",
    is_nullable => 0,
    size => 20,
  },
  "sort",
  { data_type => "integer", is_nullable => 1 },
  "modified_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "type",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 100,
  },
  "code",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 100,
  },
  "question",
  { data_type => "text", default_value => \"null", is_nullable => 0 },
  "yesnogroup",
  { data_type => "json", is_nullable => 1 },
  "intro",
  { data_type => "json", is_nullable => 1 },
  "relevance",
  { data_type => "varchar", default_value => 1, is_nullable => 0, size => 2000 },
  "button_label",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "questionnaire_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "yesno_yes_label",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "yesno_no_label",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "yesno_no_value",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "yesno_yes_value",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "options",
  { data_type => "json", default_value => "[]", is_nullable => 0 },
  "progress_bar",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "appendix",
  { data_type => "json", default_value => "[]", is_nullable => 0 },
  "text_validation",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "camera_lens_direction",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "button_style",
  {
    data_type     => "text",
    default_value => "primary",
    is_nullable   => 1,
    original      => { data_type => "varchar" },
  },
  "button_change_questionnaire",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "button_change_questionnaire",
  "Lgpdjus::Schema::Result::Questionnaire",
  { id => "button_change_questionnaire" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->belongs_to(
  "questionnaire",
  "Lgpdjus::Schema::Result::Questionnaire",
  { id => "questionnaire_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-10-29 22:00:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jHx75iXW1jVM7Lv5dhi7iA

# ALTER TABLE quiz_config ADD FOREIGN KEY (questionnaire_id) REFERENCES questionnaires(id) ON DELETE CASCADE ON UPDATE cascade;
=pod

CREATE FUNCTION f_tgr_quiz_config_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    update questionnaires
     set modified_on = now()
     where id = NEW.questionnaire_id OR id = OLD.questionnaire_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tgr_on_quiz_config_after_update AFTER DELETE OR UPDATE OR INSERT ON quiz_config FOR EACH ROW EXECUTE PROCEDURE f_tgr_quiz_config_after_update();

=cut

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
