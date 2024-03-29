# LGPDJus


# Configuração de infraestrutura
Abaixo instruções para uma sugestão para o deploy em Produção/Homologação:

## requisitos do mínimos de sistema

- PostgreSQL 14 ou superior (precisa do gen_random_uuid())
- docker community edition 19 or maior (testado na 19.03.12)
- docker-compose 1.21 ou superior
- Nginx ou outro proxy reverso para finalização do HTTPS
- redis-server 5 ou superior
- Servidor SMTP para envio de e-mails
- S3 (compatível), pode ser AWS s3, backblaze b2 ou subir um MinIO https://min.io/
- Recomendado 4 GB de RAM e 25GB de disco livres para as imagens dos containers.
- Metabase para relatórios (opcional)

## Componentes

<img src="https://raw.githubusercontent.com/AppCivico/lgpdjus-api/main/misc/LGPDJus-Containers.svg" alt="Deps">

<h1>Atenção: para seguir os os passos a passos, utilize o arquivo `docker-compose.from-readme.yaml` e não `docker-compose.yaml`</h1>

No arquivo `docker-compose.yaml` original do repositório, já estão configurados todos os serviços (PostgreSQL, redis, etc..) e não é necessário configurar
cada um individualmente, exceto pelo proxy reverso.

## Instalação dos requisitos:

Instale o PostgreSQL, docker e docker-compose.
No Ubuntu 20.04, os comandos são os seguintes:

docker

> Consultar https://docs.docker.com/engine/install/ubuntu/

    apt-get update
    #apt-get remove docker docker-engine docker.io # remove versoes antigas/da distro
    apt-get install apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install docker-ce


docker-compose

> Consultar https://docs.docker.com/compose/install/

O docker-compose é um binário go e pode ser baixado diretamente usando wget

    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose



PostgreSQL

> Consultar https://www.postgresql.org/download/linux/ubuntu/


    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    sudo apt-get update
    sudo apt-get -y install postgresql-12


nginx:

    apt-get install nginx-extras

redis:

    apt-get install redis-server

> Esta versão do nginx adiciona o suporte ao Lua, que pode ser usado para ter logs mais completos, ajudando no debug.

## Configurando PostgreSQL

> Este é apenas um exemplo, pode ser usado um host externo como RDS por exemplo

Depois de instalado, verifique se o pg encontra-se rodando usando o comando `service postgresql status`, faça o restart ou init do cluster se necessário.

Neste exemplo, vamos deixar o banco rodando no mesmo servidor, porém, o arquivo de configuração de exemplo docker-compose está configurado
para conversar com a bridge do docker, geralmente configurada como 172.17.0.1
Precisamos alterar o PostgreSQL para fazer o listen nessa interface ou configurar o firewall para fazer o encaminhamento.

Altere o `listen_addresses` para o valor de 'localhost,172.17.0.1'
Aproveite para ajustar os valores de random_page_cost e cpu_tuple_cost.

> Ao alterar para 172.17.0.1 é necessário que o postgres suba após o serviço do docker0, caso contrario, o bind não irá funcionar em caso de reboot, para resolver este problema, utilize `EDITOR=view systemctl edit --full postgresql@.service` e depois troque `After=network.target` por `After=sys-devices-virtual-net-docker0.device` Para que o postgres aguarde a interface docker0. Consultar https://serverfault.com/questions/840996/modify-systemd-unit-file-without-altering-upstream-unit-file
> Outra alternativa é criar um novo docker-compose e hospedar o PostgreSQL/redis também em containers.

> Se o hardware encontra-se usando SSD-backed, é recomendado trocar o random_page_cost para 1.1.

> Se o clock da máquina for pelo menos 3ghz, altere cpu_tuple_cost para 0.02.


    ## su postgres
    #$ view /etc/postgresql/12/main/postgresql.conf # edit the file

Ainda nesse usuário, vamos configurar o `pg_hba` para liberar os acessos ao banco

