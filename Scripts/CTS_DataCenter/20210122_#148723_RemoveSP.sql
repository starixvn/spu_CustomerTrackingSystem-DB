/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 202110122@Aries.Nguyen
	Task: 	 Remove sp [Redmine ID: #148723]
	DB: 	 DCS_DataCenter
*/

USE DCS_DataCenter;
DROP PROCEDURE IF EXISTS `DCS_DC_TransformToCTS_Account_Completed`;
DROP PROCEDURE IF EXISTS `DCS_DC_TransformToCTS_Association_Unsuccess_GetPackage`;