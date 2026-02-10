package io.confluent.ps.producer;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class PaymentProducerTest {

    @Test
    void buildPaymentJson_shouldContainMaskedCardNumber() {
        String json = PaymentProducer.buildPaymentJson("txn-001", 42);

        assertTrue(json.contains("\"transaction_id\":\"txn-001\""),
                "Should contain the transaction ID");
        assertTrue(json.contains("****-****-****-"),
                "Card number must be masked (PCI-DSS)");
        assertFalse(json.matches(".*\\d{13,19}.*"),
                "Must not contain a full card number");
    }

    @Test
    void buildPaymentJson_shouldHaveValidJsonStructure() {
        String json = PaymentProducer.buildPaymentJson("txn-002", 0);

        assertTrue(json.startsWith("{") && json.endsWith("}"),
                "Should be a valid JSON object");
        assertTrue(json.contains("\"amount\":"),  "Should contain amount");
        assertTrue(json.contains("\"currency\":\"USD\""), "Should contain currency");
        assertTrue(json.contains("\"status\":\"PENDING\""), "Should contain status");
        assertTrue(json.contains("\"merchant_id\":"), "Should contain merchant_id");
        assertTrue(json.contains("\"region\":"), "Should contain region");
        assertTrue(json.contains("\"timestamp\":"), "Should contain timestamp");
    }

    @Test
    void buildPaymentJson_shouldCalculateAmountCorrectly() {
        // amount = 10.00 + (sequence % 500) * 1.37
        String json = PaymentProducer.buildPaymentJson("txn-003", 100);
        // 10.00 + (100 % 500) * 1.37 = 10.00 + 137.00 = 147.00
        assertTrue(json.contains("\"amount\":147.00"), "Amount should be 147.00 for sequence=100");
    }

    @Test
    void buildPaymentJson_shouldCycleThroughRegions() {
        String json0 = PaymentProducer.buildPaymentJson("txn-r0", 0);
        String json1 = PaymentProducer.buildPaymentJson("txn-r1", 1);
        String json2 = PaymentProducer.buildPaymentJson("txn-r2", 2);
        String json3 = PaymentProducer.buildPaymentJson("txn-r3", 3);

        assertTrue(json0.contains("US-EAST"), "Sequence 0 -> US-EAST");
        assertTrue(json1.contains("US-WEST"), "Sequence 1 -> US-WEST");
        assertTrue(json2.contains("EU-WEST"), "Sequence 2 -> EU-WEST");
        assertTrue(json3.contains("AP-SOUTH"), "Sequence 3 -> AP-SOUTH");
    }
}
