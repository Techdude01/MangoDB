-- put in each individually works the best
CREATE TABLE `User` (
  userID INT AUTO_INCREMENT PRIMARY KEY,
  userName VARCHAR(16) UNIQUE,
  password VARCHAR(32),
  firstName VARCHAR(32),
  lastName VARCHAR(32)
);


CREATE TABLE Tag (
  tagID INT AUTO_INCREMENT PRIMARY KEY,
  tagName VARCHAR(16) NOT NULL UNIQUE
);

CREATE TABLE TimeStamp( 
 TimeStampID INT AUTO_INCREMENT PRIMARY KEY,
 sentTime TIME,
 sentDate DATE
);

CREATE TABLE TagList(
 tagID INT,
 questionID INT,
 userID INT,
 FOREIGN KEY (tagID) REFERENCES Tag(tagID),
 FOREIGN KEY (questionID) REFERENCES Question(questionID),
 FOREIGN KEY (userID) REFERENCES User(userID),
 PRIMARY KEY (tagID, userID)
);

CREATE TABLE Chat(
 chatID INT AUTO_INCREMENT PRIMARY KEY,
 userID INT,
 chatName VARCHAR(32),
 FOREIGN KEY (userID) REFERENCES User(userID)
);

CREATE TABLE Question (
  questionID INT AUTO_INCREMENT PRIMARY KEY,
  userID INT,
  questionText TEXT,
  TimeStampID INT,
  tagID INT,
  upvotes INT DEFAULT 0 CHECK (upvotes >= 0),
  downvotes INT DEFAULT 0 CHECK (downvotes >= 0),
  status ENUM('draft', 'published', 'canceled') DEFAULT 'draft',
  FOREIGN KEY (userID) REFERENCES User(userID),
  FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID),
  FOREIGN KEY (tagID) REFERENCES Tag(tagID)
);

CREATE TABLE Response (
  responseID INT AUTO_INCREMENT PRIMARY KEY,
  userID INT,
  questionID INT,
  responseText TEXT,
  TimeStampID INT,
  status ENUM('draft', 'published', 'canceled') DEFAULT 'draft',
  FOREIGN KEY (questionID) REFERENCES Question(questionID),
  FOREIGN KEY (userID) REFERENCES User(userID),
  FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);


