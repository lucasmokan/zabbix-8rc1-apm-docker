# Zabbix 8.0 RC1 com APM em Docker

**Laboratório completo com Zabbix server, frontend, agente e proxy compilado com APM.**
**PostgreSQL 18 + TimescaleDB para a infraestrutura e ClickHouse para o APM (OpenTelemetry).** 

Dois bancos, cada um com seu papel:

- **PostgreSQL 18 + TimescaleDB 2.29**: tudo o que o Zabbix sempre guardou (configuração, eventos, histórico e trends) e o resultado dos itens *Telemetry query*.
- **ClickHouse**: só os dados brutos de APM (traces, logs e métricas OpenTelemetry).

```
aplicação --OTLP 4317--> proxy com APM --> ClickHouse (otel_*)
                                              ^
frontend (APM > Traces) e server (Telemetry query) leem daqui
```

> Laboratório de testes: senhas simples, portas do ClickHouse abertas e sem TLS. Não use em produção.

## Estrutura

```
docker-compose.yml        server, web, agent, PostgreSQL + TimescaleDB e ClickHouse
.env                      versões e senhas
clickhouse-init/          cria as tabelas otel_traces, otel_logs e otel_metrics_* na primeira subida
proxy/                    proxy compilado com APM (Dockerfile, conf, compose)
lab-app/                  app de exemplo que envia traces, logs e métricas
```

## Passo a passo

**1. Baixe o repositório** (precisa de Docker com Compose e `git`):

```bash
git clone https://github.com/lucasmokan/zabbix-8rc1-apm-docker.git
cd zabbix-8rc1-apm-docker
```

**2. Troque as senhas** em `.env` (`POSTGRES_PASSWORD` e `CLICKHOUSE_PASSWORD`) e em `proxy/.env` (`CLICKHOUSE_PASSWORD`, a mesma).

**3. Suba a stack:**

```bash
docker compose up -d
```

**4. Confira os bancos:**

```bash
source .env
docker compose exec postgres psql -U zabbix -d zabbix -c "SELECT extname, extversion FROM pg_extension WHERE extname='timescaledb'"
docker compose exec clickhouse clickhouse-client --user zabbix --password "$CLICKHOUSE_PASSWORD" -q "SHOW TABLES FROM zabbix"
```

Esperado: `timescaledb 2.29.x` e 7 tabelas: `otel_traces`, `otel_logs` e `otel_metrics_*` (gauge, sum, histogram, exponential_histogram, summary).

**5. Configure o frontend** em `http://IP_DO_HOST:8080` (`Admin` / `zabbix`):

- **Host "Zabbix server":** na interface do agente, use *Connect to: DNS*, `zabbix-agent`, porta `10050`.
- **Administration → Data sources → APM:** marque *Enable global data source* e preencha URL `http://clickhouse:8123`, *Username and password*, usuário `zabbix`, a senha do ClickHouse e database `zabbix`. Clique em *Update* e *Test*.
- **Administration → Proxies → Create proxy:** nome `proxy-apm-01`, modo *Active*, e na aba *APM* marque *Data collection enabled*.

**6. Suba o proxy com APM** (a compilação leva vários minutos):

```bash
cd proxy
docker compose up -d --build
docker compose logs -f zabbix-proxy
```

Procure `Open Telemetry collector listening on 0.0.0.0:4317`. Em *Administration → Proxies* o *Last seen* deve atualizar.

**7. Envie traces de teste:**

```bash
docker run --rm --network host ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:latest \
  traces --otlp-insecure --otlp-endpoint localhost:4317 --service lab-app --rate 5 --duration 30s
```

Abra **APM → Traces**. Resultado esperado: 152 spans em 76 traces. No ClickHouse:

```bash
cd ..
docker compose exec clickhouse clickhouse-client --user zabbix --password "$CLICKHOUSE_PASSWORD" -q "SELECT count(), uniqExact(TraceId) FROM zabbix.otel_traces"
```

**8. (Opcional) Itens Telemetry query:**

1. Em *Data collection → Templates → Import*, importe o template **Generic OpenTelemetry by OTLP** (YAML do Zabbix 8.0).
2. Crie um host (ex.: `test_apm`), monitorado pelo *Server*, sem interface, com esse template.
3. Suba o app de exemplo, que envia spans Ok, Error e Unset:

```bash
cd lab-app
docker compose up -d --build
```

4. Em 2 a 3 minutos, veja os valores (traces, logs e métricas) em *Monitoring → Latest data*. Eles ficam no PostgreSQL:

```bash
cd ..
docker compose exec postgres psql -U zabbix -d zabbix -c "SELECT i.key_, h.value, to_timestamp(h.clock) FROM history_uint h JOIN items i USING(itemid) WHERE i.key_ LIKE 'otlp.span%' ORDER BY h.clock DESC LIMIT 5"
```

**IMPORTANTE**
5. O `lab-app` envia dados sem parar e enche o ClickHouse. Quando terminar o teste, pare:

```bash
docker compose -f lab-app/compose.yaml down
```

## Observações

- **Tabelas:** o proxy insere por posição de coluna e envia timestamps como decimal (`1759700000.123456789`), que o ClickHouse não converte em `DateTime64`. Por isso os SQLs usam uma coluna `...Raw Decimal(19,9)` e a coluna `DateTime64` real como `MATERIALIZED`. Não altere a ordem das colunas.
- **Proxy:** as imagens oficiais não têm o coletor OTLP, por isso o proxy é compilado com `--with-apm` (`proxy/Dockerfile`). Ele grava no ClickHouse com `ZBX_TELEMETRYPROVIDER_0` em JSON (usuário e senha em variáveis separadas).
- **Server:** a imagem não aplica o `ZBX_TELEMETRYPROVIDER_0`, e o APM funciona sem ele, com o ClickHouse configurado em *Data sources → APM*.
- **Tabelas do ClickHouse:** são criadas só quando o volume é novo. Em volume existente, aplique uma vez (`source .env` antes):

  ```bash
  for f in clickhouse-init/*.sql; do docker compose exec -T clickhouse clickhouse-client --user zabbix --password "$CLICKHOUSE_PASSWORD" --multiquery < $f; done
  ```
- **Depois de um `docker compose down -v` na raiz:** cadastre o proxy de novo e recrie o container dele (`cd proxy && docker compose down && docker compose up -d`).
- **Imagens:** o Docker Hub não tem tag 8.0. O laboratório usa `alpine-trunk` (desenvolvimento do 8.0) e a imagem `timescale/timescaledb:2.29.2-pg18`.
- **Retenção:** o housekeeper não limpa o ClickHouse. Quem remove dados antigos é o TTL da tabela (31 dias).
- **Portas `8123` e `9000`** do ClickHouse ficam abertas à rede. Remova `ports` do serviço se não precisar.

## Referências

- [Release notes do Zabbix 8.0.0rc1](https://www.zabbix.com/rn/rn8.0.0rc1)
- [zabbix_proxy.conf](https://github.com/zabbix/zabbix/blob/master/conf/zabbix_proxy.conf)
