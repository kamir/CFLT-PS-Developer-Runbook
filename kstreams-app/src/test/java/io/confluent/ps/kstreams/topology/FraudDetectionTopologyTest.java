package io.confluent.ps.kstreams.topology;

import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.TestInputTopic;
import org.apache.kafka.streams.TestOutputTopic;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.TopologyTestDriver;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Properties;

import static org.junit.jupiter.api.Assertions.*;

class FraudDetectionTopologyTest {

    private TopologyTestDriver testDriver;
    private TestInputTopic<String, String> inputTopic;
    private TestOutputTopic<String, String> fraudAlertsTopic;
    private TestOutputTopic<String, String> approvedTopic;

    @BeforeEach
    void setup() {
        Properties props = new Properties();
        props.put(StreamsConfig.APPLICATION_ID_CONFIG, "fraud-detection-test");
        props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "dummy:9092");

        Topology topology = FraudDetectionTopology.build(props);
        testDriver = new TopologyTestDriver(topology, props);

        inputTopic = testDriver.createInputTopic(
                FraudDetectionTopology.INPUT_TOPIC,
                Serdes.String().serializer(),
                Serdes.String().serializer()
        );

        fraudAlertsTopic = testDriver.createOutputTopic(
                FraudDetectionTopology.FRAUD_ALERTS_TOPIC,
                Serdes.String().deserializer(),
                Serdes.String().deserializer()
        );

        approvedTopic = testDriver.createOutputTopic(
                FraudDetectionTopology.APPROVED_TOPIC,
                Serdes.String().deserializer(),
                Serdes.String().deserializer()
        );
    }

    @AfterEach
    void tearDown() {
        if (testDriver != null) {
            testDriver.close();
        }
    }

    @Test
    void lowValueTransaction_shouldBeApproved() {
        String payment = "{\"transaction_id\":\"txn-low\","
                + "\"card_number_masked\":\"****-****-****-1234\","
                + "\"amount\":50.00,"
                + "\"currency\":\"USD\","
                + "\"merchant_id\":\"MERCH-001\","
                + "\"timestamp\":1700000000000,"
                + "\"status\":\"PENDING\","
                + "\"region\":\"US-EAST\"}";

        inputTopic.pipeInput("txn-low", payment);

        assertTrue(fraudAlertsTopic.isEmpty(), "Low-value txn should NOT trigger fraud alert");
        assertFalse(approvedTopic.isEmpty(), "Low-value txn should be approved");

        String approved = approvedTopic.readValue();
        assertTrue(approved.contains("\"risk_score\":"), "Should contain risk_score");
    }

    @Test
    void highValueTransaction_fromHighRiskRegion_shouldBeFlagged() {
        // amount > 5000 gives 0.4 + 0.3 = 0.7, AP-SOUTH adds 0.2 -> total 0.9
        String payment = "{\"transaction_id\":\"txn-fraud\","
                + "\"card_number_masked\":\"****-****-****-9999\","
                + "\"amount\":7500.00,"
                + "\"currency\":\"USD\","
                + "\"merchant_id\":\"MERCH-002\","
                + "\"timestamp\":1700000000000,"
                + "\"status\":\"PENDING\","
                + "\"region\":\"AP-SOUTH\"}";

        inputTopic.pipeInput("txn-fraud", payment);

        assertFalse(fraudAlertsTopic.isEmpty(), "High-risk txn should trigger fraud alert");

        String alert = fraudAlertsTopic.readValue();
        assertTrue(alert.contains("\"risk_score\":"), "Alert should contain risk_score");
    }

    @Test
    void extractAmount_shouldParseCorrectly() {
        String json = "{\"amount\":1234.56,\"other\":\"field\"}";
        assertEquals(1234.56, FraudDetectionTopology.extractAmount(json), 0.01);
    }

    @Test
    void extractAmount_missingField_shouldReturnZero() {
        String json = "{\"other\":\"field\"}";
        assertEquals(0.0, FraudDetectionTopology.extractAmount(json), 0.01);
    }

    @Test
    void computeRiskScore_lowAmount_shouldBeLow() {
        String json = "{\"amount\":50.00,\"region\":\"US-EAST\"}";
        double score = FraudDetectionTopology.computeRiskScore(50.00, json);
        assertTrue(score < 0.7, "Low-value US-EAST txn should have low risk");
    }

    @Test
    void computeRiskScore_highAmount_highRiskRegion_shouldBeHigh() {
        String json = "{\"amount\":6000.00,\"region\":\"AP-SOUTH\"}";
        double score = FraudDetectionTopology.computeRiskScore(6000.00, json);
        assertTrue(score > 0.7, "High-value AP-SOUTH txn should have high risk");
    }

    @Test
    void isFraudulent_shouldDetectHighRiskScore() {
        String enriched = "{\"amount\":100,\"risk_score\":0.85}";
        assertTrue(FraudDetectionTopology.isFraudulent(enriched));
    }

    @Test
    void isFraudulent_shouldPassLowRiskScore() {
        String enriched = "{\"amount\":100,\"risk_score\":0.20}";
        assertFalse(FraudDetectionTopology.isFraudulent(enriched));
    }
}
