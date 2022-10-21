/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb,ctsAPI" isFunction="0" isNested="1"></info>*/

DROP PROCEDURE IF EXISTS `CTS_DC_AssociationDetection_GetNode`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationDetection_GetNode`(
		IN	ip_CustJson 		JSON
	,   IN  ip_HasDevice		BIT
    ,   IN  ip_HasManual		BIT
    ,   IN  ip_HasAI			BIT
    ,   IN  ip_HasIP			BIT
)
    SQL SECURITY INVOKER
sp:BEGIN 
	/*  
		Created:	20221006@Aries.Nguyen
		Task:		[CTS] Modify rule of Hedging Detection on MM
		DB:			CTS_DataCenter
        
		Revisions:
			- 20221006@Aries.Nguyen: Created [Redmine ID: #178310]

		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetNode_xtest(lv_CTSCustIDs,1,1,1,1);
	*/   
    DECLARE CONS_Range0 			BIGINT DEFAULT 0;
    DECLARE CONS_Range1 			BIGINT DEFAULT 10000000000;
	DECLARE CONS_Range2 			BIGINT DEFAULT 20000000000;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 	Temp_Cust (
			CTSCustID 			BIGINT  PRIMARY KEY 
		,	CustID   			BIGINT	
		,	INDEX Temp_Cust(CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustParam;
	CREATE TEMPORARY TABLE 	Temp_CustParam (
			CTSCustID 			BIGINT  
		,	CustID   			BIGINT
        ,	Weight				BIGINT
        ,	PRIMARY KEY 		PK_Temp_Cust(CTSCustID,Weight)
		,	INDEX 				IX_Temp_Cust(CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Graph;
    CREATE TEMPORARY TABLE 	Temp_Graph (
			OrigID 				BIGINT  
		,	DestID   			BIGINT
		,	Weight 				BIGINT 
		,	AssociationType		SMALLINT 
		,	PRIMARY KEY(OrigID, DestID,Weight,AssociationType)
		,	INDEX IX_Temp_Graph(DestID)
	);
                        
    INSERT IGNORE INTO Temp_CustParam(CTSCustID, CustID, Weight)
	SELECT 	js.CTSCustID
		, 	js.CustID
        ,	js.Weight
	FROM JSON_TABLE(ip_CustJson,
		 "$[*]" COLUMNS(
				CTSCustID 		BIGINT 		PATH "$.CTSCustID"
			,	CustID 			BIGINT 		PATH "$.CustID"
            ,	Weight 			BIGINT 		PATH "$.Weight"
		 )) AS js;
	
    INSERT INTO Temp_Cust(CTSCustID, CustID)
    SELECT 	DISTINCT
			CTSCustID
		, 	CustID
	FROM	Temp_CustParam;
    
    /*******************1. Device*************************/
    IF ip_HasDevice = 1 THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_Device;
		CREATE TEMPORARY TABLE 		Temp_Device (
				DCSDeviceID		BIGINT PRIMARY KEY 
		);
			
		INSERT INTO Temp_Device(DCSDeviceID)
		SELECT 	DISTINCT
				dv.DCSDeviceID 
		FROM Temp_Cust AS cus
			INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID = cus.CTSCustID;    
		
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (CONS_Range0 + cus.CTSCustID)
			,	(CONS_Range1 + tmp.DCSDeviceID) AS DestID
			,	IFNULL(para.Weight,0) AS Weight
			,	1 AS AssociationType 
		FROM Temp_Device AS tmp
			INNER JOIN CTS_DataCenter.AssociationByDevice AS lv1 ON tmp.DCSDeviceID =  lv1.DCSDeviceID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON lv1.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0
            LEFT JOIN Temp_CustParam AS para ON para.CTSCustID = cus.CTSCustID;
	END IF;
	
    /*******************2. Manual*************************/
    IF ip_HasManual = 1 THEN
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (CONS_Range0 + tmp.CTSCustID) AS OrigID
			, 	(CONS_Range0 + ma.FromCTSCustID) AS DestID
			,	IFNULL(tmp.Weight,0) AS Weight
			,	2 AS AssociationType
		FROM Temp_CustParam AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = tmp.CTSCustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.FromCTSCustID AND cus.IsInternal = 0;
			
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (CONS_Range0 + tmp.CTSCustID) AS OrigID
			, 	(CONS_Range0 + ma.ToCTSCustID) AS DestID
			,	IFNULL(tmp.Weight,0) AS Weight
			,	2 AS AssociationType
		FROM Temp_CustParam AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID  = tmp.CTSCustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.ToCTSCustID AND cus.IsInternal = 0;
    END IF; 
    /*******************3. AI*************************/
    IF ip_HasAI = 1 THEN
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (CONS_Range0 + tmp.CTSCustID) AS OrigID
			, 	(CONS_Range0 + cus.CTSCustID) AS DestID
			,	IFNULL(tmp.Weight,0) AS Weight
			,	3 AS AssociationType
		FROM Temp_CustParam AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = tmp.CustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ai.ToCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
			
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (CONS_Range0 + tmp.CTSCustID) AS OrigID
			, 	(CONS_Range0 + cus.CTSCustID) AS DestID
			,	IFNULL(tmp.Weight,0) AS Weight
			,	3 AS AssociationType
		FROM Temp_CustParam AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = tmp.CustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ai.FromCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
		
		/*******************4. Group AI*************************/
		DROP TEMPORARY TABLE IF EXISTS Temp_AIGroup;
		CREATE TEMPORARY TABLE 	Temp_AIGroup (
				GroupID			BIGINT  PRIMARY KEY
		);
		
		INSERT INTO Temp_AIGroup(GroupID)
		SELECT	DISTINCT
				asg.GroupID 
		FROM Temp_Cust AS cus 
			INNER JOIN CTS_DataCenter.AssociationGroupByAI AS asg ON asg.CustID = cus.CustID;  
			
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (CONS_Range0 + cus.CTSCustID) AS OrigID
			, 	(CONS_Range2 + tmp.GroupID) AS DestID
			,	IFNULL(para.Weight,0) AS Weight
			,	4 AS AssociationType
		FROM Temp_AIGroup AS tmp 
			INNER JOIN CTS_DataCenter.AssociationGroupByAI AS asg ON tmp.GroupID = asg.GroupID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = asg.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0
            LEFT JOIN Temp_CustParam AS para ON para.CTSCustID = cus.CTSCustID;
    END IF;
    /*******************5. IP*************************/
    IF ip_HasIP = 1 THEN
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (CONS_Range0 + tmp.CTSCustID) AS OrigID
			, 	(CONS_Range0 + cus.CTSCustID) AS DestID
			,	IFNULL(tmp.Weight,0) AS Weight
			,	5 AS AssociationType
		FROM Temp_CustParam AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = tmp.CustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ip.ToCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
			
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (CONS_Range0 + tmp.CTSCustID) AS OrigID
			, 	(CONS_Range0 + cus.CTSCustID) AS DestID
			,	IFNULL(tmp.Weight,0) AS Weight
			,	5 AS AssociationType
		FROM Temp_CustParam AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = tmp.CustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ip.FromCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
	END IF;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Graph_Dup;
	CREATE TEMPORARY TABLE Temp_Graph_Dup LIKE Temp_Graph;
    INSERT INTO Temp_Graph_Dup SELECT * FROM Temp_Graph;
    
	INSERT IGNORE INTO Temp_Graph(OrigID, DestID, Weight, AssociationType)
	SELECT 	DestID 
		,	OrigID
        ,	Weight
        ,	AssociationType
    FROM Temp_Graph_Dup;

END$$
DELIMITER ;
