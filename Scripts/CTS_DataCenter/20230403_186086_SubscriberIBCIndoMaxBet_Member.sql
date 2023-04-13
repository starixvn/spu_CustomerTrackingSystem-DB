/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	202304035@Casey.Huynh
Task:	 	Update Setting mapping sub-site and correct data for Member '76666B' only
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 202304035@Casey.Huynh: Created [Redmine ID: #186086]
            - Member Correct :
				+ Update SubscriberID for CTS_Archive.AssocationByDevice
				+ CustDCSAccount: Correct SubscriberID for Member
Reviewer:
*/

USE CTS_DataCenter;

/**********************CORRECT FOR MEMBER**************************/
#=====================================AssociationByDevice====================================
UPDATE CTS_Archive.AssociationByDevice_Arc AS t 
	INNER JOIN CTS_DataCenter.CTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = s.SubscriberID
WHERE s.SiteID = 547 AND s.RoleID = 1 AND s.SubscriberID <> t.SubscriberID;

UPDATE CTS_DataCenter.AssociationByDevice AS t 
	INNER JOIN CTS_DataCenter.CTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = s.SubscriberID
WHERE s.SiteID = 547 AND s.RoleID = 1 AND s.SubscriberID <>  t.SubscriberID;

#=============================CustDCSAccount====================================================================
UPDATE CTS_DataCenter.CustDCSAccount t
	INNER JOIN DCS_DataCenter.Account AS a ON t.AccountID = a.AccountID AND t.SubscriberID <> a.SubScriberID
SET t.SubscriberID = a.SubScriberID
WHERE t.SubscriberID = 13658;
