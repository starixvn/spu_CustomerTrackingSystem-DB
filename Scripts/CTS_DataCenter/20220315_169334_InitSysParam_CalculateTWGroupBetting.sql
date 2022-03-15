/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220207@Harvey.Nguyen
    Task:	 	Add system parameter for calculate TW Groupbeting  [Redmine ID: 169334]
    DBName:		CTS_DataCenter
*/

/*Run on Master*/
USE CTS_DataCenter;
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('77', 'TWGroupBetting_LastScanTime', 'TWGroupBetting_LastScanTime', 'DATETIME', '2022-03-15 00:00:00');
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('78', 'TWGroupBetting_LastTimeCountTotalTicket', 'TWGroupBetting_LastTimeCountTotalTicket', 'DATETIME', '2022-03-15 00:00:00');
