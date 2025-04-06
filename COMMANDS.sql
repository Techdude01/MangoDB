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
	FOREIGN KEY (userID) REFERENCES User(userID),
	FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);

CREATE TABLE Response(
	responseID INT AUTO_INCREMENT PRIMARY KEY,
	userID INT,
	responseText TEXT,
	TimeStampID INT,
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


---------------------------------------------------------------------------------------
--                  POPULATE TABLES (10 entries per table)
---------------------------------------------------------------------------------------


-- user entries
INSERT INTO User (userName, password, firstName, lastName) VALUES 
('jdoe', 'password123', 'John', 'Doe'),('asmith', 'securePass456', 'Alice', 'Smith'),
('bwayne', 'batman2025', 'Bruce', 'Wayne'),('ckent', 'superman2025', 'Clark', 'Kent'),
('dprince', 'wonderWoman!', 'Diana', 'Prince'),('pparker', 'sp1derman', 'Peter', 'Parker'),
('tstark', 'ironman3000', 'Tony', 'Stark'),('ssmith', 'spy123', 'Sam', 'Smith'),
('nbarton', 'hawkeye!', 'Natasha', 'Barton'),('srogers', 'capShield1', 'Steve', 'Rogers');

-- tag entries
INSERT INTO Tag (tagName) VALUES 
('tech'), ('lifestyle'), ('academics'), ('NYU Tandon'), ('raspberrypi'),
('fishhobbyists'), ('travel'), ('politics'), ('movies'), ('random');

-- taglist entries
INSERT INTO TagList (tagID, userID) VALUES
(1,1), (2,2), (3,3), (4,4), (5,5), 
(3,6), (7,7), (4,8), (7,9), (8,10);

-- chat entries
INSERT INTO Chat (userID, chatName) VALUES 
(1, 'MangoDB'), (2, 'EG RAD'), (3, 'tomfoolery'), (4, 'benedict cumberpatch fans'), (5, 'pigeonreport'),
(6, 'peanuts'), (7, 'flabbergasted'), (8, 'my name is fred'), (9, 'bettafish owners'), (10, 'revit');

-- chatmember entires
INSERT INTO ChatMember (userID, chatID) VALUES
(1,1), (2,1), (3,2), (4,3), (5,4),
(6,5), (7,2), (8,5), (9,1), (10, 9);

-- chatmessage entires
INSERT INTO ChatMessage (chatID, userID, messageText, TimeStampID) VALUES 
(1, 1, 'Project is due tomorrow!!', 1),(2, 2, 'i think i fried the arduino', 2),
(3, 3, 'Anyone playing tonight?', 3),(4, 4, 'his wifes so hot', 4),
(5, 5, 'can we feed them laxatives?', 5),(6, 6, 'oven roast is better ', 6),
(7, 7, 'Just chilling here.', 7),(8, 8, 'New tech trends?', 8),
(9, 9, 'tried hikari fancy guppy pellets', 9),(10, 10, 'im getting fired...', 10);

-- question entries
INSERT INTO Question (userID, questionText, TimeStampID) VALUES 
(1,'What is the speed of light?',1),(2,'How to build a REST API?',2),
(3,'What’s the best sci-fi book?',3),(4,'Tips for staying fit?',4),
(5,'Favorite Marvel character?',5),(6,'How to train for a marathon?',6),
(7,'Whats the difference better INNER JOIN and LEFT JOIN?',7),
(8,'Who lives in a pineapple under the sea?',8),(9,'What’s up?',9),
(10,'How to get better at chess?',10);

-- response entries
INSERT INTO Response (userID, responseText, TimeStampID) VALUES 
(1,'299,792,458 m/s',11),(2,'Use Flask or Express',12),
(3,'Dune by Frank Herbert',13),(4,'Consistency and diet',14),
(5,'Doctor Strange, obviously!',15),(6,'Run short distances daily',16),
(7,'Google is a great start',17),(8,'Spongebob Squarepants',18),
(9,'We may never know...',19),(10,'Play puzzles and practice',20);

-- comment entries
INSERT INTO Comment (userID, questionID, commentText, TimeStampID) VALUES 
(3, 1, 'Good question!', 1),(4, 2, 'Helpful info.', 2),
(5, 3, 'Thanks for sharing.', 3),(6, 4, 'Clarify more?', 4),
(7, 5, 'Great explanation.', 5),(8, 6, 'Interesting.', 6),
(9, 7, 'Didn’t know that.', 7),(10, 8, 'Cool.', 8),
(1, 9, 'Thanks!', 9),(2, 10, 'Useful tip.', 10);


-- timestamp entries
INSERT INTO TimeStamp (sentTime, sentDate) VALUES
('08:00:00', '2025-01-01'),('09:10:00', '2025-01-02'),('10:30:00', '2025-01-03'),
('11:15:00', '2025-01-04'),('12:20:00', '2025-01-05'),('13:00:00', '2025-01-06'),
('14:45:00', '2025-01-07'),('15:30:00', '2025-01-08'),('16:40:00', '2025-01-09'),
('17:25:00', '2025-01-10'),('18:00:00', '2025-01-11'),('19:10:00', '2025-01-12'),
('20:30:00', '2025-01-13'),('21:15:00', '2025-01-14'),('22:20:00', '2025-01-15'),
('23:00:00', '2025-01-16'),('00:45:00', '2025-01-17'),('01:30:00', '2025-01-18'),
('02:40:00', '2025-01-19'),('03:25:00', '2025-01-20'),('04:00:00', '2025-01-21'),
('05:10:00', '2025-01-22'),('06:30:00', '2025-01-23'),('07:15:00', '2025-01-24'),
('08:20:00', '2025-01-25'),('09:00:00', '2025-01-26'),('10:45:00', '2025-01-27'),
('11:30:00', '2025-01-28'),('12:40:00', '2025-01-29'),('13:25:00', '2025-01-30');
('08:00:00', '2025-03-01'),('08:15:00', '2025-03-02'),('08:30:00', '2025-03-03'),
('08:45:00', '2025-03-04'),('09:00:00', '2025-03-05'),('09:15:00', '2025-03-06'),
('09:30:00', '2025-03-07'),('09:45:00', '2025-03-08'),('10:00:00', '2025-03-09'),
('10:15:00', '2025-03-10');

-- chatrequest entries
INSERT INTO ChatRequest (fromUserID, toUserID, chatID, status, TimeStampID) VALUES
(3, 9, 5, 'pending', 31),(4, 10, 6, 'pending', 32),(2, 10, 5, 'pending', 33),(2, 6, 1, 'pending', 34),(1, 6, 3, 'pending', 35),
(3, 10, 10, 'pending', 36),(2, 10, 7, 'pending', 37),(5, 9, 8, 'pending', 38),(3, 7, 10, 'pending', 39),(4, 6, 6, 'pending', 40);

-- questionlog entries
INSERT INTO QuestionLog (userID, questionID, action, TimeStampID) VALUES
(4, 6, 'enter', 31),(2, 5, 'enter', 32),(2, 8, 'exit', 33),(7, 2, 'enter', 34),(8, 9, 'enter', 35),
(3, 10, 'enter', 36),(4, 2, 'exit', 37),(9, 3, 'exit', 38),(10, 2, 'exit', 39),(3, 2, 'exit', 40);

-- chatlog entries
INSERT INTO ChatLog (userID, chatID, action, TimeStampID) VALUES
(3, 4, 'enter', 31),(6, 7, 'exit', 32),(4, 8, 'enter', 33),(8, 2, 'exit', 34),(4, 9, 'exit', 35),
(3, 2, 'enter', 36),(7, 8, 'exit', 37),(9, 8, 'exit', 38),(4, 5, 'exit', 39),(10, 1, 'exit', 40);




---------------------------------------------------------------------------------
--                       QUESTION BASED PROCEDURES
---------------------------------------------------------------------------------
-- ASK QUESTION
DELIMITER //
CREATE PROCEDURE AskQuestion(IN p_userID INT, IN p_questionText TEXT)
BEGIN
	-- Insert timestamp entry
	INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE());
	SET @tsID = LAST_INSERT_ID();

	-- Insert new question
	INSERT INTO Question (userID, questionText, TimeStampID)
	VALUES (p_userID, p_questionText, @tsID);
