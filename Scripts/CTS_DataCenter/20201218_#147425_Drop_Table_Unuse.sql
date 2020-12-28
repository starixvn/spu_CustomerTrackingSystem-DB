/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20201218@Aries.Nguyen
	Task: Remove table unuse. Add primary key for tables [Redmine ID: #147425] 
	DB: CTS_Admin, CTS_DataCenter, DCS_DataCenter
*/
USE CTS_Admin;
DROP TABLE IF EXISTS CTS_Admin.ZZZ_UserLog_UAT_Removing;


USE CTS_DataCenter;
DROP TABLE IF EXISTS CTS_DataCenter.ZZZ_Temp_DEL_CTSCustomer_Removing;
DROP TABLE IF EXISTS CTS_DataCenter.ZZZ_tempCustomerCategory_Removing;
DROP TABLE IF EXISTS CTS_DataCenter.ZZZ_tempProAss1_Removing;
DROP TABLE IF EXISTS CTS_DataCenter.ZZZ_tempProDev1_Removing;


USE DCS_DataCenter;
DROP TABLE IF EXISTS DCS_DataCenter.ZZZ_TEMP_MaxAccount_Removing;
DROP TABLE IF EXISTS DCS_DataCenter.ZZZ_TEMP_MaxTrans_Removing;

DROP TABLE IF EXISTS DCS_DataCenter.ZZZ_Transaction_AccountIPFirstLogin_Removing;
DROP TABLE IF EXISTS DCS_DataCenter.ZZZ_Transaction_IPAccountFirstLogin_Removing;
DROP TABLE IF EXISTS DCS_DataCenter.ZZZ_Transaction_IpChangeTimeDiff_Removing;
DROP TABLE IF EXISTS DCS_DataCenter.ZZZ_DeviceCode_Issue20200924_Removing;
DROP TABLE IF EXISTS DCS_DataCenter.ZZZ_MoveTransaction_Removing;

DROP TABLE IF EXISTS DCS_DataCenter.ZZZ_LastLoginTime_TransformTemp_Removing;
DROP TABLE IF EXISTS DCS_DataCenter.ZZZ_dba_track_blocking_issue_Removing;
