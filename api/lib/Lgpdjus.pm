package Lgpdjus;
use Mojo::Base 'Mojolicious';

use Lgpdjus::Config;
use Lgpdjus::Helpers;
use Lgpdjus::Routes;
use Lgpdjus::Logger;
use Lgpdjus::Utils;
use Lgpdjus::SchemaConnected;
use Lgpdjus::Authentication;

# carregar controllers usados usados
use Lgpdjus::Controller::Me;

sub startup {
    my $self = shift;

    # Config.
    Lgpdjus::Config::setup($self);

    # Logger.
    undef $Lgpdjus::Logger::instance;
    get_logger();
    $self->plugin('Log::Any' => {logger => 'Log::Log4perl'});

    # RSA keys.
    $self->helper(schema => \&Lgpdjus::SchemaConnected::get_schema);
    my $schema = $self->schema;
    my $secret = $schema->get_jwt_key;

    # usado pra assianr os cookies # https://docs.mojolicious.org/Mojolicious#secrets
    $self->secrets([$secret . '4COOKIES']);

    # Helpers after loaded envs (from schema)
    Lgpdjus::Helpers::setup($self);

    # Não precisa manter conexao no processo manager
    $self->schema->storage->dbh->disconnect if not $ENV{HARNESS_ACTIVE};

    # Plugins.
    $self->plugin('JWT', secret => $secret);

    $self->plugin('ParamLogger', filter => [qw(password senha senha_atual message)]);


    # servir a /public (templates de email e arquivos static)
    $self->plugin('RenderFile');

    $self->plugin('StaticCache' => {even_in_dev => 1, max_age => 31536000});

    # Minion (job manager)
    $self->plugin('Lgpdjus::Minion');

    # Subprocess (do small background jobs without locking worker)
    $self->plugin('Subprocess');

    $self->plugin('AccessLog');

    # Helpers.
    $self->controller_class('Lgpdjus::Controller');

    # Routes.
    Lgpdjus::Routes::register($self->routes);

    # minion admin
    # Secure access to the admin ui with Basic authentication
    my $under = $self->routes->under(
        '/minion' => sub {
            my $c = shift;
            return 1
              if $c->req->url->to_abs->userinfo eq 'admin:' . ($ENV{MINION_ADMIN_PASSWORD} || $c->reply_forbidden());
            $c->res->headers->www_authenticate('Basic');
            $c->render(text => 'Authentication required!', status => 401);
            return undef;
        }
    );
    $self->plugin('Minion::Admin' => {route => $under});

    $self->hook(
        around_dispatch => sub {
            my ($next, $c) = @_;
            Log::Log4perl::NDC->remove;

            $next->();
        }
    );


}

1;
