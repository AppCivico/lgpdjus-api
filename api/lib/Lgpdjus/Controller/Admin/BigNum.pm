package Lgpdjus::Controller::Admin::BigNum;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;
use JSON;
use Lgpdjus::Utils;
use DateTime;
use MooseX::Types::Email qw/EmailAddress/;
use Crypt::JWT qw(encode_jwt decode_jwt);
use Mojo::URL;

sub abignum_get {
    my $c = shift;
    $c->stash(
        template => 'admin/big_num',
    );

    if (!$ENV{METABASE_BASE_URL}) {
        my $message = 'Faltando configurar METABASE_BASE_URL';
        $c->flash_to_redis({message => $message});

        return $c->respond_to_if_web(
            json => {json => {message => $message}}, html => {},
        );
    }

    my @rows = (
        {name => 'Visão Geral',         resource => {dashboard => 3}, params => {}},
        {name => 'Resumo solicitações', resource => {dashboard => 2}, params => {}},
        {name => 'Resumo solicitantes', resource => {dashboard => 1}, params => {}},
    );
    my $metabase_secret = $ENV{METABASE_SECRET} || 'secret';
    my @ret             = ();
    foreach my $payload (@rows) {
        $payload->{_}{admin_user} = $c->stash('admin_user')->id;
        $payload->{exp} = time() + 3600;                           # 1 hour

        my $jwt = encode_jwt(
            alg     => 'HS256',
            key     => $metabase_secret,
            payload => $payload
        );
        my $url = Mojo::URL->new($ENV{METABASE_BASE_URL});
        $url->path('/embed/dashboard/' . $jwt);
        $url->fragment('bordered=false&titled=false');

        push @ret, {
            name => $payload->{name},
            url  => $url->to_string(),
        };
    }

    return $c->respond_to_if_web(
        json => {
            json => {
                reports => \@ret,
            }
        },
        html => {
            reports => \@ret,
        },
    );
}


1;
