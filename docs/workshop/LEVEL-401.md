# Level 401 — Art of Optimization

> *The art of optimization.*
> Full-day engineering deep dive (6h) — performance tuning, RocksDB, production hardening.

---

## Prerequisites

- Level 101, 201, and 301 complete
- Solid understanding of Kafka internals (partitions, ISR, consumer groups)
- Access to a Confluent Cloud **dedicated** cluster (or local multi-broker setup)
- Monitoring stack available (JMX + Prometheus + Grafana or equivalent)

---

## Schedule

| Time | Block | Topic | Badge |
|---|---|---|---|
| 09:00 – 09:15 | Opening | Level 401 objectives, performance mindset | — |
| 09:15 – 10:45 | **Block 16** | Producer & Consumer Tuning | Tuner Badge |
| 10:45 – 11:00 | *Break* | | |
| 11:00 – 12:30 | **Block 17** | Kafka Streams & RocksDB Optimization | Engineer Badge |
| 12:30 – 13:30 | *Lunch* | | |
| 13:30 – 15:00 | **Block 18** | Kubernetes Resource Tuning & JVM Optimization | Architect Badge |
| 15:00 – 15:15 | *Break* | | |
| 15:15 – 16:30 | **Block 19** | Production Load Testing & Capacity Planning | Field Marshal Badge |
| 16:30 – 17:00 | Closing | Recap, certification | Grand Master |

---

## Block 16 — Producer & Consumer Tuning

### Goal: Earn the **Tuner Badge**

---

### 16.1 — Producer Throughput Optimization (30 min)

#### Key Tuning Parameters

```properties
# ---------- Batching (most impactful) ----------
# Larger batches = fewer network requests = higher throughput
batch.size=65536                    # Default: 16384 (16 KB)
linger.ms=20                       # Default: 0 (send immediately)
# batch.size=64KB + linger.ms=20ms → producer buffers up to 64KB or 20ms

# ---------- Compression ----------
# Compress batches before sending → less network, more CPU
compression.type=lz4               # Options: none, gzip, snappy, lz4, zstd
# lz4: best throughput/compression ratio for most workloads
# zstd: best compression ratio (20–30% smaller than lz4)

# ---------- Memory ----------
buffer.memory=67108864              # Default: 32MB → increase for bursty workloads
max.block.ms=60000                 # Block time when buffer is full

# ---------- In-flight requests ----------
max.in.flight.requests.per.connection=5   # Max with idempotence=true

# ---------- Durability vs. throughput ----------
acks=all                           # Keep for PCI-DSS
enable.idempotence=true            # Keep for exactly-once
```

#### Lab: Benchmark Different Configurations

```bash
# Baseline: default settings
kafka-producer-perf-test \
  --topic perf-test \
  --num-records 1000000 \
  --record-size 512 \
  --throughput -1 \
  --producer-props bootstrap.servers=localhost:9092

# Tuned: larger batches + compression
kafka-producer-perf-test \
  --topic perf-test \
  --num-records 1000000 \
  --record-size 512 \
  --throughput -1 \
  --producer-props bootstrap.servers=localhost:9092 \
    batch.size=65536 \
    linger.ms=20 \
    compression.type=lz4

# Record results:
# | Config    | Records/sec | MB/sec | Avg Latency | P99 Latency |
# |-----------|-------------|--------|-------------|-------------|
# | Baseline  | ???         | ???    | ???         | ???         |
# | Tuned     | ???         | ???    | ???         | ???         |
```

---

### 16.2 — Consumer Throughput Optimization (25 min)

#### Key Tuning Parameters

```properties
# ---------- Fetch size ----------
fetch.min.bytes=1048576             # Default: 1 → wait for 1MB before returning
fetch.max.wait.ms=500              # Max wait time for fetch.min.bytes
max.partition.fetch.bytes=1048576  # Max bytes per partition per fetch

# ---------- Polling ----------
max.poll.records=1000              # Default: 500 → more records per poll
max.poll.interval.ms=300000        # Default: 5min → increase for slow processing

# ---------- Threading model ----------
# Option A: Multiple consumers in the same group (scale out)
# Option B: Thread pool inside a single consumer (scale up)
```

#### Lab: Consumer Scaling Strategies

```java
// Option B: Thread pool inside consumer
ExecutorService executor = Executors.newFixedThreadPool(8);

while (running.get()) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(1000));

    // Process records in parallel
    List<Future<?>> futures = new ArrayList<>();
    for (ConsumerRecord<String, String> record : records) {
        futures.add(executor.submit(() -> processRecord(record)));
    }

    // Wait for all to complete before committing
    for (Future<?> f : futures) { f.get(); }
    consumer.commitSync();
}
```

