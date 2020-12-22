/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20201218@Aries.Nguyen
	Task: Remove table unuse. Add primary key for tables [Redmine ID: #147425] 
	DB: CTS_Admin, CTS_DataCenter, DCS_DataCenter
*/
USE CTS_Admin;
ALTER TABLE CTS_Admin.UserLog_UAT RENAME TO CTS_Admin.ZZZ_UserLog_UAT_Removing, ALGORITHM=INSTANT;


USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.Temp_DEL_CTSCustomer RENAME TO CTS_DataCenter.ZZZ_Temp_DEL_CTSCustomer_Removing, ALGORITHM=INSTANT;
ALTER TABLE CTS_DataCenter.tempCustomerCategory RENAME TO CTS_DataCenter.ZZZ_tempCustomerCategory_Removing, ALGORITHM=INSTANT;
ALTER TABLE CTS_DataCenter.tempProAss1 RENAME TO CTS_DataCenter.ZZZ_tempProAss1_Removing, ALGORITHM=INSTANT;
ALTER TABLE CTS_DataCenter.tempProDev1 RENAME TO CTS_DataCenter.ZZZ_tempProDev1_Removing, ALGORITHM=INSTANT;



USE DCS_DataCenter;
ALTER TABLE DCS_DataCenter.TEMP_MaxAccount RENAME TO CTS_DataCenter.ZZZ_TEMP_MaxAccount_Removing, ALGORITHM=INSTANT;
ALTER TABLE DCS_DataCenter.TEMP_MaxTrans RENAME TO CTS_DataCenter.ZZZ_TEMP_MaxTrans_Removing, ALGORITHM=INSTANT;

ALTER TABLE DCS_DataCenter.Transaction_AccountIPFirstLogin RENAME TO CTS_DataCenter.ZZZ_Transaction_AccountIPFirstLogin_Removing, ALGORITHM=INSTANT;
ALTER TABLE DCS_DataCenter.Transaction_IPAccountFirstLogin RENAME TO CTS_DataCenter.ZZZ_Transaction_IPAccountFirstLogin_Removing, ALGORITHM=INSTANT;
ALTER TABLE DCS_DataCenter.Transaction_IpChangeTimeDiff RENAME TO CTS_DataCenter.ZZZ_Transaction_IpChangeTimeDiff_Removing, ALGORITHM=INSTANT;
ALTER TABLE DCS_DataCenter.DeviceCode_Issue20200924 RENAME TO CTS_DataCenter.ZZZ_DeviceCode_Issue20200924_Removing, ALGORITHM=INSTANT;
ALTER TABLE DCS_DataCenter.MoveTransaction RENAME TO CTS_DataCenter.ZZZ_MoveTransaction_Removing, ALGORITHM=INSTANT;

ALTER TABLE DCS_DataCenter.LastLoginTime_TransformTemp RENAME TO CTS_DataCenter.ZZZ_LastLoginTime_TransformTemp_Removing, ALGORITHM=INSTANT;
ALTER TABLE DCS_DataCenter.dba_track_blocking_issue RENAME TO CTS_DataCenter.ZZZ_dba_track_blocking_issue_Removing, ALGORITHM=INSTANT;
