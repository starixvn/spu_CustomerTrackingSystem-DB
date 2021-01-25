/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 202110125@Aries.Nguyen
	Task: 	 Create index EvidenceCode for Evidence table [Redmine ID: #146852]
	DB: 	 CTS_DataCenter
*/

USE CTS_DataCenter;
ALTER TABLE  CTS_DataCenter.Evidence ADD INDEX IX_Evidence_EvidenceCode (EvidenceCode) , ALGORITHM=INPLACE, LOCK=NONE;