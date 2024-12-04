/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_ArchiveData_MBLastAccessedDate_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_ArchiveData_MBLastAccessedDate_Update`(
	IN ip_BatchSize INT
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20241204@Jonathan.Doan
	    Task : Update LastAccessedDate
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20241204@Jonathan.Doan: Created [Redmine ID: #213401]
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_ArchiveData_MBLastAccessedDate_Update(100);
    */
    
    DECLARE CONST_SYSTEMSETTING_MAXMBTRANSACTION07ID	INT DEFAULT 30;
    DECLARE lv_MaxID	 								BIGINT UNSIGNED;
    DECLARE lv_CurrentDate 								TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    
    SELECT VValue
    INTO lv_MaxID
    FROM DCS_DataCenter.SystemSetting
    WHERE ID = CONST_TRANS07_SYSTEMARCHIVEID;
    
    
    /*******INIT TEMPORARY TABLE************/
    DROP TEMPORARY TABLE IF EXISTS Temp_MBTransaction07;
	CREATE TEMPORARY TABLE Temp_MBTransaction07(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MBAccountID			BIGINT UNSIGNED
        ,	CreatedDate			DATE
        ,	TransTime			DATETIME(4)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MBAccount;
	CREATE TEMPORARY TABLE Temp_MBAccount(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	LastLoginTime		DATETIME
    );
    
    
    /*******GET DATA Transaction07********************/
    INSERT INTO Temp_MBTransaction07(ID, MBAccountID, CreatedDate, TransTime)
    SELECT 	trans.ID
        ,	IFNULL(trans.MBAccountID, 0) AS MBAccountID
        ,	trans.CreatedDate
        ,	trans.TransTime
	FROM DCS_DataCenter.MBTransaction07 AS trans
	WHERE trans.ID > lv_MaxID
	LIMIT ip_BatchSize;
    
    
    /*******GET LastAccessedDate ********************/
    INSERT INTO Temp_MBAccount(ID, LastLoginTime)
    SELECT 	MBAccountID AS ID
		,	MAX(TransTime) AS LastLoginTime
    FROM Temp_MBTransaction07
    WHERE MBAccountID IS NOT NULL
    GROUP BY MBAccountID;
    
    
    /*******UPDATE MBAccount.LastLoginTime********************/
    UPDATE DCS_DataCenter.MBAccount AS acc
		INNER JOIN Temp_MBAccount AS tmp ON tmp.ID = acc.ID
	SET acc.LastLoginTime = tmp.LastLoginTime;

END$$
DELIMITER ;