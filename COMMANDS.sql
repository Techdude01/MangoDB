CREATE TABLE User(
	userID INT AUTO_INCREMENT PRIMARY KEY,
	userName VARCHAR(16) UNIQUE,
	password VARCHAR(32),
	firstName VARCHAR(32),
	lastName VARCHAR(32)
);

CREATE TABLE Tag(
	tagID INT AUTO_INCREMENT PRIMARY KEY,
	tagName VARCHAR(16) UNIQUE
);

CREATE TABLE TagList(
	tagID INT,
	userID INT,
	FOREIGN KEY (tagID) REFERENCES Tag(tagID),
	FOREIGN KEY (userID) REFERENCES User(userID),
	PRIMARY KEY (tagID, userID)
);

CREATE TABLE Chat(
	chatID INT AUTO_INCREMENT PRIMARY KEY,
	userID INT,
	chatName VARCHAR(32),
	FOREIGN KEY (userID) REFERENCES User(userID)
);

CREATE TABLE ChatMessage(
	chatMessageID INT AUTO_INCREMENT PRIMARY KEY,
	chatID INT,
	userID INT,
	messageText TEXT,
	TimeStampID INT,
	FOREIGN KEY (chatID) REFERENCES Chat(chatID),
	FOREIGN KEY (userID) REFERENCES User(userID),
	FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);

CREATE TABLE ChatMember(
	userID INT,
	chatID INT,
	FOREIGN KEY (userID) REFERENCES User(userID),
	FOREIGN KEY (chatID) REFERENCES Chat(chatID),
	PRIMARY KEY (userID, chatID)
);

CREATE TABLE Comment(
	commentID INT AUTO_INCREMENT PRIMARY KEY,
	userID INT,
	questionID INT,
	commentText TEXT,
	TimeStampID INT,
	FOREIGN KEY (questionID) REFERENCES Question(questionID),
	FOREIGN KEY (userID) REFERENCES User(userID),
	FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);

CREATE TABLE Question(
	questionID INT AUTO_INCREMENT PRIMARY KEY,
	userID INT,
	questionText TEXT,
	TimeStampID INT,
	upvotes INT DEFAULT 0 CHECK (upvotes >= 0), 
	downvotes INT DEFAULT 0 CHECK (downvotes >= 0),
	ENUM('draft', 'published', 'canceled') DEFAULT 'draft',
	FOREIGN KEY (userID) REFERENCES User(userID),
	FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);

CREATE TABLE Response(
	responseID INT AUTO_INCREMENT PRIMARY KEY,
	userID INT,
	responseText TEXT,
	TimeStampID INT,
	FOREIGN KEY (questionID) REFERENCES Question(questionID),
	FOREIGN KEY (userID) REFERENCES User(userID),
	FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);

CREATE TABLE TimeStamp( -- no foreign keys to avoid circular reference
	TimeStampID INT AUTO_INCREMENT PRIMARY KEY,
	sentTime TIME,
	sentDate DATE,
);

-- ADDITIONAL HELPER TABLES

-- table to handle chat requests
CREATE TABLE ChatRequest (
    requestID INT AUTO_INCREMENT PRIMARY KEY,
    fromUserID INT,
    toUserID INT,
    chatID INT,
    status VARCHAR(10),   -- ex. 'pending', 'accepted', 'rejected'
    TimeStampID INT,
    FOREIGN KEY (fromUserID) REFERENCES User(userID),
    FOREIGN KEY (toUserID) REFERENCES User(userID),
    FOREIGN KEY (chatID) REFERENCES Chat(chatID),
    FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);

-- table to log question-related actions (enter/exit)
CREATE TABLE QuestionLog (
    logID INT AUTO_INCREMENT PRIMARY KEY,
    userID INT,
    questionID INT,
    action VARCHAR(10),   -- 'enter' or 'exit'
    TimeStampID INT,
    FOREIGN KEY (userID) REFERENCES User(userID),
    FOREIGN KEY (questionID) REFERENCES Question(questionID),
    FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);

-- table to log chat-related actions (e.g., enter/exit)
CREATE TABLE ChatLog (
    logID INT AUTO_INCREMENT PRIMARY KEY,
    userID INT,
    chatID INT,
    action VARCHAR(10),   -- 'enter' or 'exit'
    TimeStampID INT,
    FOREIGN KEY (userID) REFERENCES User(userID),
    FOREIGN KEY (chatID) REFERENCES Chat(chatID),
    FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);

