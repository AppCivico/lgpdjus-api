#<<<
use utf8;
package Lgpdjus::Schema::Result::RssFeedsTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("rss_feeds_tags");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "rss_feeds_tags_id_seq",
  },
  "rss_feeds_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "tags_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "rss_feed",
  "Lgpdjus::Schema::Result::RssFeed",
  { id => "rss_feeds_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->belongs_to(
  "tag",
  "Lgpdjus::Schema::Result::Tag",
  { id => "tags_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-19 11:54:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y7XGZsvL7PoD+yVT6Ai9Bw

# ALTER TABLE rss_feeds_tags ADD FOREIGN KEY (rss_feeds_id) REFERENCES rss_feeds(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE rss_feeds_tags ADD FOREIGN KEY (tags_id) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
