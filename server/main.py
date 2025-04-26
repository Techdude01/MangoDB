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
            db='mango',
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
    # Get current time and date
    now = datetime.now()
    sent_time = now.strftime('%H:%M:%S')
    sent_date = now.strftime('%Y-%m-%d')

    # Execute insert using the passed cursor
    cursor.execute("""
        INSERT INTO TimeStamp (sentTime, sentDate)
        VALUES (%s, %s)
    """, (sent_time, sent_date))

    return cursor.lastrowid

def register_user(connection, username, password, role='user',firstName='', lastName=''):
    hashed_password = generate_password_hash(password)
    query = "INSERT INTO user (username, password, role, firstName,lastName) VALUES (%s, %s, %s,%s,%s)"
    execute_query(connection, query, (username, hashed_password, role,firstName,lastName))

def verify_user(connection, username, password):
    query = "SELECT password, role FROM user WHERE username = %s"
    result = execute_query(connection, query, (username,))
    if not result.empty:
        stored_password = result.iloc[0]['password']
        # Check if the stored password is already hashed
        if stored_password.startswith('pbkdf2:') or stored_password.startswith('scrypt:'):
            # If it's hashed, use check_password_hash
            result_check = check_password_hash(stored_password, password)
        else:
            # If it's not hashed (plain text), do a direct comparison
            result_check = stored_password == password
        if result_check:
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
        conn = connect_db()
        authenticated, role = verify_user(conn, username, password)
        if authenticated:
            cursor = conn.cursor(pymysql.cursors.DictCursor)
            cursor.execute("SELECT userID, role FROM User WHERE userName = %s", (username,))
            user = cursor.fetchone()
            session['username'] = username
            session['role'] = role  
            session['userID'] = user['userID']

            if role == 'admin':
                return redirect(url_for('admin_dashboard'))
            else: 
                return redirect(url_for('dashboard'))
        else:
            flash('Login failed: Invalid username or password.', 'login-danger')
            return redirect(url_for('login'))
    return render_template('user_login.html')

@app.route('/logout')
def logout():
    session.pop('username', None)
    session.pop('role', None)
    session.pop('userID', None)
    return redirect(url_for('home'))

@app.route('/dashboard')
def dashboard():
    """
    Display the user's dashboard with their questions and tags.
    Requires user to be logged in with a valid session.
    """
    # Redirect to login if user is not authenticated
    if 'username' not in session:
        return redirect(url_for('login'))
    
    # Connect to database and get user's questions and tags
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)
    
    # Get questions created by the current user
    cursor.execute("CALL GetQuestionsByUserID(%s)", (session['userID'],))
    questions = cursor.fetchall()

    # Get tags used by the current user
    cursor.execute("CALL GetTagsByUserID(%s)", (session['userID'],))
    tags = cursor.fetchall()
    # Get all tags in the system for comparison
    cursor.execute("SELECT tagID, tagName FROM Tag")
    tags2 = cursor.fetchall()
    # Render the dashboard template with the user's data
    return render_template('dashboard.html', tags=tags, tags2=tags2,questions=questions,numQuestions=len(questions), numTags=len(tags))

@app.route('/admin_dashboard')
def admin_dashboard():
    #only admins access this route
    if session.get('role') != 'admin':
        flash('Access denied: Admins only.', 'danger')
        return redirect(url_for('home'))
    #fetch admin-specific data (e.g., user/question management)
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)
    try: 
        cursor.execute("""
            SELECT questionID, questionText, visibility, userID
            FROM Question
            ORDER BY TimeStampID DESC
        """)
        questions = cursor.fetchall()
    except Exception as e:
        flash(f"Error loading admin dashboard: {e}")
        questions = []
    finally:
        cursor.close()
        conn.close() 
    return render_template('admin_dashboard.html', question=questions)

