require('dotenv').config()

const { Pool } = require('pg')

const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'url_shortener',
    password: process.env.DB_PASSWORD || 'password',
    port: process.env.DB_PORT || 5432,
    ssl: false
    // ssl: {
    //     rejectUnauthorized: false // Allow self-signed AWS certificates
    // }
})

// Test the database connection
pool.connect()
    .then(client => {
        console.log('✅ Successfully connected to PostgreSQL!')
        client.release() // Release connection back to pool
    })
    .catch(err => console.error('❌ Database connection error:', err))

module.exports = pool