USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_InsertUserPermission`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_InsertUserPermission`(
	 IN ip_UserIDList		JSON
    
    ,OUT op_ErrorMessage 		VARCHAR(200)
)
BEGIN
	/*
		Created:	20200818@Roger.Le
		Task:		Enhance Associated Account Monitor by NAP Permission 
		DB:			CTS_DataCenter
		Original:
        
        Revision:
			- 20200818@Roger.Le: [Redmine ID: 138575] Created
            - 20200918@Lex.Khuat: [Redmine ID: 141755] Support new probation notification
                
		Param's Explanation (filtered by):
                call CTS_DataCenter.CTS_DC_InsertUserPermission('[{"UserID": 1111, "FuncID": 1}, {"UserID": 1112, "FuncID": 2}], @error)';
	*/

	DECLARE lv_CurrentTime	DATETIME DEFAULT CURRENT_TIME();
    
    # Handle error
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    #============================================
    DROP TEMPORARY TABLE IF EXISTS Temp_CTSUserPermission;
    #============================================

    CREATE TEMPORARY TABLE Temp_CTSUserPermission (
		UserID			INT 		UNSIGNED
    ,	FuncID			SMALLINT	UNSIGNED
    ,	PRIMARY KEY		PK_Temp_CTSUserPermission_UserID(UserID, FuncID)
    );
	
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    #========= GET DATA TO UPDATE =========
	INSERT INTO Temp_CTSUserPermission(UserID, FuncID)
	SELECT 	tmp.UserID
		, 	tmp.FuncID
	FROM JSON_TABLE(ip_UserIDList,
		 "$[*]" COLUMNS(
			  UserID 	INT UNSIGNED		PATH "$.UserID"
			, FuncID	SMALLINT UNSIGNED	PATH "$.FuncID"
		 )) AS tmp;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    #========= REVOKE PERMISSION ON CURRENT USERS =========
    UPDATE CTS_DataCenter.CTSUserPermission AS up
    LEFT JOIN Temp_CTSUserPermission AS temp
		ON	temp.UserID = up.UserID
        AND	temp.FuncID = up.FunctionID
	SET		up.LastModifiedDate = lv_CurrentTime
		,	up.GrantedTo =	lv_CurrentTime
	WHERE temp.UserID IS NULL
		AND	up.GrantedTo IS NULL;
	
    #========= INSERT NEW PERMISSION LIST =========
    INSERT INTO CTS_DataCenter.CTSUserPermission (UserID, FunctionName, GrantedFrom, GrantedTo, CreatedDate, LastModifiedDate, FunctionID, IsTurnedOnNotification)
    SELECT	DISTINCT temp.UserID
		,	CASE	WHEN temp.FuncID = 1 THEN 'AssociatedAccountMonitor'
					WHEN temp.FuncID = 2 THEN 'ProbationManagement'
                    ELSE 'Unassigned'
			END
		,	lv_CurrentTime AS GrantedFrom
        ,	NULL AS GrantedTo
        ,	lv_CurrentTime AS CreatedDate
        ,	lv_CurrentTime AS LastModifiedDate
        ,	temp.FuncID
        ,	1
    FROM Temp_CTSUserPermission AS temp
    LEFT JOIN CTS_DataCenter.CTSUserPermission AS up
		ON	temp.UserID = up.UserID
        AND	temp.FuncID = up.FunctionID
	WHERE up.UserID IS NULL
		OR	(up.UserID IS NOT NULL
			AND NOT EXISTS (SELECT 1 
							FROM CTS_DataCenter.CTSUserPermission AS tup 
                            WHERE tup.UserID = up.UserID 
								AND tup.FunctionID = up.FunctionID
                                AND tup.GrantedTo IS NULL));
    
END$$

DELIMITER ;

