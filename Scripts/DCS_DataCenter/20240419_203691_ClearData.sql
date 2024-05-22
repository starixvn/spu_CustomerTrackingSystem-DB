/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20240419@Jonathan.Doan [Redmine ID: #203691]
	Task: Clear Data RawTransaction
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

DELETE FROM DCS_DataCenter.RawTransaction
WHERE CreatedDate < DATE_FORMAT(CURRENT_TIMESTAMP(), '%Y-%m-%d')
	AND IsProcessed = -1;