/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
USE `DCS_DataCenter`;
DROP procedure IF EXISTS `DCS_DataCenter`.`DCS_DC_Transform_JSChallengeInfo_Insert`;
;

DELIMITER $$
USE `DCS_DataCenter`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_JSChallengeInfo_Insert`(
		IN ip_TableName VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20240313@Teddy.le
		Task : Insert into DCS_DataCenter.JSChallengeInfo
		DB: DCS_DataCenter
		Original:

		Revisions:
			- 20240313@Teddy.le [Redmine ID: #196667]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Transform_JSChallengeInfo_Insert();

	*/
    DECLARE lv_CurrentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_InputData;
	DROP TEMPORARY TABLE IF EXISTS Temp_JSChallengeInfo;
    
	CREATE TEMPORARY TABLE Temp_InputData(
			TmpID			 			BIGINT UNSIGNED	NOT NULL
		,	CreatedTime					TIMESTAMP(4)	NOT NULL
        ,	RawJsChallengeInfo			LONGTEXT		NULL
        ,	PRIMARY KEY (TmpID)
    );
    
	CREATE TEMPORARY TABLE Temp_JSChallengeInfo(
			TmpID			 			BIGINT UNSIGNED		NOT NULL  
		,	JsChallengeID	 			BIGINT UNSIGNED    	NULL  
        ,	CreatedTime 				TIMESTAMP(4) NOT NULL
        ,	ChallengeCode 				VARCHAR(50)
		,   ChallengeIds 				VARCHAR(50) NULL DEFAULT ''
		,   Expect 						VARCHAR(100) NULL DEFAULT ''
		,   Actual 						VARCHAR(100) NULL DEFAULT ''
		,  	Parameters 					VARCHAR(300) NULL DEFAULT ''
		,   ExeServerTimeInSecond 		INT UNSIGNED NOT NULL DEFAULT 0
		,   ExeClientTimeInSecond 		INT UNSIGNED NOT NULL DEFAULT 0
		,   Result 						TINYINT NOT NULL DEFAULT 0
		,   ErrMsg 						VARCHAR(300) NULL DEFAULT ''
        
        ,	PRIMARY KEY (TmpID)
    );
    
	SET @sql = CONCAT('INSERT INTO Temp_InputData(TmpID, CreatedTime, RawJsChallengeInfo) 
						SELECT 	ID AS TmpID
							,	TransTime
                            ,   RawJsChallengeInfo
                        FROM ', ip_TableName, 
					' 	WHERE RawJsChallengeInfo IS NOT NULL');
                    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    INSERT IGNORE INTO Temp_JSChallengeInfo(TmpID, CreatedTime, ChallengeCode, ChallengeIds, Expect, Actual, Parameters, ExeServerTimeInSecond, ExeClientTimeInSecond, Result, ErrMsg)
    SELECT 	TmpID
		,	CreatedTime
		,	RawJsChallengeInfo->>'$.ChallengeCode'
		,	RawJsChallengeInfo->>'$.ChallengeIds'
		,	RawJsChallengeInfo->>'$.Expect'
		,	RawJsChallengeInfo->>'$.Actual'
		,	RawJsChallengeInfo->>'$.Parameters'
		,	RawJsChallengeInfo->>'$.ExeServerTimeInSecond'
		,	RawJsChallengeInfo->>'$.ExeClientTimeInSecond'
        ,   RawJsChallengeInfo->>'$.Result'
		,	RawJsChallengeInfo->>'$.ErrMsg'
    FROM Temp_InputData;
    
    ALTER TABLE Temp_JSChallengeInfo
	ADD INDEX UX_Temp_JSChallengeInfo_ChallengeCode (ChallengeCode);
    
	INSERT IGNORE INTO DCS_DataCenter.JSChallengeInfo (CreatedTime, ChallengeCode, ChallengeIds, Expect, Actual, Parameters, ExeServerTimeInSecond, ExeClientTimeInSecond, Result, ErrMsg)
	SELECT	DISTINCT
			tmp.CreatedTime
		,	tmp.ChallengeCode
		,	tmp.ChallengeIds
		,	tmp.Expect
		,	tmp.Actual
		,	tmp.Parameters
		,	tmp.ExeServerTimeInSecond
		,	tmp.ExeClientTimeInSecond
        ,   tmp.Result
		,	tmp.ErrMsg
	FROM Temp_JSChallengeInfo AS tmp;
    
    UPDATE Temp_JSChallengeInfo AS tmp
		INNER JOIN DCS_DataCenter.JSChallengeInfo AS ua ON ua.ChallengeCode = tmp.ChallengeCode
	SET tmp.JsChallengeID = ua.ID;
    
	SET @sql = CONCAT('UPDATE ', ip_TableName,' AS tmp
						INNER JOIN Temp_JSChallengeInfo AS ua ON ua.TmpID = tmp.ID
                        SET tmp.JsChallengeID = ua.JsChallengeID');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
END$$

DELIMITER ;
;
