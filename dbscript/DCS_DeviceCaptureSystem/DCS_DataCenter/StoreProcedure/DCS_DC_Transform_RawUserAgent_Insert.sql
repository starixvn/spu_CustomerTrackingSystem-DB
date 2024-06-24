/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_RawUserAgent_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_RawUserAgent_Insert`(
		IN ip_RawUserAgentJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20231108@Jonathan.Doan
		Task : Insert into DCS_DataCenter.RawUserAgent
		DB: DCS_DataCenter
		Original:

		Revisions:
			- 20231108@Jonathan.Doan: Created [Redmine ID: #196570]
			- 20240621@Jonathan.Doan: Change data flow v5.1 [Redmine ID: #206403]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Transform_RawUserAgent_Insert ('[{"RawUserAgent":"FireFox1","RawUserAgentCode":"Code1","ClientType":"ClientType1","ClientName":"ClientName1","ClientVersion":"ClientVersion1","OSName":"OSName1","OSShortName":"OSShortName1","OSVersion":"OSVersion1","OSPlatform":"OSPlatform1","Device":"Device1","Brand":"Brand1","Model":"Model1"},{"RawUserAgent":"FireFox2","RawUserAgentCode":"Code2","ClientType":"ClientType2","ClientName":"ClientName2","ClientVersion":"ClientVersion2","OSName":"OSName2","OSShortName":"OSShortName2","OSVersion":"OSVersion2","OSPlatform":"OSPlatform2","Device":"Device2","Brand":"Brand2","Model":"Model2"}]');

	*/
    DECLARE lv_CurrentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_RawUserAgent;
    
	CREATE TEMPORARY TABLE Temp_RawUserAgent(
			ID				 			INT UNSIGNED AUTO_INCREMENT		NOT NULL
		,	RawUserAgent	 			VARCHAR(1000)    				NULL
		,	RawUserAgentCode 			VARCHAR(100)    				NULL
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
		,	IsNewRawUserAgent			TINYINT		 					DEFAULT 1
        
        ,	PRIMARY KEY (ID)
    );
    
    
    INSERT IGNORE INTO Temp_RawUserAgent(RawUserAgent, RawUserAgentCode, ClientType, ClientName, ClientVersion, OSName, OSShortName, OSVersion, OSPlatform, Device, Brand, Model)
    SELECT	rt.RawUserAgent
		,	rt.RawUserAgentCode
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
			ip_RawUserAgentJson,
			 "$[*]" COLUMNS(
						RawUserAgent		VARCHAR(1000) 	PATH "$.RawUserAgent"
					,	RawUserAgentCode	VARCHAR(100) 	PATH "$.RawUserAgentCode"
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
	
	ALTER TABLE Temp_RawUserAgent
	ADD INDEX IX_Temp_RawUserAgent_RawUserAgentCode (RawUserAgentCode);
	
    UPDATE Temp_RawUserAgent AS tmp
		INNER JOIN DCS_DataCenter.RawUserAgent AS c ON c.RawUserAgentCode = tmp.RawUserAgentCode
    SET tmp.IsNewRawUserAgent = 0;
	
    INSERT IGNORE INTO DCS_DataCenter.RawUserAgent(RawUserAgentCode, RawUserAgent, ClientType, ClientName, ClientVersion, OSName, OSShortName, OSVersion, OSPlatform, Device, Brand, Model, CreatedDate)
	SELECT	DISTINCT
			tmp.RawUserAgentCode
		,	tmp.RawUserAgent
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
        ,	lv_CurrentDate AS CreatedDate
	FROM Temp_RawUserAgent AS tmp
    WHERE IsNewRawUserAgent = 1;
END$$

DELIMITER ;
