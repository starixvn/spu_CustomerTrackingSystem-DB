/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 20230316@Jonathan.Doan
Task:	 	Support return new device login for Alpha
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230316@Jonathan.Doan: Created [#185185]
Reviewer:
*/

CREATE TABLE IF NOT EXISTS DCS_DataCenter.Offset(
		Id					INT NOT NULL
	, 	OffsetName			VARCHAR(100) NOT NULL
	, 	OffsetValue			BIGINT UNSIGNED NOT NULL
	, 	CreatedDate			DATETIME
	,	PRIMARY KEY (`Id`)
	,	UNIQUE KEY `UX_Offset_OffsetName` (`OffsetName`)				
) ENGINE=InnoDB;


INSERT INTO `DCS_DataCenter`.`Offset` (`Id`, `OffsetName`, `OffsetValue`, `CreatedDate`) 
VALUES (1, 'AbnormalTransaction', 0, NOW());