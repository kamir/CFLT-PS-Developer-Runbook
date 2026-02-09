package io.confluent.ps.kstreams;

import io.confluent.ps.kstreams.topology.FraudDetectionTopology;

import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.Topology;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;
import java.util.concurrent.CountDownLatch;

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
            return KafkaStreams.StreamsUncaughtExceptionHandler
                    .StreamThreadExceptionResponse.SHUTDOWN_APPLICATION;
        });

        try {
            streams.start();
            log.info("FraudDetectionApp started");
            latch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Main thread interrupted");
        } finally {
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
