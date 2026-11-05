
import os
import mysql.connector
from flask import Flask, request, jsonify

app = Flask(__name__)

def get_db_connection():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "localhost"),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME", "taskdb")
    )


@app.route("/")
def home():
    return jsonify({"message": "Task Tracker API is running"})


@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200


@app.route("/tasks", methods=["GET"])
def get_tasks():
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("SELECT * FROM tasks")
    tasks = cursor.fetchall()

    cursor.close()
    connection.close()

    return jsonify(tasks)


@app.route("/tasks", methods=["POST"])
def create_task():
    data = request.get_json()

    if not data or not data.get("title"):
        return jsonify({"error": "Task title is required"}), 400

    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute(
        "INSERT INTO tasks (title) VALUES (%s)",
        (data["title"],)
    )

    connection.commit()
    task_id = cursor.lastrowid

    cursor.close()
    connection.close()

    return jsonify({
        "id": task_id,
        "title": data["title"],
        "message": "Task created successfully"
    }), 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
