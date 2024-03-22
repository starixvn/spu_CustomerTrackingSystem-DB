/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_SpecialCustClass_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SpecialCustClass_Remove`(
    	IN ip_ListCust					JSON    
	,	IN ip_Remark					VARCHAR(500)
    ,   IN ip_RemovedBy					INT
)
    SQL SECURITY INVOKER
BEGIN
		/*
		Created:	20200908@Long.Luu
		Task:		Remove special customer class [Redmine ID: #140996]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200908@Long.Luu [Redmine ID: #140996]: Created 
			- 20201229@Irena.Vo: Insert History Log.  [Redmine ID: #145951]
            - 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
            - 20210920@Aries.Nguyen: Split history log  [Redmine ID: #161890]
			- 20240318@Thomas.Nguyen: Support list custs, add comment/log and special CC by sport [Redmine ID: #201360]
        
		Param's Explanation (filtered by):
	*/
    
    DECLARE lv_CurrentDateTime  DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_SPName           VARCHAR(200) DEFAULT 'CTS_DC_SpecialCustClass_Remove'; 
	DECLARE lv_ListCustInfo		LONGTEXT;	
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;    
	CREATE TEMPORARY TABLE Temp_Customer (	 
			CTSCustID			BIGINT UNSIGNED
		,	CustID				INT UNSIGNED
		,	SportID				SMALLINT UNSIGNED
		,	SubscriberID		INT
		,	PRIMARY KEY (CTSCustID, SportID)
		,	KEY IX_Temp_Customer_SportID (SportID)
    );   

	INSERT INTO Temp_Customer(CTSCustID,CustID,SportID,SubscriberID)
	SELECT	tmp.CTSCustID
		,	tmp.CustID
		,	tmp.SportID
		,	tmp.SubscriberID
	FROM JSON_TABLE(ip_ListCust, 
						'$[*]' COLUMNS (CTSCustID		BIGINT UNSIGNED			PATH '$.CTSCustID'
									,	CustID			INT UNSIGNED			PATH '$.CustID'
									,	SportID			SMALLINT UNSIGNED   	PATH '$.SportID'
									,	SubscriberID	INT						PATH '$.SubscriberID'
								)) AS tmp;
    
	/*For General*/
	IF EXISTS (SELECT 1 FROM Temp_Customer WHERE SportID = 0) THEN
		-- Remove old CC
		DELETE	s
		FROM CTS_DataCenter.SpecialCustomerClass AS s
			INNER JOIN Temp_Customer AS tmp ON tmp.CTSCustID = s.CTSCustID AND tmp.SportID = 0
		WHERE s.CreatedFromFunction = 1;
		
		INSERT INTO CTS_DataCenter.SpecialCustomerClass_History(CTSCustID, CustID, RootCTSCustID, SubscriberID, CustomerClass, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate, CreatedFromFunction, Remark, ActionType)
		SELECT 	CTSCustID
			,	CustID
			,	CTSCustID
			,	SubscriberID
			,	-1 AS CustomerClass
			,	ip_RemovedBy
			,	lv_CurrentDateTime
			,	ip_RemovedBy
			,	lv_CurrentDateTime
			,   1 -- for Special Customer
			,	ip_Remark
			,	2 -- remove
		FROM Temp_Customer AS tmp
		WHERE tmp.SportID = 0;

		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT	20 AS LogTypeID
			,	lv_SPName
			,	CONCAT('Remove special customer class: CTSCustList: ', GROUP_CONCAT(tmp.CTSCustID))
			,	DATE(lv_CurrentDateTime)
			,	ip_RemovedBy
		FROM Temp_Customer AS tmp
		WHERE tmp.SportID = 0;

		-- Insert Log
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, LastModifiedDate,LastModifiedBy, ActionType,  IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, Remark)
		SELECT  tmp.CustID
			,   tmp.CTSCustID
			,   lv_CurrentDateTime
			,   ip_RemovedBy
			,   2 -- remove
			,   0 -- manual
			,   DATE(lv_CurrentDateTime)
			,   -1
			,   12 -- item name = Remove Customer Class
			,   1  -- View History
			,	ip_Remark
		FROM Temp_Customer AS tmp
		WHERE tmp.SportID = 0;	

		INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, LastModifiedDate,LastModifiedBy, ActionType,  IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, Remark)
		SELECT  tmp.CustID
			,   tmp.CTSCustID
			,   lv_CurrentDateTime
			,   ip_RemovedBy
			,   2 -- remove
			,   0 -- manual
			,   DATE(lv_CurrentDateTime)
			,   -1
			,   12 -- item name = Remove Customer Class
			,   1  -- View History
			,	ip_Remark
		FROM Temp_Customer AS tmp
		WHERE tmp.SportID = 0;
	END IF;

	/*For BySport*/
	IF EXISTS (SELECT 1 FROM Temp_Customer WHERE SportID <> 0) THEN
		-- Remove old CC
		DELETE sb
		FROM CTS_DataCenter.SpecialCustomerClass_BySport AS sb
			INNER JOIN Temp_Customer AS tmp ON tmp.CTSCustID = sb.CTSCustID AND tmp.SportID = sb.SportID
		WHERE tmp.SportID <> 0;
		
		INSERT INTO CTS_DataCenter.SpecialCustomerClass_BySport_History(CTSCustID, CustID, SportID, SubscriberID, CustomerClass, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate, Remark, ActionType)
		SELECT 	CTSCustID
			,	CustID
			,	SportID
			,	SubscriberID
			,	-1 AS CustomerClass
			,	ip_RemovedBy
			,	lv_CurrentDateTime
			,	ip_RemovedBy
			,	lv_CurrentDateTime
			,	ip_Remark
			,	2 -- remove
		FROM Temp_Customer AS tmp
		WHERE tmp.SportID <> 0;

		SELECT JSON_ARRAYAGG(JSON_OBJECT('CTSCustID',CTSCustID,'SportID',SportID))
		INTO lv_ListCustInfo
		FROM Temp_Customer AS tmp
		WHERE tmp.SportID <> 0;

		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT	20 AS LogTypeID
			,	lv_SPName
			,	CONCAT('Remove special customer class by sport: CTSCustList: ', lv_ListCustInfo)
			,	DATE(lv_CurrentDateTime)
			,	ip_RemovedBy
		FROM Temp_Customer AS tmp
		WHERE tmp.SportID <> 0;

		-- Insert Log
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_BySport_History(CustID, CTSCustID, SportID, LastModifiedDate, LastModifiedBy, ActionType, InsertDate, TargetCC, Remark, SourceTypeID)
		SELECT  tmp.CustID
			,   tmp.CTSCustID
			,	tmp.SportID
			,   lv_CurrentDateTime
			,   ip_RemovedBy
			,   2 -- remove
			,   DATE(lv_CurrentDateTime)
			,   -1
			,   ip_Remark
			,	12
		FROM Temp_Customer AS tmp
		WHERE tmp.SportID <> 0;	

		INSERT INTO CTS_DataCenter.CTSCustomerClassification_BySport_Log(CustID, CTSCustID, SportID, LastModifiedDate, LastModifiedBy, ActionType, InsertDate, TargetCC, Remark, SourceTypeID)
		SELECT  tmp.CustID
			,   tmp.CTSCustID
			,	tmp.SportID
			,   lv_CurrentDateTime
			,   ip_RemovedBy
			,   2 -- remove
			,   DATE(lv_CurrentDateTime)
			,   -1
			,   ip_Remark
			,	12
		FROM Temp_Customer AS tmp
		WHERE tmp.SportID <> 0;
	END IF;

END$$

DELIMITER ;