from app import app
from flaskext.mysql import MySQL
from dotenv import load_dotenv
import os

load_dotenv()
mysql = MySQL()

# Esta API se conecta a "db_clientes", UNA de las 5 bases que viven en la MISMA instancia
# compartida de MariaDB (ver tp-2026/db). Las credenciales deben venir del .env.
def required_env(key):
    value = os.environ.get(key)
    if not value:
        raise RuntimeError(f'Falta la variable obligatoria {key}')
    return value


app.config['MYSQL_DATABASE_USER'] = required_env('DB_USER')
app.config['MYSQL_DATABASE_PASSWORD'] = required_env('DB_PASSWORD')
app.config['MYSQL_DATABASE_DB'] = os.environ.get('DB_NAME') or 'db_clientes'
app.config['MYSQL_DATABASE_HOST'] = os.environ.get('DB_HOST') or 'localhost'
app.config['MYSQL_DATABASE_PORT'] = int(os.environ.get('DB_PORT') or 3306)

mysql.init_app(app)
