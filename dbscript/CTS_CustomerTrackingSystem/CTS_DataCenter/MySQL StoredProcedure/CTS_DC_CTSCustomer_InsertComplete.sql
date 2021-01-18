/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTSCustomer_InsertComplete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CTSCustomer_InsertComplete`(IN ip_CustIDList TEXT)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210115@Casey.Huynh
		Task:		Insert Customer Complte [Redmine ID: 148849]. Re-Transfrom DCS Account and update LastInsertedCustID System Parameter
		DB:			CTS_DataCenter
		Original:

		Revisions:
			
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_DC_InsertCTSCustomer ('[{"BatchId":1,"CustId":1,"CustSubId":0,"Username":"SA-SD$","Username2":null,"Site":"BEST-ODDS","SiteId":1,"RoleId":4,"CurrencyId":1,"Currency":"SD$","Srecommend":1,"Mrecommend":0,"Recommend":0,"CreatedDate":"2020-04-24T03:18:00"},{"BatchId":1,"CustId":2,"CustSubId":0,"Username":"SA-RM","Username2":null,"Site":"BEST-ODDS","SiteId":1,"RoleId":4,"CurrencyId":2,"Currency":"RM","Srecommend":2,"Mrecommend":0,"Recommend":0,"CreatedDate":"2020-04-24T03:18:00"}]')
	*/
    DECLARE lv_LastInsertCustID INT;
    DECLARE lv_LastInsertCustSubID INT;
    
    CALL CTS_DC_Sys_SplitStringToTempItemTable(ip_CustIDList,',','BIGINT');
  
   #=====ReTransform==============================
    UPDATE		DCS_DataCenter.Account AS acc	
    INNER JOIN	TempItemTable AS tmpCus
				ON acc.LoginName = tmpCus.RegisterName
				AND	acc.SubscriberID = tmpCus.SubscriberID
	SET			acc.IsCTSTransformed = 0
	WHERE		acc.IsCTSTransformed = -1;    
    
	UPDATE		DCS_DataCenter.Account AS acc	
    INNER JOIN	TempItemTable AS tmpCus
				ON acc.LoginName = tmpCus.UserName
                AND acc.SubscriberID = tmpCus.SubscriberID
	SET			acc.IsCTSTransformed = 0
	WHERE		acc.IsCTSTransformed = -1;    	
    
    #=====Update Scan System Parameter;
    SET lv_LastInsertCustID = (SELECT MAX(tmpCus.CustID) FROM TempItemTable AS tmpCus);
    IF lv_LastInsertCustID > 0
    THEN
		UPDATE 	CTS_DataCenter.SystemParameter AS s
        SET		s.ParamaterValue = lv_LastInsertCustID
		WHERE	s.ParameterID = 7 AND s.ParameterName = 'CTSCustomer_LastInsertCustID';
	END IF;
    
	SET lv_LastInsertCustSubID = (SELECT MAX(tmpCus.CustSubID) FROM TempItemTable AS tmpCus);
    IF lv_LastInsertCustSubID > 0
    THEN
		UPDATE 	CTS_DataCenter.SystemParameter AS s
        SET		s.ParamaterValue = lv_LastInsertCustSubID
		WHERE	s.ParameterID = 8 AND s.ParameterName = 'CTSCustomer_LastInsertCustSubID';
	END IF;
END$$
DELIMITER ;