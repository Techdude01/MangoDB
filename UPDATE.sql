-- update.sql - MySQL specific schema updates
-- Run this after your initial create.sql

START TRANSACTION;

-- 1. User table 
ALTER TABLE User 
ADD COLUMN email VARCHAR(255) AFTER lastName,
ADD COLUMN last_login DATETIME AFTER email,
MODIFY COLUMN password VARCHAR(255) COMMENT 'Hashed password storage',
ADD COLUMN is_active TINYINT(1) DEFAULT 1 AFTER password;

-- 2. Tag table 
ALTER TABLE Tag
ADD COLUMN description TEXT AFTER tagName,
ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP AFTER description;

-- 3. Chat table 
ALTER TABLE Chat
ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP AFTER chatName,
ADD COLUMN is_group_chat TINYINT(1) DEFAULT 0 AFTER created_at;

-- 4. ChatMessage 
ALTER TABLE ChatMessage
ADD COLUMN is_edited TINYINT(1) DEFAULT 0 AFTER TimeStampID,
ADD COLUMN is_deleted TINYINT(1) DEFAULT 0 AFTER is_edited,
ADD COLUMN sent_at DATETIME DEFAULT CURRENT_TIMESTAMP AFTER is_deleted;

-- 5. Question table 
ALTER TABLE Question
ADD COLUMN title VARCHAR(255) AFTER userID,
ADD COLUMN is_closed TINYINT(1) DEFAULT 0 AFTER questionText,
ADD COLUMN view_count INT DEFAULT 0 AFTER is_closed,
ADD COLUMN asked_at DATETIME DEFAULT CURRENT_TIMESTAMP AFTER view_count;

-- 6. Response table 
ALTER TABLE Response
ADD COLUMN is_accepted TINYINT(1) DEFAULT 0 AFTER responseText,
ADD COLUMN upvotes INT DEFAULT 0 AFTER is_accepted,
ADD COLUMN posted_at DATETIME DEFAULT CURRENT_TIMESTAMP AFTER upvotes;

-- 7. Comment table 
ALTER TABLE Comment
ADD COLUMN is_deleted TINYINT(1) DEFAULT 0 AFTER TimeStampID,
ADD COLUMN commented_at DATETIME DEFAULT CURRENT_TIMESTAMP AFTER is_deleted;

-- 8. TimeStamp table
ALTER TABLE TimeStamp
DROP FOREIGN KEY timestamp_chatmessageid_fkey,
DROP FOREIGN KEY timestamp_responseid_fkey,
DROP FOREIGN KEY timestamp_questionid_fkey,
DROP FOREIGN KEY timestamp_commentid_fkey,
DROP COLUMN ChatMessageID,
DROP COLUMN ResponseID,
DROP COLUMN QuestionID,
DROP COLUMN CommentID;

-- 9. Add indexes
CREATE INDEX idx_user_email ON User(email);
CREATE INDEX idx_chatmessage_chatid ON ChatMessage(chatID);
CREATE INDEX idx_question_userid ON Question(userID);
CREATE INDEX idx_response_userid ON Response(userID);
CREATE INDEX idx_taglist_userid ON TagList(userID);
CREATE INDEX idx_chatmember_chatid ON ChatMember(chatID);

