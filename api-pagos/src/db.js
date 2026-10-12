const mysql = require('mysql2/promise');

function requireEnv(name) {
  const value = process.env[name];
  if (value === undefined || value.trim() === '') {
    throw new Error(`Falta la variable de entorno obligatoria ${name}`);
  }
  return value;
}

// Esta API se conecta a "db_pagos", UNA de las 5 bases que viven en la MISMA instancia
// compartida de MariaDB (ver tp-2026/db). No se usan credenciales de respaldo.
const dbPort = Number(requireEnv('DB_PORT'));
if (!Number.isInteger(dbPort) || dbPort < 1 || dbPort > 65535) {
  throw new Error('DB_PORT debe ser un puerto válido');
}

const pool = mysql.createPool({
<<<<<<< HEAD
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  database: process.env.DB_NAME || 'db_pagos',
  user: requiredEnv('DB_USER'),
  password: requiredEnv('DB_PASSWORD'),
=======
  host: requireEnv('DB_HOST'),
  port: dbPort,
  database: requireEnv('DB_NAME'),
  user: requireEnv('DB_USER'),
  password: requireEnv('DB_PASSWORD'),
>>>>>>> lu
  waitForConnections: true,
  connectionLimit: 5,
});

module.exports = pool;
