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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationDevice_Level1;
	CREATE TEMPORARY TABLE 		Temp_AssociationDevice_Level1 (
		    CTSCustID			BIGINT UNSIGNED 
		,	Level1				BIGINT UNSIGNED	        
        ,	INDEX				IX_Temp_AssociationDevice_Level1_(Level1,CTSCustID)
        ,	PRIMARY KEY(CTSCustID, Level1)
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
		 	CustID 			BIGINT UNSIGNED 
	);
    
	SET @sql = 	CONCAT("INSERT INTO Temp_CustInfo (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;  
	
    INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID)
	SELECT IFNULL(cus.CTSCustID,0), tmp.CustID
	FROM Temp_CustInfo AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON tmp.CustID = cus.CustID AND cus.CustSubID = 0;
    
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
	
    INSERT IGNORE INTO Temp_AssociationDevice_Level1(CTSCustID, Level1)
    SELECT 	cuDv.CTSCustID
		, 	lv1.CTSCustID
	FROM Temp_CustDevice AS cuDv
		INNER JOIN Temp_CustDevice_Level1 AS lv1 ON cuDv.DCSDeviceID =  lv1.DCSDeviceID;
	
    INSERT INTO Temp_DeviceLevel1_Group(CTSCustID, TotalCust)
	SELECT 	Level1
		, 	COUNT(1) AS TotalCust
	FROM Temp_AssociationDevice_Level1 
	GROUP BY Level1;
    
    DELETE FROM Temp_AssociationDevice_Level1 AS tmp
	WHERE tmp.CTSCustID IN (SELECT CTSCustID FROM Temp_DeviceLevel1_Group WHERE TotalCust = 1);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationDevice_Level1_Duplicate;
	CREATE TEMPORARY TABLE Temp_AssociationDevice_Level1_Duplicate LIKE Temp_AssociationDevice_Level1;
	INSERT INTO Temp_AssociationDevice_Level1_Duplicate 
	SELECT * FROM Temp_AssociationDevice_Level1;
    
    INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType, Level)
	SELECT 	DISTINCT 
			lv1.CTSCustID
		,  	lv2.CTSCustID  
        , 	1 AS AssociationType 
        ,	2 AS Level
	FROM Temp_AssociationDevice_Level1 AS lv1
		INNER JOIN Temp_AssociationDevice_Level1_Duplicate AS lv2 ON lv1.Level1 = lv2.Level1 AND lv1.CTSCustID != lv2.CTSCustID;
    
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
	DROP TEMPORARY TABLE IF EXISTS Temp_Cust_Duplicate;
	CREATE TEMPORARY TABLE Temp_Cust_Duplicate LIKE Temp_Cust;
	INSERT INTO Temp_Cust_Duplicate
	SELECT * FROM Temp_Cust;
    
    /*-------Manual Level 1---------*/
    
	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType, Level)
	SELECT  cus.CTSCustID
		,  	ma.ToCTSCustID
        , 	2 AS AssociationType
        , 	1 AS Level
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma.ToCTSCustID);

	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType, Level)
	SELECT  ma.ToCTSCustID
		, 	cus.CTSCustID
        , 	2 AS AssociationType
        , 	1 AS Level
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma.ToCTSCustID);

	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType, Level)
	SELECT  cus.CTSCustID
		,  	ma.FromCTSCustID
        , 	2 AS AssociationType
        , 	1 AS Level
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma.FromCTSCustID);

	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType, Level)
	SELECT  ma.FromCTSCustID
		, 	cus.CTSCustID
        ,   2 AS AssociationType
        , 	1 AS Level
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma.FromCTSCustID);
    
    /*-------Manual Level 2---------*/
    
    INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType, Level)
    SELECT  ma1.FromCTSCustID
		, 	ma2.ToCTSCustID
        ,  	2 AS AssociationType
        , 	2 AS Level
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma1 ON ma1.FromCTSCustID = cus.CTSCustID
        INNER JOIN CTS_DataCenter.AssociationByManual AS ma2 ON ma2.FromCTSCustID = ma1.ToCTSCustID AND ma1.FromCTSCustID != ma2.ToCTSCustID
    WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma2.ToCTSCustID);
    
    INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType, Level)
    SELECT  ma1.FromCTSCustID
		, 	ma2.FromCTSCustID
        ,  	2 AS AssociationType
        , 	2 AS Level
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma1 ON ma1.FromCTSCustID = cus.CTSCustID
        INNER JOIN CTS_DataCenter.AssociationByManual AS ma2 ON ma2.ToCTSCustID = ma1.ToCTSCustID AND ma1.FromCTSCustID != ma2.FromCTSCustID
    WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma2.FromCTSCustID);

  /*----------------------------------------------Get association by AI-------------------------------------------*/
	
     /*-------AI Level 1---------*/
    
	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType, Level)
	SELECT  cus.CustID
		,  	ai.ToCustID
        , 	3 AS AssociationType
        , 	1 AS Level
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = cus.CustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai.ToCustID);

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType, Level)
	SELECT	ai.ToCustID
		, 	cus.CustID
        ,  	3 AS AssociationType
        , 	1 AS Level
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = cus.CustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai.ToCustID);

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType, Level)
	SELECT  cus.CustID
		,  	ai.FromCustID
        , 	3 AS AssociationType
        , 	1 AS Level
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = cus.CustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai.FromCustID);

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType, Level)
	SELECT  ai.FromCustID
		, 	cus.CustID
        ,  	3 AS AssociationType
        , 	1 AS Level
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = cus.CustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai.FromCustID);
    
    /*-------AI Level 2---------*/
    
    INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType, Level)
    SELECT  ai1.FromCustID
		, 	ai2.ToCustID
        ,  	3 AS AssociationType
        , 	2 AS Level
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai1 ON ai1.FromCustID = cus.CustID
        INNER JOIN CTS_DataCenter.AssociationByAI AS ai2 ON ai2.FromCustID = ai1.ToCustID AND ai1.FromCustID != ai2.ToCustID
    WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai2.ToCustID);
    
    INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType, Level)
    SELECT  ai1.FromCustID
		, 	ai2.FromCustID
        ,  	3 AS AssociationType
        , 	2 AS Level
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai1 ON ai1.FromCustID = cus.CustID
        INNER JOIN CTS_DataCenter.AssociationByAI AS ai2 ON ai2.ToCustID = ai1.ToCustID AND ai1.FromCustID != ai2.FromCustID
    WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai2.FromCustID);
    