Altere 127.0.0.1 para trust, e adicione a rede usada pelo containers:

    $ view /etc/postgresql/12/main/pg_hba.conf

        ## IPv4 local connections:
        host    all             all             127.0.0.1/32            trust ## Configurar md5 em produção
        host    all             all             172.17.0.0/24           trust ## Configurar md5 em produção

    $ exit

    ## service postgresql restart

Agora, vamos criar o banco:

    ## createdb -h 127.0.0.1 -U postgres lgpdjus_dev

## Configurando redis

> Este é apenas um exemplo, pode ser usado um host externo como ElastiCache for Redis (AWS) por exemplo

Alterar o bind para `bind 127.0.0.1 172.17.0.1` em /etc/redis/redis.conf

O mesmo conceito sobre aguardar a interface docker0 se aplica aqui. Ou então usar docker-compose para subir o redis como container


### Configurando Firewall

Se houver um firewall (recomendado, mesmo se tiver com o firewall da AWS), precisamos ainda adicionar uma regra liberando o container a conversar com a interface bridge docker0

usando UFW firewall, você pode adicionar essa liberação utilizando o seguinte comando:

    ##  ufw allow from 172.17.0.0/24 to any port 5432 proto tcp

> 5432 é a porta do postgres, 172.17.0.0/24 são os hosts que podem conectar com ela.

O LGPDJus também precisa do serviço wkhtmltopdf, que no arquivo .env está configurado para subir em 64596

    ##  ufw allow from 172.17.0.0/24 to any port 64596 proto tcp

O LGPDJus também precisa do serviço redis 6379

    ##  ufw allow from 172.17.0.0/24 to any port 6379 proto tcp


## Build dos containers

Antes de começar, vamos criar as pastas:

    ( o usuário ubuntu precisa ja existir, e ter o id 1000)
    # cd /home/ubuntu
    # git clone https://github.com/appcivico/lgpdjus-backend.git
    # chmod 1000:1000 lgpdjus-backend -R # altera a pasta do codigo para o 1000:1000, pelo menos a pasta de código (/api) precisa estar com o 1000:1000


Para fazer o build, basta ir o path ./api/ e executar o arquivo `build_container.sh`

    # cd /home/ubuntu/lgpdjus-backend/api
    # ./build_container.sh

Esse processo pode levar alguns minutos na primeira vez.

Depois que o processo terminar, temos um arquivo de exemplo de como subir apenas o container da api, `api/sample-run-container.sh` porém vamos utilizar o docker-compose para subir o container junto com o directus e o wkhtmltopdf.

Existe um arquivo .env com as seguintes variáveis:

    DIRECTUS_KEY=5569ed57-66f2-4cbb-b3a9-0b0062edf798    # deve ser alterado para qualquer valor aleatório
    DIRECTUS_SECRET=07cec12f-f625-4006-8b31-e477319b6758 # deve ser alterado para qualquer valor aleatório
    POSTGRESQL_HOST=172.17.0.1 # qual endereço do servidor postgres
    POSTGRESQL_PORT=5432
    POSTGRESQL_DBNAME=lgpdjus_dev
    POSTGRESQL_USER=postgres
    POSTGRESQL_PASSWORD=postgres #
    REDIS_NS=lgpdjus # qual namespace usar no redis
    REDIS_SERVER=172.17.0.1:6379 # qual endereço do servidor do redis
    DIRECTUS_PUBLIC_URL=https://lgpdjus-directus.domain.com   # qual domínio externo do directus
    LGPDJUS_WKHTMLTOPDF_PORT=64596        # qual porta o serviço de html2pdf deve fazer o bind na interface 172.17.0.1
    LGPDJUS_API_PORT=64598                # qual porta o serviço de da api deve fazer o bind na interface 172.17.0.1
    LGPDJUS_DIRECTUS_PORT=64597           # qual porta o serviço de da directus deve fazer o bind na interface 172.17.0.1
    EMAIL_SMTP_HOST=...                   # usado pelo directus, host do smtp
    EMAIL_SMTP_PORT=...                   # porta do smtp (usar 465 para secure)
    EMAIL_SMTP_USER=...                   # usuário do smtp
    EMAIL_SMTP_PASSWORD=...               # senha do smtp

