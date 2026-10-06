-- Metricas OTel: gauge (TTL de 31 dias)
CREATE TABLE IF NOT EXISTS zabbix.otel_metrics_gauge
(
    ResourceAttributes            Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    ResourceSchemaUrl             String CODEC(ZSTD(1)),
    ScopeName                     String CODEC(ZSTD(1)),
    ScopeVersion                  String CODEC(ZSTD(1)),
    ScopeAttributes               Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    ScopeDroppedAttrCount         UInt32 CODEC(ZSTD(1)),
    ScopeSchemaUrl                String CODEC(ZSTD(1)),
    ServiceName                   LowCardinality(String) CODEC(ZSTD(1)),
    MetricName                    String CODEC(ZSTD(1)),
    MetricDescription             String CODEC(ZSTD(1)),
    MetricUnit                    String CODEC(ZSTD(1)),
    Attributes                    Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    StartTimeUnixRaw              Decimal(19,9) CODEC(ZSTD(1)),
    TimeUnixRaw                   Decimal(19,9) CODEC(ZSTD(1)),
    Value                         Float64 CODEC(ZSTD(1)),
    Flags                         UInt32 CODEC(ZSTD(1)),
    `Exemplars.FilteredAttributes`Array(Map(LowCardinality(String), String)) CODEC(ZSTD(1)),
    `Exemplars.TimeUnixRaw`       Array(Decimal(19,9)) CODEC(ZSTD(1)),
    `Exemplars.Value`             Array(Float64) CODEC(ZSTD(1)),
    `Exemplars.SpanId`            Array(String) CODEC(ZSTD(1)),
    `Exemplars.TraceId`           Array(String) CODEC(ZSTD(1)),
    StartTimeUnix                 DateTime64(9) MATERIALIZED fromUnixTimestamp64Nano(CAST(StartTimeUnixRaw * 1000000000 AS Int64)) CODEC(ZSTD(1)),
    TimeUnix                      DateTime64(9) MATERIALIZED fromUnixTimestamp64Nano(CAST(TimeUnixRaw * 1000000000 AS Int64)) CODEC(Delta, ZSTD(1)),
    `Exemplars.TimeUnix`          Array(DateTime64(9)) MATERIALIZED arrayMap(x -> fromUnixTimestamp64Nano(CAST(x * 1000000000 AS Int64)), `Exemplars.TimeUnixRaw`) CODEC(ZSTD(1))
)
ENGINE = MergeTree
PARTITION BY toDate(TimeUnix)
ORDER BY (ServiceName, MetricName, toDateTime(TimeUnix))
TTL toDateTime(TimeUnix) + toIntervalDay(31);

-- Metricas OTel: sum (TTL de 31 dias)
CREATE TABLE IF NOT EXISTS zabbix.otel_metrics_sum
(
    ResourceAttributes            Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    ResourceSchemaUrl             String CODEC(ZSTD(1)),
    ScopeName                     String CODEC(ZSTD(1)),
    ScopeVersion                  String CODEC(ZSTD(1)),
    ScopeAttributes               Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    ScopeDroppedAttrCount         UInt32 CODEC(ZSTD(1)),
    ScopeSchemaUrl                String CODEC(ZSTD(1)),
    ServiceName                   LowCardinality(String) CODEC(ZSTD(1)),
    MetricName                    String CODEC(ZSTD(1)),
    MetricDescription             String CODEC(ZSTD(1)),
    MetricUnit                    String CODEC(ZSTD(1)),
    Attributes                    Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    StartTimeUnixRaw              Decimal(19,9) CODEC(ZSTD(1)),
    TimeUnixRaw                   Decimal(19,9) CODEC(ZSTD(1)),
    Value                         Float64 CODEC(ZSTD(1)),
    Flags                         UInt32 CODEC(ZSTD(1)),
    `Exemplars.FilteredAttributes`Array(Map(LowCardinality(String), String)) CODEC(ZSTD(1)),
    `Exemplars.TimeUnixRaw`       Array(Decimal(19,9)) CODEC(ZSTD(1)),
    `Exemplars.Value`             Array(Float64) CODEC(ZSTD(1)),
    `Exemplars.SpanId`            Array(String) CODEC(ZSTD(1)),
    `Exemplars.TraceId`           Array(String) CODEC(ZSTD(1)),
    AggregationTemporality        Int32 CODEC(ZSTD(1)),
    IsMonotonic                   Bool CODEC(ZSTD(1)),
    StartTimeUnix                 DateTime64(9) MATERIALIZED fromUnixTimestamp64Nano(CAST(StartTimeUnixRaw * 1000000000 AS Int64)) CODEC(ZSTD(1)),
    TimeUnix                      DateTime64(9) MATERIALIZED fromUnixTimestamp64Nano(CAST(TimeUnixRaw * 1000000000 AS Int64)) CODEC(Delta, ZSTD(1)),
    `Exemplars.TimeUnix`          Array(DateTime64(9)) MATERIALIZED arrayMap(x -> fromUnixTimestamp64Nano(CAST(x * 1000000000 AS Int64)), `Exemplars.TimeUnixRaw`) CODEC(ZSTD(1))
)
ENGINE = MergeTree
PARTITION BY toDate(TimeUnix)
ORDER BY (ServiceName, MetricName, toDateTime(TimeUnix))
TTL toDateTime(TimeUnix) + toIntervalDay(31);

