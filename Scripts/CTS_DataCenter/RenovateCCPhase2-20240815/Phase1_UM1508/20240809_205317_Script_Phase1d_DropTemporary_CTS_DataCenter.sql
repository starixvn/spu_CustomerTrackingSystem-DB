/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240809@Victoria.Le
Task:	 	CLEAN TEMPORARY SPs
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240809@Victoria.Le: 		Initial Writing - Phase 1-b: Initial Data [Redmine ID: #205317]
										
								
*/

USE CTS_DataCenter;

DROP PROCEDURE IF EXISTS `Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer`;
DROP PROCEDURE IF EXISTS `Adhoc_Renovate_Phase1_CTS_DC_CustClassification`;
DROP PROCEDURE IF EXISTS `Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport`;
DROP PROCEDURE IF EXISTS `Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport_History`;
DROP PROCEDURE IF EXISTS `Adhoc_Renovate_Phase1_CTS_DC_CustClassification_History`;
DROP PROCEDURE IF EXISTS `Adhoc_Renovate_Phase1_CTS_DC_CustClassification_Queue`;
