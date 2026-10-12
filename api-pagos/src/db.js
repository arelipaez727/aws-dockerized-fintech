const mysql = require('mysql2/promise');

function requiredEnv(key) {
  const value = process.env[key];
  if (!value) throw new Error(`Falta la variable obligatoria ${key}`);
  return value;
}

// Esta API se conecta a "db_pagos", UNA de las 5 bases que viven en la MISMA instancia
// compartida de MariaDB (ver tp-2026/db).
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  database: process.env.DB_NAME || 'db_pagos',
  user: requiredEnv('DB_USER'),
  password: requiredEnv('DB_PASSWORD'),
  waitForConnections: true,
  connectionLimit: 5,
});

module.exports = pool;
