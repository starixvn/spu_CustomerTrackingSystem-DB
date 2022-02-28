/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20220210@Aries.Nguyen
	Task:	 	Re-arrange customer category/class for Good/Bad robot and CategoryToDangerLevel
	Server:  	Master
	DBName:		CTS_DataCenter

	Revisions: 
			- 20220210@Aries.Nguyen: Created [Redmine ID: #167726]
	Reviewer:
*/
USE CTS_DataCenter;
/*
	INSERT INTO `CTS_DataCenter`.`StaticList` (`ListID`, `ItemID`, `ListName`, `ListNameDisplay`, `ItemName`, `ItemNameDisplay`, `PriorityOrder`, `Status`) 
	VALUES 	('12', '10', 'Problem Case', 'Problem Case', 'Bad Robot', 'Bad Robot', '10', '1'),
			('12', '11', 'Problem Case', 'Problem Case', 'Good Robot', 'Good Robot', '10', '1');
*/
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES (69, 'RobotClassification_LastID', 'RobotClassification Scan', 'BIGINT', 0),
       (70, 'RobotClassification_BatchSize', 'RobotClassification Scan', 'INT', 500);









