from app import app
from flaskext.mysql import MySQL
from dotenv import load_dotenv
import os

load_dotenv()
mysql = MySQL()


def require_env(name):
	value = os.environ.get(name)
	if value is None or not value.strip():
		raise RuntimeError(f'Falta la variable de entorno obligatoria {name}')
	return value


# Esta API se conecta a "db_clientes", UNA de las 5 bases que viven en la MISMA instancia
# compartida de MariaDB (ver tp-2026/db). La aplicación no incluye credenciales de respaldo:
# si falta una variable obligatoria, se detiene durante el inicio.
app.config['MYSQL_DATABASE_USER'] = require_env('DB_USER')
app.config['MYSQL_DATABASE_PASSWORD'] = require_env('DB_PASSWORD')
app.config['MYSQL_DATABASE_DB'] = require_env('DB_NAME')
app.config['MYSQL_DATABASE_HOST'] = require_env('DB_HOST')
app.config['MYSQL_DATABASE_PORT'] = int(require_env('DB_PORT'))

mysql.init_app(app)
