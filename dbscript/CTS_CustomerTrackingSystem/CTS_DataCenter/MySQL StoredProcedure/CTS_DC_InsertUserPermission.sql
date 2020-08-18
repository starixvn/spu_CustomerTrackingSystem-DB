CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_InsertUserPermission`(
	IN		ip_UserIds			TEXT
    ,IN 	ip_FunctionName 	VARCHAR(50)
    
    ,OUT op_ErrorMessage 		VARCHAR(200)
)
BEGIN
		/*
		Created:	Roger.Le
		Task:		Enhance Associated Account Monitor by NAP Permission [Redmine ID: 138575]
		DB:			CTS_DataCenter
		Original:
        
		Param's Explanation (filtered by):
                
	*/

	DECLARE CurrentDateTime 	DATETIME;
    
    # Handle error
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	SET CurrentDateTime = NOW();
    
    DROP TEMPORARY TABLE IF EXISTS TmpCTSUserID;
    CREATE TEMPORARY TABLE TmpCTSUserID(
		UserID				INT
		,FunctionName 		VARCHAR(50)
    );
    
	DROP TEMPORARY TABLE IF EXISTS TmpCTSUserPermission;
    CREATE TEMPORARY TABLE TmpCTSUserPermission(
		UserID				INT,
        FunctionName 		VARCHAR(50),
		IsNew 				INT DEFAULT 1
    );
    
    # Parse UserID
	IF (ip_UserIds IS NULL OR ip_UserIds = '') THEN
		SET ip_UserIds = 0;
	END IF;
	
	SET @sql = CONCAT("INSERT INTO TmpCTSUserID(UserID) VALUES ('", REPLACE(ip_UserIds,",","'),('"),"');");
	PREPARE stm1 FROM @sql;
	EXECUTE stm1;
	
	SET SQL_SAFE_UPDATES = 0;
	UPDATE TmpCTSUserID SET FunctionName = ip_FunctionName;
    
    # Check condition create
     INSERT INTO TmpCTSUserPermission(UserID, FunctionName, IsNew)
		SELECT tmp.UserID, tmp.FunctionName, 1 FROM TmpCTSUserID tmp
		WHERE (tmp.UserID, tmp.FunctionName) NOT IN ( SELECT his.UserID, his.FunctionName FROM CTS_DataCenter.CTSUserPermission_History his)
			OR (
				EXISTS (SELECT 1 
					FROM CTS_DataCenter.CTSUserPermission_History his 
					WHERE his.GrantedFrom IS NOT NULL AND his.GrantedTo IS NOT NULL AND tmp.UserID = his.UserID AND tmp.FunctionName = his.FunctionName)
				AND
				NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSUserPermission_History his WHERE his.GrantedFrom IS NOT NULL AND his.GrantedTo IS NULL AND tmp.UserID = his.UserID AND tmp.FunctionName = his.FunctionName)
			)
		;
	# Check condition update
    INSERT INTO TmpCTSUserPermission(UserID, FunctionName, IsNew)
		SELECT his.UserID, his.FunctionName, 0 FROM TmpCTSUserID tmp
		RIGHT JOIN CTS_DataCenter.CTSUserPermission_History his ON tmp.UserID = his.UserID AND tmp.FunctionName = his.FunctionName
    WHERE tmp.UserID IS NULL AND tmp.FunctionName IS NULL AND his.GrantedTo IS NULL AND his.FunctionName = ip_FunctionName;
    
    # Create new data
    IF EXISTS (select 1 from TmpCTSUserPermission where IsNew = 1) THEN
		 BEGIN 
		   INSERT INTO CTS_DataCenter.CTSUserPermission_History(UserID, FunctionName, GrantedFrom, GrantedTo)
				SELECT UserID
						,ip_FunctionName
						,CurrentDateTime
						,NULL
				FROM TmpCTSUserPermission
				WHERE UserID != 0 AND IsNew = 1;
		END;
	END IF;
    
    # Update data
	IF EXISTS (select 1 from TmpCTSUserPermission where IsNew = 0) THEN
		BEGIN
			UPDATE CTS_DataCenter.CTSUserPermission_History his
				INNER JOIN TmpCTSUserPermission tmp ON tmp.UserID = his.UserID AND tmp.FunctionName = his.FunctionName
			SET his.GrantedTo = CurrentDateTime
            WHERE tmp.IsNew = 0;
        END;
  	END IF;
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	
END