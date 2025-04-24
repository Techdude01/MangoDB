-- Safe MySQL database creation script for MangoDB
-- This script creates tables, populates them with data, and creates stored procedures
-- use mysql -u root Mango < COMMANDSv2.sql
-- Create User table
CREATE TABLE `User` (
  userID INT AUTO_INCREMENT PRIMARY KEY,
  userName VARCHAR(16) UNIQUE,
  password VARCHAR(255) NOT NULL,
  firstName VARCHAR(32),
  lastName VARCHAR(32),
  role VARCHAR(50) NOT NULL DEFAULT 'user',
  CONSTRAINT CHK_UserRole CHECK (role IN ('user', 'anonymous', 'admin'))
);

-- Create Tag table
CREATE TABLE Tag (
  tagID INT AUTO_INCREMENT PRIMARY KEY,
  tagName VARCHAR(16) NOT NULL UNIQUE
);

-- Create TimeStamp table
CREATE TABLE TimeStamp( 
  TimeStampID INT AUTO_INCREMENT PRIMARY KEY,
  sentTime TIME,
  sentDate DATE
);

-- Create Question table before TagList (referenced by foreign key)
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

-- Create TagList junction table
CREATE TABLE TagList(
  tagID INT,
  questionID INT,
  userID INT,
  FOREIGN KEY (tagID) REFERENCES Tag(tagID),
  FOREIGN KEY (questionID) REFERENCES Question(questionID),
  FOREIGN KEY (userID) REFERENCES User(userID),
  PRIMARY KEY (tagID, questionID, userID)  
);

-- Create Chat table
CREATE TABLE Chat(
  chatID INT AUTO_INCREMENT PRIMARY KEY,
  userID INT,
  chatName VARCHAR(32),
  FOREIGN KEY (userID) REFERENCES User(userID)
);

-- Create Response table
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

-- Create Comment table
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

-- Create ChatMessage table
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

-- Create ChatMember junction table
CREATE TABLE ChatMember(
  userID INT,
  chatID INT,
  FOREIGN KEY (userID) REFERENCES User(userID),
  FOREIGN KEY (chatID) REFERENCES Chat(chatID),
  PRIMARY KEY (userID, chatID)
);

-- Chat request table
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

-- Chat log table
CREATE TABLE ChatLog (
  logID INT AUTO_INCREMENT PRIMARY KEY,
  userID INT,
  chatID INT,
  action VARCHAR(10),
  TimeStampID INT,
  FOREIGN KEY (userID) REFERENCES User(userID),
  FOREIGN KEY (chatID) REFERENCES Chat(chatID),
  FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);

-- Response log table
CREATE TABLE ResponseLog (
  logID INT AUTO_INCREMENT PRIMARY KEY,
  userID INT,
  responseID INT,
  action VARCHAR(10),
  TimeStampID INT,
  FOREIGN KEY (userID) REFERENCES User(userID),
  FOREIGN KEY (responseID) REFERENCES Response(responseID),
  FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);

-- Comment log table
CREATE TABLE CommentLog (
  logID INT AUTO_INCREMENT PRIMARY KEY,
  userID INT,
  commentID INT,
  action VARCHAR(10),
  TimeStampID INT,
  FOREIGN KEY (userID) REFERENCES User(userID),
  FOREIGN KEY (commentID) REFERENCES Comment(commentID),
  FOREIGN KEY (TimeStampID) REFERENCES TimeStamp(TimeStampID)
);

-- Vote table
CREATE TABLE Vote (
  voteID INT AUTO_INCREMENT PRIMARY KEY,
  userID INT,
  questionID INT,
  vote ENUM('up', 'down'),
  UNIQUE (userID, questionID),
  FOREIGN KEY (userID) REFERENCES User(userID),
  FOREIGN KEY (questionID) REFERENCES Question(questionID)
);

