/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_IsAssociatedHedgingCustByCustIDList`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_IsAssociatedHedgingCustByCustIDList`(
		IN	ip_CustIDList	LONGTEXT
	,	OUT	op_IsHedging	TINYINT
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
			CALL CTS_DC_Association_IsAssociatedHedgingCustByCustIDList('37144067,37144068', @op_IsHedging);

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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByDevice;
    CREATE TEMPORARY TABLE Temp_AssociationByDevice(
			DeviceID	BIGINT UNSIGNED
		,	CTSCustID	BIGINT UNSIGNED
        
        ,	PRIMARY KEY	PK_Temp_Association(DeviceID, CTSCustID)    
        ,	INDEX IX_Temp_AssociationByDevice_CTSCustID(CTSCustID)    
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Device;
    CREATE TEMPORARY TABLE Temp_Device(
		DeviceID	BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
    CREATE TEMPORARY TABLE Temp_Association(
			FromCTSCustID	BIGINT UNSIGNED
		,	ToCTSCustID		BIGINT UNSIGNED
        
		,	PRIMARY KEY	PK_Temp_Association(FromCTSCustID,ToCTSCustID)
        ,	INDEX	IX_Temp_Association(FromCTSCustID,ToCTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationRemove;
    CREATE TEMPORARY TABLE Temp_AssociationRemove(
			FromCTSCustID	BIGINT UNSIGNED
		,	ToCTSCustID		BIGINT UNSIGNED
        
        ,	PRIMARY KEY	IX_Temp_AssociationRemove_FromCTSCustID(FromCTSCustID,ToCTSCustID)
	);   
   
    SET @sql = CONCAT("INSERT INTO Temp_InputCust(CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

	INSERT INTO Temp_Cust(CustID, CTSCustID) 
	SELECT	tmpIc.CustID
		,	cus.CTSCustID
	FROM Temp_InputCust AS tmpIc
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpIc.CustID = cus.CustID AND cus.CustSubID = 0;  

    #=======CHECK AssociationByIP====================================
    SELECT  1
	INTO op_IsHedging
	FROM Temp_Cust AS tmpCus
		INNER JOIN CTS_DataCenter.AssociationByIP AS ma ON ma.FromCustID = tmpCus.CustID
        LEFT JOIN CTS_DataCenter.AssociationRemove AS ar ON ma.FromCustID = ar.FromCustID AND ma.ToCustID = ar.ToCustID
	WHERE	tmpCus.CTSCustID IS NOT NULL AND ar.FromCustID IS NULL
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
        LEFT JOIN CTS_DataCenter.AssociationRemove AS ar ON ma.FromCustID = ar.FromCustID AND ma.ToCustID = ar.ToCustID
	WHERE	tmpCus.CTSCustID IS NOT NULL AND ar.FromCustID IS NULL
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
        LEFT JOIN CTS_DataCenter.AssociationRemove AS ar ON ma.FromCustID = ar.FromCustID AND ma.ToCustID = ar.ToCustID
	WHERE	tmpCus.CTSCustID IS NOT NULL AND ar.FromCustID IS NULL
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
        LEFT JOIN CTS_DataCenter.AssociationRemove AS ar ON ma.FromCustID = ar.FromCustID AND ma.ToCustID = ar.ToCustID
	WHERE	tmpCus.CTSCustID IS NOT NULL AND ar.FromCustID IS NULL
		AND	EXISTS(	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
					WHERE cla.CustID = ma.FromCustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
	LIMIT 1;
    
	IF op_IsHedging IS NOT NULL THEN 
		LEAVE sp;
	END IF;
    #=======CHECK AssociationByManual====================================
	SELECT  1
	INTO op_IsHedging
	FROM Temp_Cust AS tmpCus
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = tmpCus.CTSCustID
        LEFT JOIN CTS_DataCenter.AssociationRemove AS ar ON ma.FromCTSCustID = ar.FromCTSCustID AND ma.ToCTSCustID = ar.ToCTSCustID
	WHERE	tmpCus.CTSCustID IS NOT NULL 
		AND ar.FromCTSCustID IS NULL
		AND	EXISTS(	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
					WHERE cla.CTSCustID = ma.ToCTSCustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
	LIMIT 1;

	IF op_IsHedging IS NOT NULL THEN 
		LEAVE sp;
	END IF;

    SELECT  1
	INTO op_IsHedging
	FROM Temp_Cust AS tmpCus
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = tmpCus.CTSCustID
        LEFT JOIN CTS_DataCenter.AssociationRemove AS ar ON ma.FromCTSCustID = ar.FromCTSCustID AND ma.ToCTSCustID = ar.ToCTSCustID
	WHERE	tmpCus.CTSCustID IS NOT NULL 
		AND ar.FromCTSCustID IS NULL
		AND	EXISTS(	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
					WHERE cla.CTSCustID = ma.FromCTSCustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
	LIMIT 1;
	
	IF op_IsHedging IS NOT NULL THEN 
		LEAVE sp;
	END IF;
    
    #=======CHECK AssociationByDevice================================       
    
    INSERT INTO Temp_AssociationByDevice(DeviceID, CTSCustID)
    SELECT	adv.DCSDeviceID
		,	adv.CTSCustID
	FROM Temp_Cust AS tmpCus
		INNER JOIN CTS_DataCenter.AssociationByDevice AS adv ON adv.CTSCustID = tmpCus.CTSCustID
	WHERE tmpCus.CTSCustID IS NOT NULL;
    
	INSERT INTO Temp_Device(DeviceID)
	SELECT	tmpAdv.DeviceID		
	FROM 	Temp_AssociationByDevice AS tmpAdv
	WHERE 	tmpAdv.CTSCustID IS NOT NULL
    GROUP BY tmpAdv.DeviceID	
    HAVING COUNT(1) > 0;
    
    DELETE tmpAdv
    FROM Temp_AssociationByDevice AS tmpAdv
		LEFT JOIN Temp_Device AS tmpDv ON tmpAdv.DeviceID = tmpDv.DeviceID
	WHERE tmpDv.DeviceID IS NULL;
    
    TRUNCATE TABLE Temp_Cust;
    
    IF EXISTS (SELECT 1 FROM Temp_AssociationByDevice AS tmpAdv
				INNER JOIN CTS_DataCenter.AssociationRemove AS ar ON tmpAdv.CTSCustID = ar.FromCTSCustID OR tmpAdv.CTSCustID = ar.ToCTSCustID) THEN
	
    INSERT IGNORE INTO Temp_Association(FromCTSCustID, ToCTSCustID)
    SELECT LEAST(tmpAdv.CTSCustID,adv.CTSCustID), GREATEST(tmpAdv.CTSCustID,adv.CTSCustID)
    FROM Temp_AssociationByDevice AS tmpAdv
		INNER JOIN  CTS_DataCenter.AssociationByDevice AS adv ON tmpAdv.DeviceID = adv.DCSDeviceID AND tmpAdv.CTSCustID <> adv.CTSCustID;
    
    DELETE tmpAss
    FROM Temp_Association AS tmpAss
		INNER JOIN AssociationRemove AS tmpAr ON tmpAss.FromCTSCustID = tmpAr.FromCTSCustID AND tmpAss.ToCTSCustID = tmpAr.ToCTSCustID;
    
	SELECT  1
	INTO op_IsHedging
	FROM Temp_Association AS tmpAss
	WHERE EXISTS(	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
					WHERE cla.CTSCustID = tmpAss.FromCTSCustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
	LIMIT 1;
    
    IF op_IsHedging IS NOT NULL THEN 
		LEAVE sp;
	END IF;
    
    SELECT  1
	INTO op_IsHedging
	FROM Temp_Association AS tmpAss
	WHERE EXISTS(	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
					WHERE cla.CTSCustID = tmpAss.ToCTSCustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
	LIMIT 1;	
       
    ELSE
		SELECT  1
		INTO op_IsHedging
        FROM Temp_Device AS tmpAdv
			INNER JOIN CTS_DataCenter.AssociationByDevice AS adv ON adv.DeviceID = tmpAdv.DeviceID
		WHERE EXISTS(	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
					WHERE cla.CTSCustID = adv.CTSCustID AND cla.SportGroupID = 0 AND cla.CategoryID in (73,53,153))
		LIMIT 1;	
	END IF;
END$$
DELIMITER ;