/*------------------------------------------Get association by IP-------------------------------------------------*/
	/*-------IP Level 1---------*/
    
	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType, Level)
	SELECT  cus.CustID
		,  	ip.ToCustID
        , 	4 AS AssociationType
        , 	1 AS Level
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = cus.CustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ip.ToCustID);

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType, Level)
	SELECT  ip.ToCustID
		, 	cus.CustID
        ,  	4 AS AssociationType
        , 	1 AS Level
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = cus.CustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ip.ToCustID);

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType, Level)
	SELECT 	cus.CustID
		,  	ip.FromCustID
        , 	4 AS AssociationType
        , 	1 AS Level
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = cus.CustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ip.FromCustID);

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType, Level)
	SELECT  ip.FromCustID
		, 	cus.CustID
        ,  	4 AS AssociationType
        , 	1 AS Level
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = cus.CustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ip.FromCustID);
    
    /*-------IP Level 2---------*/
    
    INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType, Level)
    SELECT  ip1.FromCustID
		, 	ip2.ToCustID
        ,  	4 AS AssociationType
        , 	2 AS Level
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip1 ON ip1.FromCustID = cus.CustID
        INNER JOIN CTS_DataCenter.AssociationByIP AS ip2 ON ip2.FromCustID = ip1.ToCustID AND ip1.FromCustID != ip2.ToCustID
    WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ip2.ToCustID);
    
    INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType, Level)
    SELECT  ip1.FromCustID
		, 	ip2.FromCustID
        ,  	4 AS AssociationType
        , 	2 AS Level
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip1 ON ip1.FromCustID = cus.CustID
        INNER JOIN CTS_DataCenter.AssociationByIP AS ip2 ON ip2.ToCustID = ip1.ToCustID AND ip1.FromCustID != ip2.FromCustID
    WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ip2.FromCustID);

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
