from flask import Flask, render_template, request, session, redirect, url_for, flash
import pymysql
from werkzeug.security import generate_password_hash, check_password_hash
import pandas as pd
from datetime import datetime
app = Flask(__name__)
app.secret_key = 'mango'

def connect_db(username='root', password=''):
    print(f"Connecting as user: '{username}'")
    try:
        conn = pymysql.connect(
            host='localhost',
            user=username,
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
    
def get_timestamp_id(cursor):
    now = datetime.now()
    sent_time = now.strftime('%H:%M:%S')
    sent_date = now.strftime('%Y-%m-%d')

    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)
    cursor.execute("""
        INSERT INTO TimeStamp (sentTime, sentDate)
        VALUES (%s, %s)
    """, (sent_time, sent_date))

    # Commit the insert so MySQL registers it
    conn.commit()

    return cursor.lastrowid  # Return the auto-incremented ID

def register_user(connection, username, password, role='user'):
    hashed_password = generate_password_hash(password)
    query = "INSERT INTO user (username, password, role) VALUES (%s, %s, %s)"
    execute_query(connection, query, (username, hashed_password, role))

def verify_user(connection, username, password):
    query = "SELECT password, role FROM user WHERE username = %s"
    result = execute_query(connection, query, (username,))

    if not result.empty and check_password_hash(result.iloc[0]['password'], password):
        return True, result.iloc[0]['role']
    return False, None

