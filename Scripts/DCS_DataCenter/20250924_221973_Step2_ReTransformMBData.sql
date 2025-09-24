/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20250924@Jonathan.Doan [Redmine ID: #221973]
	Task: Re-transform MBData from July 1
	DB: DCS_DataCenter
*/

/* Load initial data into MBRawTransaction */
USE CTS_Adhoc;

SET sql_safe_updates = 0;
CALL CTS_Adhoc.Adhoc_DCS_DC_Initial_MBRawTransaction(10000);