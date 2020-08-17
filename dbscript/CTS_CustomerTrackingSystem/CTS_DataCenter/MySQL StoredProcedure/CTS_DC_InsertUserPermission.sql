CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_InsertUserPermission`(
	 IN		ip_UserIds			TEXT
    ,IN 	ip_Type 			VARCHAR(50)
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
	DECLARE Permis_count 				INT;
    
	SET CurrentDateTime = NOW();
    
    DROP TEMPORARY TABLE IF EXISTS TmpCTSUserPermission_History;
    CREATE TEMPORARY TABLE TmpCTSUserPermission_History(
		UserID					INT
		,	Type					VARCHAR(50)
		,	GrantedFrom				DATETIME DEFAULT NULL
		,	GrantedTo				DATETIME DEFAULT NULL
    );
    
	DROP TEMPORARY TABLE IF EXISTS TmpCTSUserPermission_History_Update;
	CREATE TEMPORARY TABLE TmpCTSUserPermission_History_Update(
		UserID					INT
		,	Type					VARCHAR(50)
		,	GrantedFrom				DATETIME DEFAULT NULL
		,	GrantedTo				DATETIME DEFAULT NULL
	);
    
    # Create table store data when GrantedFrom and GrantedTo not null
    DROP TEMPORARY TABLE IF EXISTS TmpCTSUserPermission_History_Update_NotNull;
	CREATE TEMPORARY TABLE TmpCTSUserPermission_History_Update_NotNull(
		UserID					INT
		,	Type					VARCHAR(50)
		,	GrantedFrom				DATETIME DEFAULT NULL
		,	GrantedTo				DATETIME DEFAULT NULL
	);
    
    # Create table store data when GrantedTo is null
	DROP TEMPORARY TABLE IF EXISTS TmpCTSUserPermission_History_Update_Null;
	CREATE TEMPORARY TABLE TmpCTSUserPermission_History_Update_Null(
		UserID					INT
		,	Type					VARCHAR(50)
		,	GrantedFrom				DATETIME DEFAULT NULL
		,	GrantedTo				DATETIME DEFAULT NULL
	);
    
    # Create table store data after validate
    DROP TEMPORARY TABLE IF EXISTS TmpCTSUserPermission_History_Update_Validate;
	CREATE TEMPORARY TABLE TmpCTSUserPermission_History_Update_Validate(
		UserID					INT
		,	Type					VARCHAR(50)
		,	GrantedFrom				DATETIME DEFAULT NULL
		,	GrantedTo				DATETIME DEFAULT NULL
	);
		
    # Parse UserID
    	IF (ip_UserIds IS NULL OR ip_UserIds = '') THEN
			SET ip_UserIds = 0;
        END IF;
        
		SET @sql = CONCAT("INSERT INTO TmpCTSUserPermission_History(UserID) VALUES ('", REPLACE(ip_UserIds,",","'),('"),"');");
        PREPARE stm1 FROM @sql;
		EXECUTE stm1;
        
		UPDATE TmpCTSUserPermission_History SET Type = ip_Type;
			
		INSERT INTO TmpCTSUserPermission_History_Update(UserID, Type, GrantedFrom, GrantedTo)
			SELECT permis.UserID
			, permis.Type
			, permis.GrantedFrom
			, permis.GrantedTo
			FROM CTSUserPermission_History permis
				LEFT JOIN TmpCTSUserPermission_History tmpPermis ON tmpPermis.UserID = permis.UserID
			WHERE permis.GrantedTo IS NULL AND tmpPermis.UserID IS NULL AND permis.Type = ip_Type;
		
		#1. Create a table to store data if they are non-null
		 INSERT INTO TmpCTSUserPermission_History_Update_NotNull(UserID,Type)
			SELECT permis.UserID, permis.Type
				FROM TmpCTSUserPermission_History tmpPermis
					INNER JOIN CTSUserPermission_History permis ON tmpPermis.UserID = permis.UserID
				WHERE permis.GrantedFrom IS NOT NULL AND permis.GrantedTo IS NOT NULL AND permis.Type = ip_Type
				GROUP BY permis.UserID, permis.Type;
		 #2. Create a table to store data if GrantedTo is null
		INSERT INTO TmpCTSUserPermission_History_Update_Null(UserID,Type)
			SELECT permis.UserID, permis.Type
				FROM TmpCTSUserPermission_History tmpPermis
					INNER JOIN CTSUserPermission_History permis ON tmpPermis.UserID = permis.UserID
				WHERE permis.GrantedFrom IS NOT NULL AND permis.GrantedTo IS NULL AND permis.Type = ip_Type
				GROUP BY permis.UserID, permis.Type;
		
		#3. Filtering conditions
		  INSERT INTO TmpCTSUserPermission_History_Update_Validate(UserID,Type, GrantedFrom, GrantedTo)
			SELECT notNullPermis.UserID, notNullPermis.Type, NULL, NULL
				FROM TmpCTSUserPermission_History_Update_NotNull notNullPermis
					LEFT JOIN TmpCTSUserPermission_History_Update_Null nullPermiss ON notNullPermis.UserID = nullPermiss.UserID
				WHERE nullPermiss.UserID IS NULL AND notNullPermis.Type = ip_Type;

		SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;	
		# Insert new UserIds
        IF EXISTS (SELECT distinct * FROM TmpCTSUserPermission_History tmpPermis LEFT JOIN CTSUserPermission_History permis ON tmpPermis.UserID = permis.UserID  WHERE  (tmpPermis.UserID, tmpPermis.Type) NOT IN ( SELECT his.UserID, his.Type FROM CTSUserPermission_History his)) THEN
             BEGIN     
				   INSERT INTO CTS_DataCenter.CTSUserPermission_History(UserID, Type, GrantedFrom, GrantedTo)
						SELECT tmpPermis.UserID
								,ip_Type
								,CurrentDateTime
								,tmpPermis.GrantedTo
						FROM TmpCTSUserPermission_History tmpPermis
							LEFT JOIN CTSUserPermission_History permis ON tmpPermis.UserID = permis.UserID 
						WHERE tmpPermis.UserID != 0 AND (tmpPermis.UserID, tmpPermis.Type) NOT IN ( SELECT his.UserID, his.Type FROM CTSUserPermission_History his);
				END;                 
        END IF;                              
		
		# Create new value if GrantedFrom && GrantedTo not null
		IF ((SELECT COUNT(DISTINCT(tmpValue.UserID)) FROM TmpCTSUserPermission_History_Update_Validate tmpValue WHERE tmpValue.Type = ip_Type) > 0) THEN
			INSERT INTO CTS_DataCenter.CTSUserPermission_History(UserID, Type, GrantedFrom, GrantedTo)
				SELECT tmpValue.UserID
						,tmpValue.Type
						,CurrentDateTime
						,tmpValue.GrantedTo
				FROM TmpCTSUserPermission_History_Update_Validate tmpValue
				WHERE tmpValue.Type = ip_Type;
		END IF;
					
		# Check userids exist and after update GrantedTo
		IF ((SELECT COUNT(*) FROM TmpCTSUserPermission_History_Update tmpPermis) > 0) THEN
			SET SQL_SAFE_UPDATES = 0;
			UPDATE CTSUserPermission_History permis
				INNER JOIN TmpCTSUserPermission_History_Update tmpPermis ON	tmpPermis.UserID = permis.UserID AND permis.GrantedTo IS NULL AND permis.Type = ip_Type
			SET permis.GrantedTo = CurrentDateTime;
		END IF;
        
        SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END