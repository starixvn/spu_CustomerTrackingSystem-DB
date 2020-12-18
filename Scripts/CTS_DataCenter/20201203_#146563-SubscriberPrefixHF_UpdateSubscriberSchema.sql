/*<info serverAlias="CTSMain-CTS_Admin" databaseType="2"></info>*/
/*
Created: 20201217@CaseyHuynh
Task: 	 146563-SubscriberPrefix Hot Fix, Update Subscriber Schema. Not allow SubscriberPrefix NULL
DB: 	 CTS_DataCenter
*/
USE CTS_Admin;

ALTER TABLE 	CTS_Admin.Subscriber
MODIFY COLUMN 	SubscriberPrefix VARCHAR(30) NOT NULL;

