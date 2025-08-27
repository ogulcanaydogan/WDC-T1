import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 50 },
    { duration: '60s', target: 200 },
    { duration: '60s', target: 400 },
    { duration: '30s', target: 0 },
  ],
};

export default function () {
  http.get('http://3.90.142.120:8080/');
  sleep(1);
}
