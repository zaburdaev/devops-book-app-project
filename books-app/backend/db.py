import os
import psycopg2
from psycopg2.extras import RealDictCursor


def get_connection():
    return psycopg2.connect(
        host=os.environ.get("DB_HOST", "localhost"),
        port=os.environ.get("DB_PORT", 5432),
        dbname=os.environ.get("DB_NAME", "booksdb"),
        user=os.environ.get("DB_USER", "booksuser"),
        password=os.environ.get("DB_PASSWORD", "bookspass"),
        cursor_factory=RealDictCursor,
    )
