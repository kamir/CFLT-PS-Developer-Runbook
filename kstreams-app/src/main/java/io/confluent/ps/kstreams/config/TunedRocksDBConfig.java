package io.confluent.ps.kstreams.config;

import org.apache.kafka.streams.state.RocksDBConfigSetter;
import org.rocksdb.BlockBasedTableConfig;
import org.rocksdb.CompressionType;
import org.rocksdb.LRUCache;
import org.rocksdb.Options;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;

/**
 * Production-tuned RocksDB configuration for Kafka Streams state stores.
 *
 * <p>Key optimizations:
 * <ul>
 *   <li>128 MB block cache (vs. 50 MB default) — reduces disk reads</li>
 *   <li>64 MB write buffer (vs. ~4 MB default) — fewer flush operations</li>
 *   <li>LZ4 compression — good throughput/compression trade-off</li>
 *   <li>Pin index/filter blocks in cache — prevents cache churn</li>
 * </ul>
 *
 * <p><strong>Memory budget:</strong> Each state store instance uses approximately
 * 128 MB (block cache) + 192 MB (3 write buffers × 64 MB) = 320 MB of native memory.
 * Ensure your container memory limit accounts for this on top of JVM heap.
 *
 * <p>Register via:
 * <pre>
 * rocksdb.config.setter=io.confluent.ps.kstreams.config.TunedRocksDBConfig
 * </pre>
 *
 * @see <a href="https://kafka.apache.org/documentation/streams/developer-guide/config-streams.html">Kafka Streams Configuration</a>
 */
public class TunedRocksDBConfig implements RocksDBConfigSetter {

    private static final Logger log = LoggerFactory.getLogger(TunedRocksDBConfig.class);

    private static final long BLOCK_CACHE_SIZE = 128 * 1024 * 1024L;   // 128 MB
    private static final long BLOCK_SIZE = 16 * 1024L;                  // 16 KB
    private static final long WRITE_BUFFER_SIZE = 64 * 1024 * 1024L;   // 64 MB
    private static final int MAX_WRITE_BUFFER_NUMBER = 3;
    private static final int MAX_BACKGROUND_JOBS = 4;
    private static final long MAX_BYTES_FOR_LEVEL_BASE = 256 * 1024 * 1024L; // 256 MB

    private org.rocksdb.Cache cache;

    @Override
    public void setConfig(String storeName, Options options,
                          Map<String, Object> configs) {

        log.info("Applying tuned RocksDB config for store '{}'", storeName);

        // Block-based table configuration
        BlockBasedTableConfig tableConfig = new BlockBasedTableConfig();
        cache = new LRUCache(BLOCK_CACHE_SIZE);
        tableConfig.setBlockCache(cache);
        tableConfig.setBlockSize(BLOCK_SIZE);
        tableConfig.setCacheIndexAndFilterBlocks(true);
        tableConfig.setPinL0FilterAndIndexBlocksInCache(true);

        // Write buffer configuration
        options.setWriteBufferSize(WRITE_BUFFER_SIZE);
        options.setMaxWriteBufferNumber(MAX_WRITE_BUFFER_NUMBER);
        options.setMinWriteBufferNumberToMerge(1);

        // Compaction
        options.setMaxBackgroundJobs(MAX_BACKGROUND_JOBS);
        options.setMaxBytesForLevelBase(MAX_BYTES_FOR_LEVEL_BASE);

        // Compression
        options.setCompressionType(CompressionType.LZ4_COMPRESSION);

        options.setTableFormatConfig(tableConfig);

        log.info("RocksDB config for '{}': cache={}MB, writeBuffer={}MB×{}, compression=LZ4",
                storeName,
                BLOCK_CACHE_SIZE / (1024 * 1024),
                WRITE_BUFFER_SIZE / (1024 * 1024),
                MAX_WRITE_BUFFER_NUMBER);
    }

    @Override
    public void close(String storeName, Options options) {
        if (cache != null) {
            cache.close();
        }
    }
}