**Question:** Why must we wait for all futures before committing? (Answer: If we commit before processing completes and the app crashes, we lose unprocessed records.)

---

### 16.3 — Benchmark: Consumer Throughput

```bash
# Baseline
kafka-consumer-perf-test \
  --bootstrap-server localhost:9092 \
  --topic perf-test \
  --messages 1000000 \
  --threads 1

# Tuned
kafka-consumer-perf-test \
  --bootstrap-server localhost:9092 \
  --topic perf-test \
  --messages 1000000 \
  --threads 1 \
  --fetch-size 1048576
```

---

### 16.4 — Checkpoint

```bash
./scripts/workshop-check.sh block16
```

---

## Block 17 — Kafka Streams & RocksDB Optimization

### Goal: Earn the **Engineer Badge**

> *This is the engineering heart of Level 401.*

---

### 17.1 — Kafka Streams Threading Model (15 min)

```
KafkaStreams Application
├── StreamThread-1
│   ├── Task 0_0 (partition 0)
│   │   └── RocksDB State Store
│   └── Task 0_1 (partition 1)
│       └── RocksDB State Store
├── StreamThread-2
│   ├── Task 0_2 (partition 2)
│   │   └── RocksDB State Store
│   └── Task 0_3 (partition 3)
│       └── RocksDB State Store
└── Global StreamThread (if using GlobalKTable)
```

Key configuration:

```properties
# Number of stream threads per instance
num.stream.threads=4               # Default: 1 → set to available CPU cores

# Exactly-once processing (PCI-DSS)
processing.guarantee=exactly_once_v2

# Commit interval — lower = lower latency, higher = better throughput
commit.interval.ms=100             # Default: 30000 (30s)

# State store cache — buffers writes before flushing to RocksDB
statestore.cache.max.bytes=10485760  # Default: 10MB per thread
# Larger cache = fewer RocksDB writes = better throughput
```

---

### 17.2 — RocksDB Configuration Deep Dive (30 min)

RocksDB is the default state store backend for Kafka Streams. It's the most impactful tuning area for stateful applications.

#### Default vs. Tuned Configuration

```java
// Custom RocksDB config supplier
public class TunedRocksDBConfig implements RocksDBConfigSetter {

    @Override
    public void setConfig(String storeName, Options options,
                          Map<String, Object> configs) {
        // ---------- Block Cache ----------
        // Default: 50MB → increase for read-heavy workloads
        BlockBasedTableConfig tableConfig = new BlockBasedTableConfig();
        tableConfig.setBlockCache(new LRUCache(128 * 1024 * 1024L)); // 128MB
        tableConfig.setBlockSize(16 * 1024);     // 16KB (default: 4KB)
        tableConfig.setCacheIndexAndFilterBlocks(true);
        tableConfig.setPinL0FilterAndIndexBlocksInCache(true);

        // ---------- Write Buffer ----------
        // Larger write buffer = fewer flushes to disk = better write throughput
        options.setWriteBufferSize(64 * 1024 * 1024L);  // 64MB (default: ~4MB)
        options.setMaxWriteBufferNumber(3);               // Default: 2
        options.setMinWriteBufferNumberToMerge(1);

        // ---------- Compaction ----------
        options.setMaxBackgroundJobs(4);           // Parallel compaction threads
        options.setMaxBytesForLevelBase(256 * 1024 * 1024L);  // 256MB

        // ---------- Compression ----------
        options.setCompressionType(CompressionType.LZ4_COMPRESSION);

        options.setTableFormatConfig(tableConfig);
    }

    @Override
    public void close(String storeName, Options options) {
        // No-op
    }
}
```

Register it:
```properties
# application-prod.properties
rocksdb.config.setter=io.confluent.ps.kstreams.config.TunedRocksDBConfig
```

#### Memory Budget Planning

```
Total JVM Heap:                          2 GB
├── Kafka Streams Cache (per thread):    10 MB x 4 threads =  40 MB
├── RocksDB Block Cache (per store):    128 MB x 4 stores  = 512 MB
│   (Note: this is OFF-HEAP / native memory)
├── RocksDB Write Buffers:               64 MB x 3 x 4     = 768 MB
│   (Also OFF-HEAP)
├── Application logic:                                      = ~200 MB
└── JVM overhead:                                           = ~200 MB
                                                       Total ≈ 1.7 GB

Container memory limit must be:
  JVM Heap (2 GB) + OFF-HEAP (1.3 GB) + overhead = 4 GB
```

