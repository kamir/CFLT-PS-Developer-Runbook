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
import java.math.BigDecimal;
import java.math.RoundingMode;
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
    private static final int DEFAULT_MAX_RECORDS = 250;

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
        int maxRecords = resolveMaxRecords();
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
            log.info("PaymentProducer started — sending to topic '{}' (maxRecords={})", TOPIC, maxRecords);

            int count = 0;
            while (running.get() && count < maxRecords) {
                String txnId = UUID.randomUUID().toString();
                String payment = buildPaymentJson(txnId, count);

                int recordNumber = count + 1;
                ProducerRecord<String, String> record =
                        new ProducerRecord<>(TOPIC, txnId, payment);

                producer.send(record, (RecordMetadata meta, Exception ex) -> {
                    if (ex != null) {
                        log.error("Failed to send payment {}/{} txn_id={}", recordNumber, maxRecords, txnId, ex);
                    } else {
                        log.info("Sent payment {}/{} txn_id={} partition={} offset={}",
                                recordNumber, maxRecords, txnId, meta.partition(), meta.offset());
                    }
                });

                count++;
                Thread.sleep(500); // simulate real-world event cadence
            }

            producer.flush();
            log.info("PaymentProducer stopped after {} events", count);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Producer interrupted");
        }
    }

    private static int resolveMaxRecords() {
        String fromEnv = System.getenv("DEMO_MAX_RECORDS");
        if (fromEnv == null || fromEnv.isBlank()) {
            return DEFAULT_MAX_RECORDS;
        }
        try {
            int parsed = Integer.parseInt(fromEnv.trim());
            return parsed > 0 ? parsed : DEFAULT_MAX_RECORDS;
        } catch (NumberFormatException e) {
            return DEFAULT_MAX_RECORDS;
        }
    }

    /**
     * Builds a JSON payment event with masked card number (PCI-DSS).
     * In production, use Avro + Schema Registry instead of raw JSON.
     */
    static String buildPaymentJson(String txnId, int sequence) {
        String[] regions = {"US-EAST", "US-WEST", "EU-WEST", "AP-SOUTH"};
        String[] merchants = {"MERCH-001", "MERCH-002", "MERCH-003", "MERCH-004"};
        BigDecimal amount = BigDecimal.valueOf(10.00)
                .add(BigDecimal.valueOf(sequence % 500L).multiply(BigDecimal.valueOf(1.37)))
                .setScale(2, RoundingMode.HALF_UP);
        String maskedCard = "****-****-****-" + String.format("%04d", (sequence % 9999) + 1);

        return String.format(
                "{\"transaction_id\":\"%s\","
              + "\"card_number_masked\":\"%s\","
              + "\"amount\":%s,"
              + "\"currency\":\"USD\","
              + "\"merchant_id\":\"%s\","
              + "\"timestamp\":%d,"
              + "\"status\":\"PENDING\","
              + "\"region\":\"%s\"}",
                txnId,
                maskedCard,
                amount.toPlainString(),
                merchants[sequence % merchants.length],
                Instant.now().getEpochSecond(),
                regions[sequence % regions.length]
        );
    }
}
