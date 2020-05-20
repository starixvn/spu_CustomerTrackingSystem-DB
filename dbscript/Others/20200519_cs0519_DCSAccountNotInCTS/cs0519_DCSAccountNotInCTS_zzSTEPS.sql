
	/*
		Created:	20200519@Casey
		Task:		Remove Account NOT In CTS
		DB:			CTS_Adhoc
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
	
/********************************BACKUP DATE **********************************/	
/******************************************************************************/
	#====STEP01: GET Account backup
    CALL CTS_Adhoc.cs0519_DCSAccountNotInCTS_GetAccount();
    
    #====STEP02: GET Association backup
    CALL CTS_Adhoc.cs0519_DCSAccountNotInCTS_GetAssociation();
    
    #====STEP03: GET Device backup
    CALL CTS_Adhoc.cs0519_DCSAccountNotInCTS_GetDevice();
    
    #====STEP04: GET DeviceFingerprint backup
    CALL CTS_Adhoc.cs0519_DCSAccountNotInCTS_GetDeviceFingerprint();
    
/********************************REMOVE DATA **********************************/	
/******************************************************************************/
	#====STEP05: DELETE Account 
    CALL CTS_Adhoc.cs0519_DCSAccountNotInCTS_DeleteAccount();
    
    #====STEP06: DELETE Association
    CALL CTS_Adhoc.cs0519_DCSAccountNotInCTS_DeleteAssociation();
    
    #====STEP07: DELETE Device
    CALL CTS_Adhoc.cs0519_DCSAccountNotInCTS_DeleteDevice();
    
    #====STEP08: DELETE DeviceFingerprint 
    CALL CTS_Adhoc.cs0519_DCSAccountNotInCTS_DeleteDeviceFingerprint;