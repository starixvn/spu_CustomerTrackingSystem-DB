USE `CTS_Admin`;
DROP procedure IF EXISTS `CTS_AD_InsertCTSUser`;

DELIMITER $$
USE `CTS_Admin`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_AD_InsertCTSUser`(IN ip_userId INT, IN ip_userName VARCHAR(50))
BEGIN

	/*
		Created:	20201706@Lex.Khuat
		Task :		Insert new CTSUser when login
		DB:			CTS_Admin
		Original:
        
		Revisions:
		Param's Explanation (filtered by):
			- ip_userId: custID of user to insert
            - ip_userName: username to insert
	*/
    
    DECLARE vr_isAdded BIT DEFAULT 0;
    DECLARE	vr_currName VARCHAR(50);
    DECLARE vr_CreatedDate DATETIME DEFAULT current_time();
    DECLARE vr_SPName VARCHAR(100) 	DEFAULT 'CTS_AD_InsertCTSUser';
    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    # Check exists in database
    SELECT 1, UserName
    INTO vr_isAdded, vr_currName
    FROM CTS_Admin.CTSUser
    WHERE UserID = ip_userId;
    
    IF vr_isAdded = 1 AND vr_currName <> ip_userName THEN
    
		######## if username is outdated, update new username ########
        SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
        UPDATE CTS_Admin.CTSUser
        SET UserName = ip_userName
        WHERE UserID = ip_userId;
        
        INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
			VALUES(13, vr_SPName, CONCAT('Update logged in for username: ip_userId_ ', ip_userId, ';vr_oldName_', vr_currName) , vr_CreatedDate, 1);
        
	ELSEIF vr_isAdded = 0 THEN
        
        ######## if username does not exists, insert new user ########
        SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
        INSERT IGNORE INTO CTS_Admin.CTSUser(UserID, UserName, CreatedDate, IsMaster)
			VALUES (ip_userId, ip_userName, vr_CreatedDate, 1);
        
        INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
			VALUES(13, vr_SPName, CONCAT('Insert new logged in user: ip_userId_ ', ip_userId, ';ip_userName_', ip_userName) , vr_CreatedDate, 1);
        
    END IF;

END$$

DELIMITER ;

