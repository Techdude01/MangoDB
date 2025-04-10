from flask import Flask, render_template, request, session, redirect, url_for, flash
import pymysql
from werkzeug.security import generate_password_hash, check_password_hash
import pandas as pd

app = Flask(__name__)
app.secret_key = 'mango'

def connect_db(role='public_user', password=''):
    try:
        conn = pymysql.connect(
            host='localhost',
            user=role,
            password=password,
            db='your_database_name',
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        return conn
    except pymysql.Error as e:
        print(f"Error connecting to MySQL: {e}")
        raise Exception(e)

def execute_query(connection, query, params=None):
    cursor = connection.cursor()
    if params:
        cursor.execute(query, params)
    else:
        cursor.execute(query)

    if query.strip().upper().startswith('SELECT'):
        results = cursor.fetchall()
        column_names = [desc[0] for desc in cursor.description]
        df = pd.DataFrame(results, columns=column_names)
        cursor.close()
        return df
    else:
        connection.commit()
        cursor.close()
        return None
def register_user(connection, username, password, role='user'):
    hashed_password = generate_password_hash(password)
    query = "INSERT INTO users (username, password, role) VALUES (%s, %s, %s)"
    execute_query(connection, query, (username, hashed_password, role))

def verify_user(connection, username, password):
    query = "SELECT password, role FROM users WHERE username = %s"
    result = execute_query(connection, query, (username,))

    if not result.empty and check_password_hash(result.iloc[0]['password'], password):
        return True, result.iloc[0]['role']
    return False, None

@app.route('/')
def home():
    return render_template('home.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        conn = connect_db()
        authenticated, role = verify_user(conn, username, password)

        if authenticated:
            session['username'] = username
            session['role'] = role
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid credentials')

    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('username', None)
    session.pop('role', None)
    return redirect(url_for('home'))

@app.route('/dashboard')
def dashboard():
    if 'username' not in session:
        return redirect(url_for('login'))

    # Get user-specific data here
    return render_template('dashboard.html', username=session['username'])

if __name__ == '__main__':
    app.run(debug=True)
