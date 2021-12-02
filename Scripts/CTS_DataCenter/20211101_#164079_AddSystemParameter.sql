/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20211101@Aries.Nguyen
    Task:	 	Add System Parameter
    DBName:		CTS_DataCenter
*/
USE CTS_DataCenter;
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES  (64, 'AFC scan PA Last Cust', 'AFC scan PA Last Cust', 'INT', '0'),
		(65, 'AFC scan PA Current B2C SubID', 'Current B2C SubID', 'INT', '4400'),
		(66, 'AFC scan PA Batch Size', 'Batch Size', 'INT', '1000');

INSERT INTO CTS_DataCenter.StaticList(ListID, ItemID, ListName, ListNameDisplay, ItemName, ItemNameDisplay, PriorityOrder, Status, Description, CreatedDate)
VALUES 	(15, 4400, "B2C Licensee", "B2C Licensee", "N88", "N88", 1,1, "AFC - B2C Update cust infor", NOW()),
		(15, 4610, "B2C Licensee", "B2C Licensee", "N8G", "N8G", 1,1, "AFC - B2C Update cust infor", NOW()),
		(15, 4629, "B2C Licensee", "B2C Licensee", "N8B", "N8B", 1,1, "AFC - B2C Update cust infor", NOW());

USE CTS_DataCenter;
ALTER TABLE CTSCustomerClassification ADD INDEX IX_CTSCustomerClassification_SubscriberID_SportGroupID(SubscriberID,SportGroupID), ALGORITHM=INPLACE, LOCK=NONE;

ALTER TABLE CTSCustomerClassification DROP INDEX IX_CTSCustomerClassification_CTSCustID;