-- Insert user data
INSERT INTO User (userName, password, firstName, lastName, role) VALUES
('jdoe', 'password123', 'John', 'Doe', 'user'),
('asmith', 'securePass456', 'Alice', 'Smith', 'user'),
('bwayne', 'batman2025', 'Bruce', 'Wayne', 'user'),
('ckent', 'superman2025', 'Clark', 'Kent', 'user'),
('dprince', 'wonderWoman!', 'Diana', 'Prince', 'user'),
('pparker', 'sp1derman', 'Peter', 'Parker', 'user'),
('tstark', 'ironman3000', 'Tony', 'Stark','admin'),
('ssmith', 'spy123', 'Sam', 'Smith','user'),
('nbarton', 'hawkeye!', 'Natasha', 'Barton','user'),
('srogers', 'capShield1', 'Steve', 'Rogers', 'admin'),
('hpotter', 'magicPass1', 'Harry', 'Potter', 'user'),
('rwesley', 'foodLover99', 'Ron', 'Wesley', 'user'),
('hgranger', 'books!Smart', 'Hermione', 'Granger', 'user'),
('lskywalker', 'forceIsStrong', 'Luke', 'Skywalker', 'user'),
('hsolo', 'chewieBest', 'Han', 'Solo', 'user'),
('lobrien', 'transporter!', 'Miles', 'OBrien', 'user'),
('jpicard', 'makeItSo', 'Jean-Luc', 'Picard', 'admin'),
('kjaneway', 'coffeeNebula', 'Kathryn', 'Janeway', 'user'),
('anorris', 'walkerTexas', 'Chuck', 'Norris', 'user'),
('terminator', 'illBeBack', 'Arnold', 'Schwarzenegger', 'user');
 
-- Insert tag data
INSERT INTO Tag (tagName) VALUES
('tech'), ('lifestyle'), ('academics'), ('NYU Tandon'), ('raspberrypi'),
('fishhobbyists'), ('travel'), ('politics'), ('movies'), ('random'),
('programming'), ('databases'), ('comics'), ('fitness'), ('cooking'),
('gaming'), ('music'), ('science'), ('history'), ('art');
 
-- Insert timestamp data in batches
INSERT INTO `TimeStamp` (sentTime, sentDate) VALUES
('08:00:00', '2025-01-01'), ('09:10:00', '2025-01-02'), ('10:30:00', '2025-01-03'), ('11:15:00', '2025-01-04'), ('12:20:00', '2025-01-05'),
('13:00:00', '2025-01-06'), ('14:45:00', '2025-01-07'), ('15:30:00', '2025-01-08'), ('16:40:00', '2025-01-09'), ('17:25:00', '2025-01-10'),
('18:00:00', '2025-01-11'), ('19:10:00', '2025-01-12'), ('20:30:00', '2025-01-13'), ('21:15:00', '2025-01-14'), ('22:20:00', '2025-01-15'),
('23:00:00', '2025-01-16'), ('00:45:00', '2025-01-17'), ('01:30:00', '2025-01-18'), ('02:40:00', '2025-01-19'), ('03:25:00', '2025-01-20');

INSERT INTO `TimeStamp` (sentTime, sentDate) VALUES
('04:00:00', '2025-01-21'), ('05:10:00', '2025-01-22'), ('06:30:00', '2025-01-23'), ('07:15:00', '2025-01-24'), ('08:20:00', '2025-01-25'),
('09:00:00', '2025-01-26'), ('10:45:00', '2025-01-27'), ('11:30:00', '2025-01-28'), ('12:40:00', '2025-01-29'), ('13:25:00', '2025-01-30'),
('08:00:00', '2025-03-01'), ('08:15:00', '2025-03-02'), ('08:30:00', '2025-03-03'), ('08:45:00', '2025-03-04'), ('09:00:00', '2025-03-05'),
('09:15:00', '2025-03-06'), ('09:30:00', '2025-03-07'), ('09:45:00', '2025-03-08'), ('10:00:00', '2025-03-09'), ('10:15:00', '2025-03-10');

INSERT INTO `TimeStamp` (sentTime, sentDate) VALUES
('11:00:00', '2025-03-11'), ('11:10:00', '2025-03-12'), ('11:30:00', '2025-03-13'), ('11:15:00', '2025-03-14'), ('11:20:00', '2025-03-15'),
('11:00:00', '2025-03-16'), ('11:45:00', '2025-03-17'), ('11:30:00', '2025-03-18'), ('11:40:00', '2025-03-19'), ('11:25:00', '2025-03-20'),
('18:00:00', '2025-03-21'), ('19:10:00', '2025-03-22'), ('20:30:00', '2025-03-23'), ('21:15:00', '2025-03-24'), ('22:20:00', '2025-03-25'),
('23:00:00', '2025-03-26'), ('00:45:00', '2025-03-27'), ('01:30:00', '2025-03-28'), ('02:40:00', '2025-03-29'), ('03:25:00', '2025-03-30');

