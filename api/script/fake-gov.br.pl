use Mojolicious::Lite -signatures;
use Cache::File;
use Mojo::URL;
use JSON;

my $cache = Cache::File->new(
    cache_root      => '/tmp/govbrcache',
    default_expires => '1800 sec'
);


get '/authorize' => sub ($c) {
    my $query = $c->req->params->to_hash;

    return $c->render(template => 'err', message => 'inválido response_type')
      if !$query->{response_type} || $query->{response_type} ne 'code';
    return $c->render(template => 'err', message => 'faltando client_id')      unless $query->{client_id};
    return $c->render(template => 'err', message => 'faltando scope')          unless $query->{scope};
    return $c->render(template => 'err', message => 'faltando redirect_uri')   unless $query->{redirect_uri};
    return $c->render(template => 'err', message => 'faltando nounce')         unless $query->{nounce};
    return $c->render(template => 'err', message => 'faltando state')          unless $query->{'state'};
    return $c->render(template => 'err', message => 'faltando code_challenge') unless $query->{code_challenge};
    return $c->render(template => 'err', message => 'inválido code_challenge_method')
      if !$query->{code_challenge_method} || $query->{code_challenge_method} ne 'S256';

    my $code = generate_random_uuid();
    $cache->set("session:$code:query", to_json($query));

    $c->render(template => 'index', 'state' => $query->{'state'}, code => $code);
};

post '/save-and-redirect' => sub ($c) {
    my $form = $c->req->params->to_hash;

    my $code  = $form->{code};
    my $query = $cache->get("session:$code:query");
    return $c->render(template => 'err', message => 'form expirou') unless $query;
    $query = from_json($query);
use DDP; p $query;
    my $redirect_uri = $query->{redirect_uri};
    my $state = $query->{'state'};

    my $url = Mojo::URL->new($redirect_uri);
    $url->query({'state' => $state, code => $code});
use DDP; p $url;
    $c->redirect_to($url->to_string());
};


sub generate_random_uuid {
    my @chars = ('a' .. 'f', 0 .. 9);
    my @string;
    push(@string, $chars[int(rand(16))]) for (1 .. 32);
    splice(@string, 8,  0, '-');
    splice(@string, 13, 0, '-');
    splice(@string, 18, 0, '-');
    splice(@string, 23, 0, '-');
    return join('', @string);
}

app->start;
__DATA__

@@ index.html.ep
% my $url = url_for 'save-and-redirect';

<html>
<head>
</head>
<body>

<h1>Simular login como:</h1>

<form action="<%= $url->to_abs %>" method="post">
  <label for="cpf">CPF *:</label>
  <input required type="text" id="cpf" name="cpf"><br><br>

  <label for="name">Nome *:</label>
  <input required type="text" id="name" name="name"><br><br>

  <label for="phone_number">phone_number:</label>
  <input type="text" id="phone_number" name="phone_number"><br><br>

  <label for="phone_number_verified">phone_number_verified:</label>
  <select id="phone_number_verified" name="phone_number_verified">
      <option value="true">true</option>
      <option value="false">false</option>
  </select>
  <br><br>

  <label for="email">email:</label>
  <input type="email" id="email" name="email"><br><br>

  <label for="email_verified">email_verified:</label>
  <select id="email_verified" name="email_verified">
      <option value="true">true</option>
      <option value="false">false</option>
  </select>
  <br><br>

  <label for="picture">picture:</label>
  <input type="text" id="picture" name="picture"><br><br>

  <input type=hidden name=code value="<%=$code%>" />
  <button type="submit">Login</button><br><br>

  <h2>Debug</h2>
  <p style="color: #888">
    <%=$state%>
  </p>

</form>

</body>
</html>


@@ err.html.ep

<h1>Erro:</h1>

<%= $message %>