-- Metricas OTel: histogram (TTL de 31 dias)
CREATE TABLE IF NOT EXISTS zabbix.otel_metrics_histogram
(
    ResourceAttributes            Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    ResourceSchemaUrl             String CODEC(ZSTD(1)),
    ScopeName                     String CODEC(ZSTD(1)),
    ScopeVersion                  String CODEC(ZSTD(1)),
    ScopeAttributes               Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    ScopeDroppedAttrCount         UInt32 CODEC(ZSTD(1)),
    ScopeSchemaUrl                String CODEC(ZSTD(1)),
    ServiceName                   LowCardinality(String) CODEC(ZSTD(1)),
    MetricName                    String CODEC(ZSTD(1)),
    MetricDescription             String CODEC(ZSTD(1)),
    MetricUnit                    String CODEC(ZSTD(1)),
    Attributes                    Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    StartTimeUnixRaw              Decimal(19,9) CODEC(ZSTD(1)),
    TimeUnixRaw                   Decimal(19,9) CODEC(ZSTD(1)),
    Count                         UInt64 CODEC(ZSTD(1)),
    Sum                           Float64 CODEC(ZSTD(1)),
    BucketCounts                  Array(UInt64) CODEC(ZSTD(1)),
    ExplicitBounds                Array(Float64) CODEC(ZSTD(1)),
    `Exemplars.FilteredAttributes`Array(Map(LowCardinality(String), String)) CODEC(ZSTD(1)),
    `Exemplars.TimeUnixRaw`       Array(Decimal(19,9)) CODEC(ZSTD(1)),
    `Exemplars.Value`             Array(Float64) CODEC(ZSTD(1)),
    `Exemplars.SpanId`            Array(String) CODEC(ZSTD(1)),
    `Exemplars.TraceId`           Array(String) CODEC(ZSTD(1)),
    Flags                         UInt32 CODEC(ZSTD(1)),
    Min                           Float64 CODEC(ZSTD(1)),
    Max                           Float64 CODEC(ZSTD(1)),
    AggregationTemporality        Int32 CODEC(ZSTD(1)),
    StartTimeUnix                 DateTime64(9) MATERIALIZED fromUnixTimestamp64Nano(CAST(StartTimeUnixRaw * 1000000000 AS Int64)) CODEC(ZSTD(1)),
    TimeUnix                      DateTime64(9) MATERIALIZED fromUnixTimestamp64Nano(CAST(TimeUnixRaw * 1000000000 AS Int64)) CODEC(Delta, ZSTD(1)),
    `Exemplars.TimeUnix`          Array(DateTime64(9)) MATERIALIZED arrayMap(x -> fromUnixTimestamp64Nano(CAST(x * 1000000000 AS Int64)), `Exemplars.TimeUnixRaw`) CODEC(ZSTD(1))
)
ENGINE = MergeTree
PARTITION BY toDate(TimeUnix)
ORDER BY (ServiceName, MetricName, toDateTime(TimeUnix))
TTL toDateTime(TimeUnix) + toIntervalDay(31);

