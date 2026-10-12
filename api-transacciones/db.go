package main

import (
	"database/sql"
	"fmt"
	"os"
	"strings"

	_ "github.com/go-sql-driver/mysql"
)

// Esta API se conecta a "db_transacciones", UNA de las 5 bases que viven en la MISMA
// instancia compartida de MariaDB (ver tp-2026/db).
func conectarDB() (*sql.DB, error) {
	host, err := requireEnv("DB_HOST")
	if err != nil {
		return nil, err
	}
	port, err := requireEnv("DB_PORT")
	if err != nil {
		return nil, err
	}
	name, err := requireEnv("DB_NAME")
	if err != nil {
		return nil, err
	}
	user, err := requireEnv("DB_USER")
	if err != nil {
		return nil, err
	}
	pass, err := requireEnv("DB_PASSWORD")
	if err != nil {
		return nil, err
	}

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true", user, pass, host, port, name)
	return sql.Open("mysql", dsn)
}

func requireEnv(key string) (string, error) {
	value, exists := os.LookupEnv(key)
	if !exists || strings.TrimSpace(value) == "" {
		return "", fmt.Errorf("falta la variable de entorno obligatoria %s", key)
	}
	return value, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
