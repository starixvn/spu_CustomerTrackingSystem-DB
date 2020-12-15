/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_GetCustomerClassificationByCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_GetCustomerClassificationByCategory`(IN ip_CategoryIDList varchar(1000),IN ip_CustSport json)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	[20200612@Casey.Huynh][135324]
		Task:		Return the auto tag customer list by ip_category
		DB:			CTS_DataCenter
        
		Original:

		Revisions:
			[20200701@Casey.Huynh][135324]: Chagne Flow and Store more Info
            [20200826@Casey.Huynh][137693]: Add Trace Performance
            - 20201214@Irena.Vo: Enhance logic ignore Pin category & Probation List  [RedmineID: #145951] 
            
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
	*/     
    ### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200)  DEFAULT 'CTS_DC_GetCustomerClassificationByCategory' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrLgTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = '';
    SET 	vrStepID = 1;
    
    SET 	vrStartTime = CURRENT_TIMESTAMP(4);	
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);

	### PERFORMANCE: END
    
    DROP TEMPORARY TABLE IF EXISTS Temp_inputCategory;
    CREATE TEMPORARY TABLE Temp_inputCategory(
		CategoryID	SMALLINT UNSIGNED
    );
    
    #===GET Category List    
    CALL CTS_DataCenter.CTS_DC_Sys_SplitStringToTempItemTable(ip_CategoryIDList, ',', 'SMALLINT UNSIGNED');   # Return TempItemTable table within Item Column	
    INSERT INTO Temp_inputCategory (CategoryID)
    SELECT 	Item
    FROM 	TempItemTable;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_inputCustSport;
	CREATE TEMPORARY TABLE Temp_inputCustSport(
		CustID			BIGINT UNSIGNED
		, SportGroupID	SMALLINT UNSIGNED
	);
 
	INSERT INTO Temp_inputCustSport(CustID, SportGroupID)
	SELECT 		tmpTable.CustID
				, tmpTable.SportGroupID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId"
		 )) as tmpTable;       
    
    SELECT		tmpCusCat.CustID
				, tmpCusCat.SportGroupID AS SportGroupID
                , tmpCusCat.CategoryID
	FROM	(    
				SELECT 		cus.CustID AS CustID
							, cus.SportGroupID AS SportGroupID  
							, ccl.SportGroupID AS CurrentSportGroupID
							, ctg.CategoryID AS CategoryID
				FROM 	 	Temp_inputCustSport AS cus
				LEFT JOIN	CTS_DataCenter.CTSCustomerClassification AS ccl
							ON cus.CustID = ccl.CustID
								AND cus.SportGroupID = ccl.SportGroupID
				LEFT JOIN	Temp_inputCategory AS ctg
							ON ccl.CategoryID = ctg.CategoryID
			) AS tmpCusCat
	LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin ON pin.CustID = tmpCusCat.CustID
    LEFT JOIN CTS_DataCenter.ProbationAccountMonitor AS pro ON pro.CustID = tmpCusCat.CustID AND pro.SportGroupID = tmpCusCat.SportGroupID
	WHERE	pin.CustID IS NULL 
            AND pro.SportGroupID IS NULL
            AND (tmpCusCat.CurrentSportGroupID IS NULL OR tmpCusCat.CategoryID IS NOT NULL);
    
    ### PERFORMANCE
	SET		vrEndTime = CURRENT_TIMESTAMP(4);
    
	SELECT 	Count(1), Min(tas.CustID), Max(tas.CustID)
    INTO	vrLgTotalRecord, vrFromID, vrToID
    FROM	Temp_inputCustSport AS tas;    
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
            , z.TotalRecord = vrLgTotalRecord
            , z.FromID = vrFromID
            , z.ToID		= vrToID
    WHERE	z.ExecKey = vrExecKey AND z.StepID = vrStepID ;    
    
    ### PERFORMANCE: END 
    
END$$

DELIMITER ;