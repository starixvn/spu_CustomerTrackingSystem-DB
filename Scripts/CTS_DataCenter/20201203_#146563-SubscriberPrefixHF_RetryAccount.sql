/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
Created: 20201130@CaseyHuynh
Task: 	 146563-SubscriberPrefix Hot Fix, Update Account.IsCTSTransformed  = 0
DB: 	 CTS_DataCenter
*/
USE DCS_DataCenter;
/*Estimate ~17K row
SELECT 		COUNT(1)
FROM		DCS_DataCenter.Account as acc
Inner Join 	CTS_Admin.Subscriber	As sub
			ON acc.SubscriberID = sub.SubscriberID
			AND sub.SubscriberType = 0
WHere 		acc.IsCTSTransformed = -1
			;*/
            
UPDATE 		DCS_DataCenter.Account as acc
INNER JOIN 	CTS_Admin.Subscriber	As sub
			ON acc.SubscriberID = sub.SubscriberID
			AND sub.SubscriberType = 0
SET			acc.IsCTSTransformed = 0
WHERE 		acc.IsCTSTransformed = -1;
