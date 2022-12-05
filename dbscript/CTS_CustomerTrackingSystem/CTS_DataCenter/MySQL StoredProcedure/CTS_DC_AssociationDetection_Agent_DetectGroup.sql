/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationDetection_Agent_DetectGroup`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationDetection_Agent_DetectGroup`(
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
            - 20221205@Aries.Nguyen: Re-arrange type options on Association Detection  [Redmine ID: #181207]

		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DataCenter.CTS_DC_AssociationDetection_Agent_Detect('1,2,3');
	*/
    DECLARE CONST_AGENT_RANGE		BIGINT DEFAULT 3000000000;
    
    DECLARE lv_AgentCTSCustIDs 		JSON;
    DECLARE lv_OrigID 				BIGINT;
    DECLARE lv_GroupID 				BIGINT DEFAULT CONST_AGENT_RANGE;
    DECLARE lv_Count1 				INT;
    
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupResult;
	CREATE TEMPORARY TABLE 		Temp_GroupResult (
			CTSCustID 			BIGINT PRIMARY KEY	
		,	GroupID 			BIGINT
		,	INDEX			    IX_Temp_GroupResult(GroupID)
	);
        
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupID;
	CREATE TEMPORARY TABLE 		Temp_GroupID (
			GroupID 			BIGINT PRIMARY KEY	
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NodeCTSCustID;
	CREATE TEMPORARY TABLE 		Temp_NodeCTSCustID (
			CTSCustID 			BIGINT PRIMARY KEY
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
        ,	cus.CustID
	FROM Temp_Cust AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.Recommend 
														AND cus.IsInternal = 0
                                                        AND cus.CustSubID = 0;
    
    WITH CTE AS (
		SELECT 	DISTINCT
				CTSCustID
		FROM Temp_Recommend
    )
    SELECT JSON_ARRAYAGG(JSON_OBJECT('CTSCustID', CTSCustID ,'CustID', NULL)) AS CustJson
	INTO lv_AgentCTSCustIDs	
    FROM CTE;

    CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetEdge(lv_AgentCTSCustIDs,1,0,0);
    
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
        
		UPDATE Temp_Recommend AS tmp
        SET tmp.Processed = 1
        WHERE  tmp.CTSCustID = lv_OrigID;
    
		INSERT IGNORE INTO Temp_NodeCTSCustID(CTSCustID)
		WITH RECURSIVE CTE_Group AS ( 
				SELECT lv_OrigID AS OrigID
				UNION
				SELECT grp.OrigID 
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID
		) 
		SELECT cte.OrigID
        FROM CTE_Group AS cte
        WHERE EXISTS (SELECT 1 FROM Temp_Recommend AS tmp WHERE tmp.CTSCustID = cte.OrigID);
        
        SELECT 	COUNT(1)
        INTO 	lv_Count1
        FROM Temp_NodeCTSCustID;
        
        IF lv_Count1 IS NULL OR lv_Count1 = 1 THEN
			TRUNCATE TABLE Temp_NodeCTSCustID;
        END IF;
        
        INSERT IGNORE INTO Temp_GroupID(GroupID)
        SELECT 	DISTINCT 
				gr.GroupID
        FROM Temp_GroupResult AS gr
		WHERE EXISTS (SELECT 1 FROM Temp_NodeCTSCustID AS tmp WHERE gr.CTSCustID = tmp.CTSCustID);
		
        IF EXISTS (SELECT 1 FROM Temp_GroupID) THEN
			UPDATE Temp_GroupResult AS gr
            SET gr.GroupID = lv_GroupID
            WHERE EXISTS (SELECT 1 FROM Temp_GroupID AS tmp WHERE gr.GroupID = tmp.GroupID);
        END IF;
        
        INSERT IGNORE Temp_GroupResult(CTSCustID,GroupID)
        SELECT 	CTSCustID
            ,	lv_GroupID
        FROM Temp_NodeCTSCustID;
        
        UPDATE Temp_Recommend AS tmp
        SET tmp.Processed = 1
        WHERE  EXISTS (SELECT 1 FROM Temp_GroupResult AS gp WHERE  gp.CTSCustID = tmp.CTSCustID);
        
		SET lv_GroupID = lv_GroupID + 1;
        TRUNCATE TABLE Temp_NodeCTSCustID;
        TRUNCATE TABLE Temp_GroupID;
	END LOOP;

    /*******************Return Data*************************/
	SELECT 	cus.CTSCustID AS OrigID
        ,	GroupID AS DestID
    FROM Temp_GroupResult AS grp
		INNER JOIN Temp_Recommend AS re ON re.CTSCustID = grp.CTSCustID
        INNER JOIN Temp_Cust AS cus ON re.Recommend = cus.Recommend;
    
END$$

DELIMITER ;
