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

CREATE TABLE TimeStamp(
	TimeStampID INT AUTO_INCREMENT PRIMARY KEY,
	ChatMessageID INT,
	ResponseID INT,
	QuestionID INT,
	CommentID INT,
	sentTime TIME,
	sentDate DATE,
	FOREIGN KEY (ChatMessageID) REFERENCES ChatMessage(chatMessageID),
	FOREIGN KEY (ResponseID) REFERENCES Response(responseID),
	FOREIGN KEY (QuestionID) REFERENCES Question(questionID),
	FOREIGN KEY (CommentID) REFERENCES Comment(commentID)
);y
