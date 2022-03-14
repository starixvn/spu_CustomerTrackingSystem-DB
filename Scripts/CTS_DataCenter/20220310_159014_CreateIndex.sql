/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220310@Aries.Nguyen
    Task:	 	Create Index		[Redmine ID: #159014]
    DBName:		CTS_DataCenter
*/

/*Run on Master*/
USE CTS_DataCenter;
ALTER TABLE CTSCustomer 
ADD INDEX IX_CTSCustomer_SRecommend (SRecommend), 
ADD INDEX IX_CTSCustomer_MRecommend (MRecommend), 
ADD INDEX IX_CTSCustomer_Recommend (Recommend);

ALTER TABLE CTSCustomerClassification 
ADD INDEX IX_CTSCustomerClassification_SportGroupID_CreatedDate (SportGroupID,CreatedDate);