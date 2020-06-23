DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_AddManualAssociationMultiple`$$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_AddManualAssociationMultiple`(
		IN ip_ManualAssociationList 	JSON
)
BEGIN
	/*
		Created:	20200622@Harvey
		Task :		Add manual association muptiple
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200416@Harvey.Nguye: Initial	 		[Redmine ID: #136212]
            
		Param's Explanation:
        
        CALL CTS_DataCenter.CTS_DC_AddManualAssociationMultiple ('[{"FromSubscriberID":2,"FromCTSCustID":1,"ToSubscriberID":2,"ToCTSCustID":2,"Remark":"test","CreatedBy":"8"}]')
	*/ 

    DECLARE ip_CreatedBy BIGINT;
    DROP TEMPORARY TABLE IF EXISTS TempManualAssociation;
    
	CREATE TEMPORARY TABLE TempManualAssociation( 	 
		 FromSubscriberID 	INT
    , 	 FromCTSCustID 		BIGINT
    ,	 ToSubscriberID 	INT
    , 	 ToCTSCustID 		BIGINT
    , 	 Remark 			VARCHAR(500)
    , 	 CreatedBy 			BIGINT);
 
	INSERT INTO TempManualAssociation
	SELECT 
			CASE WHEN FromCTSCustID > ToCTSCustID THEN ToSubscriberID ELSE FromSubscriberID END
        ,	CASE WHEN FromCTSCustID > ToCTSCustID THEN ToCTSCustID ELSE FromCTSCustID END
        ,	CASE WHEN FromCTSCustID > ToCTSCustID THEN FromSubscriberID ELSE ToSubscriberID END
        ,	CASE WHEN FromCTSCustID > ToCTSCustID THEN FromCTSCustID ELSE ToCTSCustID END
        ,	Remark
        ,	CreatedBy
	FROM JSON_TABLE(ip_ManualAssociationList,
		 "$[*]" COLUMNS(
		  FromSubscriberID 	INT 			PATH "$.FromSubscriberID"
		, FromCTSCustID		INT	 UNSIGNED	PATH "$.FromCTSCustID" 
		, ToSubscriberID	BIGINT			PATH "$.ToSubscriberID" 
        , ToCTSCustID		INT 			PATH "$.ToCTSCustID" 
		, Remark			VARCHAR(500) 	PATH "$.Remark" 
		, CreatedBy			VARCHAR(50) 	PATH "$.CreatedBy" 
		 )) as tmpTable;

    
	INSERT INTO CTS_DataCenter.AssociationByManual(FromSubscriberID, FromCTSCustID, ToSubscriberID, ToCTSCustID, Remark, CreatedDate, CreatedBy)
	SELECT 
			FromSubscriberID
        ,	FromCTSCustID
        ,	ToSubscriberID
        ,	ToCTSCustID
        ,	Remark
        , 	CURRENT_TIME()
        ,	CreatedBy
    FROM TempManualAssociation;
    
    SELECT CreatedBy
    INTO ip_CreatedBy
    FROM TempManualAssociation
    LIMIT 1;
   
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(7, 'CTS_DC_AddManualAssociation', CONCAT('Insert Manual Association: ip_ManualAssociationList', ip_ManualAssociationList,')'), CURRENT_TIME(), ip_CreatedBy);
	
END$$	
DELIMITER ;