INSERT INTO `TimeStamp` (sentTime, sentDate) VALUES
('04:00:00', '2025-04-01'), ('05:10:00', '2025-04-02'), ('06:30:00', '2025-04-03'), ('07:15:00', '2025-04-04'), ('08:20:00', '2025-04-05'),
('09:00:00', '2025-04-06'), ('10:45:00', '2025-04-07'), ('11:30:00', '2025-04-08'), ('12:40:00', '2025-04-09'), ('13:25:00', '2025-04-10'),
('14:00:00', '2025-04-11'), ('14:15:00', '2025-04-12'), ('14:30:00', '2025-04-13'), ('14:45:00', '2025-04-14'), ('15:00:00', '2025-04-15'),
('15:15:00', '2025-04-16'), ('15:30:00', '2025-04-17'), ('15:45:00', '2025-04-18'), ('16:00:00', '2025-04-19'), ('16:15:00', '2025-04-20');

-- Insert question data
INSERT INTO Question (userID, questionText, TimeStampID, upvotes, downvotes, status) VALUES
(1,'What is the speed of light?',1, 0, 10, 'published'),
(2,'How to build a REST API?',2, 1, 9, 'published'),
(3,'What is the best sci-fi book?',3, 2, 8, 'published'),
(4,'Tips for staying fit?',4, 3, 7, 'published'),
(5,'Favorite Marvel character?',5, 4, 6, 'published'),
(6,'How to train for a marathon?',6, 5, 5, 'published'),
(7,'Whats the difference better INNER JOIN and LEFT JOIN?',7, 6, 4, 'published'),
(8,'Who lives in a pineapple under the sea?',8, 7, 3, 'published'),
(9,'What is up?',9, 8, 2, 'published'),
(10,'How to get better at chess?',10, 9, 1, 'published'),
(11,'Best spell for dueling?', 41, 15, 2, 'published'),
(12,'Where to find good snacks?', 42, 10, 1, 'published'),
(13,'How does the time-turner work?', 43, 25, 0, 'published'),
(14,'Is the Dark Side stronger?', 44, 5, 15, 'published'),
(15,'Fastest ship in the galaxy?', 45, 30, 3, 'published'),
(16,'Heisenberg compensator theory?', 46, 8, 1, 'draft'),
(17,'What is the Prime Directive?', 47, 22, 2, 'published'),
(18,'Best way to handle Borg?', 48, 18, 4, 'published'),
(19,'Can Chuck Norris divide by zero?', 49, 100, 0, 'published'),
(20,'Why does Skynet send Terminators back?', 50, 12, 6, 'published');

-- Insert taglist data
INSERT INTO TagList (tagID, questionID, userID) VALUES
(1,1,1), (2,2,2), (3,3,3), (4,4,4), (5,5,5), (3,6,6), (7,7,5), (4,8,8), (7,9,7), (8,10,9),
(11, 2, 1), (12, 7, 1), (18, 1, 1), (10, 9, 1),
(11, 2, 2), (14, 4, 2), (7, 7, 2), (17, 3, 2),
(13, 5, 3), (9, 8, 3), (20, 3, 3), (8, 10, 3),
(13, 5, 4), (18, 1, 4), (14, 4, 4), (9, 9, 4),
(13, 5, 5), (19, 3, 5), (14, 6, 5),
(13, 5, 6), (1, 1, 6), (18, 1, 6), (5, 5, 6),
(1, 2, 7), (11, 2, 7), (16, 16, 7), (10, 10, 7),
(15, 12, 8), (9, 8, 8), (2, 4, 8), (17, 9, 8),
(14, 6, 9), (19, 19, 9), (6, 8, 9), (11, 9, 9),
(19, 17, 10), (14, 4, 10), (13, 14, 10), (4, 8, 10),
(18, 11, 11), (13, 11, 11), (16, 13, 11), (9, 3, 11), (3, 11, 11),
(15, 12, 12), (6, 12, 12), (2, 2, 12), (10, 12, 12), (3, 6, 12),
(3, 13, 13), (18, 13, 13), (11, 7, 13), (12, 7, 13), (19, 17, 13),
(13, 14, 2), (18, 14, 14), (7, 15, 14), (9, 14, 13), (5, 15, 14),
(7, 15, 15), (10, 15, 15), (13, 14, 15), (1, 15, 15), (17, 5, 15),
(1, 16, 16), (11, 16, 16), (12, 16, 16), (18, 16, 16), (7, 17, 16),
(7, 17, 17), (18, 17, 17), (12, 7, 17), (19, 17, 17), (8, 10, 17),
(7, 18, 18), (18, 18, 18), (1, 16, 18), (15, 12, 18), (10, 18, 18),
(13, 19, 19), (9, 19, 19), (14, 19, 19), (4, 4, 19), (8, 8, 19),
(1, 20, 20), (11, 20, 20), (18, 20, 20), (16, 20, 20), (10, 15, 20),
(6, 1, 1), (17, 2, 3), (15, 3, 5), (16, 4, 8), (14, 5, 12),
(11, 6, 11), (12, 7, 9), (13, 8, 15), (10, 9, 17), (9, 10, 19),
(20, 1, 2), (20, 2, 4), (20, 4, 6), (20, 5, 8), (20, 6, 10);

