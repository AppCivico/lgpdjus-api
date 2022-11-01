package Lgpdjus::Controller::Govbr;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;


sub web_entrar {
    my $c = shift;

    $c->stash(texto    => 'Instale o aplicativo LGPDJus para entrar');
    $c->stash(template => 'govbr/texto');

    return $c->render(html => {});
}

# fluxo de logout
# -> app chama o endereço da api, que manda pro sso do govbr, que depois leva de volta pra ca
# -> aqui leva de novo pra lgpdjus://loggedout que deve voltar o usuário pro app, que finalmente conclui o logout
sub web_retorno_logout {
    my $c = shift;

    $c->stash(texto      => 'Você foi deslogado com sucesso. Retorne ao aplicativo para entrar');
    $c->stash(logged_off => 1);
    $c->stash(template   => 'govbr/texto');

    return $c->render(html => {});
}

sub web_textos {
    my $c = shift;

    my $query = $c->req->params->to_hash;
    $c->stash(texto    => $query->{texto});
    $c->stash(sucesso  => $query->{sucesso});
    $c->stash(template => 'govbr/texto');

    return $c->render(html => {});
}

# /permissoes-e-contas
# /recurso-acessibilidade
# - recurso_acessibilidade_ios
# - recurso_acessibilidade_android
# /govbr-niveis


1;
