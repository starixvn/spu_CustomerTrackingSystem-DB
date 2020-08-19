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

	/*
		Created:	Roger.Le@20200818
		Task:		Enhance Associated Account Monitor by NAP Permission 
		DB:			CTS_DataCenter
		Original:
        
        Revision:
			- Roger.Le@20200818: Created [Redmine ID: 138575]
                
		Param's Explanation (filtered by):
                
	*/

	DECLARE lv_CurrentDateTime 	DATETIME;
    
    # Handle error
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	SET lv_CurrentDateTime = NOW();
    
	DROP TEMPORARY TABLE IF EXISTS TmpCTSUserPermission;
    CREATE TEMPORARY TABLE TmpCTSUserPermission(
			UserID				INT
    );
    	
	SET @sql = CONCAT("INSERT INTO TmpCTSUserPermission(UserID) VALUES ('", REPLACE(ip_UserIds,",","'),('"),"');");
	PREPARE stm1 FROM @sql;
	EXECUTE stm1;
    
    SET SQL_SAFE_UPDATES = 0;
    
    # Update EndDate for users that currently have no permission on this function
    UPDATE CTS_DataCenter.CTSUserPermission AS h
		LEFT JOIN TmpCTSUserPermission AS t ON t.UserID = h.UserID
	SET h.GrantedTo = lv_CurrentDateTime,
		h.LastModifiedDate = lv_CurrentDateTime
	WHERE h.FunctionName = ip_FunctionName
		AND t.UserID IS NULL 
        AND h.GrantedTo IS NULL;
	   
    # Insert New
    INSERT INTO CTS_DataCenter.CTSUserPermission(UserID, FunctionName, GrantedFrom, GrantedTo, CreatedDate)
    SELECT DISTINCT t.UserID
		,	ip_FunctionName
		,	lv_CurrentDateTime
		,	NULL
        ,   lv_CurrentDateTime
	FROM TmpCTSUserPermission AS t
		LEFT JOIN CTS_DataCenter.CTSUserPermission AS h ON t.UserID = h.UserID AND h.FunctionName = ip_FunctionName
	WHERE h.UserID IS NULL 
		OR (h.UserID IS NOT NULL 
			AND NOT EXISTS (SELECT 1 
							FROM CTS_DataCenter.CTSUserPermission AS his 
                            WHERE his.UserID = h.UserID 
								AND his.FunctionName = ip_FunctionName
                                AND his.GrantedTo IS NULL));
	
END