-- Insert chat data
INSERT INTO Chat (userID, chatName) VALUES
(1, 'MangoDB'), (2, 'EG RAD'), (3, 'tomfoolery'), (4, 'benedict cumberpatch fans'), (5, 'pigeonreport'),
(6, 'peanuts'), (7, 'flabbergasted'), (8, 'my name is fred'), (9, 'bettafish owners'), (10, 'revit'),
(11, 'Wizarding World Fans'), (12, 'Snack Enthusiasts'), (13, 'Time Travel Debates'), (14, 'Star Wars Saga'), (15, 'Sci-Fi Ships'),
(16, 'Star Trek Tech'), (17, 'Federation Politics'), (18, 'Gaming Group'), (19, 'Action Movie Heroes'), (20, 'AI Concerns');

-- Insert response data
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
(10,10,'Play puzzles and practice',20, 'published'),
(11, 1, 'Faster than a Nimbus 2000!', 21, 'published'),
(12, 2, 'Maybe try PythonAnywhere?', 22, 'published'),
(13, 3, 'Foundation Series by Asimov is great too', 23, 'published'),
(14, 4, 'Jedi training helps!', 24, 'draft'),
(15, 5, 'Han Solo shot first!', 25, 'published'),
(16, 6, 'Chief OBrien could probably run one.', 26, 'published'),
(17, 7, 'One includes non-matching rows from the left table.', 27, 'published'),
(18, 8, 'Captain Janeway knows!', 28, 'canceled'),
(19, 9, 'The sky!', 29, 'published'),
(20, 10, 'Analyze grandmaster games.', 30, 'published');

-- Insert comment data 
INSERT INTO Comment (userID, questionID, commentText, TimeStampID, status) VALUES
(3, 1, 'Good question!', 1, 'published'), (4, 2, 'Helpful info.', 2, 'published'), (5, 3, 'Thanks for sharing.', 3, 'published'),
(6, 4, 'Clarify more?', 4, 'draft'), (7, 5, 'Great explanation.', 5, 'published'), (8, 6, 'Interesting.', 6, 'published'),
(9, 7, 'Did not know that.', 7, 'published'), (10, 8, 'Cool.', 8, 'published'), (1, 9, 'Thanks!', 9, 'published'),
(2, 10, 'Useful tip.', 10, 'canceled'),
(13, 1, 'Physics is fascinating!', 11, 'published'),
(14, 2, 'What about Node.js?', 12, 'published'),
(15, 3, 'I prefer Star Wars books.', 13, 'published'),
(16, 4, 'Running is key.', 14, 'draft'),
(17, 5, 'Jean-Luc Picard is my favorite captain.', 15, 'published'),
(18, 6, 'Pacing is crucial.', 16, 'published'),
(19, 7, 'Database joins are complex.', 17, 'published'),
(20, 8, 'Affirmative.', 18, 'published'),
(11, 9, 'Not much, studying spells.', 19, 'published'),
(12, 10, 'Practice makes perfect.', 20, 'canceled');

-- Insert chat message data
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
(10, 10, 'im getting fired...', 10),
(1, 11, 'Need help with MongoDB aggregation.', 11),
(2, 12, 'Did you check the voltage?', 12),
(3, 13, 'Anyone up for chess?', 13),
(4, 14, 'He looks good in that suit.', 14),
(5, 15, 'Pigeons are smarter than you think.', 15),
(6, 16, 'Boil em, mash em, stick em in a stew.', 16),
(7, 17, 'Just finished reading a great book.', 17),
(8, 18, 'Self-Driving Car development is accelerating.', 18),
(9, 19, 'My betta loves bloodworms.', 19),
(10, 20, 'Architecture models are complex.', 20);

