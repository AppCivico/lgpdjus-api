package Lgpdjus::Controller::JWT;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;
use Lgpdjus::KeyValueStorage;
use JSON;

sub check_user_jwt {
    my $c = shift;

    my $kv = Lgpdjus::KeyValueStorage->instance;
    my $jwt_key =
      $c->req->param('api_key') || $c->req->headers->header('x-api-key');

    # Authenticated
    if ($jwt_key) {
        $c->app->log->info("jwt-key: $jwt_key");
        my $claims = eval { $c->decode_jwt($jwt_key) };
        if ($@) {
            $c->render(
                json => {
                    error   => 'expired_jwt',
                    nessage => "Bad request - Invalid JWT"
                },
                status => 400
            );
            $c->app->log->error("JWT Error: $@");
            return undef;
        }

        # Fez o parser, e o tipo da chave é de usuario
        if (   defined $claims
            && ref $claims eq 'HASH'
            && $claims->{typ} eq 'usr' )
        {

            # usar o redis pra nao precisar ir toda hora no banco de dados
            my $session_id = $claims->{ses};
            my $cache_key  = "CaS:$session_id";
            my $ignore_cache = 0;
          AGAIN:
            my $user_id    = $kv->redis_get_cached_or_execute(
                $cache_key,
                300,    # 5min
                sub {
                    my $ret =
                      $c->schema->resultset('ClientesActiveSession')->search(
                        { 'me.id' => $session_id },
                        {
                            result_class =>
                              'DBIx::Class::ResultClass::HashRefInflator',
                            columns => ['cliente_id']
                        }
                    )->next;
                    return '' if !$ret;
                    return $ret->{cliente_id};
                },
                $ignore_cache
            );
            if ( !$user_id ) {
                $c->render(
                    json => {
                        error   => 'jwt_logout',
                        message =>
                          "Está sessão não está mais válida (Usuário saiu)"
                    },
                    status => 403
                );
                return undef;
            }
            if ( $user_id !~ /^\d+$/a ) {
                $c->log->error( "invalid return from redis_get_cached_or_execute should be a number: $user_id, running again with ignore cache" );
                $ignore_cache++;
                goto AGAIN;
            }

            Log::Log4perl::NDC->remove;
            Log::Log4perl::NDC->push( 'user-id:' . $user_id );

            $c->stash(
                apply_rps_on      => 'D' . $user_id,
                user_id           => $user_id,
                jwt_session_id    => $session_id,
                session_cache_key => $cache_key
            );

            $c->res->headers->header( 'x-extra' => 'user-id:' . $user_id );

            # 120 requests over 60 seconds
            $c->apply_request_per_second_limit( 120, 60 );

            # Can continue
            return 1;
        }else{
            $c->log->error("jwt is not valid");
        }
    }
    $c->log->error("missing jwt-key");

    die {
        status  => 401,
        error   => 'missing_jwt',
        message => "Not Authenticated"
    };
}

1;
