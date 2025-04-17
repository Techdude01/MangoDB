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
            db='Mango',
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

@app.route('/register', methods=['GET', 'POST'])
def register_route():
    """
    Handle user registration
    GET: Display registration form
    POST: Process registration form submission
    """
    if request.method == 'POST':
        # Get form data
        username = request.form.get('username')
        password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')
        
        # Basic validation
        if not username or not password or not confirm_password:
            flash('All fields are required')
            return redirect(url_for('register_route'))
        
        if password != confirm_password:
            flash('Passwords do not match')
            return redirect(url_for('register_route'))
        
        # Check if user already exists
        # Add your database logic here
        
        # Create new user
        # Add your database logic here
        
        flash('Registration successful! Please log in.')
        return redirect(url_for('home'))
    
    # GET request - show registration form
    return render_template('register.html')

@app.route('/admin-login', methods=['GET', 'POST'])
def admin_login():
    """
    Handle admin login
    GET: Display admin login form
    POST: Process admin login form submission
    """
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        conn = connect_db()
        authenticated, role = verify_user(conn, username, password)

        # Check if user is authenticated and has admin role
        if authenticated and role == 'admin':
            session['username'] = username
            session['role'] = role
            # Redirect to admin dashboard or regular dashboard
            return redirect(url_for('dashboard'))  # You might want a separate admin_dashboard
        else:
            flash('Invalid admin credentials')

    return render_template('admin_login.html')  # You'll need to create this template

@app.route('/home')
def home():
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    # Fetch top 5 questions for each category
    cursor.execute("CALL GetPopularQuestions()") 
    most_popular = cursor.fetchall()

    cursor.execute("CALL GetControversialQuestions()")
    most_controversial = cursor.fetchall()

    cursor.execute("CALL GetRecentQuestions()")
    most_recent = cursor.fetchall()

    conn.close()

    return render_template('home.html', most_popular=most_popular, most_controversial=most_controversial, most_recent=most_recent)

@app.route('/question/<int:question_id>')
def question_detail(question_id):
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    # Fetch question details
    cursor.execute("SELECT * FROM Question WHERE questionID = %s", (question_id,))
    question = cursor.fetchone()

    # Fetch responses/comments for the question
    cursor.execute("SELECT * FROM Response WHERE questionID = %s", (question_id,))
    responses = cursor.fetchall()

    conn.close()

    return render_template('question_detail.html', question=question, responses=responses)

@app.route('/most_popular')
def most_popular():
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    # Fetch all popular questions
    cursor.execute("CALL GetPopularQuestions()") 
    questions = cursor.fetchall()

    conn.close()

    return render_template('most_popular.html', questions=questions)


@app.route('/most_controversial')
def most_controversial():
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    # Fetch all controversial questions
    cursor.execute("CALL GetControversialQuestions()") 
    questions = cursor.fetchall()

    conn.close()

    return render_template('most_controversial.html', questions=questions)


@app.route('/most_recent')
def most_recent():
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    # Fetch all recent questions
    cursor.execute("CALL GetRecentQuestions()") 
    questions = cursor.fetchall()

    conn.close()

    return render_template('most_recent.html', questions=questions)

if __name__ == '__main__':
    app.run(debug=True)