> **Critical:** RocksDB uses native memory (off-heap). If your container limit
> is too low, the OOM-killer will terminate the pod silently.

---

### 17.3 — Lab: Measure State Store Performance (20 min)

```bash
# Create a stateful topology that uses windowed aggregation
# (This amplifies RocksDB read/write pressure)

# Run with default RocksDB config
java -Dapp.env=dev \
  -Xmx1g -Xms1g \
  -jar kstreams-app/target/kstreams-app-1.0.0-SNAPSHOT.jar

# Monitor RocksDB metrics via JMX
# Key metrics:
#   kafka.streams:type=stream-state-metrics,rocksdb-*
#     - bytes-written-rate
#     - bytes-read-rate
#     - memtable-bytes-flushed-rate
#     - block-cache-hit-ratio     (should be > 90%)
#     - write-stall-duration-total (should be 0)
```

**Task:** Apply the `TunedRocksDBConfig` and compare:
1. Block cache hit ratio (before vs. after)
2. Write stall duration
3. Overall process rate (`kafka.streams:type=stream-thread-metrics,process-rate`)

---

### 17.4 — Standby Replicas and State Restoration (15 min)

```properties
# Standby replicas keep a shadow copy of state on other instances
# Drastically reduces restoration time after a rebalance
num.standby.replicas=1             # Default: 0

# Acceptable lag for standby before it's considered caught up
# (impacts rebalance speed)
acceptable.recovery.lag=10000      # Default: 10000
```

**Why it matters:** Without standby replicas, a KStreams rebalance restores state from the changelog topic — this can take minutes for large state stores. With standbys, failover is near-instant.

---

### 17.5 — Checkpoint

```bash
./scripts/workshop-check.sh block17
```

---

## Block 18 — Kubernetes Resource Tuning & JVM Optimization

### Goal: Earn the **Architect Badge**

---

### 18.1 — JVM Tuning for Kafka Applications (25 min)

```bash
# Production JVM flags for KStreams apps
java \
  -Xms2g -Xmx2g                         \  # Fixed heap (avoid resize pauses)
  -XX:+UseG1GC                           \  # G1 garbage collector
  -XX:MaxGCPauseMillis=20                \  # Target GC pause time
  -XX:G1HeapRegionSize=16m               \  # Larger regions for large heaps
  -XX:+ParallelRefProcEnabled            \  # Parallel reference processing
  -XX:MaxMetaspaceSize=256m              \  # Cap metaspace
  -XX:+ExitOnOutOfMemoryError            \  # Crash instead of limping (K8s will restart)
  -XX:+HeapDumpOnOutOfMemoryError        \  # Capture heap dump before crash
  -XX:HeapDumpPath=/tmp/heapdump.hprof   \
  -Dcom.sun.management.jmxremote         \  # Enable JMX
  -Dcom.sun.management.jmxremote.port=9101 \
  -jar kstreams-app.jar
```

#### Key Decisions

| Decision | Recommendation | Reason |
|---|---|---|
| GC algorithm | G1GC | Best for heaps 1–8 GB, predictable pauses |
| Heap size | Fixed (Xms=Xmx) | Avoid resize pauses, predictable memory |
| `-XX:+ExitOnOutOfMemoryError` | Always | Let K8s restart the pod cleanly |
| Metaspace | Capped at 256m | Prevent unbounded growth |

---

### 18.2 — Kubernetes Resource Limits (20 min)

```yaml
# production-tuned K8s deployment
containers:
  - name: fraud-detection
    resources:
      requests:
        cpu: "1000m"       # 1 full core guaranteed
        memory: "4Gi"      # JVM heap + RocksDB off-heap
      limits:
        cpu: "2000m"       # Burst to 2 cores
        memory: "4Gi"      # SAME as request (no overcommit!)
    env:
      - name: JAVA_OPTS
        value: "-Xms2g -Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=20"
```

> **Rule:** For KStreams apps, set `requests.memory == limits.memory`.
> Memory overcommit + RocksDB off-heap = OOMKilled.

#### Pod Topology: Spread Across Nodes

```yaml
# Spread KStreams pods across nodes for HA
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: fraud-detection
```

---

### 18.3 — Lab: Profile Under Load (20 min)

```bash
# 1. Deploy to kind with production resource settings
kind create cluster --name tuning-lab --config kind-cluster.yaml
kind load docker-image fraud-detection:workshop --name tuning-lab
kubectl apply -k k8s/overlays/prod/

# 2. Generate load
k6 run --vus 50 --duration 5m tests/load/payment-producer-test.js

# 3. Monitor resource usage
kubectl top pods -n confluent-apps-prod --containers

# 4. Check for OOMKilled events
kubectl get events -n confluent-apps-prod | grep -i oom

# 5. Check GC logs (if enabled)
kubectl logs -n confluent-apps-prod -l app=fraud-detection | grep "GC"
```

