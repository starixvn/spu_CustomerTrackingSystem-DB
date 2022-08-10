/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationDetection_Agent_Detect`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationDetection_Agent_Detect`(
		IN	ip_CTSCustIDs 			LONGTEXT
)
    SQL SECURITY INVOKER
sp:BEGIN 
	/*  
		Created:	20220727@Aries.Nguyen
		Task:		[CTS] Enhance Association Detection
		DB:			CTS_DataCenter
        
		Revisions:
			- 20220727@Aries.Nguyen: Created [Redmine ID: #175701]

		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DataCenter.CTS_DC_AssociationDetection_Agent_Detect('1,2,3');
	*/
    DECLARE CONST_DEVICE_RANGE 		INT DEFAULT -1;
    DECLARE CONST_AGENT_RANGE 		BIGINT DEFAULT 20000000000;
    
    DECLARE lv_OrigID 		BIGINT;
    DECLARE lv_GroupId 		BIGINT DEFAULT CONST_AGENT_RANGE;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 	Temp_Cust (
			CTSCustID 			BIGINT  PRIMARY KEY 
		,	CustID   			BIGINT	
        ,	Recommend			BIGINT
		,	INDEX 				Temp_Cust(CustID)
        ,	INDEX 				Temp_Cust_Recommend(Recommend)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Recommend;
	CREATE TEMPORARY TABLE 	Temp_Recommend (
			CTSCustID 			BIGINT  PRIMARY KEY 
        ,	Recommend			BIGINT
        ,	Processed 			BIT DEFAULT 0
        ,	INDEX 				IX_Temp_Recommend_Recommend(Recommend)
        ,	INDEX				IX_Temp_Recommend_Processed(Processed)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Graph;
	CREATE TEMPORARY TABLE 	Temp_Graph (
			OrigID 				BIGINT  
		,	DestID   			BIGINT
		,	PRIMARY KEY(OrigID, DestID)
		,	INDEX IX_Temp_Graph(DestID,OrigID)
	);
    
    
    INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID, Recommend)
	SELECT 	cus.CTSCustID
		, 	cus.CustID
        ,	cus.Recommend
	FROM JSON_TABLE(CONCAT('[',ip_CTSCustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CTSCustID BIGINT UNSIGNED PATH '$'))) AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = tmp.CTSCustID 
														AND cus.IsInternal = 0
                                                        AND cus.RoleID = 1
                                                        AND cus.IsLicensee = 0;
    
    INSERT IGNORE INTO Temp_Recommend(CTSCustID, Recommend)
	SELECT 	cus.CTSCustID
        ,	cus.Recommend
	FROM Temp_Cust AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.Recommend 
														AND cus.IsInternal = 0
                                                        AND cus.CustSubID = 0;
    
    /*******************1. Device*************************/
	DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice;
	CREATE TEMPORARY TABLE 		Temp_CustDevice (
			CTSCustID			BIGINT UNSIGNED  
		,	DCSDeviceID  		BIGINT UNSIGNED 
		,	PRIMARY KEY(DCSDeviceID, CTSCustID)
	); 
        
	INSERT IGNORE INTO Temp_CustDevice(CTSCustID, DCSDeviceID)
	SELECT 	cus.CTSCustID 
		, 	dv.DCSDeviceID
	FROM Temp_Recommend AS cus
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID = cus.CTSCustID;    
		
	DROP TEMPORARY TABLE IF EXISTS Temp_Device;
	CREATE TEMPORARY TABLE 		Temp_Device (
			DCSDeviceID		BIGINT PRIMARY KEY
	);
        
	INSERT INTO Temp_Device(DCSDeviceID)
	SELECT 	DISTINCT
			DCSDeviceID
	FROM Temp_CustDevice;
    
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
	SELECT  cus.CTSCustID
		,	CONST_DEVICE_RANGE * tmp.DCSDeviceID AS DestID
	FROM Temp_Device AS tmp
		INNER JOIN CTS_DataCenter.AssociationByDevice AS lv1 ON tmp.DCSDeviceID =  lv1.DCSDeviceID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON lv1.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0;
        
	
    /*******************2. Manual*************************/
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
	SELECT  tmp.CTSCustID AS OrigID
		, 	ma.FromCTSCustID AS DestID
	FROM Temp_Recommend AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = tmp.CTSCustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.FromCTSCustID AND cus.IsInternal = 0;
			
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
	SELECT  tmp.CTSCustID AS OrigID
		, 	ma.ToCTSCustID AS DestID
	FROM Temp_Recommend AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID  = tmp.CTSCustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.ToCTSCustID AND cus.IsInternal = 0;
    
    /*****************************Merge Group**************************************************/
    DROP TEMPORARY TABLE IF EXISTS Temp_Graph_Dup;
	CREATE TEMPORARY TABLE Temp_Graph_Dup LIKE Temp_Graph;
	INSERT INTO Temp_Graph_Dup
	SELECT * FROM Temp_Graph;
	
	INSERT IGNORE INTO Temp_Graph
	SELECT DestID,OrigID FROM Temp_Graph_Dup;
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Group;
	CREATE TEMPORARY TABLE 		Temp_Group (
			CTSCustID 			BIGINT PRIMARY KEY 
		,	GroupID 			BIGINT 
		,	INDEX			    IX_Temp_Group(GroupID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupCount;
	CREATE TEMPORARY TABLE 	Temp_GroupCount (
				GroupID 	BIGINT
			,	PRIMARY KEY (GroupID)
	);
    
    lp: LOOP 
		SET lv_OrigID = NULL;
        
        SELECT CTSCustID
        INTO lv_OrigID
		FROM Temp_Recommend
        WHERE Processed = 0
		LIMIT 1;

        IF lv_OrigID IS NULL 
        THEN 
            LEAVE lp; 
        END IF;
    
		INSERT IGNORE INTO Temp_Group(CTSCustID,GroupID)
		WITH RECURSIVE CTE_Group AS ( 
				SELECT lv_OrigID AS OrigID
				UNION
				SELECT grp.OrigID 
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID
		) 
		SELECT OrigID
			,  lv_GroupId 
        FROM CTE_Group;
        
        UPDATE Temp_Recommend AS tmp
        SET tmp.Processed = 1
        WHERE  tmp.CTSCustID = lv_OrigID
			OR EXISTS (SELECT 1 FROM Temp_Group AS gp WHERE  gp.CTSCustID = tmp.CTSCustID);
            
		SET lv_GroupId = lv_GroupId + 1;
	END LOOP;
    
    DELETE 
	FROM Temp_Group AS grp
	WHERE NOT EXISTS (SELECT 1 FROM Temp_Recommend AS tmp WHERE grp.CTSCustID = tmp.CTSCustID);
    
    INSERT INTO Temp_GroupCount(GroupID)
    SELECT GroupID 
    FROM Temp_Group
    GROUP BY GroupID
    HAVING COUNT(1) = 1;
    
    DELETE 
	FROM Temp_Group AS grp
	WHERE EXISTS (SELECT 1 FROM Temp_GroupCount AS tmp WHERE grp.GroupID = tmp.GroupID);
    
    /*******************Return Data*************************/
	SELECT 	cus.CTSCustID AS FromID
        ,	GroupID AS ToID
    FROM Temp_Group AS grp
		INNER JOIN Temp_Recommend AS re ON re.CTSCustID = grp.CTSCustID
        INNER JOIN Temp_Cust AS cus ON re.Recommend = cus.Recommend;
    
END$$

DELIMITER ;
