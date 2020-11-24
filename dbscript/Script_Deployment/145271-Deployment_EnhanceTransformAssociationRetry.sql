/*<info serverAlias="CTSMain-CTS_DataCenter,DCS_DataCenter" databaseType="2"></info>*/

#*******2.1: UPDATE PARAMETER FROM SystemParameter******
USE CTS_DataCenter;
UPDATE 	CTS_DataCenter.SystemParameter
SET		ParameterName = 'RetryTransformAccount_LastCTSCustID'
		, ParameterDataType = 'BIGINT UNSIGNED'		
        , ParameterValue = (SELECT MAX(CTSCustID) FROM CTS_DataCenter.CTSCustomer)
        , ParameterDesc = 'Keep the Last CTSCustID from CTS_DC_TransformDCSAccountAssociationForNewCTSCustomer execution'
WHERE ParameterID = 4;

UPDATE 	CTS_DataCenter.SystemParameter
SET		ParameterName = 'RetryTransformAccount_LastTime'
        , ParameterDataType = 'DATETIME'
        , ParameterValue = NOW()
        , ParameterDesc = 'Keep the Last Time from CTS_DC_Task_TransformAccountAssociationToCTSRetry execution'
WHERE ParameterID = 5;

#*******2.2: ALTER EVENT******
ALTER EVENT  CTS_DataCenter.CTS_DC_JOB_TransformAccountAssociationToCTS_Retry
DISABLE
DO
	CALL CTS_DataCenter.CTS_DC_Task_TransformAccountAssociationToCTSRetry();
;
ALTER EVENT  CTS_DataCenter.CTS_DC_JOB_TransformAccountAssociationToCTS_Retry
ENABLE;

#******2.3: Fix for Old Data*******
CALL CTS_DataCenter.CTS_DC_TransformCTSCustomerRetryManual(IN ip_fromCTSCustID BIGINT, IN ip_toCTSCustID BIGINT, IN ip_Batch INT);


