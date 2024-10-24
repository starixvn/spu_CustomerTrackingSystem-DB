/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20241024@Jonathan.Doan [Redmine ID: #212641]
	Task: Truncate Data for new FP flow
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

TRUNCATE TABLE DCS_DataCenter.FP_Association;
TRUNCATE TABLE DCS_DataCenter.FP_AssociationMapping;
TRUNCATE TABLE DCS_DataCenter.FP_Device;
TRUNCATE TABLE DCS_DataCenter.FP_DeviceMapping;
TRUNCATE TABLE DCS_DataCenter.FP_DeviceFingerprintAccount;
TRUNCATE TABLE DCS_DataCenter.FP_DeviceFingerprintAccountOld;
TRUNCATE TABLE DCS_DataCenter.FP_EvolvedMapping;
TRUNCATE TABLE DCS_DataCenter.FP_FingerPrint;
TRUNCATE TABLE DCS_DataCenter.FP_FingerPrintExtra;
TRUNCATE TABLE DCS_DataCenter.FP_FingerPrintOld;
TRUNCATE TABLE DCS_DataCenter.FP_Tagging;
TRUNCATE TABLE DCS_DataCenter.FP_TransactionDeviceMapping;


ALTER TABLE DCS_DataCenter.FP_Device AUTO_INCREMENT = 300000001;