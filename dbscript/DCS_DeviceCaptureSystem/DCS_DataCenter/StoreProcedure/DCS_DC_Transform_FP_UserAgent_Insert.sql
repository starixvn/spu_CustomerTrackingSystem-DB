/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_FP_UserAgent_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_FP_UserAgent_Insert`(
	IN ip_UserAgentJson	LONGTEXT
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
			CALL DCS_DC_Transform_FP_UserAgent_Insert('[{"Code":"123","UserAgent":"Chrome v1","ClientType":"ClientType v1","ClientName":"ClientName v1","ClientVersion":"v1","OSName":"OSName v1","OSShortName":"OSShortName v1","OSVersion":"OSVersion v1","OSPlatform":"OSPlatform v1","Device":"Device v1","Brand":"Brand v1","Model":"Model v1"},{"Code":"223","UserAgent":"Chrome v2","ClientType":"ClientType v2","ClientName":"ClientName v2","ClientVersion":"v2","OSName":"OSName v2","OSShortName":"OSShortName v2","OSVersion":"OSVersion v2","OSPlatform":"OSPlatform v2","Device":"Device v2","Brand":"Brand v2","Model":"Model v2"}]');

	*/
    DECLARE lv_CurrentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_UserAgent;
    
	CREATE TEMPORARY TABLE Temp_UserAgent(
			Code			 			VARCHAR(100)    				NOT NULL
		,	UserAgent		 			VARCHAR(1000)    				NOT NULL
		,	ClientType 					VARCHAR(15) 					NULL
		,	ClientName 					VARCHAR(100) 					NULL
		,	ClientVersion 				VARCHAR(50) 					NULL
		,	OSName 						VARCHAR(100) 					NULL
		,	OSShortName 				VARCHAR(50) 					NULL
		,	OSVersion 					VARCHAR(50) 					NULL
		,	OSPlatform 					VARCHAR(15) 					NULL
		,	Device 						VARCHAR(50) 					NULL
		,	Brand 						VARCHAR(50) 					NULL
		,	Model 						VARCHAR(15) 					NULL
		,	IsNewRecord					TINYINT		 					DEFAULT 1
        
        ,	PRIMARY KEY (Code)
    );
    
    
    INSERT IGNORE INTO Temp_UserAgent(Code, UserAgent, ClientType, ClientName, ClientVersion, OSName, OSShortName, OSVersion, OSPlatform, Device, Brand, Model)
    SELECT	rt.Code
		,	rt.UserAgent
		,	rt.ClientType
		,	rt.ClientName
		,	rt.ClientVersion
		,	rt.OSName
		,	rt.OSShortName
		,	rt.OSVersion
		,	rt.OSPlatform
		,	rt.Device
		,	rt.Brand
		,	rt.Model
	FROM JSON_TABLE(
			ip_UserAgentJson,
			 "$[*]" COLUMNS(
						Code				VARCHAR(32) 	PATH "$.Code"
					,	UserAgent			VARCHAR(1000) 	PATH "$.UserAgent"
					,	ClientType			VARCHAR(15) 	PATH "$.ClientType"
					,	ClientName			VARCHAR(100) 	PATH "$.ClientName"
					,	ClientVersion		VARCHAR(50) 	PATH "$.ClientVersion"
					,	OSName				VARCHAR(100) 	PATH "$.OSName"
					,	OSShortName			VARCHAR(50) 	PATH "$.OSShortName"
					,	OSVersion			VARCHAR(50) 	PATH "$.OSVersion"
					,	OSPlatform			VARCHAR(15) 	PATH "$.OSPlatform"
					,	Device				VARCHAR(50) 	PATH "$.Device"
					,	Brand				VARCHAR(50) 	PATH "$.Brand"
					,	Model				VARCHAR(15) 	PATH "$.Model"
				)
		   ) AS  rt;
	
	ALTER TABLE Temp_UserAgent
	ADD INDEX IX_Temp_UserAgent_Code (Code);
	
    UPDATE Temp_UserAgent AS tmp
		INNER JOIN DCS_DataCenter.FP_UserAgent AS c ON c.Code = tmp.Code
    SET tmp.IsNewRecord = 0;
	
    INSERT IGNORE INTO DCS_DataCenter.FP_UserAgent(Code, UserAgent, ClientType, ClientName, ClientVersion, OSName, OSShortName, OSVersion, OSPlatform, Device, Brand, Model, InsertedTime)
	SELECT	tmp.Code
		,	tmp.UserAgent
		,	tmp.ClientType
		,	tmp.ClientName
		,	tmp.ClientVersion
		,	tmp.OSName
		,	tmp.OSShortName
		,	tmp.OSVersion
		,	tmp.OSPlatform
		,	tmp.Device
		,	tmp.Brand
		,	tmp.Model
        ,	lv_CurrentDate AS InsertedTime
	FROM Temp_UserAgent AS tmp
    WHERE IsNewRecord = 1;
END$$

DELIMITER ;