CREATE TABLE Comment(
 commentID INT AUTO_INCREMENT PRIMARY KEY,
 userID INT,
 questionID INT,
 commentText TEXT,
 TimeStampID INT,
    status ENUM('draft', 'published', 'canceled') DEFAULT 'draft',
 FOREIGN KEY (questionID) REFERENCES Question(questionID),
 FOREIGN KEY (userID) REFERENCES User(userID),
 FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
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

-- ADDITIONAL HELPER TABLES

-- table to handle chat requests
CREATE TABLE ChatRequest (
  requestID INT AUTO_INCREMENT PRIMARY KEY,
  fromUserID INT,
  toUserID INT,
  chatID INT,
  status ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending',
  TimeStampID INT,
  FOREIGN KEY (fromUserID) REFERENCES `User`(userID),
  FOREIGN KEY (toUserID) REFERENCES `User`(userID),
  FOREIGN KEY (chatID) REFERENCES Chat(chatID),
  FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);


-- table to log chat-related actions (e.g., enter/exit)
CREATE TABLE ChatLog (
 logID INT AUTO_INCREMENT PRIMARY KEY,
 userID INT,
 chatID INT,
 action VARCHAR(10), -- 'enter' or 'exit'
 TimeStampID INT,
 FOREIGN KEY (userID) REFERENCES User(userID),
 FOREIGN KEY (chatID) REFERENCES Chat(chatID),
 FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);
-- table to log Response based actions
CREATE TABLE ResponseLog (
 logID INT AUTO_INCREMENT PRIMARY KEY,
 userID INT,
 responseID INT,
 action VARCHAR(10), -- 'enter' or 'exit'
 TimeStampID INT,
 FOREIGN KEY (userID) REFERENCES User(userID),
 FOREIGN KEY (responseID) REFERENCES Response(responseID),
 FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);

-- table to log Comment based actions
CREATE TABLE CommentLog (
 logID INT AUTO_INCREMENT PRIMARY KEY,
 userID INT,
 commentID INT,
 action VARCHAR(10), -- 'enter' or 'exit'
 TimeStampID INT,
 FOREIGN KEY (userID) REFERENCES User(userID),
 FOREIGN KEY (commentID) REFERENCES Comment(commentID),
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



--                  POPULATE TABLES (10 entries per table)

-- user entries

INSERT INTO User (userName, password, firstName, lastName) VALUES 
('jdoe', 'password123', 'John', 'Doe'),
('asmith', 'securePass456', 'Alice', 'Smith'),
('bwayne', 'batman2025', 'Bruce', 'Wayne'),
('ckent', 'superman2025', 'Clark', 'Kent'),
('dprince', 'wonderWoman!', 'Diana', 'Prince'),
('pparker', 'sp1derman', 'Peter', 'Parker'),
('tstark', 'ironman3000', 'Tony', 'Stark'),
('ssmith', 'spy123', 'Sam', 'Smith'),
('nbarton', 'hawkeye!', 'Natasha', 'Barton'),
('srogers', 'capShield1', 'Steve', 'Rogers');
 
-- tag entries
INSERT INTO Tag (tagName) VALUES 
('tech'), 
('lifestyle'), 
('academics'), 
('NYU Tandon'), 
('raspberrypi'),
('fishhobbyists'), 
('travel'), 
('politics'), 
('movies'), 
('random');
 
-- timestamp entries
-- input 20 rows first and then the other 20 rows or else there might be an error
INSERT INTO `TimeStamp` (sentTime, sentDate) VALUES
('08:00:00', '2025-01-01'),
('09:10:00', '2025-01-02'),
('10:30:00', '2025-01-03'),
('11:15:00', '2025-01-04'),
('12:20:00', '2025-01-05'),
('13:00:00', '2025-01-06'),
('14:45:00', '2025-01-07'),
('15:30:00', '2025-01-08'),
('16:40:00', '2025-01-09'),
('17:25:00', '2025-01-10'),
('18:00:00', '2025-01-11'),
('19:10:00', '2025-01-12'),
('20:30:00', '2025-01-13'),
('21:15:00', '2025-01-14'),
('22:20:00', '2025-01-15'),
('23:00:00', '2025-01-16'),
('00:45:00', '2025-01-17'),
('01:30:00', '2025-01-18'),
('02:40:00', '2025-01-19'),
('03:25:00', '2025-01-20'),
('04:00:00', '2025-01-21'),
('05:10:00', '2025-01-22'),
('06:30:00', '2025-01-23'),
('07:15:00', '2025-01-24'),
('08:20:00', '2025-01-25'),
('09:00:00', '2025-01-26'),
('10:45:00', '2025-01-27'),
('11:30:00', '2025-01-28'),
('12:40:00', '2025-01-29'),
('13:25:00', '2025-01-30'),
('08:00:00', '2025-03-01'),
('08:15:00', '2025-03-02'),
('08:30:00', '2025-03-03'),
('08:45:00', '2025-03-04'),
('09:00:00', '2025-03-05'),
('09:15:00', '2025-03-06'),
('09:30:00', '2025-03-07'),
('09:45:00', '2025-03-08'),
('10:00:00', '2025-03-09'),
('10:15:00', '2025-03-10');



-- taglist entries
INSERT INTO TagList (tagID, questionID) VALUES
(1,1), 
(2,2), 
(3,3), 
(4,4), 
(5,5), 
(3,6), 
(7,7), 
(4,8), 
(7,9), 
(8,10);

-- chat entries
INSERT INTO Chat (userID, chatName) VALUES 
(1, 'MangoDB'), 
(2, 'EG RAD'), 
(3, 'tomfoolery'), 
(4, 'benedict cumberpatch fans'), 
(5, 'pigeonreport'),
(6, 'peanuts'), 
(7, 'flabbergasted'), 
(8, 'my name is fred'), 
(9, 'bettafish owners'), 
(10, 'revit');

-- question entries
INSERT INTO Question (userID, questionText, TimeStampID, upvotes, downvotes, status) VALUES 
(1,'What is the speed of light?',1, 0, 10, 'published'),
(2,'How to build a REST API?',2, 1, 9, 'published'),
(3,'What’s the best sci-fi book?',3, 2, 8, 'published'),
(4,'Tips for staying fit?',4, 3, 7, 'published'),
(5,'Favorite Marvel character?',5, 4, 6, 'published'),
(6,'How to train for a marathon?',6, 5, 5, 'published'),
(7,'Whats the difference better INNER JOIN and LEFT JOIN?',7, 6, 4, 'published'),
(8,'Who lives in a pineapple under the sea?',8, 7, 3, 'published'),
(9,'What’s up?',9, 8, 2, 'published'),
(10,'How to get better at chess?',10, 9, 1, 'published');
 
-- response entries
INSERT INTO Response (userID, questionID, responseText, TimeStampID, status) VALUES 
(1,1,'299,792,458 m/s',11, 'draft'),
(2,2,'Use Flask or Express',12, 'draft'),
(3,3,'Dune by Frank Herbert',13, 'published'),
(4,4,'Consistency and diet',14, 'published'),
(5,5,'Doctor Strange, obviously!',15, 'published'),
(6,6,'Run short distances daily',16, 'draft'),
(7,7,'Google is a great start',17, 'published'),
(8,8,'Spongebob Squarepants',18, 'canceled'),
(9,9,'We may never know...',19, 'published'),
(10,10,'Play puzzles and practice',20, 'published');
 
 -- comment entries
INSERT INTO Comment (userID, questionID, commentText, TimeStampID, status) VALUES 
(3, 1, 'Good question!', 1, 'published'),
(4, 2, 'Helpful info.', 2, 'published'),
(5, 3, 'Thanks for sharing.', 3, 'published'),
(6, 4, 'Clarify more?', 4, 'draft'),
(7, 5, 'Great explanation.', 5, 'published'),
(8, 6, 'Interesting.', 6, 'published'),
(9, 7, 'Didn’t know that.', 7, 'published'),
(10, 8, 'Cool.', 8, 'published'),
(1, 9, 'Thanks!', 9, 'published'),
(2, 10, 'Useful tip.', 10, 'canceled');


-- chatmessage entires
INSERT INTO ChatMessage (chatID, userID, messageText, TimeStampID) VALUES 
(1, 1, 'Project is due tomorrow!!', 1),
(2, 2, 'i think i fried the arduino', 2),
(3, 3, 'Anyone playing tonight?', 3),
(4, 4, 'his wifes so hot', 4),
(5, 5, 'can we feed them laxatives?', 5),
(6, 6, 'oven roast is better ', 6),
(7, 7, 'Just chilling here.', 7),
(8, 8, 'New tech trends?', 8),
(9, 9, 'tried hikari fancy guppy pellets', 9),
(10, 10, 'im getting fired...', 10);
 
-- chatmember entires
INSERT INTO ChatMember (userID, chatID) VALUES
(1,1), 
(2,1), 
(3,2), 
(4,3), 
(5,4),
(6,5), 
(7,2), 
(8,5), 
(9,1), 
(10, 9);

-- chatrequest entries
INSERT INTO ChatRequest (fromUserID, toUserID, chatID, status, TimeStampID) VALUES
(3, 9, 5, 'pending', 31),
(4, 10, 6, 'pending', 32),
(2, 10, 5, 'pending', 33),
(2, 6, 1, 'pending', 34),
(1, 6, 3, 'pending', 35),
(3, 10, 10, 'pending', 36),
(2, 10, 7, 'pending', 37),
(5, 9, 8, 'pending', 38),
(3, 7, 10, 'pending', 39),
(4, 6, 6, 'pending', 40);

-- chatlog entries
INSERT INTO ChatLog (userID, chatID, action, TimeStampID) VALUES
(3, 4, 'enter', 31),
(6, 7, 'exit', 32),
(4, 8, 'enter', 33),
(8, 2, 'exit', 34),
(4, 9, 'exit', 35),
(3, 2, 'enter', 36),
(7, 8, 'exit', 37),
(9, 8, 'exit', 38),
(4, 5, 'exit', 39),
(10, 1, 'exit', 40);

-- QuestionUpvote entries
INSERT INTO QuestionUpvote (userID, questionID) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10);

-- QuestionDownvote entries
INSERT INTO QuestionDownvote (userID, questionID) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10);