Após configurar, execute o comando `docker-compose config` para ter um preview da configuração.

Além deste arquivo .env para o docker-compose, é necessário configurar o arquivo api/sqitch.conf

    Procure pela parte [target "docker"] e altere o 127.0.0.1 para a configuração correta como no caso acima

<p style="color: red">
⚠️⚠️⚠️ Atenção, ha uma chance do serviço do directus subir antes do serviço da api❗

Neste caso, pode acontecer do directus tentar fazer o migration do schema dele antes do migration da api iniciar (o migration da api já tem o migration do directus dentro). Neste caso, deve-se comentar o serviço do directus e apagar o banco e subir novamente o container da api ou então executar o comando `docker exec -u app lgpdjus_api  /src/script/restart-services.sh` para iniciar novamente o sqitch que irá tentar executar o migration mais uma vez.
</p>

Para subir, basta executar `docker-compose up` e os serviços serão iniciados.

> Como pode ser visto acima, depois que um container esta rodando, para executar comandos dentro do ambiente dele, basta usar comando `docker exec`
> Para abrir um terminal: `docker exec -u app -it lgpdjus_api /bin/bash`. Passe -u root para trocar para root.

Você pode criar o arquivo `api/envfile_local.sh` para trocar as variáveis de ambientes, por exemplo, para aumentar o número de workers da api:

    # view envfile_local.sh e adicionar
    export API_WORKERS="2"

Caso o arquivo não exista, o arquivo padrão será carregado (api/envfile.sh) que tenta manter os valores ja carregados pelo ambiente e seta o default

Depois, ajuste a permissão do arquivo `chmod +x envfile_local.sh`
Após a troca da variável, é possível recarregar o serviço da api usando `docker exec -u app lgpdjus_api  /src/script/restart-services.sh`


Se tudo ocorreu bem, em você poderá acessar o admin do DPO da api usando

    http://172.17.0.1:64598/admin

O usuário e senha padrão (que vem no migration inicial) é `admin@sample.com` e senha `admin@sample.com`


### Configurando nginx:

A configuração do NGINX não é necessária para o ambiente de desenvolvimento, apenas para o ambiente com SSL.

A configuração do nginx ira ser diferente em cada ambiente, mas de qualquer forma, segue a base que usamos usando self-signed:

> Consultar https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04

/etc/nginx/nginx.conf

    real_ip_header CF-Connecting-IP;

    log_format timed_combined_debug '$remote_addr - $remote_user [$time_iso8601] [HOST $http_host] $http_x_host '
    '"$request" $status $body_bytes_sent '
    '"$http_referer" "$http_user_agent" '
    '$request_time $upstream_response_time $pipe $request_length $upstream_addr $http_x_api_key $http_cf_connecting_ip "$request_body" "$resp_body" $http_cf_ray';
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;


/etc/nginx/sites-enabled/lgpdjus-api

    server {
        listen 80;
        server_name lgpdjus-api.domain.com;
        return 302 https://lgpdjus-api.domain.com$request_uri;
    }

    server {
        listen 443 ssl;
        server_name lgpdjus-api.domain.com;

        access_log /var/log/nginx/debug-lgpdjus.log timed_combined_debug;


        charset utf-8;

        location / {
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
            proxy_pass http://172.17.0.1:64598;

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            lua_need_request_body on;

            set $resp_body "";
            body_filter_by_lua '
                local resp_body = string.sub(ngx.arg[1], 1, 50000)

                ngx.ctx.buffered = (ngx.ctx.buffered or "") .. resp_body
                if ngx.arg[2] then
                    ngx.var.resp_body = ngx.ctx.buffered
                end
            ';
        }
    }

/etc/nginx/sites-enabled/lgpdjus-directus

    server {
        listen 80;
        server_name lgpdjus-directus.domain.com;
        return 302 https://lgpdjus-directus.domain.com$request_uri;
    }

    server {
        listen 443 ssl;
        server_name lgpdjus-directus.domain.com;

        access_log /var/log/nginx/access-lgpdjus-directus.log;


        charset utf-8;

        location / {
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
            proxy_pass http://172.17.0.1:64597;

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            lua_need_request_body on;

        }
    }

