/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_AffectedDownline_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_AffectedDownline_Insert`(
		 IN ip_TableName	VARCHAR(200)
    ,    IN ip_InputFlowID 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20240625@Jonas.Huynh
		Task:		Renovate CC [Redmine ID: #205317]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20240625@Jonas.Huynh: Created [Redmine ID: #205317]
        
		Param's Explanation (filtered by):
			- ip_ActionType: 1:Insert VVIP, 2:Remove VVIP, 3:Mark PA, 4:UnMark PA
	*/
    DECLARE	CONST_ACTION_INSERTVVIP 	INT DEFAULT 1;
	DECLARE	CONST_ACTION_REMOVEVVIP 	INT DEFAULT 2;
	DECLARE	CONST_ACTION_MARKPA 		INT DEFAULT 3;
	DECLARE	CONST_ACTION_UNMARKPA	 	INT DEFAULT 4;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    CREATE TEMPORARY TABLE Temp_Customer(
			CTSCustID			BIGINT PRIMARY KEY
		,	CustID				BIGINT
        ,	RoleID				TINYINT
        ,	SubscriberID		INT
        ,	CreatedBy			BIGINT
        ,	Remark				VARCHAR(300)
        ,	CategoryID			SMALLINT
        ,	CategoryGroupID		INT
        ,	IsFromTVS			BIT(1)
        ,	IsFromTW			BIT(1)
        ,	IsFromCTS			BIT(1)
        ,	TVSRequestID		BIT(1)
	);
    
	SET @sql =CONCAT("	INSERT IGNORE INTO Temp_Customer (CustID, IsInternal, SiteID) 
						SELECT	ipTbl.CTSCustID
							,	ipTbl.CustID
                            ,	ipTbl.RoleID
                            ,	ipTbl.SubscriberID
                            ,	ipTbl.CreatedBy
                            ,	ipTbl.Remark
                            ,	ipTbl.CategoryID
                            ,	ipTbl.CategoryGroupID
                            ,	ipTbl.IsFromTVS
                            ,	ipTbl.IsFromTW
                            ,	ipTbl.IsFromCTS
                            ,	ipTbl.TVSRequestID
						FROM ",ip_TableName," AS ipTbl"
						);
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1; 
    
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationQueue(CTSCustID, CustID, RoleID, SubscriberID, CreatedBy, Remark, CategoryID, CategoryGroupID, LastDownlineCTSCustID
		, IsFromTVS, IsFromTW, IsFromCTS, ActionType, InsertTime, TVSRequestID)
	SELECT tmpPa.CTSCustID
		,	tmpPa.CustID
		,	tmpPa.RoleID
		,	tmpPa.SubscriberID
		,	tmpPa.CreatedBy
		,	tmpPa.Remark        
		,	tmpPa.CategoryID
		,	tmpPa.CategoryGroupID
		,	0 AS LastDownlineCTSCustID
		,	tmpPa.IsFromTVS 
		,	tmpPa.IsFromTW
		,	tmpPa.IsFromCTS
		,	CASE	
				WHEN ip_InputFlowID = 1 THEN CONST_ACTION_INSERTVVIP
                WHEN ip_InputFlowID = 50 THEN CONST_ACTION_MARKPA
                WHEN ip_InputFlowID = 98 THEN CONST_ACTION_UNMARKPA
                WHEN ip_InputFlowID = 100 THEN CONST_ACTION_REMOVEVVIP
			END AS ActionType
		,	CURRENT_TIMESTAMP(3) AS InsertTime
		,	tmpPa.TVSRequestID
	FROM Temp_Customer AS tmpPa        
	WHERE tmpPa.RoleID > 1
	ORDER BY tmpPa.LastModifiedDate, tmpPa.CategoryID;
END$$

DELIMITER ;