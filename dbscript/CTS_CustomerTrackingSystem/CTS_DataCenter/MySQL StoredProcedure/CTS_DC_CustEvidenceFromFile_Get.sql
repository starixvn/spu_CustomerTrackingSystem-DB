/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
USE `CTS_DataCenter`;
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
	*/    

	SELECT	cus.ID
		,	cus.CTSCustID
		,	cus.CustID
		,	cus.SubscriberID
		,	cus.EvidenceID
		,	cus.Remark
		,	cus.IsOverwrite
        , 	cus.FileKey
        ,	cus.FileName
        ,	cus.CreatedTime
	FROM CTS_DataCenter.CustEvidenceFromFile as cus
	WHERE cus.IsProcessed = 0
	ORDER BY cus.CreatedTime ASC;
	
END$$

DELIMITER ;