/etc/nginx/sites-enabled/lgpdjus-metabase

    server {
        listen 80;
        #server_name lgpdjus-metabase.domain.com; # ALTERAR AQUI PARA O VIRTUAL HOST!
        return 302 https://lgpdjus-metabase.domain.com$request_uri;
    }

    server {
        listen 443 ssl;
        #server_name lgpdjus-metabase.domain.com; # ALTERAR AQUI PARA O VIRTUAL HOST!

        access_log /var/log/nginx/access-lgpdjus-metabase.log;


        charset utf-8;

        location / {
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
            #proxy_pass http://172.17.0.1:4757; # ALTERAR AQUI PARA O SERVIÇO CORRETO!

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            lua_need_request_body on;

        }
    }


obs: nesse caso, usamos `/etc/nginx/ssl/nginx.crt` que precisa ser gerado, para servir de certificado auto-assinado antes de entregar os dados para a cloudflare, ou usar certificado da cloudflare, letsencrypt ou ainda então utilizar cloudflared via tunnel, que não precisa fazer esta configuração do nginx (de fato, se não fosse pelo log com debug, poderia inclusive rodar sem o nginx apenas com o cloudflared). Consultar https://dev.to/omarcloud20/a-free-cloudflare-tunnel-running-on-a-raspberry-pi-1jid

    ## mkdir /etc/nginx/ssl
    ## openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt

Outra alternativa é passar utilizar o letsencrypt para gerenciar os certificados.

## Configurando metabase

Assim como a API, o metabase precisa ser acessado por uma interface web para gerenciamento.

O Metabase pode ser executado de várias formas, a mais simples é com docker, salvando os dados dele em outro banco PostgreSQL:

    docker run -d -p 172.17.0.1:4757:3000 \
        -e "MB_DB_TYPE=postgres" \
        -e "MB_DB_DBNAME=lgdpjus_metabase" \
        -e "MB_DB_PORT=5432" \
        -e "MB_DB_USER=postgres" \
        -e "MB_DB_PASS=postgres" \
        -e "MB_DB_HOST=172.17.0.1" \
        --restart unless-stopped \
        --name lgpdjus_metabase metabase/metabase:v0.39.1

Depois só configurar o nginx para fazer o proxy do vhost para 172.17.0.1:4757

O Virtual Host deve ser configurada na variável de ambiente METABASE_BASE_URL e o METABASE_SECRET também ser configurado.

Para maiores detalhes, consulte https://www.metabase.com/docs/latest/operations-guide/running-metabase-on-docker.html

## Configurando o envio de e-mails:

Primeiro, configurar no banco, na tabela emaildb_config, o campo email_transporter_config, para apontar pra um server SMTP.

Por exemplo:


    -[ RECORD 1 ]------------+-------------------------------------------------------------------------------------------------------
    id                       | 1
    from                     | "LGPDjus" <foo@example.com>
    template_resolver_class  | Shypper::TemplateResolvers::HTTP
    template_resolver_config | {"base_url":"https://lgdpjus-api.sample.com/email-templates/"}
    email_transporter_class  | Email::Sender::Transport::SMTP::Persistent
    email_transporter_config | {"sasl_username":"apikey","sasl_password":"key","port":"587","host":"smtp.sendgrid.net"}
    delete_after             | 25 years

