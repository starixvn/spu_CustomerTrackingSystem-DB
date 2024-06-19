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

	DECLARE CONST_LIST_CLASSIFICATION		INT DEFAULT 6;
	DECLARE lv_GetTypeID	 				INT;
	DECLARE lv_CateTypeParentID 			INT UNSIGNED;
	
	SET ip_CateTypeParentName	= UPPER(ip_CateTypeParentName);
    
    IF ip_CateTypeParentName LIKE '%CATETYPE%' THEN
		SET lv_GetTypeID = 1;
	ELSEIF ip_CateTypeParentName LIKE '%PARENT%' THEN
		SET lv_GetTypeID = 2;
	ELSEIF ip_CateTypeParentName LIKE '%CATEID%' THEN
		SET lv_GetTypeID = 3;
	ELSEIF ip_CateTypeParentName LIKE '%CATEGROUPID%' THEN
		SET lv_GetTypeID = 4;
	END IF;
	

	SET lv_CateTypeParentID = (	SELECT 	stl.ItemDefaultValue
								FROM 	CTS_DataCenter.StaticList AS stl
								WHERE 	stl.ListID = CONST_LIST_CLASSIFICATION 
									AND stl.ItemParentItemID = lv_GetTypeID
									AND stl.ItemName = ip_CateTypeParentName);
	
    
	RETURN (lv_CateTypeParentID);

END$$
DELIMITER ;