--                          CHAT BASED PROCEDURES


-- "CREATE CHAT" AND SEND CHAT REQUEST
DELIMITER //
CREATE PROCEDURE CreateChatAndRequest(
	IN p_fromUserID INT, 
	IN p_chatName VARCHAR(32), 
	IN p_toUserID INT)
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
DELIMITER // 
CREATE PROCEDURE LogChatAction(
	IN p_userID INT, 
	IN p_chatID INT, 
	IN p_action VARCHAR(10))
BEGIN
	INSERT INTO TimeStamp (sentTime, sentDate) 
	VALUES (CURTIME(), CURDATE());
	SET @tsID = LAST_INSERT_ID();

	INSERT INTO ChatLog (userID, chatID, action, TimeStampID)
	VALUES (p_userID, p_chatID, p_action, @tsID);
END;
//
DELIMITER;




--                          LOGIN PROCEDURES


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
CREATE TRIGGER OnUserDelete
AFTER DELETE ON User
FOR EACH ROW
BEGIN
    DELETE FROM Chat WHERE userID = OLD.userID;

    DELETE FROM ChatMessage WHERE userID = OLD.userID;

    DELETE FROM ChatMember WHERE userID = OLD.userID;

    DELETE FROM Comment WHERE userID = OLD.userID;

    DELETE FROM Question WHERE userID = OLD.userID;

    DELETE FROM Response WHERE userID = OLD.userID;

    DELETE FROM TimeStamp WHERE userID = OLD.userID;

    DELETE FROM ChatLog WHERE userID = OLD.userID;

	DELETE FROM ResponseLog WHERE userID = OLD.userID;

    DELETE FROM CommentLog WHERE userID = OLD.userID;

    DELETE FROM QuestionUpvote WHERE userID = OLD.userID;

	DELETE FROM QuestionDownvote WHERE userID = OLD.userID;

    DELETE FROM ChatRequest WHERE fromUserID = OLD.userID OR toUserID = OLD.userID;