Usamos outro container para o envio dos e-mails, para configurar, as instruções são semelhantes as instruções acima, e o código encontra-se no repositório publico da eokoe: https://github.com/eokoe/email-db-service

    # mkdir /home/ubuntu/sfc-emaildb
    # cd /home/ubuntu/sfc-emaildb;
    # git clone https://github.com/eokoe/email-db-service.git backend/
    # view run_container.sh

        #!/bin/bash

        # arquivo de exemplo para iniciar o container

        export SOURCE_DIR='/home/ubuntu/sfc-emaildb/backend'
        export DATA_DIR='/home/ubuntu/sfc-emaildb/data'

        # confira o seu ip usando ifconfig docker0|grep 'inet addr:'
        export DOCKER_LAN_IP=172.17.0.1

        mkdir -p $DATA_DIR/log
        chown 1000:1000 $DATA_DIR/log

        docker run --name sfc_emaildb \
            -e "EMAILDB_DB_HOST=172.17.0.1" \
            -e "EMAILDB_DB_NAME=lgpdjus_dev" \
            -v $SOURCE_DIR:/src -v $DATA_DIR:/data \
            --cpu-shares=512 \
            --memory 500m -d --restart unless-stopped eokoe/emaildb

    # cd backend;
    # view envs.sh

        (altere o host do banco)

        export EMAILDB_DB_HOST=172.17.0.1
        export EMAILDB_DB_NAME=lgpdjus_dev

    # ./run_container.sh


O campo template_resolver_config configura onde o sistema deve procurar as templates, que devem ser servidas por http ou https.

Os valores da tabela emaildb_config só são lidos durante o start do container, portanto, caso mude as configurações, é necessário reiniciar o container inteiro.

    docker restart $nome_do_container_do_emaildb

## Configurações na tabela lgpdjus_config

    -- nome                     | valor/descrição
    #MAX_CPF_ERRORS_IN_24H       | 100                # numero de vezes que pode tentar logar com senha errada com o mesmo cpf em 24h
    #MINION_ADMIN_PASSWORD       | 0.4570692875903539 # senha para acessar interface admin do minion (gerenciador de jobs, tipo o RQ do python)
    #NOTIFICATIONS_ENABLED       | 1                  # se deve enviar notificações
    #JWT_SECRET_KEY              | 0.0024146289712874 # random para JWT de session e derivados
    #MAINTENANCE_SECRET          | 0.060243261640689  # random para chamar serviços de manutenção pelo crontab
    #AVATAR_PADRAO_URL           | https://lgpdjus-api.sample.com/avatar/padrao.svg # url para avatar (não usado no lgpdjus)
    #PUBLIC_API_URL              | https://lgpdjus-api.sample.com/          # endereço publico, agora da API
    #DEFAULT_NOTIFICATION_ICON   | https://lgpdjus-api.sample.com/i         # base do endereço publico para os icones usados nas notificações
    #QUESTIONNAIRE_ICON_BASE_URL | https://lgpdjus-api.sample.com/q-icon    # base do endereço publico para os icones usados no quiz_config
    #ADMIN_ALLOWED_ROLE_IDS      | 77d4e455-bd2d-46a1-9e68-05acd4d8c30f     # quais roles do directus podem fazer login na interface do admin DPO
    #LGPDJUS_S3_HOST             | s3.us-west-001.backblazeb2.com           # HOST do S3
    #LGPDJUS_S3_MEDIA_BUCKET     | bucket-name                              # Bucket do S3
    #LGPDJUS_S3_ACCESS_KEY       | s3-access-key                            # access key do S3
    #LGPDJUS_S3_SECRET_KEY       | s3-secret-key                            # secret key do S3
    #WKHTMLTOPDF_SERVER_TYPE     | http                                     # se o serviço para html2pdf deve ser chamado remoto ou local.
                                                                           ## valores possiveis são "dev-with-x" ou "http"
                                                                           ## caso usar "dev-with-x" configurar o WKHTMLTOPDF_BIN para o path do wkhtmltopdf
    #WKHTMLTOPDF_HTTP            | http://172.17.0.1:64596                  # endereço do servido do wkhtmltopdf
    #METABASE_BASE_URL           | https://lgpdjus-metabase.sample.com/     # URL base do metabase para geração do embed dashboard
    #METABASE_SECRET             | random                                   # Chave do JWT do metabase
    #TICKET_LIST_AUTO_CENTER     | 0 ou 1                                   # 1 para formatar os textos da lista do quiz
    #SOBRELGDP_LIST_AUTO_CENTER  | 0 ou 1                                   # 1 para formatar os textos da lista do sobrelgpd