-- Metricas OTel: exponential_histogram (TTL de 31 dias)
CREATE TABLE IF NOT EXISTS zabbix.otel_metrics_exponential_histogram
(
    ResourceAttributes            Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    ResourceSchemaUrl             String CODEC(ZSTD(1)),
    ScopeName                     String CODEC(ZSTD(1)),
    ScopeVersion                  String CODEC(ZSTD(1)),
    ScopeAttributes               Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    ScopeDroppedAttrCount         UInt32 CODEC(ZSTD(1)),
    ScopeSchemaUrl                String CODEC(ZSTD(1)),
    ServiceName                   LowCardinality(String) CODEC(ZSTD(1)),
    MetricName                    String CODEC(ZSTD(1)),
    MetricDescription             String CODEC(ZSTD(1)),
    MetricUnit                    String CODEC(ZSTD(1)),
    Attributes                    Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    StartTimeUnixRaw              Decimal(19,9) CODEC(ZSTD(1)),
    TimeUnixRaw                   Decimal(19,9) CODEC(ZSTD(1)),
    Count                         UInt64 CODEC(ZSTD(1)),
    Sum                           Float64 CODEC(ZSTD(1)),
    Scale                         Int32 CODEC(ZSTD(1)),
    ZeroCount                     UInt64 CODEC(ZSTD(1)),
    PositiveOffset                Int32 CODEC(ZSTD(1)),
    PositiveBucketCounts          Array(UInt64) CODEC(ZSTD(1)),
    NegativeOffset                Int32 CODEC(ZSTD(1)),
    NegativeBucketCounts          Array(UInt64) CODEC(ZSTD(1)),
    `Exemplars.FilteredAttributes`Array(Map(LowCardinality(String), String)) CODEC(ZSTD(1)),
    `Exemplars.TimeUnixRaw`       Array(Decimal(19,9)) CODEC(ZSTD(1)),
    `Exemplars.Value`             Array(Float64) CODEC(ZSTD(1)),
    `Exemplars.SpanId`            Array(String) CODEC(ZSTD(1)),
    `Exemplars.TraceId`           Array(String) CODEC(ZSTD(1)),
    Flags                         UInt32 CODEC(ZSTD(1)),
    Min                           Float64 CODEC(ZSTD(1)),
    Max                           Float64 CODEC(ZSTD(1)),
    AggregationTemporality        Int32 CODEC(ZSTD(1)),
    StartTimeUnix                 DateTime64(9) MATERIALIZED fromUnixTimestamp64Nano(CAST(StartTimeUnixRaw * 1000000000 AS Int64)) CODEC(ZSTD(1)),
    TimeUnix                      DateTime64(9) MATERIALIZED fromUnixTimestamp64Nano(CAST(TimeUnixRaw * 1000000000 AS Int64)) CODEC(Delta, ZSTD(1)),
    `Exemplars.TimeUnix`          Array(DateTime64(9)) MATERIALIZED arrayMap(x -> fromUnixTimestamp64Nano(CAST(x * 1000000000 AS Int64)), `Exemplars.TimeUnixRaw`) CODEC(ZSTD(1))
)
ENGINE = MergeTree
PARTITION BY toDate(TimeUnix)
ORDER BY (ServiceName, MetricName, toDateTime(TimeUnix))
TTL toDateTime(TimeUnix) + toIntervalDay(31);

-- Metricas OTel: summary (TTL de 31 dias)
CREATE TABLE IF NOT EXISTS zabbix.otel_metrics_summary
(
    ResourceAttributes            Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    ResourceSchemaUrl             String CODEC(ZSTD(1)),
    ScopeName                     String CODEC(ZSTD(1)),
    ScopeVersion                  String CODEC(ZSTD(1)),
    ScopeAttributes               Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    ScopeDroppedAttrCount         UInt32 CODEC(ZSTD(1)),
    ScopeSchemaUrl                String CODEC(ZSTD(1)),
    ServiceName                   LowCardinality(String) CODEC(ZSTD(1)),
    MetricName                    String CODEC(ZSTD(1)),
    MetricDescription             String CODEC(ZSTD(1)),
    MetricUnit                    String CODEC(ZSTD(1)),
    Attributes                    Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    StartTimeUnixRaw              Decimal(19,9) CODEC(ZSTD(1)),
    TimeUnixRaw                   Decimal(19,9) CODEC(ZSTD(1)),
    Count                         UInt64 CODEC(ZSTD(1)),
    Sum                           Float64 CODEC(ZSTD(1)),
    `ValueAtQuantiles.Quantile`   Array(Float64) CODEC(ZSTD(1)),
    `ValueAtQuantiles.Value`      Array(Float64) CODEC(ZSTD(1)),
    Flags                         UInt32 CODEC(ZSTD(1)),
    StartTimeUnix                 DateTime64(9) MATERIALIZED fromUnixTimestamp64Nano(CAST(StartTimeUnixRaw * 1000000000 AS Int64)) CODEC(ZSTD(1)),
    TimeUnix                      DateTime64(9) MATERIALIZED fromUnixTimestamp64Nano(CAST(TimeUnixRaw * 1000000000 AS Int64)) CODEC(Delta, ZSTD(1))
)
ENGINE = MergeTree
PARTITION BY toDate(TimeUnix)
ORDER BY (ServiceName, MetricName, toDateTime(TimeUnix))
TTL toDateTime(TimeUnix) + toIntervalDay(31);
