/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_Profile_GetAssociationAccount`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_Profile_GetAssociationAccount`(
		IN ip_CTSCustID BIGINT UNSIGNED 
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20211214@Aries.Nguyen	
		Task :		Enrich the information on customer profile
		DB:			CTS_DataCenter
		
		Revisions:
			- 20211214@Aries.Nguyen: Created [Redmine ID: #165105]

		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustInfo_Profile_GetAssociationAccount(200);
	*/
    DECLARE lv_CustID 		BIGINT UNSIGNED;
	DECLARE lv_Count_AI 	INT;
    DECLARE lv_Count_Manual INT;
    DECLARE lv_Count_Device INT;
    DECLARE lv_Count_IP 	INT;
    
    SELECT CustID
    INTO lv_CustID
    FROM CTS_DataCenter.CTSCustomer
    WHERE CTSCustID = ip_CTSCustID;
    
    SELECT COUNT(1)
    INTO lv_Count_Device
    FROM CTS_DataCenter.AssociationByDevice
    WHERE CTSCustID = ip_CTSCustID;
    
    SELECT COUNT(1)
    INTO lv_Count_Manual
    FROM CTS_DataCenter.AssociationByManual
    WHERE FromCTSCustID = ip_CTSCustID 
		OR ToCTSCustID = ip_CTSCustID;
    
    SELECT COUNT(1)
    INTO lv_Count_AI
    FROM CTS_DataCenter.AssociationByAI
    WHERE FromCustID = lv_CustID
		OR ToCustID = lv_CustID;
    
    SELECT COUNT(1)
    INTO lv_Count_IP
    FROM CTS_DataCenter.AssociationByIP
    WHERE FromCustID = lv_CustID
		OR ToCustID = lv_CustID;
    
    SELECT 	lv_Count_AI AS AI
		,	lv_Count_Manual AS Manual
        ,	lv_Count_Device AS Device
        ,	lv_Count_IP AS IP;
END$$

DELIMITER ;