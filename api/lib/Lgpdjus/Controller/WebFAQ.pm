package Lgpdjus::Controller::WebFAQ;
use Mojo::Base 'Lgpdjus::Controller';
use Lgpdjus::Utils qw/is_test/;
use DateTime;

sub apply_rps {
    my $c = shift;

    # limite de requests por segundo no IP
    # no maximo 100 request por hora
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => 'WEB' . substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(100, 3600);

    $c->stash(
        template          => 'webfaq/texto',
        texto             => 'not defined',
        add_body_gradient => 1,
    );

    return 1;
}

sub web_sobre {
    my $c = shift;

    $c->stash(texto    => $c->schema->resultset('Configuraco')->get_column('texto_sobre')->next());
    $c->stash(template => 'webfaq/texto');

    return $c->render(html => {});
}

sub web_politica_privacidade {
    my $c = shift;

    $c->stash(texto => $c->schema->resultset('Configuraco')->get_column('privacidade')->next());

    $c->stash(template => 'webfaq/texto');

    return $c->render(html => {});
}

sub web_termos_de_uso {
    my $c = shift;

    $c->stash(texto => $c->schema->resultset('Configuraco')->get_column('termos_de_uso')->next());

    $c->stash(template => 'webfaq/texto');

    return $c->render(html => {});
}


1;
