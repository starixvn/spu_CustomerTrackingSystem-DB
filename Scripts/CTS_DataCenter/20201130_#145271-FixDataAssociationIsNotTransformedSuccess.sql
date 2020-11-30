/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Created: 20201126@CaseyHuynh
Task: 	 Retry Transform Association for account has been transfromed to CTS Successfully
DB: 	 CTS_DataCenter
*/

##Run after deploy SP "CTS_DC_TransformAssociationByDevice"
CALL CTS_Adhoc.`Iss145277_ReTransformAssocition`(10000);