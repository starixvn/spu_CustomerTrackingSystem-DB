/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20240318@Jonas.Huynh
	Task:	 	Renovate NonSport Rules
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20240318@Jonas.Huynh: Create Schema [Redmine ID: #201359]
*/

INSERT INTO `CTS_DataCenter`.`StaticList` (`ListID`, `ItemID`, `ListName`, `ItemName`, `ItemNameDisplay`, `ItemValue`, `Status`, `Description`) VALUES 
('23', '1', 'Customer Classification - By Sport - Probation Days Config', 'Soccer', 'Soccer', '14', '1', 'Probation Days Config'),
('23', '2', 'Customer Classification - By Sport - Probation Days Config', 'Basketball', 'Basketball', '14', '1', 'Probation Days Config'),
('23', '43', 'Customer Classification - By Sport - Probation Days Config', 'E-Sport', 'E-Sport', '14', '1', 'Probation Days Config'),
('23', '99', 'Customer Classification - By Sport - Probation Days Config', 'OtherSports', 'OtherSports', '14', '1', 'Probation Days Config'),
('23', '229', 'Customer Classification - By Sport - Probation Days Config', 'Non-Sports', 'Non-Sports', '19', '1', 'Probation Days Config'),
('23', '145', 'Customer Classification - By Sport - Probation Days Config', 'SabaVR Soccer', 'SabaVR Soccer', '14', '1', 'Probation Days Config'),
('23', '912', 'Customer Classification - By Sport - Probation Days Config', 'SabaVR Basketball', 'SabaVR Basketball', '14', '1', 'Probation Days Config');