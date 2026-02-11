package io.confluent.ps.kstreams;

import io.confluent.ps.kstreams.topology.FraudDetectionTopology;

import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.errors.StreamsUncaughtExceptionHandler;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Kafka Streams application for real-time payment fraud detection.
 *
 * Reads from the 'payments' topic, evaluates risk rules, and writes
 * flagged transactions to the 'fraud-alerts' topic.
 *
 * Designed for Kubernetes deployment with graceful shutdown support.
 *
 * Usage:
 *   java -Dapp.env=dev  -jar kstreams-app.jar
 *   java -Dapp.env=prod -Dconfig.file=/etc/kafka/streams.properties -jar kstreams-app.jar
 */
public class FraudDetectionApp {

    private static final Logger log = LoggerFactory.getLogger(FraudDetectionApp.class);

    public static void main(String[] args) {
        Properties props = loadConfig();
        Topology topology = FraudDetectionTopology.build(props);

        log.info("Topology:\n{}", topology.describe());

        KafkaStreams streams = new KafkaStreams(topology, props);
        ScheduledExecutorService heartbeat = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "kstreams-heartbeat");
            t.setDaemon(true);
            return t;
        });

        // Graceful shutdown hook — critical for K8s SIGTERM handling
        CountDownLatch latch = new CountDownLatch(1);
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            log.info("Shutdown signal received — closing KafkaStreams");
            streams.close();
            latch.countDown();
        }));

        // State listener for health checks
        streams.setStateListener((newState, oldState) -> {
            log.info("State transition: {} -> {}", oldState, newState);
            if (newState == KafkaStreams.State.ERROR) {
                log.error("KafkaStreams entered ERROR state — shutting down");
                streams.close();
                latch.countDown();
            }
        });

        // Uncaught exception handler
        streams.setUncaughtExceptionHandler(ex -> {
            log.error("Uncaught exception in stream thread", ex);
            return StreamsUncaughtExceptionHandler.StreamThreadExceptionResponse.SHUTDOWN_APPLICATION;
        });

        try {
            streams.start();
            log.info("FraudDetectionApp started");
            heartbeat.scheduleAtFixedRate(() -> {
                log.info("Processor heartbeat — state={}, app.id={}",
                        streams.state(), props.getProperty(StreamsConfig.APPLICATION_ID_CONFIG));
            }, 10, 30, TimeUnit.SECONDS);
            latch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Main thread interrupted");
        } finally {
            heartbeat.shutdownNow();
            streams.close();
            log.info("FraudDetectionApp stopped");
        }
    }

    private static Properties loadConfig() {
        String env = System.getProperty("app.env",
                System.getenv().getOrDefault("APP_ENV", "dev"));
        Properties props = new Properties();

        loadFromClasspath(props, "application.properties");
        loadFromClasspath(props, "application-" + env + ".properties");

        loadClientProperties(props);

        String externalFile = System.getProperty("config.file");
        if (externalFile != null) {
            try (InputStream is = Files.newInputStream(Path.of(externalFile))) {
                props.load(is);
                log.info("Loaded external config: {}", externalFile);
            } catch (IOException e) {
                log.warn("Failed to load external config: {}", externalFile, e);
            }
        }

        // Environment variable overrides
        mapEnv("KAFKA_BOOTSTRAP_SERVERS",    "bootstrap.servers",    props);
        mapEnv("KAFKA_SECURITY_PROTOCOL",    "security.protocol",    props);
        mapEnv("KAFKA_SASL_MECHANISM",       "sasl.mechanism",       props);
        mapEnv("KAFKA_SASL_JAAS_CONFIG",     "sasl.jaas.config",     props);
        mapEnv("SCHEMA_REGISTRY_URL",        "schema.registry.url",  props);
        mapEnv("SCHEMA_REGISTRY_USER_INFO",  "schema.registry.basic.auth.user.info", props);

        // Ensure required Streams config
        props.putIfAbsent(StreamsConfig.APPLICATION_ID_CONFIG, "fraud-detection-app");
        props.putIfAbsent(StreamsConfig.NUM_STREAM_THREADS_CONFIG, "1");

        log.info("Loaded KStreams config for env='{}', app.id='{}'",
                env, props.getProperty(StreamsConfig.APPLICATION_ID_CONFIG));
        return props;
    }

    private static void loadClientProperties(Properties props) {
        String override = System.getProperty("client.properties");
        if (override == null || override.isBlank()) {
            override = System.getenv("CLIENT_PROPERTIES_FILE");
        }
        if (override == null || override.isBlank()) {
            override = System.getenv("KAFKA_CLIENT_PROPERTIES");
        }
        if (override == null || override.isBlank()) {
            override = "client.properties";
        }

        Path path = Path.of(override);
        if (!Files.exists(path)) {
            log.debug("client.properties not found (skipped): {}", path);
            return;
        }

        try (InputStream is = Files.newInputStream(path)) {
            props.load(is);
            log.info("Loaded client.properties: {}", path);
        } catch (IOException e) {
            log.warn("Failed to load client.properties: {}", path, e);
        }
    }

    private static void loadFromClasspath(Properties props, String resource) {
        try (InputStream is = FraudDetectionApp.class.getClassLoader().getResourceAsStream(resource)) {
            if (is != null) {
                props.load(is);
            }
        } catch (IOException e) {
            log.warn("Failed to load: {}", resource, e);
        }
    }

    private static void mapEnv(String envVar, String propKey, Properties props) {
        String value = System.getenv(envVar);
        if (value != null && !value.isBlank()) {
            props.setProperty(propKey, value);
        }
    }
}
