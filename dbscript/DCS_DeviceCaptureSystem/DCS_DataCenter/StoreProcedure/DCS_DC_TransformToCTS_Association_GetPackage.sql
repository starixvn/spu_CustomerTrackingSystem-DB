/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DELIMITER $$
DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_TransformToCTS_Association_GetPackage$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE DCS_DataCenter.DCS_DC_TransformToCTS_Association_GetPackage(IN ip_NoOfAssociation INT, IN ip_NoOfBatch INT)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20190730@Casey.Huynh
	Task : Get DeviceID NULL From Table Transaction
	DB: DCS_DataCenter
	Original:

	Revisions:
		#1. [20201112@CaseyHuynh][145271]:	
			+ GET Lastest Code Move Server P3, update Permission and Add Meta data
            + Enhance  script1
	Param's Explanation (filtered by):
	*/
	
	DECLARE		TotalRecord		INT UNSIGNED DEFAULT 0;
	DECLARE		Batch			TINYINT DEFAULT 1;
    
	### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200)  DEFAULT 'DCS_DC_TransformToCTS_Association_GetPackage' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = CONCAT('Input: ',ip_NoOfAssociation,'_', ip_NoOfBatch) ;		
    SET 	vrStepID = 1;
    
    SET 	vrStartTime = CURRENT_TIMESTAMP(4);	
    
    INSERT INTO CTS_Log.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);

	### PERFORMANCE: END
	SET TotalRecord = ip_NoOfAssociation*ip_NoOfBatch;
    
    SET @RowId = 0;
    SET @MinAssociationID = (SELECT MAX(AssociationID) FROM DCS_DataCenter.Association AS ac) ;
    SET @MaxAssociationID = 0;
    
	SET TotalRecord = ip_NoOfAssociation*ip_NoOfBatch;  
	SELECT	@RowId := @RowId+1
            , ceil(@RowId/ip_NoOfAssociation) AS BatchID
            , @MinAssociationID := LEAST(@MinAssociationID,AssociationID)
            , @MaxAssociationID := GREATEST(@MaxAssociationID,AssociationID)
			, ass.AssociationID
			, ass.AccountID
            , ass.DeviceID
            , ass.CreatedTime
            , ass.SubscriberID
	FROM 	DCS_DataCenter.Association AS ass
	WHERE	ass.IsCTSTransformed = 0
	LIMIT	TotalRecord;

    SELECT @RowId,@MinAssociationID,@MaxAssociationID;
    
      
	### PERFORMANCE
	SET		vrEndTime = CURRENT_TIMESTAMP(4);
    
    UPDATE	CTS_Log.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
            , z.TotalRecord = @RowId
            , z.FromID 		= @MinAssociationID
            , z.ToID		= @MaxAssociationID

    WHERE	z.ExecKey = vrExecKey AND z.StepID = z.StepID;
    ### PERFORMANCE: END 
END$$
DELIMITER ;
