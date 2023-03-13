/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20230313@Jonas.Huynh
Task:	 	Update Job Daily Scan PA
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230313@Jonas.Huynh: Created [#184772]
Reviewer:
*/

CREATE TABLE IF NOT EXISTS CTS_DataCenter.CTSCustomerClassification_DailyPAQueue (
		ID				BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
    ,	CustID			BIGINT UNSIGNED NOT NULL
    , 	CreatedTime		DATETIME NOT NULL
	, 	INDEX			IX_CTSCustomerClassification_DailyPAQueue_CreatedTime(CreatedTime)
) ENGINE=INNODB;
