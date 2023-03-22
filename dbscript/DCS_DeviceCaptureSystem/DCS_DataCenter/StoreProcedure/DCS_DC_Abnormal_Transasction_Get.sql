/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Abnormal_Transasction_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Abnormal_Transasction_Get`(
		IN ip_Size INT
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20230316@Jonathan.Doan
	Task : Support return new device login for Alpha
	DB: DCS_DataCenter
	Original:

	Revisions:
		- 20230316@Jonathan.Doan: Get Data [Redmine ID: 185185]
		
	Param's Explanation (filtered by):

	Example:
		- CALL DCS_DataCenter.DCS_DC_Abnormal_Transasction_Get(10);
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    
    CREATE TEMPORARY TABLE Temp_Transaction(
		ID BIGINT UNSIGNED PRIMARY KEY,
        AccountId BIGINT UNSIGNED,
		CountDevice INT
    );
    
    INSERT INTO Temp_Transaction(ID, AccountId, CountDevice)
    SELECT 	trans.ID
		,	trans.AccountID
        ,	COUNT(ass.AssociationID) AS CountDevice
	FROM DCS_DataCenter.AbnormalTransasction AS trans
		INNER JOIN DCS_DataCenter.Association AS ass ON ass.AccountID = trans.AccountID
	GROUP BY trans.ID, trans.AccountID
    ORDER BY trans.ID
    LIMIT ip_Size;
    
    SELECT 	trans.ID
		,	trans.TransID
		,	trans.LoginName
		,	trans.TransTime
		,	trans.IP
		,	ua.UserAgent
		,	ua.OS
		,	ua.Browser
		,	dt.DeviceTypeName
		,	tmp.CountDevice
	FROM Temp_Transaction AS tmp
		INNER JOIN DCS_DataCenter.AbnormalTransasction AS trans ON trans.ID = tmp.ID
		LEFT JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
		LEFT JOIN DCS_DataCenter.DeviceType AS dt ON dt.DeviceTypeID = ua.DeviceTypeID;
	
END$$
DELIMITER ;
