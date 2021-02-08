/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
USE CTS_DataCenter;
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidenceQueue_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidenceQueue_Get`(
)
SQL SECURITY INVOKER

BEGIN
	/*
		Created:	20210204@Long.Luu
		Task:		Get data from CustEvidenceQueue [Redmine ID: #148719]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210204@Long.Luu: Created [Redmine ID: #148719]
		
		Param's Explanation (filtered by): 
            
		Example:			
			- call CTS_DataCenter.CTS_DC_CustEvidenceQueue_Get();
	*/    
	
	DECLARE	lv_FileKey	varchar(50);
	
    SELECT q.FileKey 
    INTO lv_FileKey
	FROM CTS_DataCenter.CustEvidenceQueue AS q
	WHERE q.IsProcessed = 0
	ORDER BY q.ID ASC
	LIMIT 1;
		
	SELECT	q.ID
		,	q.CTSCustID
		,	q.CustID
		,	q.SubscriberID
		,	q.EvidenceID
		,	q.Remark
        ,	q.CreatedBy
		,	q.ActionID
	FROM CTS_DataCenter.CustEvidenceQueue AS q
	WHERE q.FileKey = lv_FileKey
		AND q.IsProcessed = 0;	
END$$

DELIMITER ;


