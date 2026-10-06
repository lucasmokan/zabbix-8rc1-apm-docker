-- Tabela de logs OTel (TTL de 31 dias)
CREATE TABLE IF NOT EXISTS zabbix.otel_logs
(
    TimestampRaw                  Decimal(19,9) CODEC(ZSTD(1)),
    TraceId                       String CODEC(ZSTD(1)),
    SpanId                        String CODEC(ZSTD(1)),
    TraceFlags                    UInt8 CODEC(ZSTD(1)),
    SeverityText                  LowCardinality(String) CODEC(ZSTD(1)),
    SeverityNumber                UInt8 CODEC(ZSTD(1)),
    ServiceName                   LowCardinality(String) CODEC(ZSTD(1)),
    Body                          String CODEC(ZSTD(1)),
    ResourceSchemaUrl             LowCardinality(String) CODEC(ZSTD(1)),
    ResourceAttributes            Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    ScopeSchemaUrl                LowCardinality(String) CODEC(ZSTD(1)),
    ScopeName                     String CODEC(ZSTD(1)),
    ScopeVersion                  LowCardinality(String) CODEC(ZSTD(1)),
    ScopeAttributes               Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    LogAttributes                 Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    EventName                     String CODEC(ZSTD(1)),
    Timestamp                     DateTime64(9) MATERIALIZED fromUnixTimestamp64Nano(CAST(TimestampRaw * 1000000000 AS Int64)) CODEC(Delta, ZSTD(1))
)
ENGINE = MergeTree
PARTITION BY toDate(Timestamp)
ORDER BY (ServiceName, SeverityNumber, toDateTime(Timestamp))
TTL toDateTime(Timestamp) + toIntervalDay(31);
