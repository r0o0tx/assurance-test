const request = require('supertest');
const app = require('../app');

describe('api health', () => {
  it('GET /health returns 200 without touching the database', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
