// ==============================================================================
// k6 Load Test — Payment Producer API
//
// Tests the payment ingestion endpoint under varying load conditions.
//
// Usage:
//   k6 run tests/load/payment-producer-test.js
//   k6 run --vus 50 --duration 2m tests/load/payment-producer-test.js
//   k6 run --out json=results.json tests/load/payment-producer-test.js
// ==============================================================================

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('error_rate');
const paymentLatency = new Trend('payment_latency_ms');
const paymentsProduced = new Counter('payments_produced');

// ---------- Test configuration ----------
export const options = {
  stages: [
    { duration: '15s', target: 5 },    // warm-up
    { duration: '30s', target: 20 },   // ramp to normal load
    { duration: '1m',  target: 20 },   // sustain normal load
    { duration: '15s', target: 50 },   // ramp to peak load
    { duration: '30s', target: 50 },   // sustain peak load
    { duration: '15s', target: 0 },    // ramp down
  ],
  thresholds: {
    error_rate: ['rate<0.01'],                  // < 1% error rate
    payment_latency_ms: ['p(95)<500'],          // 95th percentile < 500ms
    payment_latency_ms: ['p(99)<1000'],         // 99th percentile < 1000ms
    http_req_duration: ['avg<200'],             // average < 200ms
  },
};

// ---------- Merchant and region pools ----------
const MERCHANTS = ['MERCH-001', 'MERCH-002', 'MERCH-003', 'MERCH-004'];
const REGIONS   = ['US-EAST', 'US-WEST', 'EU-WEST', 'AP-SOUTH'];
const CURRENCIES = ['USD', 'EUR', 'GBP'];

// ---------- Test execution ----------
export default function () {
  const payload = JSON.stringify({
    transaction_id: `k6-${__VU}-${__ITER}-${Date.now()}`,
    card_number_masked: `****-****-****-${String(Math.floor(Math.random() * 9999) + 1).padStart(4, '0')}`,
    amount: parseFloat((Math.random() * 10000).toFixed(2)),
    currency: CURRENCIES[Math.floor(Math.random() * CURRENCIES.length)],
    merchant_id: MERCHANTS[Math.floor(Math.random() * MERCHANTS.length)],
    timestamp: Date.now(),
    status: 'PENDING',
    region: REGIONS[Math.floor(Math.random() * REGIONS.length)],
  });

  const params = {
    headers: { 'Content-Type': 'application/json' },
    tags: { name: 'POST /api/payments' },
  };

  // POST to the payment API (adjust URL to your setup)
  const API_URL = __ENV.API_URL || 'http://localhost:8080/api/payments';
  const res = http.post(API_URL, payload, params);

  // Assertions
  const passed = check(res, {
    'status is 200 or 202': (r) => r.status === 200 || r.status === 202,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'body contains transaction_id': (r) => r.body && r.body.includes('transaction_id'),
  });

  // Record metrics
  errorRate.add(!passed);
  paymentLatency.add(res.timings.duration);
  if (passed) paymentsProduced.add(1);

  sleep(0.05); // 50ms between requests per VU
}

// ---------- Lifecycle hooks ----------
export function setup() {
  console.log('Payment Producer Load Test starting...');
  console.log(`Target API: ${__ENV.API_URL || 'http://localhost:8080/api/payments'}`);
}

export function teardown(data) {
  console.log('Payment Producer Load Test complete.');
}