-- table to track who upvoted, prevents duplicate upvotes
CREATE TABLE QuestionUpvote (
	userID INT,
	questionID INT,
	PRIMARY KEY (userID, questionID),
	FOREIGN KEY (userID) REFERENCES User(userID),
	FOREIGN KEY (questionID) REFERENCES Question(questionID)
);

-- table to track who downvoted, prevents duplicate downvotes
CREATE TABLE QuestionDownvote (
	userID INT,
	questionID INT,
	PRIMARY KEY (userID, questionID),
	FOREIGN KEY (userID) REFERENCES User(userID),
	FOREIGN KEY (questionID) REFERENCES Question(questionID)
);

---------------------------------------------------------------------------------------
--                  POPULATE TABLES (10 entries per table)
---------------------------------------------------------------------------------------


---------------------------------------------------------------------------------
--                       QUESTION BASED PROCEDURES
---------------------------------------------------------------------------------
-- Create question in 'draft' mode
DELIMITER //
CREATE PROCEDURE StartQuestion(IN p_userID INT, IN p_questionText TEXT)
BEGIN
	-- Insert timestamp entry
	INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE());
	SET @tsID = LAST_INSERT_ID();

	-- Insert new question in 'draft' mode
	INSERT INTO Question (userID, questionText, TimeStampID, status)
	VALUES (p_userID, p_questionText, @tsID, 'draft');
END;
// 
DELIMITER ;

-- publish question
DELIMITER //
CREATE PROCEDURE PublishQuestion(IN p_questionID INT)
BEGIN
	-- Update status of question to be 'published'
	UPDATE Question
	SET status = 'published'
	WHERE questionID = p_questionID AND status = 'draft';
END;
//
DELIMITER ;

-- Cancel 'draft' question, not deleting it
DELIMITER //
CREATE PROCEDURE CancelQuestion(IN p_questionID INT)
BEGIN 
	-- Update status of question to be 'cancelled'
	UPDATE question
	SET status = 'canceled'
	WHERE questionID = p_questionID AND status = 'draft';
END;
//
DELIMITER ;

-- Delete question that is already 'published'
DELIMITER //
CREATE PROCEDURE DeleteQuestion(IN p_questionID INT)
BEGIN
	-- Check if question is 'published'
	IF (SELECT status FROM Question WHERE questionID = p_questionID) = 'published' THEN
		-- Delete related entries in dependent tables
		DELETE FROM Comment WHERE questionID = p_questionID,
		DELETE FROM Response WHERE questionID = p_questionID,
		DELETE FROM QuestionLog WHERE questionID = p_questionID,
		DELETE FROM QuestionUpvote WHERE questionID = p_questionID,
		DELETE FROM QuestionDownvote WHERE questionID = p_questionID,
		-- Delete question itself
		DELETE FROM Question WHERE questionID = p_questionID;
	END IF;
END;
//
DELIMITER;

-- LOG QUESTION "ENTER/EXIT" ACTIONS
DELIMITER //
CREATE PROCEDURE LogQuestionAction(IN p_userID INT, IN p_questionID INT, IN p_action VARCHAR(10))
BEGIN
	INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE());
	SET @tsID = LAST_INSERT_ID();

	INSERT INTO QuestionLog (userID, questionID, action, TimeStampID)
	VALUES (p_userID, p_questionID, p_action, @tsID);
END;
//
DELIMITER;


---------------------------------------------------------------------------------
--                          CHAT BASED PROCEDURES
---------------------------------------------------------------------------------

-- "CREATE CHAT" AND SEND CHAT REQUEST
DELIMITER //
CREATE PROCEDURE CreateChatAndRequest(IN p_fromUserID INT, IN p_chatName VARCHAR(32), IN p_toUserID INT)
BEGIN
	-- create new chat by sender
	INSERT INTO Chat (userID, chatName) VALUES (p_fromUserID, p_chatName);
	SET @newChatID = LAST_INSERT_ID();

	-- Automatically add creator as chat member
	INSERT INTO ChatMember (userID, chatID) VALUES (p_fromUserID, @newChatID);

	-- Create timestamp for request
	INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE());
	SET @tsID = LAST_INSERT_ID();

	-- Insert chat request with a 'pending' status
	INSERT INTO ChatRequest (fromUserID, toUserID, chatID, status, TimeStampID)
	VALUES (p_fromUserID, p_toUserID, @newChatID, 'pending', @tsID);
END;
//
DELIMITER;

