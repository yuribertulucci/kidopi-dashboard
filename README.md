# Dashboard Kidopi — Trino + Metabase (Docker)

Resumo
- Projeto Docker com Trino (query engine), Metabase (BI) e PostgreSQL (Metabase DB).
- Configura serviços em [docker-compose.yaml](docker-compose.yaml) e usa variáveis em [.env](.env) / [.env.example](.env.example).

Serviços principais
- Trino: serviço definido em [docker-compose.yaml](docker-compose.yaml). Configurações em [trino/trino-config](trino/trino-config).
  - Arquivos chave: [`trino/trino-config/config.properties`](trino/trino-config/config.properties), [`trino/trino-config/jvm.config`](trino/trino-config/jvm.config), [`trino/trino-config/node.properties`](trino/trino-config/node.properties).
  - Catalogs dinâmicos criados no startup via o script [trino/init-trino.sh](trino/init-trino.sh). Funções relevantes: [`create_catalog`](trino/init-trino.sh) e [`add_property`](trino/init-trino.sh).
  - Exemplos de catalogos: [trino/trino-config/catalog/mysql.properties](trino/trino-config/catalog/mysql.properties) e [trino/trino-config/catalog/mongodb.properties](trino/trino-config/catalog/mongodb.properties).

- Metabase: definido em [docker-compose.yaml](docker-compose.yaml). Usa volume de entropia em [metabase/urandom](metabase/urandom) e dados PostgreSQL em [metabase/pgdata-metabase](metabase/pgdata-metabase).

- PostgreSQL (Metabase): serviço definido em [docker-compose.yaml](docker-compose.yaml). Dados persistentes em [metabase/pgdata-metabase](metabase/pgdata-metabase).

Configuração
- Copie `.env.example` para `.env` e ajuste:
  - Trino: TRINO_PORT
  - MySQL: MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE
  - MongoDB: MONGODB_HOST, MONGODB_PORT, MONGODB_USER, MONGODB_PASSWORD
  - Metabase/Postgres: variáveis comentadas em [.env.example](.env.example)

Como rodar
1. Ajuste o `.env` (veja [.env.example](.env.example)).
2. Suba os containers:
   ```sh
   docker compose up -d
   ```
3. Ver logs:
   ```sh
   docker compose logs -f trino-kidopi
   docker compose logs -f metabase-kidopi
   ```

Como Trino cria catalogs
- No startup, o entrypoint executa [trino/init-trino.sh](trino/init-trino.sh). O script:
  - chama [`create_catalog`](trino/init-trino.sh) para gerar arquivos em `/etc/trino/catalog`.
  - usa [`add_property`](trino/init-trino.sh) para adicionar propriedades opcionais (connection strings, usuário, senha).
- Para ver exemplos gerados, confira [trino/trino-config/catalog/mysql.properties](trino/trino-config/catalog/mysql.properties) e [trino/trino-config/catalog/mongodb.properties](trino/trino-config/catalog/mongodb.properties).

Notas e dicas
- Os arquivos em [trino/trino-config/catalog/.git-ignore](trino/trino-config/catalog/.git-ignore) e [metabase/.git-ignore](metabase/.git-ignore) evitam versionar catalogs/volumes gerados.
- Ajuste memória JVM em [`trino/trino-config/jvm.config`](trino/trino-config/jvm.config) conforme necessidade.
- Se precisar conectar Trino a outros DBs, adicione novos catalog files em [trino/trino-config/catalog](trino/trino-config/catalog) ou estenda [trino/init-trino.sh](trino/init-trino.sh).

Arquivos importantes (resumo com links)
- [docker-compose.yaml](docker-compose.yaml)
- [.env.example](.env.example)
- [.env](.env)
- [trino/init-trino.sh](trino/init-trino.sh) (funções: [`create_catalog`](trino/init-trino.sh), [`add_property`](trino/init-trino.sh))
- [trino/trino-config/config.properties](trino/trino-config/config.properties)
- [trino/trino-config/jvm.config](trino/trino-config/jvm.config)
- [trino/trino-config/node.properties](trino/trino-config/node.properties)
- [trino/trino-config/catalog/mysql.properties](trino/trino-config/catalog/mysql.properties)
- [trino/trino-config/catalog/mongodb.properties](trino/trino-config/catalog/mongodb.properties)

Documentações específicas encontradas em:
- [docs](docs)
- [docs/trino](docs/trino) (específico do Trino)
- [docs/metabase](docs/metabase) (específico do Metabase)