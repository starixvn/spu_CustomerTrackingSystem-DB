/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_Profile_GetStats`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_Profile_GetStats`(
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
            - 20210317@Casey.Huynh: Count AssociationByIP to lv_TotalAccounts [Redmine ID: #131662]
			- 20210423@Irena.Vo: Get condition more with AccountStatus, SubscriberID & SiteID [Redmine ID: #152963]
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_Association_Profile_GetStats(221882500);
	*/
    DECLARE lv_TotalAccounts INT;
    DECLARE lv_TotalDevices INT;
    DECLARE lv_CustID INT;
   
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountStatusID;
    CREATE TEMPORARY TABLE Temp_AccountStatusID (
			AccountStatusID 	INT UNSIGNED
        , 	PRIMARY KEY (AccountStatusID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_SubscriberSiteID;
    CREATE TEMPORARY TABLE Temp_SubscriberSiteID (
			SubscriberID 	INT UNSIGNED
		, 	SiteID			INT UNSIGNED
        , 	PRIMARY KEY (SubscriberID,SiteID)
	);
    
    INSERT IGNORE INTO Temp_AccountStatusID (AccountStatusID)
	SELECT ItemID 
    FROM CTS_DataCenter.StaticList 
    WHERE ListID = 1 AND PriorityOrder IS NOT NULL;
    
    INSERT IGNORE INTO Temp_SubscriberSiteID (SubscriberID,SiteID)
	SELECT	s.SubscriberID, s.SiteID
    FROM CTS_DataCenter.MappingSubscriberSite AS s 
        INNER JOIN CTS_DataCenter.SubscriberGroup AS sg ON s.SubscriberGroupID = sg.SubscriberGroupID
	WHERE sg.IsActive = 1;
    
	SELECT CustID 
    INTO lv_CustID
    FROM CTS_DataCenter.CTSCustomer 
    WHERE CTSCustID = ip_CTSCustID;    
    
	SELECT  COUNT(1)
	INTO lv_TotalDevices
	FROM CTS_DataCenter.AssociationByDevice  AS asDv 
    WHERE  asDv.CTSCustID =  ip_CTSCustID;
    
    WITH CTS_Stat AS (
		SELECT  asCus.CTSCustID, cust.CustStatusID, cust.SubscriberID, cust.SiteID
		FROM CTS_DataCenter.AssociationByDevice as asDv
			INNER JOIN CTS_DataCenter.AssociationByDevice AS asCus ON asCus.DCSDeviceID =  asDv.DCSDeviceID  AND asCus.CTSCustID <>  asDv.CTSCustID
            INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CTSCustID  = asCus.CTSCustID
		WHERE asDv.CTSCustID = ip_CTSCustID
        
		UNION 
        
		SELECT  asMa.ToCTSCustID AS CTSCustID, cust.CustStatusID, cust.SubscriberID, cust.SiteID
		FROM  CTS_DataCenter.AssociationByManual AS asMa  
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CTSCustID  = asMa.ToCTSCustID
		WHERE asMa.FromCTSCustID =  ip_CTSCustID
        
        UNION
        
        SELECT  asMa.FromCTSCustID AS CTSCustID, cust.CustStatusID, cust.SubscriberID, cust.SiteID
		FROM  CTS_DataCenter.AssociationByManual AS asMa  
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CTSCustID  = asMa.FromCTSCustID
		WHERE asMa.ToCTSCustID =  ip_CTSCustID

        UNION
        SELECT  cust.CTSCustID, cust.CustStatusID, cust.SubscriberID, cust.SiteID
		FROM  CTS_DataCenter.AssociationByAI AS asAI
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID  = asAI.ToCustID AND cust.CustSubID = 0
		WHERE asAI.FromCustID =  lv_CustID
        
        UNION
        
        SELECT  cust.CTSCustID, cust.CustStatusID, cust.SubscriberID, cust.SiteID
		FROM  CTS_DataCenter.AssociationByAI AS asAI 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID  = asAI.FromCustID AND cust.CustSubID = 0
		WHERE asAI.ToCustID =  lv_CustID
        
        UNION
        
		SELECT  cust.CTSCustID, cust.CustStatusID, cust.SubscriberID, cust.SiteID
		FROM  CTS_DataCenter.AssociationByIP AS asAP
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID  = asAP.ToCustID AND cust.CustSubID = 0
		WHERE asAP.FromCustID =  lv_CustID
        
        UNION
        
        SELECT  cust.CTSCustID, cust.CustStatusID, cust.SubscriberID, cust.SiteID
		FROM  CTS_DataCenter.AssociationByIP AS asAP 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID  = asAP.FromCustID AND cust.CustSubID = 0
		WHERE asAP.ToCustID =  lv_CustID
	)
    SELECT COUNT(1)
    INTO lv_TotalAccounts
	FROM CTS_Stat
		INNER JOIN  Temp_AccountStatusID AS tmpSt ON tmpSt.AccountStatusID = CTS_Stat.CustStatusID
		INNER JOIN  Temp_SubscriberSiteID AS tmpSS ON tmpSS.SubscriberID = CTS_Stat.SubscriberID AND tmpSS.SiteID = CTS_Stat.SiteID;
    
    SELECT 	lv_TotalAccounts AS TotalAccounts, lv_TotalDevices AS TotalDevices;
END$$
DELIMITER ;