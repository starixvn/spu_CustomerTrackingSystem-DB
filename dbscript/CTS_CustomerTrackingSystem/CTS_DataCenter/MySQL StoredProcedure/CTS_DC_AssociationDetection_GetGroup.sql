/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb" isFunction="0" isNested="1"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationDetection_GetGroup`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationDetection_GetGroup`(
		IN	ip_CustIDs LONGTEXT
)
    SQL SECURITY INVOKER
sp:BEGIN
	/*  
		Created:	20210326@Aries.Nguyen
		Task:		Get Association Detection
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210720@Aries.Nguyen: Created [Redmine ID: #157086
            
		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DataCenter.CTS_DC_Association_GetGroupNLevel('257861,11436');
	*/
    DECLARE lv_CustID BIGINT UNSIGNED;
    DECLARE lv_GroupId INT DEFAULT 1;
      
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
	CREATE TEMPORARY TABLE 		Temp_Association (
			CTSCustID_1 		BIGINT UNSIGNED 
		 , 	CustID_1 			BIGINT UNSIGNED 
		 ,	CTSCustID_2 	    BIGINT UNSIGNED 
		 ,  CustID_2 	    	BIGINT UNSIGNED 
		 ,  AssociationType		SMALLINT
         ,	Level 				SMALLINT DEFAULT 1
		 ,	INDEX 				IX_Temp_Association_CTSCustID1_CTSCustID2(CTSCustID_1,CTSCustID_2)
		 ,	INDEX 				IX_Temp_Association_CustID1_CustID2(CustID_1,CustID_2)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Distinct;
	CREATE TEMPORARY TABLE 		Temp_Association_Distinct (
			CTSCustID_1 		BIGINT UNSIGNED 
		 , 	CustID_1 			BIGINT UNSIGNED 
		 ,	CTSCustID_2 	    BIGINT UNSIGNED 
		 ,  CustID_2 	    	BIGINT UNSIGNED
         ,	INDEX 				IX_Temp_Association_Distinct_CTSCustID1_CTSCustID2(CTSCustID_1,CTSCustID_2)
		 ,	INDEX 				IX_Temp_Association_Distinct_CustID1_CustID2(CustID_1,CustID_2)
	);

    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Remove;
	CREATE TEMPORARY TABLE 		Temp_Association_Remove (
			CTSCustID_1 		BIGINT UNSIGNED 
		 ,	CTSCustID_2 	    BIGINT UNSIGNED
		 ,	INDEX 				IX_Temp_Association_CTSCustID_1(CTSCustID_1)
		 ,	INDEX 				IX_Temp_Association_CTSCustID_2(CTSCustID_2)
	); 
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 		Temp_Cust (
			CTSCustID 			BIGINT UNSIGNED 
		 ,	CustID 				BIGINT UNSIGNED PRIMARY KEY
		 ,	INDEX 				IX_Temp_Cust_CTSCustID(CTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice;
	CREATE TEMPORARY TABLE 		Temp_CustDevice (
			CTSCustID			BIGINT UNSIGNED  
		 ,	DCSDeviceID  		BIGINT UNSIGNED 
		 ,	PRIMARY KEY(DCSDeviceID, CTSCustID)
	);  
    

    
	DROP TEMPORARY TABLE IF EXISTS Temp_Device_Level0;
	CREATE TEMPORARY TABLE 		Temp_Device_Level0 (
		    DCSDeviceID			BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice_Level1;
	CREATE TEMPORARY TABLE 		Temp_CustDevice_Level1 (
		    CTSCustID			BIGINT UNSIGNED  
		 ,	DCSDeviceID  		BIGINT UNSIGNED 
		 ,	PRIMARY KEY(DCSDeviceID, CTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level1;
	CREATE TEMPORARY TABLE 		Temp_Association_Level1 (
		    CTSCustID			BIGINT UNSIGNED 
		,	CTSCustID_Level1	BIGINT UNSIGNED	 
        ,	CustID				BIGINT UNSIGNED 
		,	CustID_Level1		BIGINT UNSIGNED
        ,	AssociationType		SMALLINT
        ,	INDEX				IX_Temp_Association_CTSCustID_Level1_(CTSCustID_Level1)
        ,	INDEX 				IX_Temp_Association_CTSCustID_CTSCustID(CTSCustID, CTSCustID_Level1)
        ,	INDEX				IX_Temp_Association_CustID(CustID_Level1)
        ,	INDEX 				IX_Temp_Association_CustID_Level1(CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level1_Distinct;
	CREATE TEMPORARY TABLE 		Temp_Association_Level1_Distinct (
		    CTSCustID			BIGINT UNSIGNED 
		,	CTSCustID_Level1	BIGINT UNSIGNED	 
		,	PRIMARY KEY 		PK_Temp_Association_Level1_Distinct(CTSCustID_Level1, CTSCustID )
	);
    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Level1_Info;
	CREATE TEMPORARY TABLE 		Temp_Level1_Info (
		    CTSCustID			BIGINT UNSIGNED 
        ,	CustID				BIGINT UNSIGNED 
        ,	INDEX				IX_Temp_Level1_Info(CTSCustID)
	);

    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCust_Group;
	CREATE TEMPORARY TABLE 		Temp_DeviceCust_Group (
			DCSDeviceID  		BIGINT UNSIGNED PRIMARY KEY
		 ,	TotalCust			INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceLevel1_Group;
	CREATE TEMPORARY TABLE 		Temp_DeviceLevel1_Group (
			CTSCustID  		BIGINT UNSIGNED PRIMARY KEY
		 ,	TotalCust		INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Group;
	CREATE TEMPORARY TABLE 		Temp_Group (
		    CustID 				BIGINT UNSIGNED 
		 ,	CTSCustID 			BIGINT UNSIGNED 
		 ,	GroupID 			INT
		 ,	INDEX			    IX_Temp_Group(CTSCustID)
		 ,	PRIMARY KEY (CustID)
         
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;
	CREATE TEMPORARY TABLE 		Temp_CustInfo (
		 	CustID 			BIGINT UNSIGNED PRIMARY KEY
	);
    
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CustInfo (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;  
	
    INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID)
	SELECT IFNULL(cus.CTSCustID,0), tmp.CustID
	FROM Temp_CustInfo AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON tmp.CustID = cus.CustID AND cus.CustSubID = 0;
        
	DROP TEMPORARY TABLE IF EXISTS Temp_Cust_Duplicate;
	CREATE TEMPORARY TABLE Temp_Cust_Duplicate LIKE Temp_Cust;
	INSERT INTO Temp_Cust_Duplicate
	SELECT * FROM Temp_Cust;
    
/*------------Get association Device ------------------*/
	INSERT IGNORE INTO Temp_CustDevice(CTSCustID, DCSDeviceID)
	SELECT 	cus.CTSCustID 
		, 	dv.DCSDeviceID
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM CTS_DataCenter.DeviceAssociationDay AS dd WHERE dd.DCSDeviceID = dv.DCSDeviceID);
	# select * from Temp_CustDevice;
    
    INSERT INTO Temp_Device_Level0(DCSDeviceID)
    SELECT 	DISTINCT
			DCSDeviceID
	FROM Temp_CustDevice;
    
    INSERT IGNORE INTO Temp_CustDevice_Level1(CTSCustID,DCSDeviceID)
    SELECT  lv1.CTSCustID
		,	dv.DCSDeviceID
    FROM Temp_Device_Level0 AS dv
		INNER JOIN CTS_DataCenter.AssociationByDevice AS lv1 ON dv.DCSDeviceID =  lv1.DCSDeviceID
    WHERE  NOT EXISTS (SELECT 1 FROM Temp_Cust AS cust WHERE lv1.CTSCustID =  cust.CTSCustID);
	
    INSERT IGNORE INTO Temp_Association_Level1(CTSCustID, CTSCustID_Level1, AssociationType)
    SELECT 	cuDv.CTSCustID
		, 	lv1.CTSCustID
        ,	1 AS AssociationType
	FROM Temp_CustDevice AS cuDv
		INNER JOIN Temp_CustDevice_Level1 AS lv1 ON cuDv.DCSDeviceID =  lv1.DCSDeviceID;
	
	INSERT INTO Temp_DeviceCust_Group(DCSDeviceID, TotalCust)
	SELECT 	DCSDeviceID
		, 	COUNT(1) AS TotalCust
	FROM Temp_CustDevice 
	GROUP BY DCSDeviceID;

	DELETE FROM Temp_CustDevice AS tmp
	WHERE tmp.DCSDeviceID IN (SELECT DCSDeviceID FROM Temp_DeviceCust_Group WHERE TotalCust = 1);
	# select * from Temp_DeviceCust_Group;

	DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice_Duplicate;
	CREATE TEMPORARY TABLE Temp_CustDevice_Duplicate LIKE Temp_CustDevice;
	INSERT INTO Temp_CustDevice_Duplicate 
	SELECT * FROM Temp_CustDevice;

	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType, Level)
	SELECT 	DISTINCT 
			dv.CTSCustID
		,  	dv1.CTSCustID  
        , 	1 AS AssociationType
        ,	1 AS Level
	FROM Temp_CustDevice AS dv
		INNER JOIN Temp_CustDevice_Duplicate AS dv1 ON dv.DCSDeviceID = dv1.DCSDeviceID AND dv.CTSCustID != dv1.CTSCustID;

/*---------------------------------------------Get Association Manual --------------------------------------- */
    INSERT IGNORE INTO Temp_Association_Level1(CTSCustID, CTSCustID_Level1, AssociationType)
    SELECT  cus.CTSCustID
		, 	ma.ToCTSCustID
        ,  	2 AS AssociationType
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = cus.CTSCustID;
    
    INSERT IGNORE INTO Temp_Association_Level1(CTSCustID, CTSCustID_Level1, AssociationType)
    SELECT  cus.CTSCustID
		, 	ma.FromCTSCustID
        ,  	2 AS AssociationType
	FROM Temp_Cust AS cus 
        INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = cus.CTSCustID;
        
  /*----------------------------------------------Get association by AI-------------------------------------------*/
	INSERT IGNORE INTO Temp_Association_Level1(CustID, CustID_Level1, AssociationType)
    SELECT  cus.CustID
		, 	ai.ToCustID
        ,  	3 AS AssociationType
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = cus.CustID;
    
    INSERT IGNORE INTO Temp_Association_Level1(CustID, CustID_Level1, AssociationType)
    SELECT  cus.CustID
		, 	ai.FromCustID
        ,  	3 AS AssociationType
	FROM Temp_Cust AS cus 
        INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = cus.CustID;
    

/*------------------------------------------Get association by IP-------------------------------------------------*/
	INSERT IGNORE INTO Temp_Association_Level1(CustID, CustID_Level1, AssociationType)
    SELECT  cus.CustID
		, 	ip.ToCustID
        ,  	4 AS AssociationType
	FROM Temp_Cust AS cus 
        INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = cus.CustID;
    
    INSERT IGNORE INTO Temp_Association_Level1(CustID, CustID_Level1, AssociationType)
    SELECT  cus.CustID
		, 	ip.FromCustID
        ,  	4 AS AssociationType
	FROM Temp_Cust AS cus 
        INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = cus.CustID;
    
/*******************************Level 2**********************************************/
	INSERT IGNORE INTO Temp_CustInfo(CustID)
	SELECT lv1.CustID
	FROM Temp_Association_Level1 AS lv1
    WHERE lv1.CTSCustID IS NULL;
    
    INSERT IGNORE INTO Temp_CustInfo(CustID)
	SELECT lv1.CustID_Level1
	FROM Temp_Association_Level1 AS lv1
    WHERE lv1.CTSCustID_Level1 IS NULL;
    
	INSERT INTO Temp_Level1_Info(CTSCustID, CustID)
    SELECT 	cust.CTSCustID
		, 	cust.CustID
    FROM Temp_CustInfo AS info
		INNER JOIN CTSCustomer AS cust ON cust.CustID = info.CustID AND CustSubID = 0;


    UPDATE Temp_Association_Level1 AS lv1
		INNER JOIN Temp_Level1_Info AS info ON info.CustID = lv1.CustID
	SET lv1.CTSCustID = info.CTSCustID;
    
    UPDATE Temp_Association_Level1 AS lv1
		INNER JOIN Temp_Level1_Info AS info ON info.CustID = lv1.CustID_Level1
	SET lv1.CTSCustID_Level1 = info.CTSCustID;
	
    INSERT IGNORE Temp_Association_Level1_Distinct(CTSCustID,CTSCustID_Level1)
    SELECT DISTINCT
		   CTSCustID
		,  CTSCustID_Level1
    FROM Temp_Association_Level1;
    
	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType, Level)
	SELECT 	cus.CTSCustID
		,  	lv1.CTSCustID_Level1  
        , 	0 AS AssociationType 
        ,	1 AS Level
	FROM Temp_Cust AS cus 
        INNER JOIN Temp_Association_Level1_Distinct AS lv1 ON lv1.CTSCustID = cus.CTSCustID AND lv1.CTSCustID_Level1 != cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS dup WHERE dup.CTSCustID = lv1.CTSCustID_Level1);
    
    INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType, Level)
	SELECT 	cus.CTSCustID
		,  	lv1.CTSCustID  
        , 	0 AS AssociationType 
        ,	1 AS Level
	FROM Temp_Cust AS cus 
        INNER JOIN Temp_Association_Level1_Distinct AS lv1 ON lv1.CTSCustID_Level1 = cus.CTSCustID AND lv1.CTSCustID != cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS dup WHERE dup.CTSCustID = lv1.CTSCustID);
    
    DELETE 
    FROM Temp_Association_Level1_Distinct AS lv1
    WHERE EXISTS (SELECT 1 FROM Temp_Association AS ass WHERE ass.CTSCustID_1 = lv1.CTSCustID AND ass.CTSCustID_2 = lv1.CTSCustID_Level1);
    
    DELETE 
    FROM Temp_Association_Level1_Distinct AS lv1
    WHERE EXISTS (SELECT 1 FROM Temp_Association AS ass WHERE ass.CTSCustID_2 = lv1.CTSCustID AND ass.CTSCustID_1  = lv1.CTSCustID_Level1);
    
	INSERT INTO Temp_DeviceLevel1_Group(CTSCustID, TotalCust)
	SELECT 	CTSCustID_Level1
		, 	COUNT(1) AS TotalCust
	FROM Temp_Association_Level1_Distinct 
	GROUP BY CTSCustID_Level1;
    

    DELETE
    FROM Temp_Association_Level1_Distinct AS tmp
	WHERE tmp.CTSCustID_Level1 IN (SELECT CTSCustID FROM Temp_DeviceLevel1_Group WHERE TotalCust = 1);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level1_Distinct_Duplicate;
	CREATE TEMPORARY TABLE Temp_Association_Level1_Distinct_Duplicate LIKE Temp_Association_Level1_Distinct;
	INSERT INTO Temp_Association_Level1_Distinct_Duplicate 
	SELECT * FROM Temp_Association_Level1_Distinct;
    
    INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType, Level)
	SELECT 	DISTINCT 
			lv1.CTSCustID
		,  	lv2.CTSCustID  
        , 	0 AS AssociationType 
        ,	2 AS Level
	FROM Temp_Association_Level1_Distinct AS lv1
		INNER JOIN Temp_Association_Level1_Distinct_Duplicate AS lv2 ON lv1.CTSCustID_Level1 = lv2.CTSCustID_Level1 AND lv1.CTSCustID != lv2.CTSCustID;

#-----------------------------------------------------------Update CustId, CTSCustID of Association table------------------------------------------------
	INSERT IGNORE INTO Temp_Association_Distinct(CTSCustID_1, CustID_1, CTSCustID_2, CustID_2)
	SELECT 	DISTINCT 
			CTSCustID_1
		, 	CustID_1
        , 	CTSCustID_2
        , 	CustID_2 
	FROM Temp_Association;
    
	UPDATE Temp_Association_Distinct AS ass
		INNER JOIN Temp_Cust AS cus ON ass.CustID_1 = cus.CustID
	SET ass.CTSCustID_1 = cus.CTSCustID
	WHERE ass.CTSCustID_1 IS NULL;

	UPDATE Temp_Association_Distinct AS ass
		INNER JOIN Temp_Cust AS cus ON ass.CustID_2 = cus.CustID
	SET ass.CTSCustID_2 = cus.CTSCustID
	WHERE ass.CTSCustID_2 IS NULL;

	UPDATE Temp_Association_Distinct AS ass
		INNER JOIN Temp_Cust AS cus ON ass.CTSCustID_1 = cus.CTSCustID
	SET ass.CustID_1 = cus.CustID
	WHERE ass.CustID_1 IS NULL;

	UPDATE Temp_Association_Distinct AS ass
		INNER JOIN Temp_Cust AS cus ON ass.CTSCustID_2 = cus.CTSCustID
	SET ass.CustID_2 = cus.CustID
	WHERE ass.CustID_2 IS NULL;

#-----------------------------------------------------------------Handle Association Remove-------------------------------------------------------
	INSERT INTO Temp_Association_Remove(CTSCustID_1, CTSCustID_2)
	SELECT 	FromCTSCustID
		, 	ToCTSCustID 
	FROM CTS_DataCenter.AssociationRemove AS rm
	WHERE EXISTS (SELECT 1 FROM Temp_Association_Distinct AS ass WHERE  rm.FromCTSCustID = ass.CTSCustID_1 AND rm.ToCTSCustID = ass.CTSCustID_2);

	INSERT INTO Temp_Association_Remove(CTSCustID_1, CTSCustID_2)
	SELECT 	FromCTSCustID
		, 	ToCTSCustID 
	FROM CTS_DataCenter.AssociationRemove AS rm
	WHERE EXISTS (SELECT 1 FROM Temp_Association_Distinct AS ass WHERE  rm.FromCTSCustID = ass.CTSCustID_2 AND rm.ToCTSCustID = ass.CTSCustID_1);

	DELETE 
    FROM Temp_Association_Distinct AS ass
	WHERE EXISTS (SELECT 1 FROM Temp_Association_Remove AS rm WHERE  rm.CTSCustID_1 = ass.CTSCustID_1 AND rm.CTSCustID_2 = ass.CTSCustID_2);

	#select * from Temp_Association;
	lp: LOOP 
		SET lv_CustID = (SELECT CustID_1
							FROM Temp_Association_Distinct
							GROUP BY CustID_1
							ORDER BY count(1) DESC
							LIMIT 1);
        
        IF lv_CustID IS NULL 
        THEN
            LEAVE lp; 
        END IF;
        
        INSERT INTO Temp_Group(CustID,GroupID)
		WITH RECURSIVE CTE_Group AS ( 
			SELECT lv_CustID AS CustID
			UNION
			SELECT ass.CustID_2 
            FROM Temp_Association_Distinct  AS ass
				JOIN CTE_Group ON CTE_Group.CustID = ass.CustID_1
		) 
		SELECT CustID, lv_GroupId FROM CTE_Group;
        
        DELETE FROM Temp_Association_Distinct AS ass
        WHERE EXISTS (SELECT 1 FROM Temp_Group AS grp WHERE ass.CustID_1 = grp.CustID);
        
		SET lv_GroupId = lv_GroupId + 1;
		
	END LOOP;
    
    UPDATE Temp_Group AS grp 
		INNER JOIN Temp_Cust AS cus	ON grp.CustID = cus.CustID
    SET grp.CTSCustID = cus.CTSCustID;

END$$

DELIMITER ;
