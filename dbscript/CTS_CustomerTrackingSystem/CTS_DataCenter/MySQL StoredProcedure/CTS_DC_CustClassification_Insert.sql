/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Insert`(
		IN	ip_InputFlowID			INT 
		IN	ip_FromAction			TINYINT
		IN	ip_UplineRoleID			TINYINT
		IN	ip_QueueID				BIGINT
		IN	ip_AffectDownline		BIT(1)
		IN	ip_IsToQueue			BIT(1)
		IN	ip_CustInfo				JSON
		OUT op_ErrorMessage 		VARCHAR(200)
)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240618@Victoria.Le
		Task:		Insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
		
		Revisions: 
			-	20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
			
		Param's Expanation:
			- 
*/


	DECLARE CONST_CATETYPEID_VVIP 			INT;
	DECLARE CONST_CATETYPEID_WRAPPER 		INT;
	DECLARE CONST_CATETYPEID_PA 			INT;
	DECLARE CONST_CATETYPEID_POTENTIALPA 	INT;
	DECLARE CONST_CATETYPEID_NORMAL 		INT;
	
	SET CONST_CATETYPEID_VVIP 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATETYPEID_VVIP');
	SET CONST_CATETYPEID_WRAPPER 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATETYPEID_WRAPPER');
	SET CONST_CATETYPEID_PA 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATETYPEID_PA');
	SET CONST_CATETYPEID_POTENTIALPA 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATETYPEID_POTENTIALPA');
	SET CONST_CATETYPEID_NORMAL 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATETYPEID_NORMAL');
	
	/*STEP 1: Parse raw data and get custinfo*/
	CALL CTS_DataCenter.CTS_DC_CustClassification_Insert_GetInfo (ip_InputFlowID,ip_FromAction,ip_CustInfo);
	
	
	/*STEP 2: Preprocess*/
	CALL CTS_DataCenter.CTS_DC_CustClassification_Insert_PreProcess ();
	
	
	/*STEP 3: Process*/
	CALL CTS_DataCenter.CTS_DC_CustClassification_Insert_Process ();
	
	
	/*STEP 4: Complete*/
	CALL CTS_DataCenter.CTS_DC_CustClassification_Insert_Complete ();
	
	
	/*STEP N: Return data*/
END$$
DELIMITER ;