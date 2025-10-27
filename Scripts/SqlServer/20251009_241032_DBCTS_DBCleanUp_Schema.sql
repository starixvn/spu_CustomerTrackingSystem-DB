/*<info serverAlias="DBCTS-bodb02,DBCTS-WASAVerse" databaseType="1"></info>*/
/*
Creator:	20251009@Thomas.Nguyen
Task:	 	DB CleanUp Schema
Server:  	DBCTS
DBName:		bodb02, WASAVerse

Revisions: 
		- 20251009@Thomas.Nguyen: Created [Redmine ID: #241032]
Reviewer:
*/

USE bodb02;
GO
DROP PROCEDURE IF EXISTS CTS_CustomerEsportAutoSuspendStatus_Get;
DROP PROCEDURE IF EXISTS CTS_CustomerGeneralStatus_Get;
DROP PROCEDURE IF EXISTS CTS_CustomerLastTicketDate_Get;
DROP PROCEDURE IF EXISTS CTS_GetMainDbCustomerForUpdateUsername2;

DROP PROCEDURE IF EXISTS CTS_CustomerEsportAutoSuspendStatus_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_CustomerGeneralStatus_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_CustomerLastTicketDate_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_GetMainDbCustomerForUpdateUsername2_xtest;

USE WASAVerse;
GO
DROP FUNCTION IF EXISTS f_CTS_TWGroupBetting_GetTimeRange;
DROP FUNCTION IF EXISTS f_CTS_TWGroupBetting_GetTimeRange_xtest;