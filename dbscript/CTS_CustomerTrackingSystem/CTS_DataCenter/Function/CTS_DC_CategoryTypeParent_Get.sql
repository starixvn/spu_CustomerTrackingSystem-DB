/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="1" isNested="0"></info>*/
DROP FUNCTION IF EXISTS `CTS_DC_CategoryTypeParent_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` FUNCTION `CTS_DC_CategoryTypeParent_Get`(
    	ip_CateTypeParentName		VARCHAR(200)
)
RETURNS INT
DETERMINISTIC
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240618@Victoria.Le
		Task:		Function to return the CategoryTypeID/ParentID
		DB:			CTS_DataCenter
		
		Revisions: 
			-	20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
			
		Param's Expanation:
			- ip_CateTypeParentName: refer to table CTS_DataCenter.StaticList - ListID = 6
				
				+ CONST_CATEGORYTYPEID_VVIP			>> 1
				+ CONST_CATEGORYTYPEID_WRAPPER		>> 2
				+ CONST_CATEGORYTYPEID_PA			>> 3
				+ CONST_CATEGORYTYPEID_POTENTIALPA	>> 4
				+ CONST_CATEGORYTYPEID_NORMAL		>> 5
			
			SELECT ItemID FROM CTS_DataCenter.StaticList WHERE ListID = 6; -- Return CategoryTypeID
			SELECT ItemParentItemID FROM CTS_DataCenter.StaticList WHERE ListID = 6; -- Return ParentID
*/

	DECLARE lv_GetTypeID	 			INT;
	DECLARE lv_CateTypeParentID 		INT UNSIGNED;
    
    IF ip_CateTypeParentName LIKE 'CONST_CATEGORYTYPEID%' THEN
		SET lv_GetTypeID = 1;
	ELSEIF ip_CateTypeParentName LIKE 'CONST_PARENTID%' THEN
		SET lv_GetTypeID = 2;
	END IF;
	
    IF lv_GetTypeID = 1 THEN
		IF ip_CateTypeParentName = 'CONST_CATEGORYTYPEID_VVIP' THEN
			SET lv_CateTypeParentID 	= 1;
			
		ELSEIF ip_CateTypeParentName = 'CONST_CATEGORYTYPEID_WRAPPER' THEN 
			SET lv_CateTypeParentID 	= 2;
			
		ELSEIF ip_CateTypeParentName = 'CONST_CATEGORYTYPEID_PA' THEN 
			SET lv_CateTypeParentID 	= 3;
			
		ELSEIF ip_CateTypeParentName = 'CONST_CATEGORYTYPEID_POTENTIALPA' THEN 
			SET lv_CateTypeParentID 	= 4;
			
		ELSEIF ip_CateTypeParentName = 'CONST_CATEGORYTYPEID_NORMAL' THEN 
			SET lv_CateTypeParentID 	= 5;
		
		END IF;
	END IF;
	
    IF lv_GetTypeID = 2 THEN
		IF ip_CateTypeParentName = 'CONST_PARENTID_VVIP' THEN
			SET lv_CateTypeParentID		= 1000;
			
		ELSEIF ip_CateTypeParentName = 'CONST_PARENTID_WRAPPER' THEN 
			SET lv_CateTypeParentID	 	= 10000;
			
		ELSEIF ip_CateTypeParentName = 'CONST_PARENTID_PA' THEN 
			SET lv_CateTypeParentID	 	= 20000;
			
		ELSEIF ip_CateTypeParentName = 'CONST_PARENTID_POTENTIALPA' THEN 
			SET lv_CateTypeParentID 	= 30000;
			
		ELSEIF ip_CateTypeParentName = 'CONST_PARENTID_NORMAL' THEN 
			SET lv_CateTypeParentID 	= 40000;
		
		END IF;
	END IF;
    
	RETURN (lv_CateTypeParentID);

END$$
DELIMITER ;