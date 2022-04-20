/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationGroupByAI_MergeGroup`;

DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationGroupByAI_MergeGroup`(
		IN ip_MergeInfo	 				JSON
	,	IN ip_MaxMergedGroupLength		SMALLINT UNSIGNED
    
    ,	OUT op_ErrorMessage 			VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220404@Long.Luu
		Task:		Merge Group Association [Redmine ID: #0000]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20220404@Long.Luu: Created [Redmine ID: #0000]
            
		Example:
			call CTS_DataCenter.CTS_DC_AssociationGroupByAI_MergeGroup ('[{"MG": "1,2"},{"MG": "4,5"}]',@ErrorMessage);    
	*/        
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MergeGroup;    
	CREATE TEMPORARY TABLE Temp_MergeGroup(	  	
			ID					SMALLINT UNSIGNED
		,	OriginGroupID		BIGINT UNSIGNED
        ,	PRIMARY KEY 		PK_Temp_MergeGroup_IDOriginGroupID(ID,OriginGroupID)
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MergedGroupID;    
	CREATE TEMPORARY TABLE Temp_MergedGroupID(	  	
			ID					SMALLINT UNSIGNED
		,	OldGroupID			BIGINT UNSIGNED
		,	NewGroupID			BIGINT UNSIGNED
        ,	PRIMARY KEY 		PK_Temp_MergedGroupID_IDOldGroupID(ID,OldGroupID)
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MinMergedGroupID;    
	CREATE TEMPORARY TABLE Temp_MinMergedGroupID(	  	
			ID					SMALLINT UNSIGNED
		,	NewGroupID			BIGINT UNSIGNED
        ,	PRIMARY KEY 		PK_Temp_MinMergedGroupID_IDNewGroupID(ID,NewGroupID)
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AffectedCustGroup;    
	CREATE TEMPORARY TABLE Temp_AffectedCustGroup(	  	
			ID					INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
		,	CustID				BIGINT UNSIGNED
		,	OldGroupID			BIGINT UNSIGNED
		,	NewGroupID			BIGINT UNSIGNED
        ,	OrderID				SMALLINT UNSIGNED
        ,	INDEX 				IX_Temp_AffectedCustGroup_CustIDOldGroupID(CustID,OldGroupID)
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MergeInfo;    
	CREATE TEMPORARY TABLE Temp_MergeInfo(	  	
			ID					SMALLINT UNSIGNED AUTO_INCREMENT
		,	MergeGroup			TEXT
        ,	PRIMARY KEY 		PK_Temp_MergeInfo(ID)
	); 
    
    INSERT INTO Temp_MergeInfo(MergeGroup)
	SELECT 	tmpTable.MergeGroup
	FROM JSON_TABLE(ip_MergeInfo,
		 "$[*]" COLUMNS(
				MergeGroup 		TEXT		PATH "$.MG"
		 )) AS tmpTable;  
    
    INSERT INTO Temp_MergeGroup(ID,OriginGroupID)
    WITH RECURSIVE v_pointer AS (
		SELECT 1 AS rowID
		UNION ALL
		SELECT rowID + 1
		FROM v_pointer
		WHERE rowID < ip_MaxMergedGroupLength
	)
	SELECT 	t.ID
		,	SUBSTRING_INDEX(SUBSTRING_INDEX(t.MergeGroup, ',', p.rowID), ',', -1)
	FROM v_pointer AS p
		INNER JOIN Temp_MergeInfo AS t ON CHAR_LENGTH(t.MergeGroup) - CHAR_LENGTH(REPLACE(t.MergeGroup, ',', '')) >= p.rowID - 1;
    
    INSERT INTO Temp_MergedGroupID(ID,OldGroupID)
    SELECT DISTINCT t.ID, g.GroupID
    FROM Temp_MergeGroup AS t
		INNER JOIN AssociationGroupByAI AS g ON t.OriginGroupID = g.OriginGroupID;
    
    INSERT INTO Temp_MinMergedGroupID(ID, NewGroupID)
    SELECT a.ID, MIN(g.GroupID)
	FROM Temp_MergeGroup AS a
		INNER JOIN AssociationGroupByAI AS g ON a.OriginGroupID = g.OriginGroupID
	GROUP BY a.ID;
                    
    UPDATE Temp_MergedGroupID AS t
		INNER JOIN Temp_MinMergedGroupID AS v ON t.ID = v.ID
	SET t.NewGroupID = v.NewGroupID;
    
    INSERT INTO Temp_AffectedCustGroup(CustID,OldGroupID,NewGroupID, OrderID)
    SELECT g.CustID, t.OldGroupID, t.NewGroupID, RANK() OVER (PARTITION BY g.CustID, t.NewGroupID ORDER BY t.OldGroupID DESC )
    FROM Temp_MergedGroupID AS t
		INNER JOIN AssociationGroupByAI AS g ON t.OldGroupID = g.GroupID;
        
	DELETE g
    FROM AssociationGroupByAI AS g
		INNER JOIN Temp_AffectedCustGroup AS t ON g.CustID = t.CustID AND g.GroupID = t.OldGroupID
	WHERE t.OrderID > 1;
    
    UPDATE Temp_MergedGroupID AS t
		INNER JOIN AssociationGroupByAI AS g ON t.OldGroupID = g.GroupID
	SET g.GroupID = t.NewGroupID
		,	g.CreatedDate = NOW();
    
END$$	
DELIMITER ;