@app.route('/hide_question/<int:question_id>', methods=['POST'])
def hide_question(question_id):
    if session.get('role') != 'admin':
        flash('Access denied: Admins only.', 'danger')
        return redirect(url_for('home'))

    conn = connect_db()
    cursor = conn.cursor()
    try:
        cursor.execute("UPDATE Question SET visibility = 'hidden' WHERE questionID = %s", (question_id,))
        conn.commit()
        flash('Question hidden successfully.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f"Error hiding question: {e}", 'danger')
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('admin_dashboard'))


@app.route('/unhide_question/<int:question_id>', methods=['POST'])
def unhide_question(question_id):
    if session.get('role') != 'admin':
        flash('Access denied: Admins only.', 'danger')
        return redirect(url_for('home'))

    conn = connect_db()
    cursor = conn.cursor()
    try:
        cursor.execute("UPDATE Question SET visibility = 'visible' WHERE questionID = %s", (question_id,))
        conn.commit()
        flash('Question unhidden successfully.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f"Error unhiding question: {e}", 'danger')
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('admin_dashboard'))

@app.route('/register', methods=['GET', 'POST'])
def register_route():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        firstName = request.form.get('firstName')
        lastName = request.form.get('lastName')
        if not username or not password:
            flash('All fields are required', 'register-danger')
            return redirect(url_for('register_route'))
        
        conn = None # Initialize conn to None
        cursor = None # Initialize cursor to None
        try:
            conn = connect_db()
            cursor = conn.cursor(pymysql.cursors.DictCursor) # Use DictCursor for consistency
            cursor.execute("SELECT COUNT(*) AS count FROM User WHERE username = %s", (username,))
            user_exists = cursor.fetchone()['count'] > 0
            
            if user_exists:
                flash('Username already exists. Please choose a different username.', 'register-danger')
                return redirect(url_for('register_route')) # Redirect if user exists

            # Call register_user within the same try block
            register_user(conn, username, password, 'user', firstName, lastName)
            conn.commit() # Commit after successful registration
            flash('Registration successful! You can now log in.', 'register-success')
            return redirect(url_for('login')) # Redirect on success

        except Exception as e:
            if conn: # Check if connection exists before rollback
                conn.rollback()
            flash(f'Registration error: {e}', 'register-danger')
            # Redirect back to registration page on error
            return redirect(url_for('register_route')) 
        finally:
            if cursor: # Check if cursor exists before closing
                cursor.close()
            if conn: # Check if connection exists before closing
                conn.close()
                
    # Handle GET request
    return render_template('register.html')


@app.route('/home')
def home():
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)
    qCount = 5
    user_id = session.get('userID')
    user_role = session.get('role', 'anonymouse')
    active_draft = None

    try:
        if session.get('role') == 'admin':
            cursor.execute("SELECT COUNT(*) AS total FROM Question WHERE status = 'published'")
        else:
            cursor.execute("SELECT COUNT(*) AS total FROM Question WHERE status = 'published' AND visibility = 'visible'")
        total_questions = cursor.fetchone()['total']
        total_pages = (total_questions + qCount - 1) // qCount

        # Fetch questions for each category (first page by default)
        if session.get('role') == 'admin':
            cursor.execute("CALL GetPopularQuestionsWithPagination(%s, 0)", (qCount,))
        else:
            cursor.execute("""
                SELECT * FROM Question
                WHERE status = 'published ' AND visiblity = 'visible'
                ORDER BY upvotes DESC
                LIMIT %s
            """)
        most_popular = cursor.fetchall()

        # Fetch most controversial questions
        if session.get('role') == 'admin':
            cursor.execute("CALL GetControversialQuestionsWithPagination(%s, 0)", (qCount,))
        else:
            cursor.execute("""
                SELECT * FROM Question
                WHERE status = 'published' AND visibility = 'visible'
                ORDER BY (downvotes - upvotes) DESC
                LIMIT %s
            """, (qCount,))
        most_controversial = cursor.fetchall()

        # Fetch most recent questions
        if session.get('role') == 'admin':
            cursor.execute("CALL GetRecentQuestionsWithPagination(%s, 0)", (qCount,))
        else:
            cursor.execute("""
                SELECT * FROM Question
                WHERE status = 'published' AND visibility = 'visible'
                ORDER BY TimeStampID DESC
                LIMIT %s
            """, (qCount,))
        most_recent = cursor.fetchall()

        # Get tags
        cursor.execute("SELECT tagID, tagName FROM Tag")
        tags = cursor.fetchall()

        # Look for an active draft
        if user_id:
            cursor.execute("""
                SELECT questionID, questionText
                FROM Question
                WHERE userID = %s AND status = 'draft'
                ORDER BY TimeStampID DESC
                LIMIT 1
            """, (user_id,))
            active_draft = cursor.fetchone()
        
        return render_template(
            'home.html',
            user_role=user_role,
            tags=tags,
            most_popular=most_popular,
            most_controversial=most_controversial,
            most_recent=most_recent,
            most_popular_page=1,
            most_controversial_page=1,
            most_recent_page=1,
            total_pages=total_pages,
            active_draft=active_draft
        )
    except Exception as e:
        flash(f"Error loading homepage: {e}", "home-danger")
        return render_template('home.html', tags=[], most_popular=[], most_controversial=[], most_recent=[], active_draft=None)
    finally:
        conn.close()

