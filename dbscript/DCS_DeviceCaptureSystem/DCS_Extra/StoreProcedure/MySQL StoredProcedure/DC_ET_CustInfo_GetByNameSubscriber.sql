/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DC_ET_CustInfo_GetByNameSubscriber`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DC_ET_CustInfo_GetByNameSubscriber`(
		IN ip_SubscriberID	INT
	,	IN ip_LoginName		VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230601@Casey.Huynh
		Task :		Search Customer by LoginName in subscribers
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230601@Casey.Huynh: Created [Redmine ID: 185787]
			
		Param's Explanation (filtered by):

		Example:
			CALL DC_ET_CustInfo_GetByNameSubscriber(@ip_SubscriberID:=8000001,@ip_LoginName:='Exciting8');
			CALL DC_ET_CustInfo_GetByNameSubscriber(@ip_SubscriberID:=8000001,@ip_LoginName:='DenVau');
	*/   

	#========SEARCH BY LoginName=====================
    SELECT	acc.AccountID
		,	acc.LoginName
        ,	acc.SubscriberID
    FROM DCS_Extra.Account AS acc
	WHERE acc.SubscriberID = ip_SubscriberID AND acc.LoginName = ip_LoginName;        
    
END$$
DELIMITER ;
