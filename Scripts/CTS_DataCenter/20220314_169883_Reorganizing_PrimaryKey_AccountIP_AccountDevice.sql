/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220314@Aries.Nguyen
    Task:	 	Reorganizing the primary key of the AccountIP, AccountDevice tables		[Redmine ID: 168091]
    DBName:		CTS_DataCenter
*/

/*Run on Master AND Replica*/
USE DCS_DataCenter;
SET sql_log_bin = OFF;


ALTER TABLE AccountIP 
DROP PRIMARY KEY,
ADD COLUMN ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT FIRST,
ADD PRIMARY KEY (ID),
ADD UNIQUE KEY UN_AccountIP_AccountID_IP(AccountID,IP);

ALTER TABLE AccountDevice 
DROP PRIMARY KEY,
ADD COLUMN ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT FIRST,
ADD PRIMARY KEY (ID),
ADD UNIQUE KEY UN_AccountDevice_AccountID_DeviceID(AccountID,DeviceID);