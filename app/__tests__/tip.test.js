const request = require('supertest');
const app = require('../src/app');
const tips = require('../data/tips');

describe('GET /tip', () => {
  it('returns a random tip from the full set when no category is given', async () => {
    const res = await request(app).get('/tip');

    expect(res.status).toBe(200);
    expect(tips.map((t) => t.text)).toContain(res.text);
  });

  it('returns a tip matching the given category', async () => {
    const res = await request(app).get('/tip').query({ category: 'docker' });

    expect(res.status).toBe(200);
    const dockerTips = tips.filter((t) => t.category === 'docker').map((t) => t.text);
    expect(dockerTips).toContain(res.text);
  });

  it('returns a tip matching the terraform category', async () => {
    const res = await request(app).get('/tip').query({ category: 'terraform' });

    expect(res.status).toBe(200);
    const terraformTips = tips.filter((t) => t.category === 'terraform').map((t) => t.text);
    expect(terraformTips).toContain(res.text);
  });

  it('returns 400 for an unrecognized category', async () => {
    const res = await request(app).get('/tip').query({ category: 'nope' });

    expect(res.status).toBe(400);
  });
});