-- Insert chat member data
INSERT INTO ChatMember (userID, chatID) VALUES
(1,1), (2,1), (3,2), (4,3), (5,4),
(6,5), (7,2), (8,5), (9,1), (10, 9),
(11, 11), (12, 12), (13, 13), (14, 14), (15, 15),
(16, 16), (17, 17), (18, 18), (19, 19), (20, 20);

-- Updated Vote data with more entries
INSERT INTO Vote (userID, questionID, vote) VALUES
(1, 1, 'up'), (2, 2, 'down'), (3, 3, 'up'), (4, 4, 'down'), (5, 5, 'up'),
(6, 6, 'up'), (7, 7, 'down'), (8, 8, 'up'), (9, 9, 'down'), (10, 10, 'up'),
(11, 11, 'up'), (12, 12, 'down'), (13, 13, 'up'), (14, 14, 'down'), (15, 15, 'up'),
(16, 16, 'up'), (17, 17, 'down'), (18, 18, 'up'), (19, 19, 'up'), (20, 20, 'down'),
(1, 19, 'up'), (2, 19, 'up'), (3, 19, 'up'), (4, 19, 'up'), (5, 19, 'up'),
(6, 19, 'up'), (7, 19, 'up'), (8, 19, 'up'), (9, 19, 'up'), (10, 19, 'up'),
(11, 19, 'up'), (12, 19, 'up'), (13, 19, 'up'), (14, 19, 'up'), (15, 19, 'up'),
(16, 19, 'up'), (17, 19, 'up'), (18, 19, 'up'), (20, 19, 'up'),
(1, 15, 'up'), (2, 15, 'up'), (3, 15, 'up'), (4, 15, 'up'), (5, 15, 'up'),
(6, 15, 'up'), (7, 15, 'up'), (8, 15, 'up'), (9, 15, 'up'), (10, 15, 'up'),
(11, 15, 'up'), (12, 15, 'up'), (13, 15, 'up'), (14, 15, 'up'), (16, 15, 'up'),
(17, 15, 'up'), (18, 15, 'up'), (19, 15, 'up'), (20, 15, 'up'),
(1, 13, 'up'), (2, 13, 'up'), (3, 13, 'up'), (4, 13, 'up'), (5, 13, 'up'),
(6, 13, 'up'), (7, 13, 'up'), (8, 13, 'up'), (9, 13, 'up'), (10, 13, 'up'),
(11, 13, 'up'), (12, 13, 'up'), (14, 13, 'up'), (15, 13, 'up'), (16, 13, 'up'),
(17, 13, 'up'), (18, 13, 'up'), (19, 13, 'up'), (20, 13, 'up'),
(1, 14, 'down'), (2, 14, 'down'), (3, 14, 'down'), (4, 14, 'down'), (5, 14, 'down'),
(6, 14, 'down'), (7, 14, 'down'), (8, 14, 'down'), (9, 14, 'down'), (10, 14, 'down'),
(11, 14, 'down'), (12, 14, 'down'), (13, 14, 'down'), (15, 14, 'down'),
(1, 11, 'up'), (2, 11, 'up'), (3, 11, 'up'), (4, 11, 'up'),
(5, 11, 'up'), (6, 11, 'up'), (7, 11, 'up'), (8, 11, 'up'),
(9, 11, 'up'), (10, 11, 'up'), (12, 11, 'up'), (13, 11, 'up'),
(14, 11, 'up'), (15, 11, 'up'), (16, 11, 'up'),
(2, 1, 'down'), (3, 1, 'down'), (4, 1, 'down'), (5, 1, 'down'),
(6, 1, 'down'), (7, 1, 'down'), (8, 1, 'down'), (9, 1, 'down'),
(10, 1, 'down'), (11, 1, 'down'), (12, 1, 'down'), (13, 1, 'down'),
(14, 1, 'down');

UPDATE Question q
SET q.upvotes = (
    SELECT COUNT(*) FROM Vote 
    WHERE questionID = q.questionID AND vote = 'up'
),
q.downvotes = (
    SELECT COUNT(*) FROM Vote 
    WHERE questionID = q.questionID AND vote = 'down'
)
WHERE 1=1;


-- Create stored procedures with proper delimiters
DELIMITER //
-- Create chat and send request procedure
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
END//

-- Trigger to add user to chat when request accepted
CREATE TRIGGER AfterChatRequestAccepted
AFTER UPDATE ON ChatRequest
FOR EACH ROW 
BEGIN
    IF NEW.status = 'accepted' AND OLD.status <> 'accepted' THEN
        INSERT INTO ChatMember (userID, chatID)
        VALUES (NEW.toUserID, NEW.chatID);
    END IF;
