-- how to run
-- mysql -u root Mango < PERMISSIONS.sql
CREATE USER 'mango_user'@'localhost' IDENTIFIED BY 'arfaouiRocks123';
GRANT SELECT, INSERT, UPDATE, DELETE ON `mango`.* TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`CancelComment` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`CancelCommentDraft` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`CancelQuestion` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`CancelResponse` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`CreateChatAndRequest` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`DeleteQuestion` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`DeleteUserByUsername` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`DownvoteQuestion` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`DraftComment` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`DraftResponse` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`GetChatIDsForUser` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`GetChatName` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`GetControversialQuestionswithPagination` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`GetPopularQuestionsWithPagination` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`GetQuestionsByTag` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`GetQuestionsByUserID` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`GetRecentQuestionsWithPagination` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`GetRelevantQuestions` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`GetSimilarUsersByTags` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`GetTagsByUserID` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`GetUserCredentials` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`InsertNewUser` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`LogChatAction` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`LogCommentAction` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`LogResponseAction` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`PublishComment` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`PublishQuestion` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`PublishResponse` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`RetrieveResponses` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`SearchQuestions` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`StartQuestion` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`UpvoteQuestion` TO 'mango_user'@'localhost';
GRANT EXECUTE ON PROCEDURE `Mango`.`ValidResponse` TO 'mango_user'@'localhost';
-- Revoke potentially dangerous privileges that might have been granted
REVOKE DROP ON *.* FROM 'mango_user'@'localhost';
REVOKE CREATE ON *.* FROM 'mango_user'@'localhost';
REVOKE ALTER ON *.* FROM 'mango_user'@'localhost';
REVOKE SUPER ON *.* FROM 'mango_user'@'localhost';
REVOKE SHUTDOWN ON *.* FROM 'mango_user'@'localhost';
REVOKE PROCESS ON *.* FROM 'mango_user'@'localhost';
REVOKE FILE ON *.* FROM 'mango_user'@'localhost';
REVOKE RELOAD ON *.* FROM 'mango_user'@'localhost';

-- Flush privileges to ensure changes take effect
FLUSH PRIVILEGES;