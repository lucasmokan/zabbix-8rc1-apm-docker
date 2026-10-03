# Zabbix 8.0 em Docker com ClickHouse (laboratório)

Laboratório Zabbix 8.0 100% em Docker: o histórico dos itens vai para o ClickHouse e o restante (configuração, eventos e trends) fica no PostgreSQL.

> Laboratório de testes: senhas simples, portas do ClickHouse abertas e sem TLS. Não use assim em produção.

## O que sobe

| Serviço | Função | Porta no host |
| --- | --- | --- |
| `postgres` | Banco de configuração, eventos e trends | nenhuma |
| `clickhouse` | Histórico dos itens | 8123 (HTTP), 9000 (nativa) |
| `zabbix-server` | Servidor Zabbix | 10051 |
| `zabbix-web` | Frontend (nginx) | 8080 |
| `zabbix-agent` | Agente do host "Zabbix server" | nenhuma |

O server grava o histórico no ClickHouse com `ZBX_HISTORYPROVIDER_0`, na sintaxe do `zabbix_server.conf`. O frontend lê do mesmo lugar com `ZBX_HISTORYPROVIDERS`, um único objeto JSON.

## Pré-requisitos

- Linux com Docker Engine e o plugin Compose (`docker compose`)
- `git` e `curl`

## Baixar os arquivos

Clone este repositório e entre na pasta. Todos os comandos seguintes rodam de dentro dela.

```bash
git clone https://github.com/lucasmokan/zabbix8-clickhouse-docker.git
cd zabbix8-clickhouse-docker
```

Se preferir não usar o `git`, baixe só os dois arquivos necessários, em uma pasta vazia:

```bash
mkdir zabbix8-clickhouse-docker && cd zabbix8-clickhouse-docker
curl -O https://raw.githubusercontent.com/lucasmokan/zabbix8-clickhouse-docker/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/lucasmokan/zabbix8-clickhouse-docker/main/.env
```

Troque as senhas no `.env` antes de continuar (`nano .env`). Os comandos abaixo leem as senhas desse arquivo.

## Instalação

**1. Suba só os bancos:**

```bash
docker compose up -d postgres clickhouse
```

**2. Baixe os scripts oficiais de schema do ClickHouse (só o commit mais recente):**

```bash
git clone --depth 1 https://github.com/zabbix/zabbix.git ~/zabbix
```

**3. Crie as tabelas de histórico.** O `-t` é o TTL em segundos: `2678400` equivale a 31 dias.

```bash
source .env
~/zabbix/database/clickhouse/history_all.sh -s http://localhost:8123 -d zabbix -u zabbix -p "$CLICKHOUSE_PASSWORD" -t 2678400
```

O script não imprime nada quando termina sem erro. Ele apaga e recria as tabelas, então não rode de novo depois que o Zabbix já gravou dados.

**4. Apague o clone:**

```bash
rm -rf ~/zabbix
```

**5. Suba o restante:**

```bash
docker compose up -d
```

## Verificação

Confirme as seis tabelas no ClickHouse (`history`, `history_json`, `history_log`, `history_str`, `history_text` e `history_uint`):

```bash
source .env
docker compose exec clickhouse clickhouse-client --user zabbix --password "$CLICKHOUSE_PASSWORD" -q "SHOW TABLES FROM zabbix"
```

Acesse o frontend em `http://IP_DO_HOST:8080` com `Admin` / `zabbix`.

O host "Zabbix server" vem com a interface do agente em `127.0.0.1:10050`, que só funciona quando o agente roda junto com o server. Aqui o agente é outro container. Em **Data collection → Hosts → Zabbix server**, na interface do agente, use **Connect to: DNS**, DNS name `zabbix-agent`, porta `10050`.

Depois de alguns minutos, o histórico deve estar no ClickHouse e não no PostgreSQL:

```bash
source .env
docker compose exec clickhouse clickhouse-client --user zabbix --password "$CLICKHOUSE_PASSWORD" -q "SELECT count() FROM zabbix.history_uint"
docker compose exec postgres psql -U zabbix -d zabbix -c "SELECT count(*) FROM history_uint"
```

O primeiro comando deve retornar um número maior que zero e crescendo. O segundo deve retornar `0`.

## Pontos de atenção

- **Tag das imagens:** o Docker Hub não tem tag 8.0. O laboratório usa `alpine-trunk`, o desenvolvimento do 8.0, que pode estar à frente ou atrás da RC1.
- **Retenção:** o housekeeper do Zabbix não limpa o ClickHouse. Quem remove os dados antigos é o TTL das tabelas (31 dias aqui).
- **Trends:** continuam só no PostgreSQL. O ClickHouse guarda apenas o histórico.
- **PostgreSQL sem TimescaleDB:** a imagem `postgres:17-alpine` é o PostgreSQL puro.
- **Proxy:** o ClickHouse não é suportado como histórico em proxies, só no server.
- **Portas abertas:** `8123` e `9000` ficam acessíveis a toda a rede. Remova a seção `ports` do `clickhouse` se não precisar delas fora do Docker.

## APM (OpenTelemetry)

O APM da 8.0 não está incluído. O coletor OTLP/gRPC existe só no proxy e depende de compilação com a opção `--with-apm`. As imagens oficiais do proxy (`alpine-trunk`) foram compiladas sem ela e recusam os parâmetros `APMListenIP` e `APMListenPort` ("compiled without APM support"). Para usar APM é preciso compilar o proxy com `--with-apm` ou esperar imagens oficiais com suporte.

## Referências

- [Release notes do Zabbix 8.0.0rc1](https://www.zabbix.com/rn/rn8.0.0rc1)
- [Scripts de schema do ClickHouse (zabbix/zabbix)](https://github.com/zabbix/zabbix/tree/master/database/clickhouse)
- [zabbix_proxy.conf (zabbix/zabbix)](https://github.com/zabbix/zabbix/blob/master/conf/zabbix_proxy.conf)
- [Laboratório de referência (enderkus/zabbix8-clickhouse)](https://github.com/enderkus/zabbix8-clickhouse)
