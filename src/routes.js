const express = require('express')
const pool = require('./db')
const { generateRandomWords } = require('./utils')

const router = express.Router()

// Health route for AWS ALB
router.get('/', (req, res) => {
    res.sendStatus(200)
})

// Route to shorten a URL
router.post('/shorten', async (req, res) => {
    const { originalUrl } = req.body
    if (!originalUrl) { return res.status(400).json({ error: 'URL is required' }) }

    let shortPath = generateRandomWords()
    let exists = await pool.query('SELECT * FROM urls WHERE short_path = $1', [shortPath])

    while (exists.rowCount > 0) {
        shortPath = generateRandomWords()
        exists = await pool.query('SELECT * FROM urls WHERE short_path = $1', [shortPath])
    }

    await pool.query('INSERT INTO urls (short_path, original_url) VALUES ($1, $2)', [shortPath, originalUrl])
    res.json({ shortUrl: `/go/${shortPath}` })
})

// Route to redirect
router.get('/go/:path', async (req, res) => {
    const { path } = req.params
    const result = await pool.query('SELECT original_url FROM urls WHERE short_path = $1', [path])

    if (result.rowCount === 0) { return res.status(404).json({ error: 'URL not found' }) }

    res.redirect(result.rows[0].original_url)
})

module.exports = router