END//

-- Get chat name procedure
CREATE PROCEDURE GetChatName(IN p_chatID INT)
BEGIN
    SELECT chatName FROM Chat Where chatID = p_chatID;
END//

-- Trigger for chat message timestamp
CREATE TRIGGER BeforeInsertChatMessage
BEFORE INSERT ON ChatMessage
FOR EACH ROW 
BEGIN	
    IF NEW.TimeStampID IS NULL THEN
        INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE());
        SET NEW.TimeStampID = LAST_INSERT_ID();
    END IF;
END//

-- Log chat action procedure
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
END//

-- Insert new user procedure
CREATE PROCEDURE InsertNewUser (
    IN p_username VARCHAR(16),
    IN p_password VARCHAR(32),
    IN p_firstName VARCHAR(32),
    IN p_lastName VARCHAR(32)
)
BEGIN
    INSERT INTO User (userName, password, firstName, lastName)
    VALUES (p_username, p_password, p_firstName, p_lastName);
END//

-- Get user credentials procedure
CREATE PROCEDURE GetUserCredentials (
    IN p_username VARCHAR(16)
)
BEGIN
    SELECT userName, password
    FROM User
    WHERE userName = p_username;
END//

-- Delete user by username procedure
CREATE PROCEDURE DeleteUserByUsername (
    IN p_username VARCHAR(16)
)
BEGIN
    DELETE FROM User
    WHERE userName = p_username;
END//

-- Trigger for user deletion
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
    DELETE FROM Vote WHERE userID = OLD.userID;
    DELETE FROM ChatRequest WHERE fromUserID = OLD.userID OR toUserID = OLD.userID;
END//

-- Start question procedure
CREATE PROCEDURE StartQuestion(IN p_userID INT, IN p_questionText TEXT)
BEGIN
    -- Insert timestamp entry
    INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE());
    SET @tsID = LAST_INSERT_ID();

    -- Insert new question in 'draft' mode
    INSERT INTO Question (userID, questionText, TimeStampID, status)
    VALUES (p_userID, p_questionText, @tsID, 'draft');
END//

-- Publish question procedure
CREATE PROCEDURE PublishQuestion(IN p_questionID INT)
BEGIN
    -- Update status of question to be 'published'
    UPDATE Question
    SET status = 'published'
    WHERE questionID = p_questionID AND status = 'draft';
END//

-- Cancel question procedure
CREATE PROCEDURE CancelQuestion(IN p_questionID INT)
BEGIN 
    -- Update status of question to be 'cancelled'
    UPDATE Question
    SET status = 'canceled'
    WHERE questionID = p_questionID AND status = 'draft';
END//

-- Delete question procedure
CREATE PROCEDURE DeleteQuestion(IN p_questionID INT)
BEGIN
    -- Check if question is 'published'
    IF (SELECT status FROM Question WHERE questionID = p_questionID) = 'published' THEN
        -- Delete related entries in dependent tables
        DELETE FROM Comment WHERE questionID = p_questionID;
        DELETE FROM Response WHERE questionID = p_questionID;
        DELETE FROM Vote WHERE questionID = p_questionID;
        -- Delete question itself
        DELETE FROM Question WHERE questionID = p_questionID;
    END IF;
END//

-- Get recent questions with pagination procedure
CREATE PROCEDURE GetRecentQuestionsWithPagination (
    IN lim INT, IN offset INT
)
BEGIN
    SELECT q.questionID, u.userName, q.questionText, t.sentTime, t.sentDate
    FROM Question q
    JOIN TimeStamp t ON q.TimeStampID = t.TimeStampID
    JOIN User u ON q.userID = u.userID
    WHERE q.status = 'published'
    ORDER BY t.sentDate DESC, t.sentTime DESC
    LIMIT lim OFFSET offset;
END//

-- Get popular questions with pagination procedure
CREATE PROCEDURE GetPopularQuestionsWithPagination (
    IN lim INT, 
    IN offset INT
)
BEGIN
    SELECT q.questionID, u.userName, q.questionText, t.sentTime, t.sentDate, q.upvotes, COUNT(c.commentID) AS commentCount
    FROM Question q
    JOIN TimeStamp t ON q.TimeStampID = t.TimeStampID
    LEFT JOIN Comment c ON c.questionID = q.questionID
    JOIN User u ON q.userID = u.userID
    WHERE q.status = 'published'
    GROUP BY q.questionID, q.questionText, t.sentTime, t.sentDate, q.upvotes, u.userName
    ORDER BY q.upvotes DESC, commentCount DESC, t.sentDate DESC, t.sentTime DESC
    LIMIT lim OFFSET offset;
