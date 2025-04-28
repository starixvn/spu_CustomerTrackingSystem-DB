/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
    Creator: 	20250428@Thomas.Nguyen
    Task:	 	Switch SP to WASAVerse [Redmine ID: #225335]
    DBName:		bodb02
*/
USE bodb02;

--===========  REMOVE UNUSED SPs ============
DROP PROCEDURE IF EXISTS CTS_Customer_GetNewCustSubInfo;
DROP PROCEDURE IF EXISTS CTS_Customer_GetNewCustSubInfo_xtest;

DROP PROCEDURE IF EXISTS CTS_GetCustomerInfo;
DROP PROCEDURE IF EXISTS CTS_GetCustomerInfo_xtest;

DROP PROCEDURE IF EXISTS CTS_GetCustSubInfo;
DROP PROCEDURE IF EXISTS CTS_GetCustSubInfo_xtest;

DROP PROCEDURE IF EXISTS CTS_Rpt_BettingPattern_TicketDetails;
DROP PROCEDURE IF EXISTS CTS_Rpt_BettingPattern_TicketDetails_xtest;

DROP PROCEDURE IF EXISTS CTS_TicketDetails_Get;
DROP PROCEDURE IF EXISTS CTS_TicketDetails_Get_xtest;

