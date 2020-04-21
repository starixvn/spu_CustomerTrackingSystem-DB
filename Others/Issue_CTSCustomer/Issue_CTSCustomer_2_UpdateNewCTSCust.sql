/*
Creator: 20191106@CaseyHuynh 
Task:	 	Correct data CTS_customer Missing vs CustDCSAccount
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
		
Reviewer:
*/

#2. Update NewCTSCustID
UPDATE		CTS_DataCenter.CustDCSAccount AS acc
INNER JOIN	CTS_DataCenter.zzzIssueCustMissing_CustDCSAccount AS ms
			ON acc.CTSCustID = ms.CTSCustID
				AND acc.SubscriberID = ms.SubscriberID
SET			acc.CTSCustID = ms.NewCTSCustID                
WHERE		ms.NewCTSCustID > 0;

UPDATE		CTS_DataCenter.AssociationByDevice AS ad
INNER JOIN	CTS_DataCenter.zzzIssueCustMissing_CustDCSAccount AS ms
			ON ad.CTSCustID = ms.CTSCustID
				AND ad.SubscriberID = ms.SubscriberID
SET			ad.CTSCustID = ms.NewCTSCustID                
WHERE		ms.NewCTSCustID > 0;