END;
// 
DELIMITER;

-- CANCEL QUESTION
DELIMITER //
CREATE PROCEDURE CancelQuestion(IN p_questionID INT)
BEGIN
	DELETE FROM Question WHERE questionID = p_questionID;
END;
//
DELIMITER;

-- LOG QUESTION "ENTER/EXIT" ACTIONS
DELIMITER //
CREATE PROCEDURE LogQuestionAction(IN p_userID INT, IN p_questionID INT, IN p_action VARCHAR(10))
BEGIN
	INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CUREDATE());
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
    SELECT q.questionText, t.sentTime, t.sentDate
    FROM Question q
    JOIN TimeStamp t ON q.questionID = t.questionID
    JOIN Comment c ON c.questionID = q.questionID
    GROUP BY q.questionID, q.questionText, t.sentTime, t.sentDate
    ORDER BY q.upvotes DESC, COUNT(c.commentID) DESC, t.sentDate DESC, t.sentTime DESC
    LIMIT 10;
END;
//
DELIMITER ;

-- users can upvote a question
DELIMITER //

CREATE PROCEDURE UpvoteQuestion(IN p_questionID INT)
BEGIN 
	UPDATE Question
	SET upvotes = upvotes + 1
	WHERE questionID = p_questionID;
END;
//
DELIMITER ;

-- Get Controversial Questions
DELIMITER //
CREATE PROCEDURE GetControversialQuestions ()
BEGIN
    SELECT q.questionText, t.sentTime, t.sentDate
    FROM Question q
    JOIN TimeStamp t ON q.questionID = t.questionID
    JOIN Comment c ON c.questionID = q.questionID
    GROUP BY q.questionID, q.questionText, t.sentTime, t.sentDate
    ORDER BY q.downvotes DESC, COUNT(c.commentID) DESC, t.sentDate DESC, t.sentTime DESC
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

---------------------------------------------------------------------------------
--                          User POPULATION PROCEDURES
---------------------------------------------------------------------------------

