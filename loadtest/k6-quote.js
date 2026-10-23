import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const quoteUrl = __ENV.QUOTE_URL || 'http://host.docker.internal:8080/api/quote';
const errorRate = new Rate('quote_errors');
const quoteDuration = new Trend('quote_duration_ms', true);

// Thresholds justified from measured ~100ms CPU work per request on a local
// k3d harness: p95 under moderate load should stay <500ms; error rate <5%.
// Adjust after baseline in loadtest/evidence/baseline.txt + k6-summary.json.
export const options = {
  stages: [
    { duration: '20s', target: 5 },
    { duration: '40s', target: 15 },
    { duration: '40s', target: 30 },
    { duration: '20s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<500'],
    quote_errors: ['rate<0.05'],
  },
};

export default function () {
  const res = http.get(quoteUrl);
  quoteDuration.add(res.timings.duration);
  const ok = check(res, {
    'status is 200': (r) => r.status === 200,
    'has quote field': (r) => {
      try {
        return JSON.parse(r.body).quote !== undefined;
      } catch (e) {
        return false;
      }
    },
  });
  errorRate.add(!ok);
  sleep(0.2);
}
