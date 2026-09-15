const request = require('supertest');
const app = require('../app');

describe('web health', () => {
  it('GET /health returns 200 without calling the api', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