## Crontab

Temos algumas ações que precisam rodar periodicamente no sistema, são eles:

- Adicionar na fila os jobs longos (ex: apagar conta)

Para executar tais ações, basta fazer uma chamada HTTP usando o secret do MAINTENANCE_SECRET

Os endpoints são os seguintes:

- http://172.17.0.1:64598/maintenance/housekeeping?secret=MAINTENANCE_SECRET
- http://172.17.0.1:64598/maintenance/ping-db?secret=MAINTENANCE_SECRET

Pode-se configurar para o crontab executar de 1 em 1 minuto, pois a api faz o controle de quantos jobs executar em cada request.

Também pode ser usado um serviço de monitoramento para fazer as chamadas no lugar de utilizar o crontab.

Acima, estamos usando o IP `http://172.17.0.1:64598`, mas no seu deploy, a porta pode ser diferente.

## Directus

O banco inicializado pela api tem já um usuário e senha configurado no directus.

Assim como o login da área do DPO, o acesso no directus é com o mesmo usuário e senha. Para acessar, acesse http://172.17.0.1:64597 e utilize o usuário `admin@sample.com` e senha `admin@sample.com`.

No directus existe uma descrição para cada tabela que pode ser modificada pelos administradores.

# Dicas para o desenvolvimento

O sistema foi criado utilizando o framework web Mojolicious (https://mojolicious.org/).
Alem de ser um framework web, este framework contém várias ferramentas para facilitar o trabalho com html, por exemplo, o pacote Mojo::DOM. Você pode aprender mais sobre em https://docs.mojolicious.org/
Além do Mojolicious, para executar os jobs em background, foi utilizado o framework Minion https://docs.mojolicious.org/Minion que além de processar os jobs, fornece uma interface administrativa para acompanhamento dos trabalhos.

Para ORM, foi utilizado o framework DBIx::Class. Uma das vantagem de utilizar o DBIx::Class é poder utilizar o DBIx::Class::Schema::Loader para gerar automaticamente o código para uso das tabelas, e não precisar escrever praticamente nenhum SQL na mão.

## Processo para adicionar uma nova modificação no banco:

Primeiro, nunca deve-se alterar o banco diretamente ou pela interface do directus, isso irá gerar uma inconsistência com o schema esperado pela api.
O primeiro passo deve ser criar uma nova migration (veja: "Criando novas migrações de banco (sqitch)" abaixo) e depois rodar o comando para atualizar o código automaticamente com o novo schema.

Para isso, basta rodar o comando:

    ir para pasta api/

    $ . script/schema.dump.sh

Lembrando que o banco já deve estar configurado corretamente no arquivo `envfile_local.sh` ou `envfile.sh`

## Estrutura de pastas

Comentários sobre os arquivos mais importantes

    .
    ├── api                     # código fonte para lgdpjus
    │   ├── build-container.sh  # constrói a imagem do container
    │   ├── deploy_db           # Migrations
    │   │   ├── deploy          # SQL de cada migration
    │   │   │   ├── 0001-db-init.sql
    |   |   |   ...
    │   │   └── sqitch.plan     # Controle de migrations
    │   ├── dist.ini            # Configuração de dependências e empacotamento do projeto
                                # este arquivo serve para gerar o Makefile.PL (que é como se fosse o package.json em node.js)
    │   ├── docker              # Arquivos para montar a imagem docker
    |   |       ...
    │   ├── envfile.sh          # arquivo de configuração de exemplo, criar envfile_local.sh
    │   ├── lib
    │   │   ├── Lgpdjus         # Pasta base do código do LGPDJus
    │   │   │   ├── Controller  # Pasta com as controllers
    │   │   │   │   ...
    │   │   │   ├── Controller.pm # Base da classe de controllers,
    │   │   │   ├── Helpers
        │   │   │   ...
    │   │   │   ├── Helpers.pm    # Carrega as helpers
    │   │   │   ├── Minion        # Código para executar os jobs registrados no Minion
    │   │   │   │   ├── Tasks
    │   │   │   │   │   ├── AddBlockchain.pm
    │   │   │   │   │   ├── DeleteUser.pm
    │   │   │   │   │   └── VerifyBlockchain.pm
    │   │   │   │   └── Tasks.pm
    │   │   │   ├── Routes.pm     # Configuração de rotas do sistema (como se fosse os handlers em golang)
    │   │   │   ├── Schema
    │   │   │   │   ├── Base.pm
    │   │   │   │   └── Result   # Arquivos do schema gerados automaticamente pelo schema.dump.sh
                        # ...
    │   │   │   ├── SchemaConnected.pm # Singleton para abrir conexão com o banco e iniciar as variáveis de ambiente
    │   │   │   ├── Schema.pm       # Modifica o Base class do ORM, para extender funções, eg: acessar funções do banco
    │   │   │   ├── Types.pm        # Validações de dados, ex: CPF, Nome, IntList
    │   │   │   ├── Uploader.pm     # Faz envio para S3
    │   │   │   └── Utils.pm        # "pure functions" aleatórias
    │   │   ├── Lgpdjus.pm   # Bootstrap do sistema web
    │   │   ├── Mojolicious
    │   │   │   └── Plugin
    │   │   │       └── JWT.pm  # nao deveria ser plugin, deveria ser uma helper!
    │   ├── Makefile.PL         # arqivo com as deps "package.json"
    │   ├── Makefile            # arquivo make (não usado, mas gerado sozinho pelo dist.ini)
    │   ├── MYMETA.json         # idem
    │   ├── MYMETA.yml          # idem
    │   ├── public     # pasta com arquivos publicos, servido automaticamente pelo mojolicious quando a rota não existe
    │   │   ├── email-templates  # pasta com as templates utilizada pelo serviço de e-mail
    │   │   │   ├── account_deletion.html
    │   │   │   ├── account_reactivate.html
    │   │   │   ├── forgot_password.html
    │   │   │   ├── generic.html
    │   │   │   ├── raw.html
    │   │   │   └── selo_blockchain.png
    │   │   │   ... # muitos arquivos
    │   │   └── web-assets  # arquivos para ser usado na interface web do DPO
        │   │   │   ... # muitos arquivos
    │   ├── sample-gracefully-reload.sh  # exemplo de script para reiniciar o docker
    │   ├── sample-run-container.sh      # exemplo de script para subir o docker sem docker-compose
    │   ├── script                       # scripts do projeto
    │   │   ├── lgpdjus-api              # sobe a aplicação
    │   │   ├── restart-services.sh      # reinicia o serviço da api
    │   │   └── start-server.sh          # inicia o serviço da api
    │   │   ├── schema.dump.sh           # refaz o schema a partir do banco
    │   │   ├── start-minion-worker.sh   # inicia os serviços em background
    │   ├── sqitch.conf     # configuração do banco para o rodar o migration
    │   ├── t # pasta de testes do sistema
    │   │   ├── api  # testes da api
    │   │   │   ├── 001-sign-up-duplicate.t   # cria conta
    │   │   │   ├── 015-quiz-tickets.t        # cria solicitações
    │   │   │   ├── 100-public-api.t          # testa parte publica da api
    │   │   │   └── 123-web.t                 # testa parte do DPO
    │   │   ├── data # dados utilizado nos testes
    │   │   │   └── small.png
    │   │   └── lib # códigos helpers apena para os testes
    │   │       └── Lgpdjus
    │   │           └── Test.pm
    │   ├── templates  # pasta com as templates para a parte do DPO e outros HTMLs
    │   └── xt  # testes de autor (só rode se precisar)
    │       ├── 999-clear-db.t
    │       ├── 999-load-ticket.t
    │       ├── 999-load-user.t
    │       └── 999-verify_blockchain.t
    ├── docker-compose.yaml  # configurações do containers
    ├── misc                 # arquivos não relacionados com código
    │   ├── external-link.png
    │   ├── LGPDJus-Containers.svg
    │   └── warning.png

## Triggers

O sistema usa algumas triggers para atualizar os timestamp quando certos dados são modificados para invalidar o cache.

Você pode encontrar as triggers usando o comando:

grep -i trigger api/deploy_db/ -r

## Rodando os testes (ambiente dev) com docker

Siga os mesmos passos de instalações do pg e docker.

Depois, precisa editar o arquivo sqitch.conf. Nao precisa do arquivo envfile_local.sh

No arquivo `sqitch.conf` altere a conexão da chave "local"

Ainda será necessário um container para o wkhtmltopdf, então também é necessário criar e configurar o arquivo envfile_local.sh para configurar o caminho para este serviço, caso contrario, alguns testes não passarão. (Ver WKHTMLTOPDF_SERVER_TYPE abaixo)

Vá até o diretório base código, e execute o código:

    docker run --name lgpdjus_backend_test --rm -v $(pwd):/src -v /tmp/:/data -it -u app its/lgpdjus_api bash

    $ cd /src;
    $ . envfile_docker_test.sh # carrega as variáveis de ambiente configurado o ambiente docker
    $ yath test -j 4 -PLgpdjus  -Ilib t/ # inicia todos os testes, usando 4 tests em paralelo

Para o desenvolvedor, eu recomendo instalar o pg, redis, perl e wkhtmltopdf na máquina local, assim evita ter que subir um container inteiro toda hora que deseja rodar o teste.

Para instalar as deps, use o Dockerfile como base.

Para testar na máquina local, após instalar as dependências, execute:

    createdb -h 127.0.0.1 -U postgres lgpdjus_dev
    sqitch deploy  -t development
    DBIC_TRACE=1 TRACE=1 yath test -j 8 -PLgpdjus -Ilib t/


TRACE=1 mostra o request/response que são executados
DBIC_TRACE=1 mostra as queries que foram executadas por dentro do ORM

## Criando novas migrações de banco (sqitch)

> instruções dadas aqui consideram que você está trabalhando na pasta "api" (e nao no root do repo)

Usamos um padrão para criar um novo arquivo sqitch:

- Cada arquivo faz "require" no último deploy
- Não usamos revert nem verify

O problema de usar o revert, é que nem toda alteração tem revert, e, quando você faz deploy de mais de uma alteração ao mesmo tempo, e uma desta falha, o sqitch roda todos os reverts (que se não existir, irá ficar em branco), dando um trabalho extra para voltar o banco em um estado estável.
Quando não existe arquivo, ele simplesmente não executa o revert, e você pode arrumar o arquivo de deploy que deu errado e executar novamente `sqitch deploy` que ele irá apenas executar os arquivos ainda não executados (ou executados com erro).

Para ajudar, uso essas funções no meu .bashrc para criar novos sqitch.

    deploydb_last_version () {
       perl -e 'my $last = [ sort { $b <=> $a } grep {/^\d{1,4}-/} @ARGV]->[0]; $last =~ s/\.sql$//; print "$last"' `ls deploy_db/deploy/`
    }

    deploydb_next_version () {
       perl -e 'my $name = shift @ARGV; my $last = [ sort { $b <=> $a } grep {/^\d{1,4}-/} @ARGV]->[0]; $last =~ s/\.sql$//; $last =~ s/^(\d+)-.+/sprintf(q{%04d}, $1+1)/e;  print "$last-$name"' $1 `ls deploy_db/deploy/`
    }

    new_deploy (){
        sqitch add `deploydb_next_version $1` --requires `deploydb_last_version` -n "${*:2}"
        ## $EDITOR deploy_db/deploy/`deploydb_last_version`.sql

        rm -rf deploy_db/revert
        rm -rf deploy_db/verify
    }


E para criar um novo deploy, simplesmente executar `new_deploy nome-do-arquivo descrição do será modificado`

Depois de criar e editar o arquivo (fica na pasta deploy_db/deploy/) você poderá executar as alterações no banco usando `sqitch deploy -t development` (-t é o target, pode ser outro)