END;
//
DELIMITER ;



--                       QUESTION BASED PROCEDURES


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
	UPDATE Question
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
		DELETE FROM Comment WHERE questionID = p_questionID;

		DELETE FROM Response WHERE questionID = p_questionID;

		DELETE FROM QuestionUpvote WHERE questionID = p_questionID;

		DELETE FROM QuestionDownvote WHERE questionID = p_questionID;

		-- Delete question itself
		DELETE FROM Question WHERE questionID = p_questionID;
	END IF;
END;
//
DELIMITER;


--                          QUESTION POPULATION PROCEDURES


-- Get Recent Questions
DELIMITER //
CREATE PROCEDURE GetRecentQuestionsWithPagination (
	IN limit INT, IN offset INT
)
BEGIN
    SELECT q.questionID, q.questionText, t.sentTime, t.sentDate
    FROM Question q
    JOIN TimeStamp t ON q.TimeStampID = t.TimeStampID
    ORDER BY t.sentDate DESC, t.sentTime DESC
    LIMIT limit OFFSET offset;
END;
//
DELIMITER ;


-- Get Popular Questions
DELIMITER //
CREATE PROCEDURE GetPopularQuestionsWithPagination (
	IN limit INT, IN offset INT
)
BEGIN
    SELECT q.questionText, t.sentTime, t.sentDate,
		   q.upvotes, COUNT(c.commentID) AS commentCount
    FROM Question q
    JOIN TimeStamp t ON q.TimestampID = t.TimeStampID
    LEFT JOIN Comment c ON c.questionID = q.questionID
    GROUP BY q.questionID, q.questionText, t.sentTime, t.sentDate, q.upvotes
    ORDER BY q.upvotes DESC, commentCount DESC, t.sentDate DESC, t.sentTime DESC
    LIMIT limit OFFSET offset;
END;
//
DELIMITER ;


-- Get Controversial Questions
DELIMITER //
CREATE PROCEDURE GetControversialQuestionswithPagination (
	IN limit INT, IN offset INT
)
BEGIN
    SELECT q.questionText, t.sentTime, t.sentDate, 
		   q.downvotes, COUNT(c.commentID) AS commentCount,
		   (q.downvotes + COUNT(c.commentID)) AS controversyScore
    FROM Question q
    JOIN TimeStamp t ON q.TimeStampID = t.TimeStampID
    LEFT JOIN Comment c ON c.questionID = q.questionID
    GROUP BY q.questionID, q.questionText, t.sentTime, t.sentDate, q.downvotes
    ORDER BY controversyScore DESC, t.sentDate DESC, t.sentTime DESC
    LIMIT limit OFFSET offset;
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


