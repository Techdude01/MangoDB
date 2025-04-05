CREATE TABLE User(
	userID INT AUTO_INCREMENT PRIMARY KEY,
	userName VARCHAR(16),
	password VARCHAR(32),
	firstName VARCHAR(32),
	lastName VARCHAR(32)
);

CREATE TABLE Tag(
	tagID INT AUTO_INCREMENT PRIMARY KEY,
	tagName VARCHAR(16)
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


-- populate tables (10 entries per table)

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

-- question entries
INSERT INTO Question (userID, questionText, TimeStampID) VALUES 
(1,'What is the speed of light?',1),
(2,'How to build a REST API?',2),
(3,'What’s the best sci-fi book?',3),
(4,'Tips for staying fit?',4),
(5,'Favorite Marvel character?',5),
(6,'How to train for a marathon?',6),
(7,'Whats the difference better INNER JOIN and LEFT JOIN?',7),
(8,'Who lives in a pineapple under the sea?',8),
(9,'What’s up?',9),
(10,'How to get better at chess?',10);

-- response entries
INSERT INTO Response (userID, responseText, TimeStampID) VALUES 
(1,'299,792,458 m/s',11),
(2,'Use Flask or Express',12),
(3,'Dune by Frank Herbert',13),
(4,'Consistency and diet',14),
(5,'Doctor Strange, obviously!',15),
(6,'Run short distances daily',16),
(7,'Google is a great start',17),
(8,'Spongebob Squarepants',18),
(9,'We may never know...',19),
(10,'Play puzzles and practice',20);

-- comment entries
INSERT INTO Comment (userID, questionID, commentText, TimeStampID) VALUES 
(3, 1, 'Good question!', 1),
(4, 2, 'Helpful info.', 2),
(5, 3, 'Thanks for sharing.', 3),
(6, 4, 'Clarify more?', 4),
(7, 5, 'Great explanation.', 5),
(8, 6, 'Interesting.', 6),
(9, 7, 'Didn’t know that.', 7),
(10, 8, 'Cool.', 8),
(1, 9, 'Thanks!', 9),
(2, 10, 'Useful tip.', 10);


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


