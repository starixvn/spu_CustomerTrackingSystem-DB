/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/

/***1: DEPLOYE SCHEMA***********************************************
# 20210412_152454_DelUnuAccount_Step00_Schema
*/
/***2: DEPLOYED CTS_ADHOC SP***********************************************
# 20210412_152454_DelUnuAccount_Step10_Account_Get
# 20210412_152454_DelUnuAccount_Step11_Account_ExcluCustDCSAcc
# 20210412_152454_DelUnuAccount_Step12_Association_Get
# 20210412_152454_DelUnuAccount_Step13_DeviceDeviceCodeFC_Get
# 20210412_152454_DelUnuAccount_Step20_UMExcludeAccAss
# 20210412_152454_DelUnuAccount_Step21_UMExcludeDeviceDcDF
# 20210412_152454_DelUnuAccount_Step30_UMAccount_Delete
# 20210412_152454_DelUnuAccount_Step31_UMAssociation_Delete
# 20210412_152454_DelUnuAccount_Step32_UMDevice_Delete
# 20210412_152454_DelUnuAccount_Step33_UMDeviceCode_Delete
# 20210412_152454_DelUnuAccount_Step34_UMDeviceFingerprint_Delete
*/
/***3: BEFORE UM***********************************************/
USE CTS_Adhoc;

CALL CTS_Adhoc.CTS_AD_DelUnuAccount_Step10_Account_Get(1000,1);
CALL CTS_Adhoc.CTS_AD_DelUnuAccount_Step11_Account_ExcluCustDCSAcc(1000,1);
CALL CTS_Adhoc.CTS_AD_DelUnuAccount_Step12_Association_Get(1000,1);
CALL CTS_Adhoc.CTS_AD_DelUnuAccount_Step13_DeviceDeviceCodeDeviceFP_Get(1000,1);

/****4: QC: Check Data****************/

/***5: START DCS UM (STOP DCS TRANSFORM SERVICES) ***********************************************/
CALL CTS_Adhoc.CTS_AD_DelUnuAccount_Step20_UMExcludeAccAss(1000,0);
CALL CTS_Adhoc.CTS_AD_DelUnuAccount_Step21_UMExcludeDeviceDcDF(1000,1);

/****6: Check Data****************/
CALL CTS_Adhoc.CTS_AD_DelUnuAccount_Step30_Account_Delete(1000,1);
CALL CTS_Adhoc.CTS_AD_DelUnuAccount_Step31_Association_Delete(1000, 1);
CALL CTS_Adhoc.CTS_AD_DelUnuAccount_Step32_Device_Delete(1000,1);
CALL CTS_Adhoc.CTS_AD_DelUnuAccount_Step33_DeviceCode_Delete(1000,1);
CALL CTS_Adhoc.CTS_AD_DelUnuAccount_Step34_DeviceFingerprint_Delete(1000,1);

/***5: STOP DCS UM  (START DCS TRANSFORM SERVICES) ***********************************************/