@app.route('/search', methods=['GET'])
def search():
    username = request.args.get('username')
    keyword = request.args.get('keyword')
    tag = request.args.get('tag')

    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    # Search by Username
    if username:
        cursor.execute("SELECT * FROM Question WHERE userID = (SELECT userID FROM User WHERE userName = %s) AND Question.status='published' ORDER BY Question.questionID DESC", (username,))
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
        return render_template('search_results.html', questions=questions, search_type="Tag", search_value = tag, tag_name=tag)

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
    cursor.execute("SELECT COUNT(*) AS total FROM Question WHERE status = 'published'")
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
    cursor.execute("SELECT COUNT(*) AS total FROM Question WHERE status = 'published'")
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

    # Fetch paginated recent questions with createdAt
    cursor.execute("CALL GetRecentQuestionsWithPagination(%s,%s)", (per_page, offset)) 
    questions = cursor.fetchall()

    # Fetch total num of questions for pagination
    cursor.execute("SELECT COUNT(*) AS total FROM Question WHERE status = 'published'")
    total_questions = cursor.fetchone()['total']
    
    conn.close()

    total_pages = (total_questions + per_page - 1) // per_page
    has_next = page < total_pages

    return render_template(
        'most_recent.html', 
        questions=questions,
        page=page, 
        has_next=has_next,
        total_pages=total_pages)

