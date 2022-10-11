package Lgpdjus::Controller::Govbr;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;


sub web_entrar {
    my $c = shift;

    $c->stash(texto    => 'Instale o aplicativo LGPDJus para entrar');
    $c->stash(template => 'webfaq/texto');

    return $c->render(html => {});
}

sub web_retorno_logout {
    my $c = shift;

    $c->stash(texto    => 'Você foi deslogado com sucesso. Retorne ao aplicativo para entrar');
    $c->stash(template => 'webfaq/texto');

    return $c->render(html => {});
}




1;
