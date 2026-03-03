from flask import Flask, jsonify
from flask_cors import CORS
from db import get_connection

app = Flask(__name__)
CORS(app)


@app.route("/api/books")
def get_books():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT
                    b.id,
                    b.title,
                    b.genre,
                    b.published_year,
                    b.isbn,
                    b.description,
                    a.name AS author
                FROM books b
                JOIN authors a ON a.id = b.author_id
                ORDER BY b.title;
            """)
            books = cur.fetchall()
        return jsonify(list(books))
    finally:
        conn.close()


@app.route("/api/authors")
def get_authors():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT
                    a.id,
                    a.name,
                    a.bio,
                    a.nationality,
                    a.born_year,
                    COUNT(b.id) AS book_count
                FROM authors a
                LEFT JOIN books b ON b.author_id = a.id
                GROUP BY a.id
                ORDER BY a.name;
            """)
            authors = cur.fetchall()
        return jsonify(list(authors))
    finally:
        conn.close()


@app.route("/health")
def health():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
