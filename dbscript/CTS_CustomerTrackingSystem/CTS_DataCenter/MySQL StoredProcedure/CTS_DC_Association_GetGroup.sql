/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb" isFunction="0" isNested="1"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_Association_GetGroup`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_GetGroup`(
		IN ip_CustIDs LONGTEXT
)
    SQL SECURITY INVOKER
sp:BEGIN
	/* 
		Created:	20210326@Aries.Nguyen
		Task:		Get Association Group by list custID
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210326@Aries.Nguyen: Created [Redmine ID: #148998]
            - 20210818@Aries.Nguyen: Exclude Unlink association [Redmine ID: #159708]
			- 20210915@Aries.Nguyen: Remove DeviceAssociationDay table [Redmine ID: #160470]

		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_Association_GetGroup(200);
	*/
    DECLARE lv_CustID BIGINT UNSIGNED;
    DECLARE lv_GroupId INT DEFAULT 1;
      
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
	CREATE TEMPORARY TABLE 		Temp_Association (
			CTSCustID_1 		BIGINT UNSIGNED DEFAULT 0
		 , 	CustID_1 			BIGINT UNSIGNED DEFAULT 0
		 ,	CTSCustID_2 	    BIGINT UNSIGNED DEFAULT 0
		 ,  CustID_2 	    	BIGINT UNSIGNED DEFAULT 0
		 ,  AssociationType		SMALLINT
		 ,	INDEX IX_Temp_Association_CTSCustID1_CTSCustID2(CTSCustID_1,CTSCustID_2)
		 ,	INDEX IX_Temp_Association_CustID1_CustID2(CustID_1,CustID_2)
	);

    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Remove;
	CREATE TEMPORARY TABLE 		Temp_Association_Remove (
			CTSCustID_1 		BIGINT UNSIGNED 
		 ,	CTSCustID_2 	    BIGINT UNSIGNED
		 ,	INDEX IX_Temp_Association_CTSCustID_1(CTSCustID_1)
		 ,	INDEX IX_Temp_Association_CTSCustID_2(CTSCustID_2)
	); 
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 		Temp_Cust (
			CTSCustID 			BIGINT UNSIGNED 
		 ,	CustID 				BIGINT UNSIGNED PRIMARY KEY
		 ,	INDEX IX_Temp_Cust_CTSCustID(CTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice;
	CREATE TEMPORARY TABLE 		Temp_CustDevice (
			CTSCustID			BIGINT UNSIGNED  
		 ,	DCSDeviceID  		BIGINT UNSIGNED 
		 ,	PRIMARY KEY(DCSDeviceID, CTSCustID)
	);  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCust_Group;
	CREATE TEMPORARY TABLE 		Temp_DeviceCust_Group (
			DCSDeviceID  		BIGINT UNSIGNED PRIMARY KEY
		 ,	TotalCust			INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Group;
	CREATE TEMPORARY TABLE 		Temp_Group (
		    CustID 				BIGINT UNSIGNED 
		 ,	GroupID 			INT
         ,	IsHedging			BIT DEFAULT 0
		 ,	PRIMARY KEY (CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustHedging;
	CREATE TEMPORARY TABLE 		Temp_CustHedging (
		    CustID 				BIGINT UNSIGNED PRIMARY KEY
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
    
#------------Get association Device ------------------#
	INSERT IGNORE INTO Temp_CustDevice(CTSCustID, DCSDeviceID)
	SELECT 	cus.CTSCustID 
		, 	dv.DCSDeviceID
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID = cus.CTSCustID;
	# select * from Temp_CustDevice;


	INSERT INTO Temp_DeviceCust_Group(DCSDeviceID, TotalCust)
	SELECT 	DCSDeviceID
		, 	COUNT(1) AS TotalCust
	FROM Temp_CustDevice 
	GROUP BY DCSDeviceID;

	DELETE tmp
    FROM Temp_CustDevice AS tmp
	WHERE tmp.DCSDeviceID IN (SELECT DCSDeviceID FROM Temp_DeviceCust_Group WHERE TotalCust = 1);
	# select * from Temp_DeviceCust_Group;

	DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice_Duplicate;
	CREATE TEMPORARY TABLE Temp_CustDevice_Duplicate LIKE Temp_CustDevice;
	INSERT INTO Temp_CustDevice_Duplicate 
	SELECT * FROM Temp_CustDevice;

	INSERT INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType)
	SELECT DISTINCT dv.CTSCustID,  dv1.CTSCustID  , 1
	FROM Temp_CustDevice AS dv
		INNER JOIN Temp_CustDevice_Duplicate AS dv1 ON dv.DCSDeviceID = dv1.DCSDeviceID AND dv.CTSCustID != dv1.CTSCustID;

#------------Get association manual ------------------
	DROP TEMPORARY TABLE IF EXISTS Temp_Cust_Duplicate;
	CREATE TEMPORARY TABLE Temp_Cust_Duplicate LIKE Temp_Cust;
	INSERT INTO Temp_Cust_Duplicate
	SELECT * FROM Temp_Cust;
    
	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType)
	SELECT  cus.CTSCustID,  ma.ToCTSCustID, 2
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma.ToCTSCustID);

	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType)
	SELECT  ma.ToCTSCustID, cus.CTSCustID, 2
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma.ToCTSCustID);

	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType)
	SELECT  cus.CTSCustID,  ma.FromCTSCustID, 2
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma.FromCTSCustID);

	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType)
	SELECT  ma.FromCTSCustID, cus.CTSCustID,   2
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma.FromCTSCustID);

