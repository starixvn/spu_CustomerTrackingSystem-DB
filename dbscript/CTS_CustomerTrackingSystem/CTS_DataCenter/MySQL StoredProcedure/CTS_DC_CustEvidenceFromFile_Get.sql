/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidenceFromFile_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidenceFromFile_Get`()
SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201106@Adam.Tran
		Task:		Get customer evidences [Redmine ID: 141563]
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20201106@Adam.Tran [Redmine ID: 141563]: Created
			- 20201203@Adam.Tran [Redmine ID: 141563]: add where LastModifiedBy is null
			- 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
		Param's Explanation (filtered by):
	*/    
	
	DECLARE		lv_FileKey	varchar(50);
	
	SELECT cus.FileKey 
	INTO lv_FileKey
    FROM CTS_DataCenter.CustEvidenceFromFile AS cus
    WHERE	cus.IsProcessed = 0 
		AND LastModifiedBy IS NULL
	ORDER BY cus.CreatedTime ASC
	LIMIT 1;
		
	SELECT	cus.ID
		,	cus.CTSCustID
		,	cus.CustID
		,	cus.SubscriberID
		,	cus.EvidenceID
		,	cus.Remark
		,	cus.IsOverwrite
        , 	cus.FileKey
        ,	cus.FileName
		,	cus.CreatedBy
        ,	cus.CreatedTime
	FROM CTS_DataCenter.CustEvidenceFromFile AS cus
	WHERE cus.IsProcessed = 0 
		AND cus.FileKey = lv_FileKey 
		AND LastModifiedBy IS NULL
	ORDER BY cus.CreatedTime ASC;
END$$
DELIMITER ;