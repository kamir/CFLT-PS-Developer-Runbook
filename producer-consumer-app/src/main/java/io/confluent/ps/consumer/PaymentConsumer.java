package io.confluent.ps.consumer;

import io.confluent.ps.config.ConfigLoader;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.StringDeserializer;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.Collections;
import java.util.Properties;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * PCI-DSS compliant Kafka consumer that reads masked payment events
 * from Confluent Cloud.
 *
 * Usage:
 *   java -Dapp.env=dev -jar producer-consumer-app.jar consume
 */
public class PaymentConsumer {

    private static final Logger log = LoggerFactory.getLogger(PaymentConsumer.class);
    private static final String DEFAULT_TOPIC = "payments";
    private static final AtomicBoolean running = new AtomicBoolean(true);

    public static void main(String[] args) {
        runConsumer();
    }

    public static void runConsumer() {
        Properties props = ConfigLoader.load();
        props.putIfAbsent(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG,
                StringDeserializer.class.getName());
        props.putIfAbsent(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG,
                StringDeserializer.class.getName());
        props.putIfAbsent(ConsumerConfig.GROUP_ID_CONFIG, "payment-consumer-group");
        props.putIfAbsent(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        props.putIfAbsent(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");
        props.putIfAbsent(ConsumerConfig.CLIENT_ID_CONFIG, "payment-consumer");

        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            log.info("Shutdown signal received");
            running.set(false);
        }));

        String topic = resolveTopic();
        try (KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props)) {
            consumer.subscribe(Collections.singletonList(topic));
            log.info("PaymentConsumer started — subscribed to topic '{}'", topic);

            long totalConsumed = 0;
            while (running.get()) {
                ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(1000));

                if (!records.isEmpty()) {
                    records.forEach(record -> {
                        log.info("Received payment: partition={} offset={} key={} value={}",
                                record.partition(), record.offset(),
                                record.key(), record.value());
                        // -------------------------------------------------------
                        // Business logic goes here.
                        // IMPORTANT: Never log full card numbers (PCI-DSS Req 3).
                        // -------------------------------------------------------
                    });

                    // Commit after processing the batch
                    consumer.commitSync();
                    totalConsumed += records.count();
                    log.info("Committed offsets — total consumed: {}", totalConsumed);
                }
            }

            log.info("PaymentConsumer stopped after consuming {} records", totalConsumed);
        }
    }

    private static String resolveTopic() {
        String fromEnv = System.getenv("CONSUME_TOPIC");
        if (fromEnv != null && !fromEnv.isBlank()) {
            return fromEnv.trim();
        }
        String fromProp = System.getProperty("consumer.topic");
        if (fromProp != null && !fromProp.isBlank()) {
            return fromProp.trim();
        }
        return DEFAULT_TOPIC;
    }
}
