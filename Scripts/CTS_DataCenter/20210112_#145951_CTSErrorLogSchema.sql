/*<info serverAlias="CTSMain-CTS_Log" databaseType="2"></info>*/
/*
Creator: 	20210112@Aries.Nguyen
Task:	 	Schema for CTSErrorLog  [Redmine ID: 145951]
DBName:		CTS_Log

Revisions: 
	-	[20210112@Aries.Nguyen]: Create schema CTSErrorLog, CTSErrorEvent. Init data for CTSErrorEvent, Create sp CTS_Log_ErrorLog_Insert
*/

USE CTS_Log;
CREATE TABLE `CTSErrorLog` (
	`RowID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`EventID` INT DEFAULT NULL,
	`Message` VARCHAR(300) DEFAULT NULL,
	`Description` JSON DEFAULT NULL,
	`CreatedDate` DATETIME DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`RowID`),
	KEY `IX_CTSErrorLog_EventID` (`EventID`),
	KEY `IX_CTSErrorLog_CreatedDate` (`CreatedDate` DESC)
) ENGINE=InnoDB AUTO_INCREMENT=1;   


USE CTS_Log;
CREATE TABLE `CTSErrorEvent` (
	`EventID` int NOT NULL AUTO_INCREMENT,
	`EventName` varchar(100) NOT NULL,
	`Description` varchar(200) DEFAULT NULL,
	PRIMARY KEY (`EventID`),
	KEY `IX_CTSErrorEvent_EventName` (`EventName`)
) ENGINE=InnoDB;


USE CTS_Log;
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (1,'CTS_DC_CustClassification_GetLatestClassification','Get error messages for get lastest classification. Include: existed special cc, existed category and no mapping cc');
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (2,'CTS_DC_CustClassification_Probation_UpdateLastScanDate','Get error messages for update probation info (LastScanDate)');
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (3,'CTS_DC_CustClassification_UpdateIsAppliedCC','Get error messages for update history info (IsAppliedCC)');
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (4,'CTS_DC_CustEvidence_GetExistedEvidencesToSync','Get error messages for get existed evidence category');
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (5,'CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers','Get error messages for import customer evidences from API');
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (6,'CTS_DC_CustEvidence_InsertMultiple','Get error messages for import evidences by Customer from file');
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (7,'CTS_DC_CustEvidence_InsertMultiple_ByCustId','Get error messages for import evidences by Customer from API');
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (8,'CTS_DC_CustEvidence_RemoveOldEvidenceForInsertMultiple','Get error messages for remove old evidences by Customer from file');
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (9,'CTS_DC_CustEvidence_SyncToCategory','Get error messages for sync evidence to category');
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (10,'CTS_DC_InsertCategorizedProblemAccounts','Get error messages for auto tag problem account');
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (11,'CTS_DC_InsertMainCustomerClassification','Get error messages for auto tag normal account');
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (12,'CTS_DC_SpecialCustClass_InsertRobotUsers','Get error messages for scan robot user');
INSERT INTO CTS_Log.CTSErrorEvent (EventID, EventName, Description) VALUES (13,'CTS_DC_InsertCTSCustomer','Get error messages for insert new customer');



USE CTS_Log;
DROP procedure IF EXISTS `CTS_Log_ErrorLog_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_ErrorLog_Insert`(
		ip_EventName	VARCHAR(100)
	,	ip_Message 		VARCHAR(300)
	,	ip_Description 	JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210112@Aries.Nguyen
		Task:		Monitor Error [Redmine ID: 145066]
		DB:			CTS_Log
        
		Revisions:
			-	20210112@Aries.Nguyen: Create SP [Redmine ID: 145066]
            
		Param's Explanation (filtered by):
			-	CALL CTS_Log.CTS_Log_ErrorLog_Insert ('CTS_DC_CustInfo_GetFlagged', 'error message', '{"custId":1}');
            
	*/

	DECLARE	lv_EventID BIGINT UNSIGNED DEFAULT 0;
    
    SELECT 	EventID INTO lv_EventID
		FROM CTS_Log.CTSErrorEvent 
    WHERE EventName = ip_EventName;

	IF (lv_EventID IS NULL OR lv_EventID < 1) THEN
		INSERT INTO CTS_Log.CTSErrorEvent(EventName) VALUES (ip_EventName);
        SET lv_EventID = LAST_INSERT_ID();
       
    END IF;
	
    INSERT INTO CTS_Log.CTSErrorLog(EventID, `Message`, `Description`)
    VALUES (lv_EventID, ip_Message, ip_Description);
END$$

DELIMITER ;