-- Find questions related to tags that user follows
DELIMITER //
CREATE PROCEDURE GetQuestionsByTag(IN p_tagName VARCHAR(16))
BEGIN
	SELECT DISTINCT q.questionID, q.questionText
	FROM Question q
	JOIN TagList t1 ON q.userID = t1.userID
	JOIN Tag t ON t1.tagID = t.tagID
	WHERE t.tagName = p_tagName;
END;
//
DELIMITER ;


-- Search for questions by keyword
DELIMITER //
CREATE PROCEDURE SearchQuestions (IN p_keyword VARCHAR(100))
BEGIN
	SELECT questionID, questionText
	FROM Question
	WHERE questionText LIKE CONCAT ('%', p_keyword, '%');
END;
// 
DELIMITER ;


-- users can upvote a question
DELIMITER //

CREATE PROCEDURE UpvoteQuestion(IN p_questionID INT, IN p_userID INT)
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
  IF NOT EXISTS (
    SELECT 1 FROM QuestionDownvote
    WHERE userID = p_userID AND questionID = p_questionID
  ) THEN
    INSERT INTO QuestionDownvote (userID, questionID)
    VALUES (p_userID, p_questionID);

    UPDATE Question
    SET downvotes = downvotes + 1
    WHERE questionID = p_questionID;
  END IF;
END;
//
DELIMITER ;

--                          User POPULATION PROCEDURES


-- Get Users with Most Shared Tags
DELIMITER //
CREATE PROCEDURE GetSimilarUsersByTags (
    IN target_userID INT
)
BEGIN
    SELECT u.firstName, u.lastName, COUNT(*) as sharedTags
    FROM User u
    JOIN TagList t ON t.userID = u.userID
    WHERE u.userID <> target_userID 
		AND t.tagID IN (
			SELECT tagID
			FROM TagList
			WHERE userID = target_userID
		)
    GROUP BY u.userID, u.firstName, u.lastName
    ORDER BY sharedTags DESC
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
    SELECT DISTINCT c.chatID
    FROM ChatLog c
    JOIN TimeStamp t ON c.TimeStampID = t.TimeStampID
    WHERE c.userID = target_userID
    ORDER BY t.sentDate DESC, t.sentTime DESC;
END;
//
DELIMITER;


--                       RESPONSE BASED PROCEDURES

-- DRAFT RESPONSE
DELIMITER //
CREATE PROCEDURE DraftResponse(IN p_userID INT, IN p_responseText TEXT)
BEGIN
   INSERT INTO TimeStamp (sentTime, sentDate) 
   VALUES (CURTIME(), CURDATE());
   SET @tsID = LAST_INSERT_ID();

   INSERT INTO Response (userID, responseText, TimeStampID)
   VALUES (p_userID, p_responseText, @tsID);
END;
//
DELIMITER;

-- PUBLISH RESPONSE
DELIMITER //
CREATE PROCEDURE PublishResponse(IN p_responseID INT)
BEGIN
	-- Update status of question to be 'published'
	UPDATE Response
	SET status = 'published'
	WHERE responseID = p_responseID AND status = 'draft';
END;
//
DELIMITER;

-- CANCEL RESPONSE
DELIMITER //
CREATE PROCEDURE CancelResponse(IN p_responseID INT)
BEGIN 
	UPDATE Response
	SET status = 'canceled'
	WHERE responseID = p_responseID AND status = 'draft';
END;
//
DELIMITER;


-- VALID RESPONSE PRESENT?
DELIMITER // 
CREATE PROCEDURE ValidResponse(IN p_userID INT, IN p_questionID INT, OUT p_hasResponded BOOLEAN)
BEGIN 
	IF EXISTS (SELECT 1 FROM Response WHERE userID = p_userID AND questionID = p_questionID) THEN
		SET p_hasResponded = TRUE;
	ELSE 
		SET p_hasResponded = FALSE;
	END IF;
END; 
//
DELIMITER;

