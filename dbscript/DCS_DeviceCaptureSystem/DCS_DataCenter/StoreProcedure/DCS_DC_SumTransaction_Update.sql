/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_SumTransaction_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_SumTransaction_Update`(
		IN ip_MaxTransID	BIGINT UNSIGNED
	,   IN ip_SumJson		JSON  
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20210930@Casey.Huynh
	    Task : Update TransSum
	    DB: DCS_DataCenter (Master)
	    Original:

	    Revisions:		    
        	-	20210930@Casey.Huynh: Created [Redmine ID: 161528]
            
	    Param's Explanation (filtered by):
        
        Example: CALL DCS_DC_SumTransaction_Update(70001,'[{"TransDate":"2021-09-28", "SubscriberID":4, "ValidTotal":5000,"ValidNoDevice":500
        , "ValidDeviceStatusNew":500, "ValidDeviceStatusOld":3000, "ValidDeviceStatusRecover":1000, "ValidBrowserless":1500}]');
		SELECT * FROM SumTransaction;
    */
    DROP TEMPORARY TABLE IF EXISTS Temp_SumTransaction;
    CREATE TEMPORARY TABLE Temp_SumTransaction(
			TransDate					DATETIME NOT NULL
		,	SubscriberID				INT NOT NULL
		,	ValidTotal					INT UNSIGNED
		,	ValidNoDevice				INT UNSIGNED
		,	ValidDeviceStatusNew		INT UNSIGNED
		,	ValidDeviceStatusOld		INT UNSIGNED
		,	ValidDeviceStatusRecover	INT UNSIGNED
		,	ValidBrowserless			INT UNSIGNED
		
		,	PRIMARY KEY PK_SumTransaction(TransDate, SubscriberId)
	) ENGINE=InnoDB;
    
    INSERT IGNORE INTO Temp_SumTransaction(TransDate, SubscriberID, ValidTotal, ValidNoDevice
    , ValidDeviceStatusNew, ValidDeviceStatusOld, ValidDeviceStatusRecover, ValidBrowserless)
	SELECT 	js.TransDate
		,	js.SubscriberID
        ,	js.ValidTotal
        ,	js.ValidNoDevice
        ,	js.ValidDeviceStatusNew
        ,	js.ValidDeviceStatusOld
        ,	js.ValidDeviceStatusRecover
        ,	js.ValidBrowserless
		FROM JSON_TABLE(ip_SumJson,
			"$[*]" COLUMNS(
				TransDate					DATETIME PATH "$.TransDate"
            ,   SubscriberID				INT UNSIGNED PATH "$.SubscriberID" 
			,	ValidTotal					INT UNSIGNED PATH "$.ValidTotal" 
            ,	ValidNoDevice				INT UNSIGNED PATH "$.ValidNoDevice" 
            ,	ValidDeviceStatusNew		INT UNSIGNED PATH "$.ValidDeviceStatusNew" 
            ,	ValidDeviceStatusOld		INT UNSIGNED PATH "$.ValidDeviceStatusOld" 
            ,	ValidDeviceStatusRecover	INT UNSIGNED PATH "$.ValidDeviceStatusRecover" 
            ,	ValidBrowserless			INT UNSIGNED PATH "$.ValidBrowserless"
			)
		) AS js ;
        
        INSERT IGNORE INTO SumTransaction(TransDate, SubscriberID, ValidTotal, ValidNoDevice
			, ValidDeviceStatusNew, ValidDeviceStatusOld, ValidDeviceStatusRecover, ValidBrowserless, LastTransID)
        SELECT	tmpSt.TransDate
			,	tmpSt.SubscriberID
            ,	tmpSt.ValidTotal
            ,	tmpSt.ValidNoDevice
			,	tmpSt.ValidDeviceStatusNew
            ,	tmpSt.ValidDeviceStatusOld
            ,	tmpSt.ValidDeviceStatusRecover
            ,	tmpSt.ValidBrowserless
            ,	ip_MaxTransID AS LastTransID
        FROM Temp_SumTransaction AS tmpSt;
        
        UPDATE SumTransaction AS st
			INNER JOIN Temp_SumTransaction AS tmpSt ON st.TransDate = tmpSt.TransDate 
				AND st.SubscriberID = tmpSt.SubscriberID AND st.LastTransID < ip_MaxTransID
		SET		st.ValidTotal = st.ValidTotal + st.ValidTotal
			,	st.ValidNoDevice = st.ValidNoDevice + st.ValidNoDevice
            ,	st.ValidDeviceStatusNew = st.ValidDeviceStatusNew + st.ValidDeviceStatusNew
            ,	st.ValidDeviceStatusOld = st.ValidDeviceStatusOld + st.ValidDeviceStatusOld
            ,	st.ValidDeviceStatusRecover = st.ValidDeviceStatusRecover + st.ValidDeviceStatusRecover
            ,	st.ValidBrowserless = st.ValidBrowserless + st.ValidBrowserless
            ,	st.LastTransID = ip_MaxTransID;
            
		/*Update System Setting*/
        UPDATE SystemSetting AS s
        SET	VValue = ip_MaxTransID
		,	UpdatedTime = CURRENT_TIME()
        WHERE s.ID = 11;
    
END$$
DELIMITER ;
