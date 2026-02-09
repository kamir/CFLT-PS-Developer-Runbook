package io.confluent.ps.producer;

import io.confluent.ps.config.ConfigLoader;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.clients.producer.Callback;
import org.apache.kafka.common.serialization.StringSerializer;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Instant;
import java.util.Properties;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * PCI-DSS compliant Kafka producer that publishes masked payment events
 * to Confluent Cloud.
 *
 * Usage:
 *   java -Dapp.env=dev  -jar producer-consumer-app.jar produce
 *   java -Dapp.env=qa   -jar producer-consumer-app.jar produce
 *   java -Dapp.env=prod -jar producer-consumer-app.jar produce
 */
public class PaymentProducer {

    private static final Logger log = LoggerFactory.getLogger(PaymentProducer.class);
    private static final String TOPIC = "payments";
    private static final AtomicBoolean running = new AtomicBoolean(true);

    public static void main(String[] args) {
        String mode = (args.length > 0) ? args[0] : "produce";

        switch (mode) {
            case "produce" -> runProducer();
            case "consume" -> io.confluent.ps.consumer.PaymentConsumer.runConsumer();
            default -> {
                System.err.println("Usage: java -jar producer-consumer-app.jar [produce|consume]");
                System.exit(1);
            }
        }
    }

    public static void runProducer() {
        Properties props = ConfigLoader.load();
        props.putIfAbsent(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG,
                StringSerializer.class.getName());
        props.putIfAbsent(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG,
                StringSerializer.class.getName());
        props.putIfAbsent(ProducerConfig.ACKS_CONFIG, "all");
        props.putIfAbsent(ProducerConfig.RETRIES_CONFIG, "3");
        props.putIfAbsent(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");
        props.putIfAbsent(ProducerConfig.CLIENT_ID_CONFIG, "payment-producer");

        CountDownLatch shutdownLatch = new CountDownLatch(1);
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            log.info("Shutdown signal received");
            running.set(false);
            shutdownLatch.countDown();
        }));

        try (KafkaProducer<String, String> producer = new KafkaProducer<>(props)) {
            log.info("PaymentProducer started — sending to topic '{}'", TOPIC);

            int count = 0;
            while (running.get()) {
                String txnId = UUID.randomUUID().toString();
                String payment = buildPaymentJson(txnId, count);

                ProducerRecord<String, String> record =
                        new ProducerRecord<>(TOPIC, txnId, payment);

                producer.send(record, (RecordMetadata meta, Exception ex) -> {
                    if (ex != null) {
                        log.error("Failed to send payment txn_id={}", txnId, ex);
                    } else {
                        log.info("Sent payment txn_id={} partition={} offset={}",
                                txnId, meta.partition(), meta.offset());
                    }
                });

                count++;
                if (count % 100 == 0) {
                    log.info("Produced {} payment events so far", count);
                }
                Thread.sleep(500); // simulate real-world event cadence
            }

            producer.flush();
            log.info("PaymentProducer stopped after {} events", count);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Producer interrupted");
        }
    }

    /**
     * Builds a JSON payment event with masked card number (PCI-DSS).
     * In production, use Avro + Schema Registry instead of raw JSON.
     */
    static String buildPaymentJson(String txnId, int sequence) {
        String[] regions = {"US-EAST", "US-WEST", "EU-WEST", "AP-SOUTH"};
        String[] merchants = {"MERCH-001", "MERCH-002", "MERCH-003", "MERCH-004"};
        double amount = 10.00 + (sequence % 500) * 1.37;
        String maskedCard = "****-****-****-" + String.format("%04d", (sequence % 9999) + 1);

        return String.format(
                "{\"transaction_id\":\"%s\","
              + "\"card_number_masked\":\"%s\","
              + "\"amount\":%.2f,"
              + "\"currency\":\"USD\","
              + "\"merchant_id\":\"%s\","
              + "\"timestamp\":%d,"
              + "\"status\":\"PENDING\","
              + "\"region\":\"%s\"}",
                txnId,
                maskedCard,
                amount,
                merchants[sequence % merchants.length],
                Instant.now().toEpochMilli(),
                regions[sequence % regions.length]
        );
    }
}