@app.route('/start_question', methods=['POST'])
def start_question():
    userID = session.get('userID')
    question_text = request.form.get('question_text', '')
    if not userID:
        flash('You must be logged in to ask a question.', 'home-danger')
        return redirect(url_for('login'))
    if not question_text:
        flash('Draft creation failed: You must enter a question.', 'home-danger')
        return redirect(url_for('home'))
    conn = connect_db()
    cursor = conn.cursor()
    try:
        cursor.execute("CALL StartQuestion(%s, %s)", (userID, question_text))
        conn.commit()
        flash('Draft question started successfully!', 'home-success')
    except Exception as e:
        conn.rollback()
        flash(f'Draft creation failed: {e}', 'home-danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('home'))

@app.route('/publish_question', methods=['POST'])
def publish_question():
    userID = session.get('userID')
    question_id = request.form.get('draft_id')
    tags = request.form.getlist('tags')
    if not userID or not question_id or not tags:
        flash('Publish failed: Missing data for publishing.', 'publish-danger')
        return redirect(url_for('home'))
    conn = connect_db()
    cursor = conn.cursor()
    try:
        cursor.execute("CALL PublishQuestion(%s)", (question_id,))
        for tag_id in tags:
            cursor.execute("CALL QuestionAddTag(%s, %s)", (question_id, tag_id))
        conn.commit()
        flash('Question published successfully!', 'publish-success')
    except Exception as e:
        conn.rollback()
        flash(f'Error publishing question: {e}', 'publish-danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('home'))

@app.route('/cancel_question', methods=['POST'])
def cancel_question():
    userID = session.get('userID')
    question_id = request.form.get('draft_id')
    if not userID or not question_id:
        flash('Draft cancellation failed: No draft found.', 'cancel-danger')
        return redirect(url_for('home'))
    conn = connect_db()
    cursor = conn.cursor()
    try:
        cursor.execute("CALL CancelQuestion(%s)", (question_id,))
        conn.commit()
        flash('Draft question cancelled successfully!', 'cancel-success')
    except Exception as e:
        conn.rollback()
        flash(f'Error cancelling draft: {e}', 'cancel-danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('home'))
    
@app.route('/question/<int:question_id>', methods=['GET', 'POST'])
def question_detail(question_id):
    if 'userID' not in session:
        return redirect(url_for('login'))  # Redirect if not logged in

    userID = session['userID']
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    try:
        # Fetch question
        cursor.execute("SELECT * FROM Question WHERE questionID = %s", (question_id,))
        question = cursor.fetchone()

        # CHeck if the question exists
        if not question:
            flash('Question not found.', 'danger')
            return redirect(url_for('home'))
        
        # Check visisiblity for regulars users
        if session.get('role') != 'admin' and question['visibility'] == 'hidden':
            flash('This question is not available.', 'danger')
            return redirect(url_for('home'))
        
        # Check if the user has already responded to this question
        cursor.execute("""
            SELECT responseID FROM Response
            WHERE questionID = %s AND userID = %s AND status = 'published'
        """, (question_id, userID))
        user_has_responded = cursor.fetchone() is not None

        # Check if the user has already commented on this question
        cursor.execute("""
            SELECT commentID FROM Comment
            WHERE questionID = %s AND userID = %s AND status = 'published'
        """, (question_id, userID))
        user_has_commented = cursor.fetchone() is not None
        
        # Get question tags
        cursor.execute("""
            SELECT t.tagID, t.tagName
            FROM QuestionTag qt
            JOIN Tag t ON qt.tagID = t.tagID
            WHERE qt.questionID = %s
        """, (question_id,))
        tags = cursor.fetchall()

        # Handle new response submission
        if request.method == 'POST' and not user_has_responded:
            response_text = request.form['responseText']
            timestamp_id = get_timestamp_id(cursor)  # You should define this helper
            cursor.execute("""
                INSERT INTO Response (userID, questionID, responseText, TimeStampID, status)
                VALUES (%s, %s, %s, %s, 'published')
            """, (userID, question_id, response_text, timestamp_id))
            conn.commit()
            return redirect(url_for('question_detail', question_id=question_id))

        # Handle comment submission 
        if request.method == 'POST' and 'commentText' in request.form and not user_has_commented:
            comment_text = request.form['commentText']
            timestamp_id = get_timestamp_id(cursor)  # Same helper function for timestamps
            cursor.execute("""
                INSERT INTO Comment (userID, questionID, commentText, TimeStampID, status)
                VALUES (%s, %s, %s, %s, 'published')
            """, (userID, question_id, comment_text, timestamp_id))
            conn.commit()
            return redirect(url_for('question_detail', question_id=question_id))

        # Get responses and comments only if user has responded
        responses = []
        comments = []
        if user_has_responded:
            cursor.execute("SELECT * FROM Response JOIN User ON Response.userID = User.userID WHERE questionID = %s AND status = 'published'", (question_id,))
            responses = cursor.fetchall()

            cursor.execute("""
                SELECT * FROM Comment
                WHERE questionID = %s AND status = 'published'
            """, (question_id,))
            comments = cursor.fetchall()
    except Exception as e:
        flash(f"Error loading question: {e}", 'danger')
        return redirect(url_for('home'))
    finally:
        conn.close()

    return render_template(
        'question_detail.html',
        question=question,
        responses=responses,
        comments=comments,
        user_has_responded=user_has_responded,
        user_has_commented=user_has_commented,
        tags=tags
    )

@app.route('/vote_question', methods=['POST'])
def vote_question():
    userID = session.get('userID')
    question_id = request.form.get('question_id')
    vote_type = request.form.get('vote_type')
    if not userID or not question_id or vote_type not in ['up', 'down']:
        flash('Vote failed: Invalid voting request.', 'vote-danger')
        return redirect(url_for('home'))
    conn = connect_db()
    cursor = conn.cursor()
    try:
        if vote_type == 'up':
            cursor.execute("CALL UpvoteQuestion(%s, %s)", (userID, question_id))
        else:
            cursor.execute("CALL DownvoteQuestion(%s, %s)", (userID, question_id))
        conn.commit()
        flash('Your vote has been recorded!', 'vote-success')
        return redirect(url_for('question_detail', question_id=question_id))
    except Exception as e:
        conn.rollback()
        flash(f'Error recording your vote: {e}', 'vote-danger')
        return redirect(url_for('question_detail', question_id=question_id))
    finally:
        conn.close()


@app.route('/account_settings', methods=['GET', 'POST'])
def account_settings():
    # Only allow access if user is logged in
    if 'username' not in session:
        flash('Please login to access account settings', 'login-error')
        return redirect(url_for('login'))
    
    # Get current user info
    username = session['username']
    conn = connect_db()
    cursor = conn.cursor()

    cursor.execute("SELECT userID FROM User WHERE userName = %s", (username,))
    user_id_row = cursor.fetchone()
    user_id = user_id_row['userID']

    # Handle form submission (POST)
    if request.method == 'POST':
        # Get form data
        new_password = request.form.get('new_password')
        confirm_password = request.form.get('confirm_password')
        new_first_name = request.form.get('first_name')
        new_last_name = request.form.get('last_name')
        selected_tag_ids = request.form.getlist('tags')

        
        # Validate and update password if provided
        if new_password and new_password == confirm_password:
            # In production, use password hashing here
            cursor.execute("UPDATE User SET password = %s WHERE userName = %s", 
                          (new_password, username))
            flash('Password updated successfully!', 'success')
        elif new_password:  # Passwords don't match
            flash('Passwords do not match!', 'danger')
        
        # Update name fields if provided
        # Get current first and last name to compare
        cursor.execute("SELECT firstName, lastName FROM User WHERE userName = %s", (username,))
        current_user = cursor.fetchone()
        current_first_name = current_user['firstName']
        current_last_name = current_user['lastName']

        # Only update if values are actually different
        if (new_first_name and new_first_name != current_first_name) or (new_last_name and new_last_name != current_last_name):
            update_fields = []
            params = []
            
            if new_first_name:
                update_fields.append("firstName = %s")
                params.append(new_first_name)
            
            if new_last_name:
                update_fields.append("lastName = %s")
                params.append(new_last_name)
                
            params.append(username)  # For the WHERE clause
            
            # Get the current tags the user already has
            cursor.execute("SELECT tagID FROM UserTag WHERE userID = %s", (user_id,))
            existing_tag_ids = [row['tagID'] for row in cursor.fetchall()]
    
            # Add new tags (that the user doesn't already have)
            for tag_id in selected_tag_ids:
                if int(tag_id) not in existing_tag_ids:  # Avoid duplicates
                    cursor.execute("""
                        INSERT INTO UserTag (tagID, userID)
                        VALUES (%s, %s)
                    """, (tag_id, user_id))
            
            flash('Tags updated successfully!', 'success')

            cursor.execute(f"UPDATE User SET {', '.join(update_fields)} WHERE userName = %s", tuple(params))
            flash('Profile information updated!', 'success')
            
        conn.commit()

    # Get current user data to display
    cursor.execute("SELECT firstName, lastName, role FROM User WHERE userName = %s", (username,))
    user_data = cursor.fetchone()
    
    # Fetch all available tags
    cursor.execute("SELECT tagID, tagName FROM Tag")
    all_tags = [{'id': row['tagID'], 'tagName': row['tagName']} for row in cursor.fetchall()]

    # Fetch user's selected tags
    cursor.execute("SELECT tagID FROM UserTag WHERE userID = %s", (user_id,))
    user_tags = [row['tagID'] for row in cursor.fetchall()]  
    
    cursor.close()
    conn.close()
    
    return render_template('account_settings.html', username=username, user_data=user_data, all_tags=all_tags, user_tags=user_tags)
    
@app.route('/chats')
def list_chats():
    """
    Display all chats that the logged-in user is a member of.
    Also checks for pending chat requests to show an alert.
    """
    # Ensure user is logged in
    if 'username' not in session:
        flash('Please login to view your chats.', 'login-error')
        return redirect(url_for('login'))

    user_id = session.get('userID')
    if not user_id:
        conn = connect_db()
        try:
            cursor = conn.cursor(pymysql.cursors.DictCursor)
            cursor.execute("SELECT userID FROM User WHERE userName = %s", (session['username'],))
            user_result = cursor.fetchone()
            if user_result:
                user_id = user_result['userID']
                session['userID'] = user_id
            else:
                flash('Could not verify user session.', 'danger')
                return redirect(url_for('logout'))
        except Exception as e:
            flash(f"Error verifying user: {e}", "danger")
            return redirect(url_for('logout'))
        finally:
            cursor.close()
            conn.close()

    # Fetch all chats this user is a member of
    chats = []
    has_pending_requests = False
    conn = connect_db()
    try:
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute("""
            SELECT c.chatID, c.chatName, 
                   (SELECT COUNT(*) FROM ChatMember WHERE chatID = c.chatID) as member_count
            FROM ChatMember cm
            JOIN Chat c ON cm.chatID = c.chatID
            WHERE cm.userID = %s
        """, (user_id,))
        chats = cursor.fetchall()
        # Check for pending chat requests
        cursor.execute("""
            SELECT COUNT(*) as pending_count FROM ChatRequest
            WHERE toUserID = %s AND status = 'pending'
        """, (user_id,))
        pending = cursor.fetchone()
        has_pending_requests = pending and pending['pending_count'] > 0
    except pymysql.Error as err:
        flash(f"Database error fetching chats: {err}", "danger")
        print(f"Database error: {err}")
    finally:
        if conn:
            conn.close()

    return render_template('chats.html', chats=chats, has_pending_requests=has_pending_requests)

@app.route('/create_chat', methods=['GET', 'POST'])
def create_chat():
    # Ensure user is logged in
    if 'username' not in session or 'userID' not in session:
        flash('Please login to create a chat', 'danger')
        return redirect(url_for('login'))

    creator_id = session['userID']
    conn = connect_db()
    
    try:
        # Handle POST request
        if request.method == 'POST':
            # Get form data
            chat_name = request.form.get('chat_name')
            
            # Get member IDs as integers
            try:
                members_str = request.form.getlist('members')
                members = [int(m_id) for m_id in members_str if m_id.isdigit()]
            except ValueError:
                flash('Invalid member selection', 'danger')
                return redirect(url_for('create_chat'))
                
            # Basic validation
            if not chat_name or not members:
                flash('Chat name and at least one member are required', 'danger')
                cursor_get = conn.cursor(pymysql.cursors.DictCursor)
                cursor_get.execute(
                    "SELECT userID, userName, firstName, lastName FROM User WHERE userID != %s ORDER BY userName",
                    (creator_id,)
                )
                potential_users = cursor_get.fetchall()
                cursor_get.close()
                return render_template('create_chat.html', potential_users=potential_users, chat_name=chat_name)
            chat_id = None
            cursor = conn.cursor()
            try:
                # Start transaction
                for i in range(len(members)):
                    if i ==0:
                        cursor.callproc('CreateChatAndRequest', (creator_id, chat_name, members[i]))
                        # Get the chat ID from the created chat
                        cursor.execute("""
                            SELECT chatID FROM Chat 
                            WHERE chatName = %s 
                            ORDER BY chatID DESC LIMIT 1
                        """, (chat_name,))
                        chat_result = cursor.fetchone()
                        if chat_result:
                            chat_id = chat_result['chatID']
                        else:
                            raise Exception("Failed to retrieve created chat ID")
                    else:
                        cursor.callproc('CreateChatRequest', (creator_id, members[i], chat_id))
                    
                conn.commit()
                flash("Chat created successfully!", 'success')
                return redirect(url_for('list_chats'))
                
            except Exception as e:
                conn.rollback()
                flash(f'Error creating chat: {e}', 'danger')
                print(f"Error in create_chat: {e}")
                return redirect(url_for('create_chat'))
            finally:
                cursor.close()

        # --- GET Request Logic ---
        cursor_get = conn.cursor(pymysql.cursors.DictCursor)
        try:
            cursor_get.execute(
                "SELECT userID, userName, firstName, lastName FROM User WHERE userID != %s ORDER BY userName",
                (creator_id,)
            )
            potential_users = cursor_get.fetchall()
        except Exception as e:
            flash(f'Error loading users: {e}', 'danger')
            potential_users = []
        finally:
            cursor_get.close()

        return render_template('create_chat.html', potential_users=potential_users)
        
    finally:
        if conn:
            conn.close()

@app.route('/chat/<int:chat_id>', methods=['GET', 'POST'])
def view_chat(chat_id):
    """
    Display an individual chat and handle sending new messages.
    Supports both 1-on-1 and group chats.
    """
    # Ensure user is logged in
    if 'username' not in session or 'userID' not in session:
        flash('Please login to view chats', 'danger')
        return redirect(url_for('login'))

    user_id = session['userID']
    conn = connect_db()
    try:
        cursor = conn.cursor(pymysql.cursors.DictCursor)

        # Verify the user is a member of this chat
        cursor.execute(
            "SELECT COUNT(*) as is_member FROM ChatMember WHERE chatID = %s AND userID = %s",
            (chat_id, user_id)
        )
        result = cursor.fetchone()
        if not result or result['is_member'] == 0:
            flash('You are not a member of this chat', 'danger')
            cursor.close()
            return redirect(url_for('list_chats'))

        # Get chat details
        cursor.execute("SELECT chatName FROM Chat WHERE chatID = %s", (chat_id,))
        chat = cursor.fetchone()
        
        # Get chat members (allow any number of members)
        cursor.execute("""
            SELECT u.userID, u.userName, u.firstName, u.lastName
            FROM ChatMember cm
            JOIN User u ON cm.userID = u.userID
            WHERE cm.chatID = %s
        """, (chat_id,))
        members = cursor.fetchall()
        
        # Removed check for exactly 2 members to allow group chats

        # Handle new message submission
        if request.method == 'POST':
            message_text = request.form.get('message')
            if message_text and message_text.strip():
                try:
                    # Create timestamp
                    cursor.execute("INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE())")
                    timestamp_id = cursor.lastrowid
                    
                    # Insert message
                    cursor.execute(
                        "INSERT INTO ChatMessage (chatID, userID, messageText, TimeStampID) VALUES (%s, %s, %s, %s)",
                        (chat_id, user_id, message_text, timestamp_id)
                    )
                    conn.commit()
                    return redirect(url_for('view_chat', chat_id=chat_id))
                except Exception as e:
                    conn.rollback()
                    flash(f'Error sending message: {e}', 'danger')

        # Get chat messages
        cursor.execute("""
            SELECT cm.chatMessageID as messageID, cm.messageText, u.userID,
                   u.userName, u.firstName, u.lastName,
                   ts.sentTime, ts.sentDate
            FROM ChatMessage cm
            JOIN User u ON cm.userID = u.userID
            JOIN TimeStamp ts ON cm.TimeStampID = ts.TimeStampID
            WHERE cm.chatID = %s
            ORDER BY ts.sentDate ASC, ts.sentTime ASC
        """, (chat_id,))
        messages = cursor.fetchall()
        cursor.close()

    except Exception as e:
        if conn:
            conn.rollback()
        flash(f'Error accessing chat: {e}', 'danger')
        print(f"Error in view_chat: {e}")
        return redirect(url_for('list_chats'))
    finally:
        if conn:
            conn.close()

    return render_template('view_chat.html',
                           chat=chat,
                           chat_id=chat_id,
                           members=members,
                           messages=messages,
                           current_user_id=user_id)

@app.route('/chat_requests', methods=['GET', 'POST'])
def chat_requests():
    """
    Display and handle pending chat requests for the logged-in user.
    """
    if 'userID' not in session:
        flash('Please login to view chat requests.', 'danger')
        return redirect(url_for('login'))

    user_id = session['userID']
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)
    try:
        # Fetch pending chat requests for this user
        cursor.execute("""
            SELECT cr.requestID, c.chatID, c.chatName, u.userName AS fromUserName, u.firstName, u.lastName
            FROM ChatRequest cr
            JOIN Chat c ON cr.chatID = c.chatID
            JOIN User u ON cr.fromUserID = u.userID
            WHERE cr.toUserID = %s AND cr.status = 'pending'
        """, (user_id,))
        requests = cursor.fetchall()
    except Exception as e:
        flash(f'Error loading chat requests: {e}', 'danger')
        requests = []
    finally:
        cursor.close()
        conn.close()
    return render_template('chat_requests.html', requests=requests)

@app.route('/chat_request/<int:request_id>/accept', methods=['POST'])
def accept_chat_request(request_id):
    if 'userID' not in session:
        flash('Please login to accept chat requests.', 'danger')
        return redirect(url_for('login'))
    user_id = session['userID']
    conn = connect_db()
    cursor = conn.cursor()
    try:
        # Accept the request (update status)
        cursor.execute("""
            UPDATE ChatRequest SET status = 'accepted' WHERE requestID = %s AND toUserID = %s
        """, (request_id, user_id))
        conn.commit()
        flash('Chat request accepted!', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error accepting chat request: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('chat_requests'))

@app.route('/chat_request/<int:request_id>/reject', methods=['POST'])
def reject_chat_request(request_id):
    if 'userID' not in session:
        flash('Please login to reject chat requests.', 'danger')
        return redirect(url_for('login'))
    user_id = session['userID']
    conn = connect_db()
    cursor = conn.cursor()
    try:
        # Reject the request (update status)
        cursor.execute("""
            UPDATE ChatRequest SET status = 'rejected' WHERE requestID = %s AND toUserID = %s
        """, (request_id, user_id))
        conn.commit()
        flash('Chat request rejected.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error rejecting chat request: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('chat_requests'))

@app.route('/add_tag', methods=['POST'])
def add_tag():
    if 'userID' not in session:
        flash('You must be logged in to add tags.', 'dashboard-danger')
        return redirect(url_for('login'))
    user_id = session.get('userID')
    tag_id = request.form.get('tag_id')
    if not tag_id or not tag_id.isdigit():
        flash('Invalid tag selected.', 'dashboard-danger')
        return redirect(url_for('dashboard'))
    conn = connect_db()
    cursor = conn.cursor()
    try:
        cursor.execute("CALL UserAddTag(%s, %s)", (user_id, tag_id))
        conn.commit()
        flash('Tag added successfully!', 'dashboard-success')
    except pymysql.Error as e:
        conn.rollback()
        if e.args[0] == 1062:
            flash('You already have this tag.', 'dashboard-warning')
        else:
            flash('Error adding tag.', 'dashboard-danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('dashboard'))
    
@app.context_processor
def inject_user_data():
    """
    Make user data available to all templates including base.html
    This eliminates the need to pass these variables in every route
    """
    show_login_button = True
    if 'userID' in session:
        show_login_button = False
    return {
        'show_login_button': show_login_button,
        'username': session.get('username', None),
        'user_role': session.get('role', None)
    }

if __name__ == '__main__':
    app.run(debug=True)