END//

-- Get controversial questions with pagination procedure
CREATE PROCEDURE GetControversialQuestionswithPagination (
    IN lim INT, IN offset INT
)
BEGIN
    SELECT q.questionID, u.userName, q.questionText, t.sentTime, t.sentDate, 
           q.downvotes, COUNT(c.commentID) AS commentCount,
           (q.downvotes + COUNT(c.commentID)) AS controversyScore
    FROM Question q
    JOIN TimeStamp t ON q.TimeStampID = t.TimeStampID
    LEFT JOIN Comment c ON c.questionID = q.questionID
    JOIN User u ON q.userID = u.userID
    WHERE q.status = 'published'
    GROUP BY q.questionID, q.questionText, t.sentTime, t.sentDate, q.downvotes, u.userName
    ORDER BY controversyScore DESC, t.sentDate DESC, t.sentTime DESC
    LIMIT lim OFFSET offset;
END//

-- Get relevant questions procedure
CREATE PROCEDURE GetRelevantQuestions (
    IN p_username VARCHAR(16)
)
BEGIN
    SELECT q.questionText, t.sentTime, t.sentDate
    FROM Question q
    JOIN TimeStamp t ON q.TimeStampID = t.TimeStampID
    JOIN TagList l ON q.questionID = l.questionID 
    WHERE l.tagID IN (SELECT tl.tagID FROM TagList tl JOIN User u ON tl.userID = u.userID WHERE u.userName = p_username)
    GROUP BY q.questionID, q.questionText, t.sentTime, t.sentDate
    ORDER BY count(*) DESC, t.sentDate DESC, t.sentTime DESC
    LIMIT 10;
END//

-- Get questions by tag procedure
CREATE PROCEDURE GetQuestionsByTag(IN p_tagName VARCHAR(16))
BEGIN
    SELECT DISTINCT q.questionID, q.questionText
    FROM Question q
    JOIN TagList t1 ON q.userID = t1.userID
    JOIN Tag t ON t1.tagID = t.tagID
    WHERE t.tagName = p_tagName;
END//

-- Search questions procedure
CREATE PROCEDURE SearchQuestions (IN p_keyword VARCHAR(100))
BEGIN
    SELECT questionID, questionText
    FROM Question
    WHERE questionText LIKE CONCAT ('%', p_keyword, '%');
END//

-- Upvote question procedure
CREATE PROCEDURE UpvoteQuestion(IN p_userID INT, IN p_questionID INT)
BEGIN 
    -- check if user already upvoted this question
    IF EXISTS (
    SELECT 1 FROM Vote
    WHERE userID = p_userID AND questionID = p_questionID
  ) THEN
    -- Update the vote to 'up' if it already exists
    UPDATE Vote
    SET vote = 'up'
    WHERE userID = p_userID AND questionID = p_questionID;
  ELSE
    -- Insert a new 'up' vote
    INSERT INTO Vote (userID, questionID, vote)
    VALUES (p_userID, p_questionID, 'up');
  END IF;

  -- Update the upvote count in the Question table
  UPDATE Question
  SET upvotes = (
    SELECT COUNT(*) FROM Vote
    WHERE questionID = p_questionID AND vote = 'up'
  )
  WHERE questionID = p_questionID;
END//

-- Downvote question procedure
CREATE PROCEDURE DownvoteQuestion(IN p_userID INT, IN p_questionID INT)
BEGIN
  -- Check if the user has already voted on this question
  IF EXISTS (
    SELECT 1 FROM Vote
    WHERE userID = p_userID AND questionID = p_questionID
  ) THEN
    -- Update the vote to 'down' if it already exists
    UPDATE Vote
    SET vote = 'down'
    WHERE userID = p_userID AND questionID = p_questionID;
  ELSE
    -- Insert a new 'down' vote
    INSERT INTO Vote (userID, questionID, vote)
    VALUES (p_userID, p_questionID, 'down');
  END IF;

  -- Update the downvote count in the Question table
  UPDATE Question
  SET downvotes = (
    SELECT COUNT(*) FROM Vote
    WHERE questionID = p_questionID AND vote = 'down'
  )
  WHERE questionID = p_questionID;
END//

