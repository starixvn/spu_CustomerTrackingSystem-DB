/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20201218@Aries.Nguyen
	Task: Remove table unuse. Add primary key for tables [Redmine ID: #147425] 
	DB: CTS_DataCenter, DCS_DataCenter
*/
USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.CTSUserPermission ADD COLUMN ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT FIRST, ADD PRIMARY KEY (ID), ALGORITHM=INPLACE, LOCK=SHARED; -- 113 row


USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.MappingSubscriberSite DROP INDEX PK_MappingSubscriberSite_SubscriberID;
ALTER TABLE CTS_DataCenter.MappingSubscriberSite ADD PRIMARY KEY (SiteID,SubscriberID), ALGORITHM=INPLACE, LOCK=NONE; -- 631 row



USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.NotificationSettings ADD COLUMN ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT FIRST, ADD PRIMARY KEY (ID), ALGORITHM=INPLACE, LOCK=SHARED; -- 104 Row


USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.ProcessAffectedEvidence ADD COLUMN ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT FIRST, ADD PRIMARY KEY (ID), ALGORITHM=INPLACE, LOCK=SHARED; -- 1 row



USE DCS_DataCenter;
ALTER TABLE DCS_DataCenter.ArchiveStatus ADD PRIMARY KEY (ArchiveID), ALGORITHM=INPLACE, LOCK=NONE;
ALTER TABLE DCS_DataCenter.ArchiveStatus MODIFY COLUMN ArchiveID INT AUTO_INCREMENT, ALGORITHM=COPY, LOCK=SHARED; -- 1 row