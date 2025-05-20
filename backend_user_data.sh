#!/bin/bash

# Ensure the RDS endpoint is passed or set as an environment variable
if [ -z "$rds_endpoint" ]; then
  echo "Error: rds_endpoint is not set. Please export rds_endpoint before running."
  exit 1
fi

# Update system and install required packages
apt-get update -y
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt-get install -y nodejs npm mysql-client

# Create backend directory
mkdir -p /opt/backend
cd /opt/backend

# Create environment variables file
cat > .env <<EOF
DB_HOST=$rds_endpoint
DB_USER=admin
DB_PASSWORD= DB_PASSWORD
DB_NAME=prjdb
EOF

# Create app.js with RDS integration
cat > app.js <<'EOF'
require('dotenv').config();
const express = require("express");
const cors = require("cors");
const mysql = require('mysql2/promise');

const app = express();
const port = 3000;

// Database configuration
const dbConfig = {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
};

// Initialize database connection
async function initializeDatabase() {
    try {
        const adminConnection = await mysql.createConnection({
            host: dbConfig.host,
            user: dbConfig.user,
            password: dbConfig.password
        });

        // Create database if it doesn't exist
        await adminConnection.query(`CREATE DATABASE IF NOT EXISTS \`${process.env.DB_NAME}\`;`);
        await adminConnection.end();

        const connection = await mysql.createConnection(dbConfig);

        // Create table if it doesn't exist
        await connection.query(`
            CREATE TABLE IF NOT EXISTS counters (
                id VARCHAR(255) PRIMARY KEY,
                value INT NOT NULL DEFAULT 0,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            );
        `);

        console.log('Database initialized successfully');
        return connection;
    } catch (error) {
        console.error('Database initialization failed:', error);
        throw error;
    }
}

// Middleware
app.use(cors({ origin: "*", methods: ["GET", "POST"] }));
app.use(express.json());

let dbConnection;
initializeDatabase().then(conn => {
    dbConnection = conn;
}).catch(err => {
    console.error('Failed to initialize database:', err);
    process.exit(1);
});

app.get("/api/increment", async (req, res) => {
    if (!dbConnection) {
        return res.status(500).json({ error: "Database not connected" });
    }

    try {
        const counterId = 'main_counter';
        const [rows] = await dbConnection.query(
            'SELECT value FROM counters WHERE id = ?',
            [counterId]
        );

        if (rows.length === 0) {
            await dbConnection.query(
                'INSERT INTO counters (id, value) VALUES (?, ?)',
                [counterId, 0]
            );
        }

        await dbConnection.query(
            'UPDATE counters SET value = value + 1 WHERE id = ?',
            [counterId]
        );

        const [updatedRows] = await dbConnection.query(
            'SELECT value FROM counters WHERE id = ?',
            [counterId]
        );

        res.json({ counter: updatedRows[0].value });
    } catch (error) {
        console.error('Error incrementing counter:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get("/api/health", (req, res) => {
    res.json({ status: "healthy" });
});

app.listen(port, "0.0.0.0", () => {
    console.log(`Backend API listening at http://0.0.0.0:${port}`);
});

process.on('SIGTERM', async () => {
    if (dbConnection) await dbConnection.end();
    process.exit(0);
});
process.on('SIGINT', async () => {
    if (dbConnection) await dbConnection.end();
    process.exit(0);
});
EOF

# Create package.json with dependencies
cat > package.json <<'EOF'
{
  "name": "backend",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "mysql2": "^3.6.0",
    "dotenv": "^16.0.3"
  }
}
EOF

# Install dependencies
npm install

# Start the app in the background and log output
nohup npm start > backend.log 2>&1 &
