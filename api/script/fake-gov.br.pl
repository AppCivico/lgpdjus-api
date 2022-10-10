use Mojolicious::Lite -signatures;
use Cache::File;
use Mojo::URL;
use JSON;
use Crypt::JWT qw(encode_jwt decode_jwt);
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::Bignum;
use MIME::Base64;

my $rsa_pvt = Crypt::OpenSSL::RSA->new_private_key(
    '-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA0LdLaW9i0NUVwV1+ZSnwwYebLliFLCEQjzsklGww0fYa0VWM
kEl/WD1mam/idqqAadkgMKzZY4JWx824rRpHOosTJbOMHKa1cRA933yv8Ywzahmx
ih9Jx/QjK2VHSlxTRq2cKN/E9S2VN64PBlBc2LsoAzM9M4r9X90KJFi3+VazjDZ+
9iWA5UCqrWcGrEy21ZVLF27Dm03STIewtV9goBn/7Gd5sMfDfnvMLKSK5ZRbGigt
fkjS91qZUiHjU+WXJrMS2mTr/W9fmAJ7R9jQ09wpJVqP+UOnFjL/0mesAQ5H4FTt
RoXhYiKF3zqckRkAwRuP3sv2nCGA8MoiZR5rFwIDAQABAoIBAFpoSz4shX04D+hm
ey2O8T6jYtC8f1MSL34bfEjeZHdOR2eNywllDMhIMGjCdjI4wM8YwhzTgobcGoMJ
1YkF7Pyq6WxXTcXLYKTNCEAaXowe0taOspzF2MvIMMPHZw4K1/exlAcQhtw9Fnm7
574waUdoKnjYZRZCimZP9OixlV9nKrD36lytd1HewwcD+nm0whMq4Ud5W9AyGwwM
xJR9++srSiqi6wpj5p1cP73UgpdOn293foATV3NBjTBjndk/q1IoO8ylv+rn2Pwi
iFYGHUIrLsBBBYYPclEggP09M/r4vLlVhMpvf+0UBOodRLk5QuGsPlk3ch/jfSpf
f1JNLYECgYEA6lf4yjim+U3LumPKYzhM0zsQf5Qvp0pGb/7XWw3WdWc3hcnJevMp
uL1k6Qyg3186K+loJqdrsDqOQhZO2BBA8TMcsgiiEk2pTl5InSIf/aedNzuClX0D
gxjgOTMsp+9G6YafcvzG+5gCuFM0ONqyyC+mOl55ICSF0HPgN7TaUhECgYEA5AEI
LoxwPs4fXmXmpNg/2JD8upwl8GdEiDs4yaY2kE+5ocvtaNn6qi3kO5cDIAmkUqFE
WwjFMD2sROROtpivrlb3+GJbrjbmY27KrEFd5RkNRCArZV+sUNt/s7RrvNOVvJ9z
e82xYrNBXhpFhnaI4oLSN9ZWjx+mroX2M65iwqcCgYEAzzForqLYPqQh9HI2hvNI
OZqHQ8VpPKfXDz5qef8KFlNkK831bdeAk+4gQk0AD37Kl/iONV7hP7cGADhpDW+R
e7CNNnubkENJ5hhGa2e4kTSZNDRRiIo3iLl9xhUQ7ooIUIDOiYQlCl2kSgSGr53t
ZEF83y6YOWsRRPSu0ZH9VYECgYA4A/zjmsM02uUgBv78Ptioty4wFo7HmkdfBNW1
zO0Y1U1w7637FZqc1rt83GP7KgNB/bbSerwfVveM0V55Q9fdiCZR0rBdg8VkZmLK
oSCVWWtF8nVW6YNnNhYQq2HQuVbPSYlQwD81VX7YxLGSEGse4y8MYs9PSGJl/Cl5
lv1SfwKBgFE8zTWFAnMOBczF0VCl0hpUaIknlTwvL6iGf5Vl4M4XBKE8KEkjE+gE
H7lxZ8XxxVHrvm++BZZk5uSmIWGUZlJuRNLQDiRxLqNOAaG12YGyg/eTJOzkvzfL
U8UQV8ROVyZR1Rw8ya9ksAmlDjy55VOXHT9pvHd/FjQMcBeh9lE8
-----END RSA PRIVATE KEY-----'
);

my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key(
    '-----BEGIN RSA PUBLIC KEY-----
MIIBCgKCAQEA0LdLaW9i0NUVwV1+ZSnwwYebLliFLCEQjzsklGww0fYa0VWMkEl/
WD1mam/idqqAadkgMKzZY4JWx824rRpHOosTJbOMHKa1cRA933yv8Ywzahmxih9J
x/QjK2VHSlxTRq2cKN/E9S2VN64PBlBc2LsoAzM9M4r9X90KJFi3+VazjDZ+9iWA
5UCqrWcGrEy21ZVLF27Dm03STIewtV9goBn/7Gd5sMfDfnvMLKSK5ZRbGigtfkjS
91qZUiHjU+WXJrMS2mTr/W9fmAJ7R9jQ09wpJVqP+UOnFjL/0mesAQ5H4FTtRoXh
YiKF3zqckRkAwRuP3sv2nCGA8MoiZR5rFwIDAQAB
-----END RSA PUBLIC KEY-----'
);

