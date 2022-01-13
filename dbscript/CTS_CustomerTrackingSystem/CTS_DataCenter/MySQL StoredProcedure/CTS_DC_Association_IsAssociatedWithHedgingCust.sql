/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_IsAssociatedHedgingCustByCustIDList`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_IsAssociatedHedgingCustByCustIDList`(
		IN ip_CustIDList	LONGTEXT
	,	OUT op_IsHedging	TINYINT
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20220113@Casey.Huynh
		Task :		Check CustList has any Association with a Hedging Cust
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: Created (MatchMonitor Rule) [Redmine ID: 166986]
            
		Param's Explanation (filtered by):	

		Example:
	6);
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputCust;
	CREATE TEMPORARY TABLE 		Temp_InputCust (
			CustID 	BIGINT UNSIGNED PRIMARY KEY
	);
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 		Temp_Cust (
			CTSCustID 			BIGINT UNSIGNED 
		 ,	CustID 				BIGINT UNSIGNED PRIMARY KEY
		 ,	INDEX IX_Temp_Cust_CTSCustID(CTSCustID)
	);        
   
    SET @sql = CONCAT("INSERT INTO Temp_InputCust(CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

	TRUNCATE TABLE Temp_Cust;       
	
	INSERT INTO Temp_Cust(CustID, CTSCustID) 
	SELECT	tmpIc.CustID
		,	cus.CTSCustID
	FROM Temp_InputCust AS tmpIc
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpIc.CustID = cus.CustID AND cus.CustSubID = 0;  
        
	#=======CHECK AssociationByManual====================================
	SELECT  1
	INTO op_IsHedging
	FROM Temp_Cust AS tmpCus
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = tmpCus.CTSCustID
	WHERE	tmpCus.CTSCustID IS NOT NULL
		AND	EXISTS(	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
						INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.ToCTSCustID AND cla.CustID = cus.CustID
					WHERE cla.CustID = cus.CustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
	LIMIT 1;

	IF op_IsHedging IS NOT NULL THEN 
		LEAVE sp;
	END IF;

    SELECT  1
	INTO op_IsHedging
	FROM Temp_Cust AS tmpCus
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = tmpCus.CTSCustID
	WHERE 	tmpCus.CTSCustID IS NOT NULL
		AND	EXISTS(	SELECT 1 
				FROM CTS_DataCenter.CTSCustomerClassification AS cla 
					INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.FromCTSCustID AND cla.CustID = cus.CustID
				WHERE cla.CustID = cus.CustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
	LIMIT 1;
	
	IF op_IsHedging IS NOT NULL THEN 
		LEAVE sp;
	END IF;
	
    #=======CHECK AssociationByIP====================================
    SELECT  1
	INTO op_IsHedging
	FROM Temp_Cust AS tmpCus
		INNER JOIN CTS_DataCenter.AssociationByIP AS ma ON ma.FromCustID = tmpCus.CustID
	WHERE	tmpCus.CTSCustID IS NOT NULL
		AND	EXISTS(	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
					WHERE cla.CustID = ma.ToCustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
	LIMIT 1;

	IF op_IsHedging IS NOT NULL THEN 
		LEAVE sp;
	END IF;
    
    SELECT  1
	INTO op_IsHedging
	FROM Temp_Cust AS tmpCus
		INNER JOIN CTS_DataCenter.AssociationByIP AS ma ON ma.ToCustID = tmpCus.CustID
	WHERE	tmpCus.CTSCustID IS NOT NULL
		AND	EXISTS(	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
					WHERE cla.CustID = ma.FromCustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
	LIMIT 1;

	IF op_IsHedging IS NOT NULL THEN 
		LEAVE sp;
	END IF;
	#=======CHECK AssociationByAI====================================
    SELECT  1
	INTO op_IsHedging
	FROM Temp_Cust AS tmpCus
		INNER JOIN CTS_DataCenter.AssociationByAI AS ma ON ma.FromCustID = tmpCus.CustID
	WHERE	tmpCus.CTSCustID IS NOT NULL
		AND	EXISTS(	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
					WHERE cla.CustID = ma.ToCustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
	LIMIT 1;

	IF op_IsHedging IS NOT NULL THEN 
		LEAVE sp;
	END IF;
    
    SELECT  1
	INTO op_IsHedging
	FROM Temp_Cust AS tmpCus
		INNER JOIN CTS_DataCenter.AssociationByAI AS ma ON ma.ToCustID = tmpCus.CustID
	WHERE	tmpCus.CTSCustID IS NOT NULL
		AND	EXISTS(	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
					WHERE cla.CustID = ma.FromCustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
	LIMIT 1;
    
    #=======CHECK AssociationByDevice================================
	SELECT  1
	INTO op_IsHedging
	FROM Temp_Cust AS tmpCus
		INNER JOIN CTS_DataCenter.AssociationByDevice AS ad1 ON ad1.CTSCustID = tmpCus.CTSCustID
		INNER JOIN CTS_DataCenter.AssociationByDevice AS ad2 ON ad1.DCSDeviceID = ad2.DCSDeviceID AND ad1.CTSCustID <> ad2.CTSCustID 
	WHERE	tmpCus.CTSCustID IS NOT NULL
		AND	EXISTS(	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
						INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ad2.CTSCustID AND cla.CustID = cus.CustID
					WHERE cla.CustID = cus.CustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
	LIMIT 1;
	
END$$
DELIMITER ;