-- TRIGGER TO AUTOMATICALLY ADD USER TO CHAT 
-- WHEN THEY ACCEPT CHAT REQUEST
DELIMITER //
CREATE TRIGGER AfterChatRequestAccepted
AFTER UPDATE ON ChatRequest
FOR EACH ROW 
BEGIN
	IF NEW.status = 'accepted' AND OLD.status <> 'accepted' THEN
		INSERT INTO ChatMember (userID, chatID)
		VALUES (NEW.toUserID, NEW.chatID);
	END IF;
END;
//
DELIMITER;

--	RETRIEVE CHAT NAME (BY CHATID)
DELIMITER //
CREATE PROCEDURE GetChatName(IN p_chatID INT)
BEGIN
	SELECT chatName FROM Chat Where chatID = p_chatID;
END;
//
DELIMITER;

-- TRIGGER TO AUTO-GENERATE TIMESTAMP FOR EACH CHATMESSAGE 
-- UPON INSERTION ('SEND')

DELIMITER //
CREATE TRIGGER BeforeInsertChatMessage
BEFORE INSERT ON ChatMessage
FOR EACH ROW 
BEGIN	
	IF NEW.TimeStampID IS NULL THEN
		INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE());
		SET NEW.TimeStampID = LAST_INSERT_ID();
	END IF;
END;
//
DELIMITER;

-- LOG CHAT "ENTER/EXIT" ACTIONS
DELIMITER // CREATE PROCEDURE LogChatAction(IN p_userID INT, IN p_chatID INT, IN p_action VARCHAR(10))
BEGIN
	INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE());
	SET @tsID = LAST_INSERT_ID();

	INSERT INTO ChatLog (userID, chatID, action, TimeStampID)
	VALUES (p_userID, p_chatID, p_action, @tsID);
END;
//
DELIMITER;


---------------------------------------------------------------------------------
--                          LOGIN PROCEDURES
---------------------------------------------------------------------------------
-- Insert New User
DELIMITER //
CREATE PROCEDURE InsertNewUser (
    IN p_username VARCHAR(16),
    IN p_password VARCHAR(32),
    IN p_firstName VARCHAR(32),
    IN p_lastName VARCHAR(32)
)
BEGIN
    INSERT INTO User (userName, password, firstName, lastName)
    VALUES (p_username, p_password, p_firstName, p_lastName);
END;
//
DELIMITER ;

-- Get User Credentials
-- Password not selected bc we use hashing on insert and check
DELIMITER //
CREATE PROCEDURE GetUserCredentials (
    IN p_username VARCHAR(16)
)
BEGIN
    SELECT userName, password
    FROM User
    WHERE userName = p_username;
END;
//
DELIMITER ;

-- Delete User by Username
DELIMITER //
CREATE PROCEDURE DeleteUserByUsername (
    IN p_username VARCHAR(16)
)
BEGIN
    DELETE FROM User
    WHERE userName = p_username;
END;
//
DELIMITER ;

-- Handle Delete on User to Update Tables
DELIMITER //	
CREATE TRIGGER after_user_deleted
AFTER DELETE ON User
FOR EACH ROW
BEGIN
    DELETE FROM TagList WHERE userID = OLD.userID;

    DELETE FROM Chat WHERE userID = OLD.userID;

    DELETE FROM ChatMessage WHERE userID = OLD.userID;

    DELETE FROM ChatMember WHERE userID = OLD.userID;

    DELETE FROM Comment WHERE userID = OLD.userID;

    DELETE FROM Question WHERE userID = OLD.userID;

    DELETE FROM Response WHERE userID = OLD.userID;

    DELETE FROM TimeStamp WHERE userID = OLD.userID;

    DELETE FROM ChatLog WHERE userID = OLD.userID;

    DELETE FROM QuestionUpvote WHERE userID = OLD.userID;

    DELETE FROM QuestionLog WHERE userID = OLD.userID;

    DELETE FROM ChatRequest WHERE fromUserID = OLD.userID OR toUserID = OLD.userID;

END;
//
DELIMITER ;

---------------------------------------------------------------------------------
--                          QUESTION POPULATION PROCEDURES
---------------------------------------------------------------------------------

-- Get Recent Questions
DELIMITER //
CREATE PROCEDURE GetRecentQuestions ()
BEGIN
    SELECT q.questionText, t.sentTime, t.sentDate
    FROM Question q
    JOIN TimeStamp t ON q.questionID = t.questionID
    ORDER BY t.sentDate DESC, t.sentTime DESC
    LIMIT 10;
END;
//
DELIMITER ;

