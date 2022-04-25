/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb" isFunction="0" isNested="1"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_RPT_AssociationDetection`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RPT_AssociationDetection`(
		IN ip_CTSCustIDs LONGTEXT
)
    SQL SECURITY INVOKER
sp:BEGIN
	/* 
		Created:	20210629@Casey.Huynh
		Task:		Get Report Association Detection
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210629@Casey.Huynh: Created [Redmine ID: #157086]
            - 20210818@Aries.Nguyen: Exclude Unlink association [Redmine ID: #159708]
            - 20211026@Aries.Nguyen: Bug Exclude Unlink association [Redmine ID: #163706]
            - 20220328@Aries.Nguyen: Add new category/class for PA Probation [Redmine ID: #170468]

		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DataCenter.CTS_DC_RPT_AssociationDetection('257861,11436');
	*/
    DECLARE lv_CustIDs LONGTEXT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustID;
	CREATE TEMPORARY TABLE 		Temp_CTSCustID (
		CTSCustID	BIGINT UNSIGNED PRIMARY KEY
	);
	
    DROP TEMPORARY TABLE IF EXISTS Temp_Unlink;    
	CREATE TEMPORARY TABLE Temp_Unlink(	  
			CTSCustID       	BIGINT UNSIGNED
        ,	AssCTSCustID 		BIGINT UNSIGNED
        ,	PRIMARY KEY(CTSCustID,AssCTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationInfo;
	CREATE TEMPORARY TABLE 		Temp_AssociationInfo (
			CTSCustID			BIGINT UNSIGNED PRIMARY KEY
        ,	CustID 				BIGINT UNSIGNED 
        ,	UserName			VARCHAR(50)
        ,	CustSubID			INT UNSIGNED
		,	CustStatus			VARCHAR(50)
        ,	INDEX 				IX_Temp_CustInfo_CustID(CustID)
	);
    
    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CTSCustID(CTSCustID) VALUES ('", REPLACE(ip_CTSCustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1; 
    
    INSERT INTO Temp_AssociationInfo(CTSCustID, CustID, UserName, CustSubID, CustStatus)
    SELECT 	cust.CTSCustID
		,	cust.CustID
        ,	cust.UserName
        ,	cust.CustSubID
        ,	sta.ItemName AS CustStatus
	FROM CTS_DataCenter.CTSCustomer AS cust
		INNER JOIN CTS_DataCenter.StaticList AS sta ON sta.ListID = 1 AND sta.ItemID = cust.CustStatusID
    WHERE EXISTS (SELECT 1 FROM Temp_CTSCustID AS temp WHERE temp.CTSCustID = cust.CTSCustID)
        AND cust.SiteID NOT IN (SELECT ex.ItemID FROM CTS_DataCenter.StaticList AS ex WHERE ex.ListID = 11);
    
    SELECT GROUP_CONCAT(CustID) 
    INTO lv_CustIDs
    FROM Temp_AssociationInfo;

    IF lv_CustIDs IS NULL THEN
		LEAVE sp;
	END IF;
	
    CALL CTS_DC_AssociationDetection_GetGroup(lv_CustIDs);
    
    INSERT INTO Temp_Unlink(CTSCustID, AssCTSCustID)
    SELECT 	tmp.CTSCustID
		,	rm.ToCTSCustID
    FROM  Temp_AssociationInfo AS tmp 
		INNER JOIN CTS_DataCenter.AssociationRemove AS rm ON rm.FromCTSCustID = tmp.CTSCustID;
	
    INSERT INTO Temp_Unlink(CTSCustID, AssCTSCustID)
    SELECT 	tmp.CTSCustID
		,	rm.FromCTSCustID
    FROM  Temp_AssociationInfo AS tmp 
		INNER JOIN CTS_DataCenter.AssociationRemove AS rm ON rm.ToCTSCustID = tmp.CTSCustID;
    
    SELECT 	grp.GroupID
		,	cus.CTSCustID
        ,	cus.CustID
		,	cus.UserName
        ,	cus.CustSubID 
        ,	cus.CustStatus
		, 	(SELECT GROUP_CONCAT(DISTINCT ' ',ev.EvidenceCode) 
			 FROM CTS_DataCenter.CustEvidence AS ce  
             LEFT JOIN CTS_DataCenter.Evidence AS ev ON ev.EvidenceID = ce.EvidenceID
             WHERE cus.CTSCustID = ce.CTSCustID 
				AND NOT EXISTS (SELECT 1 FROM Temp_Unlink AS ul WHERE ul.CTSCustID = ce.CTSCustID AND ul.AssCTSCustID = ce.FromCustID)
             ) AS Evidence
        , 	TRIM(GROUP_CONCAT(DISTINCT ' ',cat.CategoryName)) AS CustomerCategory
        ,	TRIM(GROUP_CONCAT(DISTINCT cat.CategoryID)) AS CategoryIDs
        ,	TRIM(GROUP_CONCAT(DISTINCT cat.ParentID)) AS ParentIDs
        ,   MAX(cat.IsProbation) AS IsProbation
    FROM Temp_Group AS grp
		INNER JOIN Temp_AssociationInfo AS cus ON cus.CustID = grp.CustID
        LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS ccl ON cus.CustID = ccl.CustID
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = ccl.CategoryID
	GROUP BY grp.GroupID
        , 	 cus.UserName
        ,    cus.CTSCustID
		, 	 cus.CustID  
        , 	 cus.CustStatus
        , 	 cus.CustSubID;            
   
END$$

DELIMITER ;
