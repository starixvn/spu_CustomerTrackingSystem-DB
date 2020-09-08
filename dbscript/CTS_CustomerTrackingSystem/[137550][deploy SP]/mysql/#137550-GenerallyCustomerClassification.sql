/*
	Created: 	20200901@Long.Luu
	Task:		Init more categories for General Classification [Redmine ID: #137550]
	DB:			CTS_DataCenter
	Original:
	Revisions:
		- 20200904@Harvey: Add column ParentCategoryID into table CTSCustomerClassification_ScanStatus
*/

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_ScanStatus ADD COLUMN ParentCategoryID SMALLINT;

#####################CTS_DataCenter.CustomerCategory
INSERT INTO CTS_DataCenter.CustomerCategory (CategoryID, CategoryName,CategorySpec,DisplayOrder,CreatedDate)
VALUE(200,'General Normal Account','General Normal Account',3,CURRENT_TIME());

# Auto
INSERT INTO CTS_DataCenter.CustomerCategory (CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,CreatedDate,IsUsedManually, ScanIntervalInSecond)
VALUE(201,'New Member','New Member',200,1,CURRENT_TIME(),0,0);

INSERT INTO CTS_DataCenter.CustomerCategory (CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,CreatedDate,IsUsedManually, ScanIntervalInSecond)
VALUE(202,'Normal Account','Normal Account',200,2,CURRENT_TIME(),0,1209600);

INSERT INTO CTS_DataCenter.CustomerCategory (CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,CreatedDate,IsUsedManually, ScanIntervalInSecond)
VALUE(203,'Smart Punter','Smart Punter',200,3,CURRENT_TIME(),0,1209600);

INSERT INTO CTS_DataCenter.CustomerCategory (CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,CreatedDate,IsUsedManually, ScanIntervalInSecond)
VALUE(204,'High Risk Punter','High Risk Punter',200,4,CURRENT_TIME(),0,1209600);

INSERT INTO CTS_DataCenter.CustomerCategory (CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,CreatedDate,IsUsedManually, ScanIntervalInSecond)
VALUE(205,'VIP','VIP',200,5,CURRENT_TIME(),0,604800);

INSERT INTO CTS_DataCenter.CustomerCategory (CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,CreatedDate,IsUsedManually, ScanIntervalInSecond)
VALUE(206,'Probation','Probation',200,6,CURRENT_TIME(),0,1209600);