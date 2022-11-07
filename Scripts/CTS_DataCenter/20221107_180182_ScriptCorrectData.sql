/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20221107@Casey.Huynh
	Task: Update Data IsTransformed = 0 for Account Not Transform
	DB: CTS_DataCenter
  
	Revisions:
		- 20221107@Casey.Huynh: created  [Redmine ID: #180182]

	Param's Explanation:
*/


USE CTS_Adhoc; 

CREATE TABLE AccountNotTransform_180182(
	AccountID BIGINT UNSIGNED PRIMARY KEY
    ,	CTSCustID BIGINT UNSIGNED
	) 
ENGINE=InnoDB;

#=============================================================
INSERT INTO CTS_Adhoc.AccountNotTransform_180182(AccountID, CTSCustID)
SELECT DISTINCT a.AccountID, c.CTSCustID
FROM CTS_DataCenter.CTSCustomer  c
	INNER JOIN DCS_DataCenter.Account a ON a.LoginName = c.RegisterName AND a.SubscriberID = c.SubscriberID
WHERE a.IsCTSTransformed = -1;

SELECT * FROM AccountNotTransform_180182;

INSERT INTO CTS_Adhoc.AccountNotTransform_180182(AccountID, CTSCustID)
SELECT DISTINCT a.AccountID, c.CTSCustID
FROM CTS_DataCenter.CTSCustomer  c
	INNER JOIN DCS_DataCenter.Account a ON a.LoginName = c.UserName AND a.SubscriberID = c.SubscriberID
WHERE a.IsCTSTransformed = -1;

#=============================================================
UPDATE DCS_DataCenter.Account acc
INNER JOIN AccountNotTransform_180182 AS ant ON acc.AccountID = ant.AccountID
SET acc.IsCTSTransformed = 0;