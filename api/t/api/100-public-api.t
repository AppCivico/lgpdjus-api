use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use DateTime;
use Lgpdjus::Test;

my $t = test_instance;

use DateTime;
use utf8;

my $schema = $t->app->schema;

&clean_up;
on_scope_exit { &clean_up; };
&test_sobrelgpd();

done_testing();

exit;

sub test_sobrelgpd {

    my $c1 = $schema->resultset('Sobrelgpd')->create(
        {
            is_test            => '1',
            nome               => 'hello',
            descricao          => 'descricao',
            link_imagem        => 'http://imagem.com',
            perguntas          => '[{"pergunta":"foo1", "resposta":"bar1"}, {"pergunta":"foo2", "resposta":"bar2"}]',
            introducao_linha_1 => 'introducao_linha_1',
            introducao_linha_2 => 'introducao_linha_2',
            rodape             => 'rodape',
            sort               => 2,
        }
    );
    my $c2 = $schema->resultset('Sobrelgpd')->create(
        {
            is_test     => '1',
            nome        => 'hello2',
            descricao   => 'descricao2',
            link_imagem => 'http://imagem.com',
            perguntas   =>
              '[{"pergunta":"xpt2", "resposta":"<p>paragrafo 1</p>"}, {"pergunta":"xpto", "resposta":"<p>paragrafo 1</p>"}]',
            introducao_linha_1 => 'introducao_linha_1',
            introducao_linha_2 => 'introducao_linha_2',
            rodape             => undef,
            sort               => 1,
        }
    );

    $t->get_ok(
        '/sobrelgpd',
      )->status_is(200, 'puxando index sobrelgpd')    #
      ->json_is('/rows/0/id',          $c2->id, 'first row is c2')    #
      ->json_is('/rows/1/id',          $c1->id, 'sort is working')    #
      ->json_is('/rows/0/descricao',   $c2->descricao)                #
      ->json_is('/rows/0/link_imagem', $c2->link_imagem)              #
      ->json_is('/rows/0/nome',        $c2->nome);


    $t->get_ok(
        '/sobrelgpd/' . $c2->id,
    )->status_is(200, 'puxando detalhe sobrelgpd');


}

sub clean_up {
    $schema->resultset('Sobrelgpd')->search(
        {
            'me.is_test' => '1',
        }
    )->delete;
}