-- RETRIEVE RESPONSES
DELIMITER //
CREATE PROCEDURE RetrieveResponses(
  IN p_userID INT,
  IN p_questionID INT,
  OUT p_hasResponse BOOLEAN
)
BEGIN 
  CALL ValidResponse(p_userID, p_questionID, p_hasResponse);

  IF p_hasResponse THEN
    SELECT * FROM Response WHERE questionID = p_questionID;
  ELSE 
    SELECT 'This user has not responded to this question yet!' AS message;
  END IF;
END;
//
DELIMITER ;


-- TRIGGER TO AUTO-GENERATE TIMESTAMP FOR EACH RESPONSE
-- UPON INSERTION ('POST)
DELIMITER //
CREATE TRIGGER BeforeInsertResponse
BEFORE INSERT ON Response
FOR EACH ROW
BEGIN
	IF NEW.TimeStampID IS NULL THEN 
		INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE());
		SET NEW.TimeStampID = LAST_INSERT_ID();
	END IF;
END;
//
DELIMITER; 

-- LOG RESPONSE ACTIONS
DELIMITER //
CREATE PROCEDURE LogResponseAction(
  IN p_userID INT,
  IN p_responseID INT,
  IN p_action VARCHAR(10)
)
BEGIN
  INSERT INTO TimeStamp(sentTime, sentDate)
  VALUES (CURTIME(), CURDATE());
  SET @tsID = LAST_INSERT_ID();

  INSERT INTO ResponseLog (userID, responseID, action, TimeStampID)
  VALUES (p_userID, p_responseID, p_action, @tsID);
END;
//
DELIMITER ;



--                       COMMENT BASED PROCEDURES

-- DRAFT COMMENT
DELIMITER //
CREATE PROCEDURE DraftComment(
  IN p_userID INT,
  IN p_questionID INT,
  IN p_commentText TEXT
)
BEGIN
  INSERT INTO TimeStamp (sentTime, sentDate)
  VALUES (CURTIME(), CURDATE());
  SET @tsID = LAST_INSERT_ID();

  INSERT INTO Comment (userID, questionID, commentText, TimeStampID, status)
  VALUES (p_userID, p_questionID, p_commentText, @tsID, 'draft');
END;
//
DELIMITER ;


-- PUBLISH COMMENT
DELIMITER //
CREATE PROCEDURE PublishComment(IN p_commentID INT)
BEGIN
	UPDATE Comment
	SET status = 'published'
	WHERE commentID = p_commentID AND status = 'draft';
END;
//
DELIMITER ;

-- CANCEL COMMENT
DELIMITER //
CREATE PROCEDURE CancelCommentDraft(IN p_commentID INT)
BEGIN
	  UPDATE Comment
	  SET status = 'canceled'
	  WHERE commentID = p_commentID AND status = 'draft';
END;
//
DELIMITER ;

-- DELETE COMMENT
DELIMITER //
CREATE PROCEDURE CancelComment(IN p_commentID INT)
BEGIN
	DELETE FROM Comment WHERE commentID = p_commentID;
	DELETE FROM TimeStamp WHERE commentID = p_commentID;
END;
//
DELIMITER;

-- TRIGGER TO AUTO-GENERATE TIMESTAMP FOR EACH COMMENT
-- UPON INSERTION ('POST)
DELIMITER //
CREATE TRIGGER BeforeInsertComment
BEFORE INSERT ON Comment
FOR EACH ROW
BEGIN
	IF NEW.TimeStampID IS NULL THEN 
		INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE());
		SET NEW.TimeStampID = LAST_INSERT_ID();
	END IF;
END;
//
DELIMITER; 

-- LOG RESPONSE "ENTER/EXIT" ACTIONS
DELIMITER //
CREATE PROCEDURE LogCommentAction(
  IN p_userID INT,
  IN p_commentID INT,
  IN p_action VARCHAR(10)
)
BEGIN
  INSERT INTO TimeStamp(sentTime, sentDate)
  VALUES (CURTIME(), CURDATE());
  SET @tsID = LAST_INSERT_ID();

  INSERT INTO CommentLog(userID, commentID, action, TimeStampID)
  VALUES (p_userID, p_commentID, p_action, @tsID);
END;
//
DELIMITER ;
