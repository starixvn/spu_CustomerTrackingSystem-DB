/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator:	20240510@Jonas.Huynh
    Task:	 	Correct Archived Customer
    Server:  	Master
    DBName:		CTS_DataCenter

    Revisions: 
		    - 20240510@Jonas.Huynh: Correct Archived Customer Missing [Redmine ID: #204368]
*/
USE CTS_DataCenter;

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('1001', 'CorrectData_ArchiveCustomer_LastArchivedDate', 'Get Last ArchiveDate ', 'DATETIME(3)', '2021-08-18 01:35:20');

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('1002', 'CorrectData_ArchiveCustomer_LastCustID', 'Get Last CustID ', 'BIGINT UNSIGNED', 0);

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('1003', 'CorrectData_ArchiveCustomer_MaxArchivedDate', 'Get Max ArchiveDate', 'DATETIME(3)', '2024-05-07 01:41:56.100');

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('1004', 'CorrectData_ArchiveCustomer_LastArchivedDate', 'Get Last ArchiveDate ', 'DATETIME(3)', '2021-08-18 01:35:20');

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('1005', 'CorrectData_ArchiveCustomer_LastCustID', 'Get Last CustID ', 'BIGINT UNSIGNED', 0);

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('1006', 'CorrectData_ArchiveCustomer_MaxArchivedDate', 'Get Max ArchiveDate', 'DATETIME(3)', '2024-05-07 01:41:56.100');

CREATE TABLE IF NOT EXISTS CTS_DataCenter.Adhoc_202405_CustMissingArchive (
		ID			    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
    ,	CustID			INT UNSIGNED NOT NULL	
    ,	ArchivedDate	DATETIME(3)	NOT NULL	
    ,	CreatedTime		DATETIME(3)	NOT NULL
	, 	INDEX			IX_Adhoc_ArchivedCustMissing_CustID(CustID)
) ENGINE=INNODB; 


