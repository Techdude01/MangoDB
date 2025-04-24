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
            # Get user information in a single query
            cursor = conn.cursor(pymysql.cursors.DictCursor)
            cursor.execute("SELECT userID, role FROM User WHERE userName = %s", (username,))
            user = cursor.fetchone()
            
            # Set session variables
            session['username'] = username
            session['role'] = role  
            session['userID'] = user['userID']
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid credentials', 'danger')
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

    print(questions)
    # Get tags used by the current user
    cursor.execute("CALL GetTagsByUserID(%s)", (session['userID'],))
    tags = cursor.fetchall()
    # Get all tags in the system for comparison
    cursor.execute("SELECT tagID, tagName FROM Tag")
    tags2 = cursor.fetchall()
    # Render the dashboard template with the user's data
    return render_template('dashboard.html', tags=tags, tags2=tags2,questions=questions,numQuestions=len(questions), numTags=len(tags))

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
        firstName = request.form.get('firstName')
        lastName = request.form.get('lastName')
        # Basic validation
        if not username or not password:
            flash('All fields are required', 'danger')
            return redirect(url_for('register_route'))
        # Check if user already exists
        conn = connect_db()
        cursor = conn.cursor()

        # Check if the username already exists in the User table
        cursor.execute("SELECT COUNT(*) AS count FROM User WHERE username = %s", (username,))
        user_exists = cursor.fetchone()['count'] > 0

        if user_exists:
            flash('Username already exists. Please choose a different username.', 'danger')
            return redirect(url_for('register_route'))
        
        try:
            # Insert the new user into the database
            register_user(conn, username, password, 'user', firstName, lastName)
            flash('Registration successful! You can now log in.', 'success')
            return redirect(url_for('login'))
        except Exception as e:
            conn.rollback()
            flash(f'Error during registration: {e}', 'danger')
        finally:
            conn.close()
        
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
    qCount = 5

    try:
        # Fetch total questions
        cursor.execute("SELECT COUNT(*) AS total FROM Question WHERE status = 'published'")
        total_questions = cursor.fetchone()['total']
        qPage= total_questions // qCount + (total_questions % qCount > 0)

        #Fetch top 5 questions for each category
        cursor.execute("CALL GetPopularQuestionsWithPagination(%s, 0)", (qCount,))
        most_popular = cursor.fetchall()

        cursor.execute("CALL GetControversialQuestionsWithPagination(%s, 0)", (qCount,))
        most_controversial = cursor.fetchall()

        cursor.execute("CALL GetRecentQuestionsWithPagination(%s, 0)", (qCount,))
        most_recent = cursor.fetchall()

        cursor.execute("SELECT tagID, tagName FROM Tag")
        tags = cursor.fetchall()
        print(most_recent)
        print('g')
        # Fetch a specific question (example: the first question)
        cursor.execute("SELECT * FROM Question WHERE status = 'published' LIMIT 1")
        question = cursor.fetchone()
        
        return render_template(
            'home.html', 
            tags=tags,
            most_popular=most_popular, 
            most_controversial=most_controversial, 
            most_recent=most_recent,
            question=question,
            most_popular_page=1,
            total_pages=qPage,
            most_controversial_page=1,
            most_recent_page=1,
        )
    except Exception as e: 
        flash(f"Error loading homepage: {e}", "danger")
        return render_template('home.html', tags=[], most_popular=[], most_controversial=[], most_recent=[])
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
        cursor.execute("SELECT * FROM Question WHERE userID = (SELECT userID FROM User WHERE userName = %s)", (username,))
        questions = cursor.fetchall()
        conn.close()
        print('i')
        return render_template('search_results.html', questions=questions, search_type="Username", search_value=username)

    # Search by Keyword
    elif keyword:
        cursor.execute("CALL SearchQuestions(%s)", (keyword,))
        questions = cursor.fetchall()
        conn.close()
        print('j')
        return render_template('search_results.html', questions=questions, search_type="Keyword", search_value=keyword)

    # Search by Tag
    elif tag:
        cursor.execute("CALL GetQuestionsByTag(%s)", (tag,))
        questions = cursor.fetchall()
        conn.close()
        print(questions)
        return render_template('search_results.html', questions=questions, search_type="Tag", tag_name=tag)

    # If no input is provided
    else:
        conn.close()
        print('l')
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
    user_id = session.get('userID') # Get userID from session
    question_text = request.form.get('question_text', '')

    if not user_id:
        # Handle case where user is not logged in
        flash('You must be logged in to ask a question.', 'danger')
        return redirect(url_for('login')) # Redirect to login
    if not question_text:
        flash('Question text cannot be empty.', 'danger')
        return redirect(url_for('home')) # Redirect back home or wherever the form is

    conn = connect_db()
    cursor = conn.cursor()
    # draft_id = None # No longer needed if not returning JSON
    try:
        # Call StartQuestion procedure
        cursor.execute("CALL StartQuestion(%s, %s)", (user_id, question_text))
        # No need to fetch LAST_INSERT_ID() if not returning JSON
        conn.commit()
        flash('Draft question started successfully! Now add tags and publish.', 'success') # Updated flash message
        # Redirect back to home, potentially with info to show the publish form
        # Simple redirect for now, frontend JS needs adjustment if it relied on draftId
        return redirect(url_for('home'))
    except Exception as e:
        conn.rollback()
        print(f"Error starting question draft: {e}")
        flash(f'Error starting question: {e}', 'danger') # Flash error message
        return redirect(url_for('home')) # Redirect on error
    finally:
        cursor.close()
        conn.close()

