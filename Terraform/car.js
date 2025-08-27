import http from 'k6/http';

export const options = {
  scenarios: {
    rps400: {
      executor: 'constant-arrival-rate',
      rate: 400,           // requests per second (try 400 → 600 → 800)
      timeUnit: '1s',
      duration: '2m',
      preAllocatedVUs: 200,
      maxVUs: 800,
    },
  },
};

export default function () {
  http.get('http://3.90.142.120:8080/');
}