-- Get similar users by tags procedure
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
END//

-- Get chat IDs for user procedure
CREATE PROCEDURE GetChatIDsForUser (
    IN target_userID INT
)
BEGIN
    SELECT DISTINCT c.chatID
    FROM ChatLog c
    JOIN TimeStamp t ON c.TimeStampID = t.TimeStampID
    WHERE c.userID = target_userID
    ORDER BY t.sentDate DESC, t.sentTime DESC;
END//

-- Get tags by user ID procedure
CREATE PROCEDURE GetTagsByUserID(IN p_userID INT)
BEGIN
    SELECT t.tagID, t.tagName
    FROM Tag t
    JOIN TagList tl ON t.tagID = tl.tagID
    WHERE tl.userID = p_userID
    GROUP BY t.tagID, t.tagName;
END//

-- Get questions by user ID procedure
CREATE PROCEDURE GetQuestionsByUserID(IN p_userID INT)
BEGIN
    SELECT q.questionID, q.questionText, q.upvotes, q.downvotes,
           t.sentDate, t.sentTime, 
           (SELECT COUNT(*) FROM Response r WHERE r.questionID = q.questionID) AS responseCount
    FROM Question q
    JOIN TimeStamp t ON q.TimeStampID = t.TimeStampID
    WHERE q.userID = p_userID AND q.status = 'published'
    ORDER BY t.sentDate DESC, t.sentTime DESC;
END//

-- Draft response procedure
CREATE PROCEDURE DraftResponse(IN p_userID INT, IN p_responseText TEXT)
BEGIN
   INSERT INTO TimeStamp (sentTime, sentDate) 
   VALUES (CURTIME(), CURDATE());
   SET @tsID = LAST_INSERT_ID();

   INSERT INTO Response (userID, responseText, TimeStampID)
   VALUES (p_userID, p_responseText, @tsID);
END//

-- Publish response procedure
CREATE PROCEDURE PublishResponse(IN p_responseID INT)
BEGIN
    -- Update status of question to be 'published'
    UPDATE Response
    SET status = 'published'
    WHERE responseID = p_responseID AND status = 'draft';
END//

-- Cancel response procedure
CREATE PROCEDURE CancelResponse(IN p_responseID INT)
BEGIN 
    UPDATE Response
    SET status = 'canceled'
    WHERE responseID = p_responseID AND status = 'draft';
END//

-- Valid response present procedure
CREATE PROCEDURE ValidResponse(IN p_userID INT, IN p_questionID INT, OUT p_hasResponded BOOLEAN)
BEGIN 
    IF EXISTS (SELECT 1 FROM Response WHERE userID = p_userID AND questionID = p_questionID) THEN
        SET p_hasResponded = TRUE;
    ELSE 
        SET p_hasResponded = FALSE;
    END IF;
END//

-- Retrieve responses procedure
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
END//

-- Trigger for response timestamp
CREATE TRIGGER BeforeInsertResponse
BEFORE INSERT ON Response
FOR EACH ROW
BEGIN
    IF NEW.TimeStampID IS NULL THEN 
        INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE());
        SET NEW.TimeStampID = LAST_INSERT_ID();
    END IF;
END//

-- Log response action procedure
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
END//

-- Draft comment procedure
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
END//

-- Publish comment procedure
CREATE PROCEDURE PublishComment(IN p_commentID INT)
BEGIN
    UPDATE Comment
    SET status = 'published'
    WHERE commentID = p_commentID AND status = 'draft';
END//

-- Cancel comment draft procedure
CREATE PROCEDURE CancelCommentDraft(IN p_commentID INT)
BEGIN
  UPDATE Comment
  SET status = 'canceled'
  WHERE commentID = p_commentID AND status = 'draft';
END//

-- Delete comment procedure
CREATE PROCEDURE CancelComment(IN p_commentID INT)
BEGIN
    DELETE FROM Comment WHERE commentID = p_commentID;
    DELETE FROM CommentLog WHERE commentID = p_commentID;
END//

-- Trigger for comment timestamp
CREATE TRIGGER BeforeInsertComment
BEFORE INSERT ON Comment
FOR EACH ROW
BEGIN
    IF NEW.TimeStampID IS NULL THEN 
        INSERT INTO TimeStamp (sentTime, sentDate) VALUES (CURTIME(), CURDATE());
        SET NEW.TimeStampID = LAST_INSERT_ID();
    END IF;
END//

-- Log comment action procedure
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
END//

DELIMITER ;