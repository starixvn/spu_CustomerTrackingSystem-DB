/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_Profile_GetStat`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_Profile_GetStat`(
		IN ip_CTSCustID BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210202@Aries.Nguyen
		Task:		Get association statistics 
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210202@Aries.Nguyen: Created [Redmine ID: #148908]
            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_Association_Profile_GetStat(38665541);
	*/
    DECLARE lv_TotalAccounts INT;
    DECLARE lv_TotalDevices INT;
    
	SELECT  COUNT(1)
		INTO lv_TotalDevices
	FROM CTS_DataCenter.AssociationByDevice  AS asDv 
    WHERE  asDv .CTSCustID =  ip_CTSCustID;
    
    WITH CTS_Stat AS (
		SELECT  asCus.CTSCustID
		FROM CTS_DataCenter.AssociationByDevice as asDv
			INNER JOIN CTS_DataCenter.AssociationByDevice AS asCus ON asCus.DCSDeviceID =  asDv.DCSDeviceID  AND asCus.CTSCustID  !=   asDv.CTSCustID
		WHERE asDv.CTSCustID = ip_CTSCustID
		
		UNION 
		
		SELECT  asMa.ToCTSCustID  
		FROM  CTS_DataCenter.AssociationByManual AS asMa  
		WHERE asMa.FromCTSCustID =  ip_CTSCustID
	)
	SELECT COUNT(1)
		INTO lv_TotalAccounts
	FROM CTS_Stat;
    
    SELECT 	lv_TotalAccounts AS TotalAccounts
		,	lv_TotalDevices AS TotalDevices
        ,	0 AS TotalIps;
END$$

DELIMITER ;