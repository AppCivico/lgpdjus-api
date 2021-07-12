#<<<
use utf8;
package Lgpdjus::Schema::Result::DirectusUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("directus_users");
__PACKAGE__->add_columns(
  "id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "first_name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "last_name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "location",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "tags",
  { data_type => "json", is_nullable => 1 },
  "avatar",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "language",
  {
    data_type => "varchar",
    default_value => "en-US",
    is_nullable => 1,
    size => 8,
  },
  "theme",
  {
    data_type => "varchar",
    default_value => "auto",
    is_nullable => 1,
    size => 20,
  },
  "tfa_secret",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "status",
  {
    data_type => "varchar",
    default_value => "active",
    is_nullable => 0,
    size => 16,
  },
  "role",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
  "token",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "last_access",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "last_page",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "lgpdjus_items_per_page",
  { data_type => "integer", default_value => 20, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("directus_users_email_unique", ["email"]);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-07-12 18:51:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XPUcTJqtzIO8Czguf9h9vw

use feature 'state';
use Crypt::Passphrase::Argon2;

sub check_password {
    my ($self, $password) = @_;

    state $passphrase = Crypt::Passphrase::Argon2->new();

    return $passphrase->verify_password($password, $self->get_column('password'));
}

sub name_or_email {
    my $self = shift;
    return $self->first_name || $self->email;
}

sub set_password {
    my ($self, $new_password) = @_;

    state $passphrase = Crypt::Passphrase::Argon2->new();

    my $newpass = $passphrase->hash_password($new_password);
    $self->update(
        {
            password => $newpass,
        }
    );
    return 1;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
