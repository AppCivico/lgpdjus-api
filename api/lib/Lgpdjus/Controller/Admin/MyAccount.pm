package Lgpdjus::Controller::Admin::MyAccount;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;
use JSON;
use Lgpdjus::Utils;

sub a_myacc_get {
    my $c = shift;

    $c->use_redis_flash();
    $c->stash(
        template => 'admin/myaccount',
    );

    return $c->respond_to_if_web(
        json => {
            json => {

            }
        },
        html => {

        },
    );
}

sub a_myacc_save_post {
    my $c = shift;

    $c->use_redis_flash();
    $c->stash(
        template => 'admin/myaccount',
    );
    my $valid = $c->validate_request_params(
        first_name       => {required => 1, type => 'Str', empty_is_valid => 1},
        last_name        => {required => 0, type => 'Str', empty_is_valid => 1},
        current_password => {required => 0, type => 'Str', empty_is_valid => 1},
        password         => {required => 0, type => 'Str', empty_is_valid => 1},
        password_confirm => {required => 0, type => 'Str', empty_is_valid => 1},

        lgpdjus_items_per_page => {required => 0, type => 'Int'},
    );

    if ($valid->{password} && !$valid->{current_password}) {
        $c->flash_to_redis({message => 'A senha atual é necessária para trocar a senha.'});
        $c->redirect_to('/admin/myacc');
        return 0;
    }
    elsif ($valid->{password} && ($valid->{password_confirm} || '') ne $valid->{password}) {
        $c->flash_to_redis({message => 'A nova senha e confirme a nova senha precisam ser iguais.'});
        $c->redirect_to('/admin/myacc');
        return 0;
    }
    if ($valid->{password} && length($valid->{password}) < 6) {
        $c->flash_to_redis({message => 'A nova senha senha precisa ter pelo menos 6 dígitos.'});
        $c->redirect_to('/admin/myacc');
        return 0;
    }

    if ($valid->{password} && $valid->{current_password}) {
        if (!$c->stash('admin_user')->check_password($valid->{current_password})) {
            $c->flash_to_redis({message => 'A senha atual não confere.'});
            $c->redirect_to('/admin/myacc');
            return 0;
        }

        $c->stash('admin_user')->set_password($valid->{password});
    }

    if (   $valid->{lgpdjus_items_per_page}
        && $valid->{lgpdjus_items_per_page} > 10
        && $valid->{lgpdjus_items_per_page} <= 100_000)
    {
        $c->stash('admin_user')->update({lgpdjus_items_per_page => $valid->{lgpdjus_items_per_page}});
    }


    if ($valid->{first_name} || $valid->{last_name}) {
        $c->stash('admin_user')->update(
            {
                first_name => $valid->{first_name} || '',
                last_name  => $valid->{last_name}  || '',
            }
        );
    }

    $c->flash_to_redis({success_message => 'Alterações executadas com sucesso!'});
    $c->redirect_to('/admin/myacc');

    return 0;


}

1;