@app.route('/publish_question', methods=['POST'])
def publish_question():
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)
    try:
        # Get the latest draft question for this user
        userID = session.get('userID')
        cursor.execute("""
            SELECT questionID FROM Question 
            WHERE userID = %s AND status = 'draft'
            ORDER BY questionID DESC LIMIT 1
        """, (userID,))
        result = cursor.fetchone()
        if result:
            question_id = result['questionID']
        else:
            flash('No draft question found to publish.', 'danger')
            return redirect(url_for('home'))
    except Exception as e:
        flash(f'Error retrieving draft question: {e}', 'danger')
        return redirect(url_for('home'))
    finally:
        cursor.close()
    tag_ids = request.form.getlist('tags')
    userID = session.get('userID')
    print(f"Publishing question {question_id} with tags {tag_ids} for user {userID}")

    if not question_id or not tag_ids or not userID:
        flash('Please provide a question and at least one tag.')
        return redirect(url_for('home'))

    conn = connect_db()
    cursor = conn.cursor()

    try:
        # Call PublishQuestion() to publish the question
        cursor.execute("CALL PublishQuestion(%s)", (question_id,))

        # Update the TagList table w selected tags
        for tag_id in tag_ids:
            cursor.execute("INSERT INTO TagList (tagID, questionID, userID) VALUES (%s, %s, %s)", (tag_id, question_id, userID))
        
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
    print('g')
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)
    try:
        # Get the latest draft question for this user
        userID = session.get('userID')
        cursor.execute("""
            SELECT questionID FROM Question 
            WHERE userID = %s AND status = 'draft'
            ORDER BY questionID DESC LIMIT 1
        """, (userID,))
        result = cursor.fetchone()
        if result:
            question_id = result['questionID']
        else:
            flash('No draft question found to publish.', 'danger')
            return redirect(url_for('home'))
    except Exception as e:
        flash(f'Error retrieving draft question: {e}', 'danger')
        return redirect(url_for('home'))
    finally:
        cursor.close()

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

    userID = session['userID']
    conn = connect_db()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

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

    # Get the question data
    cursor.execute("SELECT * FROM Question WHERE questionID = %s", (question_id,))
    question = cursor.fetchone()

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

    conn.close()

    if not question:
        flash('Question not found.', 'danger')
        return redirect(url_for('home'))

    return render_template(
        'question_detail.html',
        question=question,
        responses=responses,
        comments=comments,
        user_has_responded=user_has_responded
    )