@app.route('/')
def root():
    # Redirect root URL to /home for a single homepage logic source
    return redirect(url_for('home'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        print(f"Attempting login for user: {username}")

        conn = connect_db()
        authenticated, role = verify_user(conn, username, password)
        
<<<<<<< HEAD
=======
        cursor.execute("SELECT userID, password, role FROM User WHERE userName = %s", (username,))
        user = cursor.fetchone()
>>>>>>> 36f1d485de6a447a8c6be1fd41eb84fa03882390

        if authenticated:
            cursor = conn.cursor(pymysql.cursors.DictCursor)
            cursor.execute("SELECT userID FROM User WHERE userName = %s", (username,))
            user = cursor.fetchone()
            session['username'] = username
            session['role'] = role
            session['user_id'] = user['userID']
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid credentials')
            return redirect(url_for('login'))

    return render_template('user_login.html')

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
            flash('All fields are required', 'danger')
            return redirect(url_for('register_route'))
        
        if password != confirm_password:
            flash('Passwords do not match')
            return redirect(url_for('register_route'))
        
        # Check if user already exists
        # Add your database logic here
        conn = connect_db()
        cursor = conn.cursor()

        try:
            # Insert the new user into the database
            hashed_password = generate_password_hash(password)
            cursor.execute("INSERT INTO User (userName, password, role) VALUES (%s, %s, %s)", (username, hashed_password, 'user'))
            conn.commit()
            flash('Registration successful! You can now log in.', 'success')
            return redirect(url_for('login'))
        except Exception as e:
            conn.rollback()
            flash(f'Error during registration: {e}', 'danger')
        finally:
            conn.close()
        
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

    #Fetch top 5 questions for each category
    cursor.execute("CALL GetPopularQuestionsWithPagination(5,0)") 
    most_popular = cursor.fetchall()

    cursor.execute("CALL GetControversialQuestionsWithPagination(5,0)")
    most_controversial = cursor.fetchall()

    cursor.execute("CALL GetRecentQuestionsWithPagination(5,0)")
    most_recent = cursor.fetchall()

    cursor.execute("SELECT tagID, tagName FROM Tag")
    tags = cursor.fetchall()

    conn.close()

    return render_template(
        'home.html', 
        most_popular=most_popular, 
        most_controversial=most_controversial, 
        most_recent=most_recent,
        tags=tags,
        most_popular_page=1,
        most_popular_total_pages=1,
        most_controversial_page=1,
        most_controversial_total_pages=1,
        most_recent_page=1,
        most_recent_total_pages=1
        )

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

@app.route('/search', methods=['GET'])
def search():
    username = request.args.get('username')
    keyword = request.args.get('keyword')
    tag = request.args.get('tag')

    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    # Search by Username
    if username:
        cursor.execute("SELECT * FROM Question WHERE userID = (SELECT userID FROM User WHERE userName = %s)", (username,))
        questions = cursor.fetchall()
        conn.close()
        return render_template('search_results.html', questions=questions, search_type="Username", search_value=username)

    # Search by Keyword
    elif keyword:
        cursor.execute("CALL SearchQuestions(%s)", (keyword,))
        questions = cursor.fetchall()
        conn.close()
        return render_template('search_results.html', questions=questions, search_type="Keyword", search_value=keyword)

    # Search by Tag
    elif tag:
        cursor.execute("CALL GetQuestionsByTag(%s)", (tag,))
        questions = cursor.fetchall()
        conn.close()
        return render_template('search_results.html', questions=questions, tag_name=tag)

    # If no input is provided
    else:
        conn.close()
        return render_template('search_results.html', questions=[], search_type="None", search_value="None")
    
@app.route('/most_popular')
def most_popular():
    # get current pag num from query parameters
    page = request.args.get('page', 1, type=int)
    per_page = 5

    offset = (page - 1 ) * per_page

    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    # Fetch paginated popular questions
    cursor.execute("CALL GetPopularQuestionsWithPagination(%s, %s)",(per_page, offset))
    questions = cursor.fetchall()

    # Fetch total num of questions for pagination
    cursor.execute("SELECT COUNT(*) AS total FROM Question")
    total_questions = cursor.fetchone()['total']

    conn.close()

    total_pages = (total_questions + per_page - 1) // per_page

    return render_template(
        'most_popular.html', questions=questions,
        page=page, total_pages=total_pages)


@app.route('/most_controversial')
def most_controversial():
    # get current pag num from query parameters
    page = request.args.get('page', 1, type=int)
    per_page = 5

    offset = (page - 1 ) * per_page
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    # Fetch paginated controversial questions
    cursor.execute("CALL GetControversialQuestionsWithPagination(%s, %s)",(per_page, offset)) 
    questions = cursor.fetchall()
    
    # Fetch total num of questions for pagination
    cursor.execute("SELECT COUNT(*) AS total FROM Question")
    total_questions = cursor.fetchone()['total']
    
    conn.close()

    total_pages = (total_questions + per_page - 1) // per_page

    return render_template(
        'most_controversial.html', questions=questions,
        page=page, total_pages=total_pages)


@app.route('/most_recent')
def most_recent():
    # get current pag num from query parameters
    page = request.args.get('page', 1, type=int)
    per_page = 5

    offset = (page - 1 ) * per_page
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    # Fetch paginated recent questions
    cursor.execute("CALL GetRecentQuestionsWithPagination(%s, %s)",(per_page, offset)) 
    questions = cursor.fetchall()

    # Fetch total num of questions for pagination
    cursor.execute("SELECT COUNT(*) AS total FROM Question")
    total_questions = cursor.fetchone()['total']
    
    conn.close()

    total_pages = (total_questions + per_page - 1) // per_page

    return render_template(
        'most_recent.html', questions=questions,
        page=page, total_pages=total_pages)

@app.route('/start_question', methods=['POST'])
def start_question():
    user_id = request.form.get('user_id')  # Assume user ID is passed from the frontend
    question_text = request.form.get('question_text', '')  # Default to an empty string

    conn = connect_db()
    cursor = conn.cursor()

    try:
        # Call StartQuestion() to create a draft question
        cursor.execute("CALL StartQuestion(%s, %s)", (user_id, question_text))
        conn.commit()
        flash('Draft question created successfully!')
    except Exception as e:
        conn.rollback()
        flash(f'Error starting question: {e}')
    finally:
        conn.close()

    return redirect(url_for('home'))

@app.route('/publish_question', methods=['POST'])
def publish_question():
    question_id = request.form.get('question_id')  # Assume question ID is passed from the frontend
    tag_ids = request.form.getlist('tags')
    user_id = session.get('user_id')

    if not question_id or not tag_ids or not user_id:
        flash('Please provide a question and at least one tag.')
        return redirect(url_for('home'))

    conn = connect_db()
    cursor = conn.cursor()

    try:
        # Call PublishQuestion() to publish the question
        cursor.execute("CALL PublishQuestion(%s)", (question_id,))

        # Update the TagList table w selected tags
        for tag_id in tag_ids:
            cursor.execute("INSERT INTO TagList (tagID, questionID, userID) VALUES (%s, %s, %s)", (tag_id, question_id, user_id))
        
        conn.commit()
        flash('Question published successfully!', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error publishing question: {e}', 'danger')
    finally:
        conn.close()

    return redirect(url_for('home'))


@app.route('/cancel_question', methods=['POST'])
def cancel_question():
    question_id = request.form.get('question_id')  # Assume question ID is passed from the frontend

    conn = connect_db()
    cursor = conn.cursor()

    try:
        # Call CancelQuestion() to cancel the draft
        cursor.execute("CALL CancelQuestion(%s)", (question_id,))
        conn.commit()
        flash('Draft question cancelled successfully!')
    except Exception as e:
        conn.rollback()
        flash(f'Error cancelling question: {e}')
    finally:
        conn.close()

    return redirect(url_for('home'))

@app.route('/question/<int:question_id>', methods=['GET', 'POST'])
def question_detail(question_id):
    if 'userID' not in session:
        return redirect(url_for('login'))  # Redirect if not logged in

    user_id = session['userID']
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    # Check if the user has already responded to this question
    cursor.execute("""
        SELECT responseID FROM Response
        WHERE questionID = %s AND userID = %s AND status = 'published'
    """, (question_id, user_id))
    user_has_responded = cursor.fetchone() is not None

    # Handle new response submission
    if request.method == 'POST' and not user_has_responded:
        response_text = request.form['responseText']
        timestamp_id = get_timestamp_id(cursor)  # You should define this helper
        cursor.execute("""
            INSERT INTO Response (userID, questionID, responseText, TimeStampID, status)
            VALUES (%s, %s, %s, %s, 'published')
        """, (user_id, question_id, response_text, timestamp_id))
        db.commit()
        return redirect(url_for('question_detail', question_id=question_id))

    # Get the question data
    cursor.execute("SELECT * FROM Question WHERE questionID = %s", (question_id,))
    question = cursor.fetchone()

    # Get responses and comments only if user has responded
    responses = []
    comments = []
    if user_has_responded:
        cursor.execute("""
            SELECT * FROM Response
            WHERE questionID = %s AND status = 'published'
        """, (question_id,))
        responses = cursor.fetchall()

        cursor.execute("""
            SELECT * FROM Comment
            WHERE questionID = %s AND status = 'published'
        """, (question_id,))
        comments = cursor.fetchall()

    return render_template(
        'question_detail.html',
        question=question,
        responses=responses,
        comments=comments,
        user_has_responded=user_has_responded
    )

@app.route('/vote_question', methods=['POST'])
def vote_question():
    user_id = session.get('user_id')  # Assume user is logged in
    question_id = request.form.get('question_id')
    vote_type = request.form.get('vote')  # 'up' or 'down'

    if not user_id or not question_id or vote_type not in ['up', 'down']:
        flash('Invalid voting request.', 'danger')
        return redirect(url_for('home'))

    conn = connect_db()
    cursor = conn.cursor()

    try:
        if vote_type == 'up':
            cursor.execute("CALL UpvoteQuestion(%s, %s)", (user_id, question_id))
        elif vote_type == 'down':
            cursor.execute("CALL DownvoteQuestion(%s, %s)", (user_id, question_id))

        conn.commit()
        flash('Your vote has been recorded!', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error recording your vote: {e}', 'danger')
    finally:
        conn.close()

    return redirect(url_for('question_detail', question_id=question_id))

if __name__ == '__main__':
    app.run(debug=True)
