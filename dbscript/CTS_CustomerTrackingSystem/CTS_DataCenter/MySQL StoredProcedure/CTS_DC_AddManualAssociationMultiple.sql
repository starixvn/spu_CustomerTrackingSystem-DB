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
			- 20200416@Harvey.Nguyen: Initial	 		[Redmine ID: #136212]
            
		Param's Explanation:
        
        CALL CTS_DataCenter.CTS_DC_AddManualAssociationMultiple ('[{"FromSubscriberID":2,"FromCTSCustID":1,"ToSubscriberID":2,"ToCTSCustID":2,"Remark":"test","CreatedBy":"8"},{"FromSubscriberID":2,"FromCTSCustID":1,"ToSubscriberID":2,"ToCTSCustID":4,"Remark":"test","CreatedBy":"8"}]')
	*/ 

    DECLARE vrCreatedBy 		BIGINT;
    DECLARE vrFromCTSCustId 	VARCHAR(500);
    DECLARE vrToCTSCustId 		VARCHAR(500);
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
			FromSubscriberID 
        ,	FromCTSCustID 
        ,	ToSubscriberID 
        ,	ToCTSCustID
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
			CASE WHEN tma.FromCTSCustID > tma.ToCTSCustID THEN tma.ToSubscriberID ELSE tma.FromSubscriberID END
        ,	CASE WHEN tma.FromCTSCustID > tma.ToCTSCustID THEN tma.ToCTSCustID ELSE tma.FromCTSCustID END
        ,	CASE WHEN tma.FromCTSCustID > tma.ToCTSCustID THEN tma.FromSubscriberID ELSE tma.ToSubscriberID END
        ,	CASE WHEN tma.FromCTSCustID > tma.ToCTSCustID THEN tma.FromCTSCustID ELSE tma.ToCTSCustID END
        ,	tma.Remark
        , 	CURRENT_TIME()
        ,	tma.CreatedBy
    FROM TempManualAssociation tma;
    
    SELECT DISTINCT CreatedBy
    INTO vrCreatedBy
    FROM TempManualAssociation
    LIMIT 1;
    
    SELECT GROUP_CONCAT(DISTINCT FromCTSCustID SEPARATOR ',') 
    INTO vrFromCTSCustId
    FROM TempManualAssociation;
    
    SELECT GROUP_CONCAT(ToCTSCustID SEPARATOR ',') 
    INTO vrToCTSCustId
    FROM TempManualAssociation;    
   
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(7, 'CTS_DC_AddManualAssociationMultiple', CONCAT('Insert Manual Multiple Association: ip_FromCTSCustID: ', vrFromCTSCustId,'; ip_ToCTSCustIDList: ', vrToCTSCustId), CURRENT_TIME(), vrCreatedBy);
	
END$$	
DELIMITER ;