@app.route('/vote_question', methods=['POST'])
def vote_question():
    userID = session.get('userID')
    question_id = request.form.get('question_id')
    vote_type = request.form.get('vote')
    if not userID or not question_id or vote_type not in ['up', 'down']:
        flash('Invalid voting request.', 'danger')
        return redirect(url_for('home'))
    conn = connect_db()
    cursor = conn.cursor()
    try:
        print(f"Attempting to {vote_type}vote question {question_id} by user {userID}")
        
        if vote_type == 'up':
            print("Calling UpvoteQuestion stored procedure")
            cursor.execute("CALL UpvoteQuestion(%s, %s)", (userID, question_id))
            print("UpvoteQuestion procedure call completed")
        elif vote_type == 'down':
            cursor.execute("CALL DownvoteQuestion(%s, %s)", (userID, question_id))
            
        conn.commit()
        flash('Your vote has been recorded!', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error recording your vote: {e}', 'danger')
    finally:
        conn.close()
    
    return redirect(url_for('question_detail', question_id=question_id))

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

    # Get user ID (for tag handling)
    cursor.execute("SELECT userID FROM User WHERE userName = %s", (username,))
    user_id_row = cursor.fetchone()
    if not user_id_row:
        flash("User not found", "danger")
        return redirect(url_for('login'))
    user_id = user_id_row['userID'] 
    
    
    # Handle form submission (POST)
    if request.method == 'POST':
        # Get form data
        new_password = request.form.get('new_password')
        confirm_password = request.form.get('confirm_password')
        new_first_name = request.form.get('first_name')
        new_last_name = request.form.get('last_name')
        selected_tag_ids = request.form.getlist('user_tags')  # List of selected tag IDs

        
        # Validate and update password if provided
        if new_password and new_password == confirm_password:
            # In production, use password hashing here
            cursor.execute("UPDATE User SET password = %s WHERE userName = %s", 
                          (new_password, username))
            flash('Password updated successfully!', 'success')
        elif new_password:  # Passwords don't match
            flash('Passwords do not match!', 'danger')
        
        # Update name fields if provided
        if new_first_name or new_last_name:
            update_fields = []
            params = []
            
            if new_first_name:
                update_fields.append("firstName = %s")
                params.append(new_first_name)
            
            if new_last_name:
                update_fields.append("lastName = %s")
                params.append(new_last_name)
                
            params.append(username)  # For the WHERE clause
            
            # Update tags
            cursor.execute("DELETE FROM UserTags WHERE userID = %s", (user_id,))
            for tag_id in selected_tag_ids:
                cursor.execute("INSERT INTO UserTags (userID, tagID) VALUES (%s, %s)", (user_id, tag_id))

            cursor.execute(f"UPDATE User SET {', '.join(update_fields)} WHERE userName = %s", tuple(params))
            flash('Profile information updated!', 'success')
            
        conn.commit()

    # Fetch all available tags
    cursor.execute("SELECT tagID, tagName FROM Tag")
    all_tags = [{'id': row['tagID'], 'tagName': row['tagName']} for row in cursor.fetchall()]

    # Fetch user's selected tags
    cursor.execute("SELECT tagID FROM UserTags WHERE userID = %s", (user_id,))
    user_tag_ids = [row['tagID'] for row in cursor.fetchall()]  
    
    # Get current user data to display
    cursor.execute("SELECT firstName, lastName, role FROM User WHERE userName = %s", (username,))
    user_data = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    return render_template('account_settings.html', username=username, user_data=user_data, all_tags=all_tags, user_tag_ids=user_tag_ids)
@app.route('/chats')
def list_chats():
    """
    Display all chats that the logged-in user is a member of.
    """
    # Ensure user is logged in
    if 'username' not in session:
        flash('Please login to view your chats.', 'login-error')
        return redirect(url_for('login'))

    # Use the correct session key - userID with capital ID to match login route
    user_id = session.get('userID')
    if not user_id:
        # Fetch user_id if it's somehow missing from session
        conn = connect_db()
        try:
            cursor = conn.cursor(pymysql.cursors.DictCursor)
            cursor.execute("SELECT userID FROM User WHERE userName = %s", (session['username'],))
            user_result = cursor.fetchone()
            
            if user_result:
                user_id = user_result['userID']
                session['userID'] = user_id  # Store it for future use
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
    except pymysql.Error as err:
        flash(f"Database error fetching chats: {err}", "danger")
        print(f"Database error: {err}")
    finally:
        if conn:
            conn.close()

    return render_template('chats.html', chats=chats)

@app.route('/create_chat', methods=['GET', 'POST'])
def create_chat():
    """
    Route for creating a new group chat.
    Handles both 1-on-1 and multi-user chats.
    """
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

            cursor = conn.cursor()
            try:
                # Start transaction
                # If only one member selected, use CreateChatAndRequest procedure
                if len(members) == 1:
                    cursor.callproc('CreateChatAndRequest', (creator_id, chat_name, members[0]))
                # Otherwise create multi-user chat directly
                else:
                    # Create the chat
                    cursor.execute(
                        "INSERT INTO Chat (chatName, userID) VALUES (%s, %s)",
                        (chat_name, creator_id)
                    )
                    chat_id = cursor.lastrowid
                    
                    # Include creator in members if not already
                    if creator_id not in members:
                        members.append(creator_id)
                        
                    # Add all members to the chat
                    for member_id in members:
                        # Use individual inserts instead of executemany
                        cursor.execute(
                            "INSERT INTO ChatMember (chatID, userID) VALUES (%s, %s)",
                            (chat_id, member_id)
                        )
                        print(f"Added member {member_id} to chat {chat_id}")
                    
                    # Create welcome message
                    cursor.execute("INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE())")
                    timestamp_id = cursor.lastrowid
                    cursor.execute(
                        "INSERT INTO ChatMessage (chatID, userID, messageText, TimeStampID) VALUES (%s, %s, %s, %s)",
                        (chat_id, creator_id, f"Group chat '{chat_name}' created", timestamp_id)
                    )
                    
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
@app.route('/add_tag', methods=['POST'])
def add_tag():
    if 'userID' not in session:
        flash('You must be logged in to add tags.', 'danger')
        return redirect(url_for('login'))
    
    user_id = session.get('userID')
    tag_id = request.form.get('tag_id')
    
    # Validate the tag_id
    if not tag_id or not tag_id.isdigit():
        flash('Invalid tag selected.', 'danger')
        return redirect(url_for('dashboard'))
    
    conn = connect_db()
    cursor = conn.cursor()
    
    try:
        # Call the AddTag stored procedure
        cursor.execute("CALL UserAddTag(%s, %s)", (user_id, tag_id))
        conn.commit()
        flash('Tag added successfully!', 'success')
    except pymysql.Error as e:
        conn.rollback()
        # Check if it's a duplicate entry error
        if e.args[0] == 1062:  # MySQL duplicate entry error code
            flash('You already have this tag.', 'warning')
        else:
            flash(f'Error adding tag: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    
    # Redirect back to dashboard or another appropriate page
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