#----------------------Get association by AI-------------------------------

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType)
	SELECT  cus.CustID,  ai.ToCustID, 3
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = cus.CustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai.ToCustID);

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType)
	SELECT   ai.ToCustID, cus.CustID,  3
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = cus.CustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai.ToCustID);

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType)
	SELECT  cus.CustID,  ai.FromCustID, 3
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = cus.CustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai.FromCustID);

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType)
	SELECT   ai.FromCustID, cus.CustID,  3
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = cus.CustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai.FromCustID);

#-----------------------------------------------------------Update CustId, CTSCustID of Association table------------------------------------------------

	UPDATE Temp_Association AS ass
	INNER JOIN Temp_Cust AS cus ON ass.CustID_1 = cus.CustID
	SET ass.CTSCustID_1 = cus.CTSCustID
	WHERE ass.CTSCustID_1 = 0 ;

	UPDATE Temp_Association AS ass
	INNER JOIN Temp_Cust AS cus ON ass.CustID_2 = cus.CustID
	SET ass.CTSCustID_2 = cus.CTSCustID
	WHERE ass.CTSCustID_2 = 0;

	UPDATE Temp_Association AS ass
	INNER JOIN Temp_Cust AS cus ON ass.CTSCustID_1 = cus.CTSCustID
	SET ass.CustID_1 = cus.CustID
	WHERE ass.CustID_1 = 0;

	UPDATE Temp_Association AS ass
	INNER JOIN Temp_Cust AS cus ON ass.CTSCustID_2 = cus.CTSCustID
	SET ass.CustID_2 = cus.CustID
	WHERE ass.CustID_2 = 0;

#-----------------------------------------------------------------Handle Association Remove-------------------------------------------------------

	INSERT INTO Temp_Association_Remove(CTSCustID_1, CTSCustID_2)
	SELECT FromCTSCustID, ToCTSCustID 
	FROM CTS_DataCenter.AssociationRemove AS rm
	WHERE EXISTS (SELECT 1 FROM Temp_Association AS ass WHERE  rm.FromCTSCustID = ass.CTSCustID_1 AND rm.ToCTSCustID = ass.CTSCustID_2);

	INSERT INTO Temp_Association_Remove(CTSCustID_1, CTSCustID_2)
	SELECT FromCTSCustID, ToCTSCustID 
	FROM CTS_DataCenter.AssociationRemove AS rm
	WHERE EXISTS (SELECT 1 FROM Temp_Association AS ass WHERE  rm.FromCTSCustID = ass.CTSCustID_2 AND rm.ToCTSCustID = ass.CTSCustID_1);

	DELETE FROM Temp_Association AS ass
	WHERE EXISTS (SELECT 1 FROM Temp_Association_Remove AS rm WHERE  rm.CTSCustID_1 = ass.CTSCustID_1 AND rm.CTSCustID_2 = ass.CTSCustID_2);

	DELETE FROM Temp_Association AS ass
	WHERE EXISTS (SELECT 1 FROM Temp_Association_Remove AS rm WHERE  rm.CTSCustID_1 = ass.CTSCustID_2 AND rm.CTSCustID_2 = ass.CTSCustID_1);

	# select * from Temp_Association;
	lp: LOOP 
		SET lv_CustID = (SELECT CustID_1
							FROM Temp_Association
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
            FROM Temp_Association  AS ass
				JOIN CTE_Group ON CTE_Group.CustID = ass.CustID_1
		) 
		SELECT CustID, lv_GroupId FROM CTE_Group;
        
        DELETE FROM Temp_Association AS ass
        WHERE EXISTS (SELECT 1 FROM Temp_Group AS grp WHERE ass.CustID_1 = grp.CustID);
        
		SET lv_GroupId = lv_GroupId + 1;
		
	END LOOP;
    
    INSERT INTO Temp_CustHedging(CustID)
    SELECT grp.CustID 
    FROM Temp_Group AS grp
	WHERE EXISTS (	SELECT 1 
					FROM CTSCustomerClassification AS cla 
                    WHERE cla.CustID = grp.CustID
						AND cla.SportGroupID = 0
                        AND cla.CategoryID in (73,53,153));
    
    UPDATE Temp_Group AS grp
	SET grp.IsHedging = 1
    WHERE EXISTS (SELECT 1 FROM Temp_CustHedging AS hed WHERE hed.CustID = grp.CustID);
    
END$$

DELIMITER ;