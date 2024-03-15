/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsService,ctsAPI" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_PA_Dangerous_ReScan_xpre`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_Dangerous_ReScan_xpre`(
		IN ip_CustIDs	LONGTEXT
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20240315@Casey.Huynh
		Task :		Renovate PA Process
		DB:			CTS_DataCenter 
		Original: 
		Revisions:  
			- 20240315@Casey.Huynh:	Created [Redmine ID: #201358]

        Param's Explanation:

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_Dangerous_ReScan_xpre("1,2,3,4, 11");
	*/ 
	DECLARE	CONST_CATEGORYID_EARLYWARININGMEMBER INT DEFAULT 190;
	DECLARE	CONST_CATEGORYID_EARLYWARININGMEMBER_LOSING INT DEFAULT 191;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustID;    
	CREATE TEMPORARY TABLE Temp_CustID (	  
		CustID	BIGINT UNSIGNED PRIMARY KEY 
     );
     
	DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;    
	CREATE TEMPORARY TABLE Temp_CustCategory (	 
			CustID				BIGINT UNSIGNED  
        ,	CategoryGroup   	SMALLINT
        ,   CategoryID			INT
        ,	IsDirect			BIT        	
        ,	IsDangerousScore	BIT DEFAULT 0
		,	Remark				VARCHAR(500)
		,	PRIMARY KEY(CustID,CategoryID)
	);
    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CustID (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    
    
    /***********************Check Dangerous Score****************************/
    INSERT IGNORE INTO Temp_CustCategory(CustID,CategoryID,CategoryGroup, IsDirect, IsDangerousScore, Remark)
    SELECT 	tmp.CustID
		,	CONST_CATEGORYID_EARLYWARININGMEMBER AS CategoryID
        ,	CONST_CATEGORYID_EARLYWARININGMEMBER AS CategoryGroup
        ,	1 AS IsDirect
        ,	1 AS IsDangerousScore
        ,	CONCAT('Detection Date: ',DATE(ltr.ClassifiedDate),' - Dangerous Score: ',FLOOR(ClassifiedScore*100),'%') AS Remark
    FROM  Temp_CustID AS tmp,
    LATERAL (SELECT cd.ClassifiedScore, ClassifiedDate
			FROM CTS_DataCenter.Customer_DangerousScore AS cd
            WHERE cd.CustID = tmp.CustID 
				AND cd.ClassifiedScore IS NOT NULL
			LIMIT 1) AS ltr;	
        
	SELECT 	cus.CTSCustID
		,	cus.CustID
		,	cus.RoleID 			 
		, 	cus.SubscriberID	 
        ,	cus.IsLicensee
		, 	tmp.CategoryID
        ,	tmp.CategoryGroup
        , 	tmp.IsDirect
		,	tmp.IsDangerousScore
		,	tmp.Remark
    FROM Temp_CustCategory AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
 
END$$

DELIMITER ;