---

### 18.4 — Checkpoint

```bash
./scripts/workshop-check.sh block18
```

---

## Block 19 — Production Load Testing & Capacity Planning

### Goal: Earn the **Field Marshal Badge**

---

### 19.1 — Capacity Planning Framework (20 min)

```
Inputs:
  - Peak message rate:     10,000 msg/sec
  - Average message size:  512 bytes
  - Retention period:      7 days
  - Replication factor:    3
  - Number of consumers:   4

Calculations:
  Ingress throughput  = 10,000 × 512 B = 5 MB/sec
  Storage per day     = 5 MB/s × 86400 = 432 GB/day
  With replication    = 432 × 3 = 1.3 TB/day
  7-day retention     = 1.3 × 7 = 9.1 TB total storage

  Partitions needed:
    Rule: 1 partition ≈ 10 MB/sec throughput (conservative)
    Min for throughput: 5 / 10 = 1 partition
    Min for parallelism: max(consumers) = 4
    Recommended: 6 partitions (headroom for growth)

  KStreams instances:
    Max parallelism = number of partitions = 6
    Recommended: 3–4 instances (each handles 1.5–2 partitions)
```

---

### 19.2 — End-to-End Load Test (30 min)

```bash
# Create the performance test topic
docker exec broker kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic perf-payments \
  --partitions 12 \
  --replication-factor 1

# Phase 1: Sustained load (baseline)
kafka-producer-perf-test \
  --topic perf-payments \
  --num-records 500000 \
  --record-size 512 \
  --throughput 10000 \
  --producer-props bootstrap.servers=localhost:9092 \
    batch.size=65536 linger.ms=20 compression.type=lz4

# Phase 2: Burst test (2x peak)
kafka-producer-perf-test \
  --topic perf-payments \
  --num-records 200000 \
  --record-size 512 \
  --throughput 20000 \
  --producer-props bootstrap.servers=localhost:9092 \
    batch.size=65536 linger.ms=20 compression.type=lz4

# Phase 3: Consumer throughput
kafka-consumer-perf-test \
  --bootstrap-server localhost:9092 \
  --topic perf-payments \
  --messages 500000 \
  --threads 4
```

**Record results and compare against SLA targets.**

---

### 19.3 — Production Readiness Checklist (15 min)

| Category | Check | Status |
|---|---|---|
| **Performance** | Throughput exceeds 2x peak requirement | [ ] |
| **Performance** | P99 latency under SLA threshold | [ ] |
| **Performance** | Consumer lag stays below threshold under load | [ ] |
| **Resilience** | App recovers from broker restart | [ ] |
| **Resilience** | KStreams state restores within SLA | [ ] |
| **Resilience** | Pod restart completes within liveness probe timeout | [ ] |
| **Security** | SASL_SSL configured, API keys rotated | [ ] |
| **Security** | NetworkPolicy restricts egress | [ ] |
| **Security** | No secrets in Git, Vault integration working | [ ] |
| **Monitoring** | JMX metrics exported to Prometheus | [ ] |
| **Monitoring** | Alerts configured for lag, errors, thread death | [ ] |
| **Operations** | Runbook documented and tested | [ ] |
| **Operations** | Rollback procedure validated | [ ] |
| **PCI-DSS** | Card data masked in all messages and logs | [ ] |
| **PCI-DSS** | Audit logging enabled (90-day retention) | [ ] |

---

### 19.4 — Checkpoint

```bash
./scripts/workshop-check.sh block19
```

---

## Level 401 Complete!

```bash
./scripts/workshop-check.sh level401
```

```
  ================================================
    GROSSMEISTER — Level 401 Complete!
    You have mastered the art of optimization.
    You are ready for production.
  ================================================
```

---

## Complete Learning Path Summary

```
Level 101 — Earn Your Badges    (1 day)
  Blocks 1–6, Badges: Bronze → Diamant → Master Badge

Level 201 — Know the Tools           (half day)
  Blocks 7–10, Badges: Smith → Messenger → Tool Master

Level 301 — Master the Workshop        (1 day)
  Blocks 11–15, Badges: Pipeline → General → Workshop Master

Level 401 — Art of Optimization     (1 day)
  Blocks 16–19, Badges: Tuner → Field Marshal → Grand Master
```

**Total:** 3.5 days | 19 blocks | 17 Badges | 1 Grand Master
