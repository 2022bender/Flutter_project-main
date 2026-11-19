import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.orm import DeclarativeBase, sessionmaker

# Carga las variables de conexión definidas en el archivo .env.
load_dotenv()

# Construye la URL de conexión a MySQL.
url = URL.create(
    drivername="mysql+pymysql",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST", "127.0.0.1"),
    port=int(os.getenv("DB_PORT", "3306")),
    database=os.getenv("DB_NAME", "bd_Aplicacion_movil"),
    query={"charset": "utf8mb4"},
)

# Crea el motor y verifica las conexiones antes de reutilizarlas.
engine = create_engine(url, pool_pre_ping=True)
SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)


# Clase base para los modelos ORM de SQLAlchemy.
class Base(DeclarativeBase):
    pass


def obtener_sesion():
    # Entrega una sesión de base de datos y la cierra al terminar la petición.
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