my ($n, $e, @o) = $rsa_pub->get_key_parameters();

# tem algo de errado aqui
$n = encode_base64($n->to_bin(), '');
$e = encode_base64($e->to_bin(), '');


my $kids = {
    "keys" => [
        {
            "kty" => "RSA",
            "kid" => "rsa1",
            "alg" => "RS256",
            "use" => "sig",
            "n"   => $n,
            "e"   => $e
        }
    ]
};

=pod
my $encoded = encode_jwt(
    payload       => {a => 'b'},
    alg           => 'RS256',
    key           => $rsa_pvt,
    extra_headers => {'kid' => 'rsa1'},
);

my $decoded = decode_jwt(
    token => $encoded,
    key   => $rsa_pub,
);

# ta falhando...
my $decoded2 = decode_jwt(
    token    => $encoded,
    kid_keys => $kids,
);
use DDP;
p $decoded2;

exit;
=cut

# http://127.0.0.1:3000/authorize?response_type=code&client_id=foo&scope=bar&redirect_uri=http%3A%2F%2Flocalhost%2Fgov-br-get-token&nonce=not&state=jwt&code_challenge=foo&&code_challenge_method=S256

my $cache = Cache::File->new(
    cache_root      => '/tmp/govbrcache',
    default_expires => '86400 sec'
);


get '/jwk' => sub ($c) {
    $c->render(json => $kids);
};


get '/authorize' => sub ($c) {
    my $query = $c->req->params->to_hash;

    return $c->render(template => 'err', message => 'inválido response_type')
      if !$query->{response_type} || $query->{response_type} ne 'code';
    return $c->render(template => 'err', message => 'faltando client_id')      unless $query->{client_id};
    return $c->render(template => 'err', message => 'faltando scope')          unless $query->{scope};
    return $c->render(template => 'err', message => 'faltando redirect_uri')   unless $query->{redirect_uri};
    return $c->render(template => 'err', message => 'faltando nonce')          unless $query->{nonce};
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

    my $redirect_uri = $query->{redirect_uri};
    my $state        = $query->{'state'};

    my $url = Mojo::URL->new($redirect_uri);
    $url->query({'state' => $state, code => $code});


    $cache->set("session:$code:form", to_json($form));

    $c->redirect_to($url->to_string());
};

post '/token' => sub ($c) {
    my $form = $c->req->params->to_hash;

    return $c->render(template => 'err', message => 'inválido grant_type')
      if !$form->{grant_type} || $form->{grant_type} ne 'authorization_code';
    return $c->render(template => 'err', message => 'faltando code')          unless $form->{code};
    return $c->render(template => 'err', message => 'faltando redirect_uri')  unless $form->{redirect_uri};
    return $c->render(template => 'err', message => 'faltando code_verifier') unless $form->{code_verifier};

    my $code  = $form->{code};
    my $query = $cache->get("session:$code:query");
    return $c->render(template => 'err', message => 'form expirou') unless $query;
    $query = from_json($query);

    my $form = $cache->get("session:$code:form");
    return $c->render(template => 'err', message => 'form expirou') unless $form;
    $form = from_json($form);

    use DDP;
    p $query;

    $c->render(
        json => {

            access_token => encode_jwt(
                payload => {

                    "jti"   => reverse($code),
                    "aud"   => $query->{client_id},
                    "iss"   => "https://sso.staging.acesso.gov.br/",
                    "iat"   => time(),
                    "exp"   => time() + 3600,
                    "uat"   => "...",
                    "scope" => [
                        "govbr_confiabilidades",
                        "email",
                        "profile",
                        "openid"
                    ],
                    "sub"                => $form->{cpf},
                    "preferred_username" => $form->{cpf},
                    "amr"                => ["passwd"],
                    "nonce"              => $query->{nonce}
                },
                alg           => 'RS256',
                key           => $rsa_pvt,
                extra_headers => {'kid' => 'rsa1'},
            ),
            id_token => encode_jwt(
                payload => {
                    "jti"                => reverse($code),
                    "sub"                => $form->{cpf},
                    "preferred_username" => $form->{cpf},
                    "aud"                => $query->{client_id},
                    "iss"                => "https://sso.staging.acesso.gov.br/",
                    "iat"                => time(),
                    "exp"                => time() + 3600,
                    "scope"              => [
                        "govbr_confiabilidades",
                        "email",
                        "profile",
                        "openid"
                    ],
                    "amr"            => ["passwd"],
                    "nonce"          => $query->{nonce},
                    "name"           => $form->{name},
                    "email"          => $form->{email},
                    "email_verified" => $form->{email_verified},
                    "picture"        => "https://sso.staging.acesso.gov.br/userinfo/picture",
                    "profile"        => "https://contas.staging.acesso.gov.br"
                },
                alg           => 'RS256',
                key           => $rsa_pvt,
                extra_headers => {'kid' => 'rsa1'},
            ),
            token_type => 'Bearer',
            expires_in => '3600',
            scope      => 'govbr_confiabilidades email profile openid',
        }
    );
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