-- Get Popular Questions
DELIMITER //
CREATE PROCEDURE GetPopularQuestions ()
BEGIN
    SELECT q.questionText, t.sentTime, t.sentDate,
		   q.upvotes, COUNT(c.commentID) AS commentCount
    FROM Question q
    JOIN TimeStamp t ON q.TimestampID = t.TimeStampID
    LEFT JOIN Comment c ON c.questionID = q.questionID
    GROUP BY q.questionID, q.questionText, t.sentTime, t.sentDate, q.upvotes
    ORDER BY q.upvotes DESC, commentCount DESC, t.sentDate DESC, t.sentTime DESC
    LIMIT 10;
END;
//
DELIMITER ;

-- Get Controversial Questions
DELIMITER //
CREATE PROCEDURE GetControversialQuestions ()
BEGIN
    SELECT q.questionText, t.sentTime, t.sentDate, 
		   q.downvotes, COUNT(c.commentID) AS commentCount,
		   (q.downvotes + COUNT(c.commentID)) AS controversyScore
    FROM Question q
    JOIN TimeStamp t ON q.TimeStampID = t.TimeStampID
    LEFT JOIN Comment c ON c.questionID = q.questionID
    GROUP BY q.questionID, q.questionText, t.sentTime, t.sentDate, q.downvotes
    ORDER BY controversyScore DESC, t.sentDate DESC, t.sentTime DESC
    LIMIT 10;
END;
//
DELIMITER ;

-- Get Relevant Questions
DELIMITER //
CREATE PROCEDURE GetRelevantQuestions (
    IN p_username VARCHAR(16)
)
BEGIN
    SELECT q.questionText, t.sentTime, t.sentDate
    FROM Question q
    JOIN TimeStamp t ON q.questionID = t.questionID
    JOIN TagList l ON q.questionID = l.questionID 
    WHERE q.tagID IN (SELECT tl.tagID FROM TagList tl JOIN User u ON tl.userID = u.userID WHERE u.userName = p_username)
    GROUP BY q.questionID, q.questionText, t.sentTime, t.sentDate
    ORDER BY count(*) DESC, t.sentDate DESC, t.sentTime DESC
    LIMIT 10;
END;
//
DELIMITER ;

-- users can upvote a question
DELIMITER //

CREATE PROCEDURE UpvoteQuestion(IN p_questionID INT, IN p_questionID INT)
BEGIN 
	-- check if user already upvoted this question
	IF NOT EXISTS (
		SELECT 1 FROM QuestionUpvote
		WHERE userID = p_userID AND questionID = p_questionID
	)
	THEN
		-- log upvote
		INSERT INTO QuestionUpvote (userID, questionID)
		VALUES (p_userID, p_questionID);
		-- increment upvote count
		UPDATE Question
		SET upvotes = upvotes + 1
		WHERE questionID = p_questionID;
	END IF;
END;
//
DELIMITER ;

-- users can downvote a question
DELIMITER //

CREATE PROCEDURE DownvoteQuestion(IN p_userID INT, IN p_questionID INT)
BEGIN
	-- check if user already downvoted this question
	IF NOT EXISTS (
		SELECT 1 FROM QuestionDownvoote
		WHERE userID = p_userID AND questionID = p_questionID
	)
	THEN
		-- log downvoate
		INSERT INTO QuestionDownvote (userID, questionID)
		VALUES (p_userID, p_questionID);

		-- increment downvote count
		UPDATE Question
		SET downvotes = downvotes + 1
		WHERE questionID = p_questionID;
	END IF;
END;
//
DELIMITER ;
---------------------------------------------------------------------------------
--                          User POPULATION PROCEDURES
---------------------------------------------------------------------------------

-- Get Users with Most Shared Tags
DELIMITER //
CREATE PROCEDURE GetSimilarUsersByTags (
    IN target_userID INT
)
BEGIN
    SELECT u.firstName, u.lastName
    FROM User u
    JOIN TagList t ON t.userID = u.userID
    WHERE u.userID <> target_userID 
    GROUP BY u.userID, u.firstName, u.lastName
    ORDER BY
        (SELECT COUNT(*)
         FROM TagList a
         WHERE a.userID = u.userID
           AND a.tagID IN (SELECT tagID FROM TagList WHERE userID = target_userID)) DESC
    LIMIT 4;
END;
//
DELIMITER ;

-- Get Chat Order By UserID
DELIMITER //
CREATE PROCEDURE GetChatIDsForUser (
    IN target_userID INT
)
BEGIN
    SELECT c.chatID
    FROM ChatLog c
    JOIN TimeStamp t ON c.TimeStampID = t.TimeStampID
    WHERE c.userID = target_userID
    ORDER BY t.sentTime DESC, t.sentDate DESC;
END;
//
DELIMITER ;
