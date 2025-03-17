const request = require('supertest');
const app = require('../src/index'); // Import the app, no need to run it manually
const pool = require('../src/db'); // PostgreSQL connection

beforeAll(async () => {
    // Create test table
    await pool.query(`CREATE TABLE IF NOT EXISTS urls (
        id SERIAL PRIMARY KEY,
        short_path TEXT UNIQUE NOT NULL,
        original_url TEXT NOT NULL
    );`);
});

afterAll(async () => {
    // Clean up the database after tests
    await pool.query('DROP TABLE IF EXISTS urls;');
    await pool.end(); // Close DB connection
});

describe('URL Shortener API', () => {
    test('POST /shorten should return a short URL', async () => {
        const res = await request(app).post('/shorten').send({ originalUrl: 'https://example.com' });
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('shortUrl');
        expect(res.body.shortUrl).toMatch(/go\/[a-z]+\.[a-z]+\.[a-z]+/);
    });

    test('POST /shorten without URL should return an error', async () => {
        const res = await request(app).post('/shorten').send({});
        expect(res.statusCode).toBe(400);
        expect(res.body).toHaveProperty('error', 'URL is required');
    });

    test('GET /go/:path should redirect to the original URL', async () => {
        const postRes = await request(app).post('/shorten').send({ originalUrl: 'https://example.com' });
        const shortPath = postRes.body.shortUrl.split('/go/')[1];

        const res = await request(app).get(`/go/${shortPath}`);
        expect(res.statusCode).toBe(302);
        expect(res.headers.location).toBe('https://example.com');
    });

    test('GET /go/:path with nonexistent URL should return 404', async () => {
        const res = await request(app).get('/go/non.existent.path');
        expect(res.statusCode).toBe(404);
        expect(res.body).toHaveProperty('error', 'URL not found');
    });
});
