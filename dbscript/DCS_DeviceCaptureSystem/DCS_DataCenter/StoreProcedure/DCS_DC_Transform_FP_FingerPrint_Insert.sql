/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_FP_FingerPrint_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_FP_FingerPrint_Insert`(
	IN ip_FingerPrintJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20240729@Jonathan.Doan
	    Task : Change Data Flow Ver. 6
		DB: DCS_DataCenter
		Original:

		Revisions:
			- 20240730@Jonathan.Doan: Created [Redmine ID: #206403]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Transform_FP_FingerPrint_Insert('[{"FingerPrintCode":"123","FingerPrintAttribute":{"Name":"ABC"},"FingerPrintExtraCode":"123","FingerPrintExtraAttribute":{"Name":"Extra"}},{"FingerPrintCode":"222","FingerPrintAttribute":{"Name":"ABC2"},"FingerPrintExtraCode":"2222","FingerPrintExtraAttribute":{"Name":"Extra2"}}]');

	*/
    DECLARE lv_CurrentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Input;
	DROP TEMPORARY TABLE IF EXISTS Temp_InputFingerPrint;
	DROP TEMPORARY TABLE IF EXISTS Temp_InputFingerPrintExtra;
        
	CREATE TEMPORARY TABLE Temp_Input(
			ID							INT UNSIGNED AUTO_INCREMENT		PRIMARY KEY
        ,	FingerPrintCode				VARCHAR(32) 					NOT NULL
        ,	FingerPrintAttribute		JSON
        ,	FingerPrintExtraCode		VARCHAR(32) 					NOT NULL
        ,	FingerPrintExtraAttribute	JSON
    );
        
	CREATE TEMPORARY TABLE Temp_InputFingerPrint(
        	FingerPrintCode				VARCHAR(32) NOT NULL			PRIMARY KEY
        ,	FingerPrintAttribute		JSON
        
		,	IsNewRecord					TINYINT		 					DEFAULT 1
    );
        
	CREATE TEMPORARY TABLE Temp_InputFingerPrintExtra(
        	FingerPrintExtraCode		VARCHAR(32) NOT NULL			PRIMARY KEY
        ,	FingerPrintExtraAttribute	JSON
        
		,	IsNewRecord					TINYINT		 					DEFAULT 1
    );
    
    INSERT IGNORE INTO Temp_Input(FingerPrintCode, FingerPrintAttribute, FingerPrintExtraCode, FingerPrintExtraAttribute)
    SELECT	input.FingerPrintCode
		,	input.FingerPrintAttribute
		,	input.FingerPrintExtraCode
		,	input.FingerPrintExtraAttribute
	FROM JSON_TABLE(
			ip_FingerPrintJson,
			 "$[*]" COLUMNS(
						FingerPrintCode					VARCHAR(32) 	PATH "$.FingerPrintCode"
					,	FingerPrintAttribute			JSON 			PATH "$.FingerPrintAttribute"
					,	FingerPrintExtraCode			VARCHAR(32) 	PATH "$.FingerPrintExtraCode"
					,	FingerPrintExtraAttribute		JSON 			PATH "$.FingerPrintExtraAttribute"
				)
		   ) AS input;

    INSERT IGNORE INTO Temp_InputFingerPrint(FingerPrintCode, FingerPrintAttribute)
    SELECT 	FingerPrintCode
		,	FingerPrintAttribute
    FROM Temp_Input
    WHERE IFNULL(FingerPrintCode, '') <> '';

    INSERT IGNORE INTO Temp_InputFingerPrintExtra(FingerPrintExtraCode, FingerPrintExtraAttribute)
    SELECT 	FingerPrintExtraCode
		,	FingerPrintExtraAttribute
    FROM Temp_Input
    WHERE IFNULL(FingerPrintExtraCode, '') <> '';
    
    /* ==== Insert Fingerprint ==== */
    UPDATE Temp_InputFingerPrint AS tmp
		INNER JOIN DCS_DataCenter.FP_FingerPrint AS fp ON fp.Code = tmp.FingerPrintCode
    SET tmp.IsNewRecord = 0;
    
	INSERT IGNORE INTO DCS_DataCenter.FP_FingerPrint(Code, Attribute, InsertedTime)
	SELECT	FingerPrintCode
		,	FingerPrintAttribute
		,	lv_CurrentDate AS InsertedTime
	FROM Temp_InputFingerPrint
    WHERE IsNewRecord = 1;
    
    /* ==== Insert FingerprintExtra ==== */
    UPDATE Temp_InputFingerPrintExtra AS tmp
		INNER JOIN DCS_DataCenter.FP_FingerPrintExtra AS fp ON fp.Code = tmp.FingerPrintExtraCode
    SET tmp.IsNewRecord = 0;
    
	INSERT IGNORE INTO DCS_DataCenter.FP_FingerPrintExtra(Code, Attribute, InsertedTime)
	SELECT	FingerPrintExtraCode
		,	FingerPrintExtraAttribute
		,	lv_CurrentDate AS InsertedTime
	FROM Temp_InputFingerPrintExtra
    WHERE IsNewRecord = 1;
END$$

DELIMITER ;