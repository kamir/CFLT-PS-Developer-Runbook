package io.confluent.ps.kstreams.topology;

import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.Named;
import org.apache.kafka.streams.kstream.Produced;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Properties;

/**
 * Kafka Streams topology for real-time payment fraud detection.
 *
 * Pipeline:
 *   payments (input)
 *     -> filter high-value transactions (> threshold)
 *     -> evaluate risk score
 *     -> branch: fraud-alerts / approved-payments
 */
public class FraudDetectionTopology {

    private static final Logger log = LoggerFactory.getLogger(FraudDetectionTopology.class);

    public static final String INPUT_TOPIC = "payments";
    public static final String FRAUD_ALERTS_TOPIC = "fraud-alerts";
    public static final String APPROVED_TOPIC = "approved-payments";

    private static final double HIGH_VALUE_THRESHOLD = 1000.00;
    private static final double RISK_SCORE_THRESHOLD = 0.7;

    private FraudDetectionTopology() {}

    public static Topology build(Properties props) {
        props.putIfAbsent(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG,
                Serdes.StringSerde.class.getName());
        props.putIfAbsent(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG,
                Serdes.StringSerde.class.getName());

        StreamsBuilder builder = new StreamsBuilder();

        // Source: read payment events
        KStream<String, String> payments = builder.stream(
                INPUT_TOPIC,
                Consumed.with(Serdes.String(), Serdes.String())
                        .withName("source-payments")
        );

        // Step 1: Enrich with risk score
        KStream<String, String> scored = payments
                .mapValues((key, value) -> enrichWithRiskScore(key, value),
                        Named.as("enrich-risk-score"));

        // Step 2: Branch — flagged vs. approved
        scored.split(Named.as("fraud-check-"))
                .branch(
                        (key, value) -> isFraudulent(value),
                        org.apache.kafka.streams.kstream.Branched.withConsumer(
                                flagged -> flagged.to(
                                        FRAUD_ALERTS_TOPIC,
                                        Produced.with(Serdes.String(), Serdes.String())
                                                .withName("sink-fraud-alerts")
                                ),
                                "flagged"
                        )
                )
                .defaultBranch(
                        org.apache.kafka.streams.kstream.Branched.withConsumer(
                                approved -> approved.to(
                                        APPROVED_TOPIC,
                                        Produced.with(Serdes.String(), Serdes.String())
                                                .withName("sink-approved")
                                ),
                                "approved"
                        )
                );

        return builder.build();
    }

    /**
     * Simulates risk scoring. In production, this would call an ML model
     * or a rules engine.
     */
    static String enrichWithRiskScore(String key, String paymentJson) {
        double amount = extractAmount(paymentJson);
        double riskScore = computeRiskScore(amount, paymentJson);

        // Inject risk_score into the JSON (simplified — use proper JSON library in production)
        String enriched = paymentJson.substring(0, paymentJson.length() - 1)
                + ",\"risk_score\":" + String.format("%.2f", riskScore) + "}";

        if (riskScore > RISK_SCORE_THRESHOLD) {
            log.warn("HIGH RISK txn_id={} amount={} risk_score={}", key, amount, riskScore);
        }

        return enriched;
    }

    static boolean isFraudulent(String enrichedJson) {
        // Extract risk_score from enriched JSON
        int idx = enrichedJson.indexOf("\"risk_score\":");
        if (idx < 0) return false;
        String scoreStr = enrichedJson.substring(idx + 13).split("[,}]")[0];
        try {
            return Double.parseDouble(scoreStr) > RISK_SCORE_THRESHOLD;
        } catch (NumberFormatException e) {
            return false;
        }
    }

    /**
     * Simple risk scoring heuristic.
     * Replace with a real ML model or rules engine for production.
     */
    static double computeRiskScore(double amount, String paymentJson) {
        double score = 0.0;

        // Rule 1: High-value transactions are riskier
        if (amount > HIGH_VALUE_THRESHOLD) {
            score += 0.4;
        }
        if (amount > 5000.00) {
            score += 0.3;
        }

        // Rule 2: Certain regions are higher risk (simplified)
        if (paymentJson.contains("\"region\":\"AP-SOUTH\"")) {
            score += 0.2;
        }

        // Rule 3: Round amounts are suspicious
        if (amount == Math.floor(amount) && amount > 500) {
            score += 0.15;
        }

        return Math.min(score, 1.0);
    }

    static double extractAmount(String json) {
        int idx = json.indexOf("\"amount\":");
        if (idx < 0) return 0.0;
        String amountStr = json.substring(idx + 9).split("[,}]")[0];
        try {
            return Double.parseDouble(amountStr);
        } catch (NumberFormatException e) {
            return 0.0;
        }
    }
}
