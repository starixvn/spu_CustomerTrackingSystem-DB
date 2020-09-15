DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_Subscriber_Update $$


CREATE PROCEDURE `CTS_DC_Subscriber_Update`(
    	IN ip_SubscriberList 	JSON
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
BEGIN
/*
		Created:	20200915@Roger.Le
		Task :		Function add new subscriber
		DB:			CTS_DataCenter && CTS_Admin
		Original: 
		Revisions:
			- 20200914@Roger.Le: Created [Redmine ID: #138102]
            
		Param's Explanation:
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT CURRENT_DATE();
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	-- SubscriberType: 0 => Credit, 1 => Licensees
	DROP TEMPORARY TABLE IF EXISTS Temp_Subscriber;
	CREATE TEMPORARY TABLE Temp_Subscriber( 	 
			SiteID 					INT
		, 	Site 					VARCHAR(50)
		,	SubscriberName 			VARCHAR(50)
		, 	IBCUserNamePrefix 		VARCHAR(30)
		, 	SubscriberGroup 		SMALLINT
		, 	RoleMapping 			TINYINT
		, 	SubscriberID 			INT
		, 	SubscriberType			TINYINT 
		, 	IsTest					TINYINT 
        
        , 	PRIMARY KEY	Temp_Subscriber(SiteID)
        , 	INDEX		IX_Subscriber(SiteID, SubscriberID)
        , 	INDEX		IX_Subscriber_SubscriberID(SubscriberID)
    );
    
    INSERT INTO Temp_Subscriber(SiteID, Site, IBCUserNamePrefix, SubscriberGroup, SubscriberName, RoleMapping, IsAction)
	SELECT 
			SiteID
		,	Site
        ,	IBCUserNamePrefix 
        ,	SubscriberGroup
        ,	SubscriberName
        ,	RoleMapping
        ,	IsTest
	FROM JSON_TABLE(ip_SubscriberList,
		 "$[*]" COLUMNS(
		  SiteID				INT	 UNSIGNED		PATH "$.SiteID" 
		, Site 					VARCHAR(50) 		PATH "$.Site"
		, IBCUserNamePrefix		VARCHAR(30)			PATH "$.IBCUserNamePrefix" 
        , SubscriberGroup		SMALLINT 			PATH "$.SubscriberGroup" 
		, SubscriberName		VARCHAR(50) 		PATH "$.SubscriberName" 
		, RoleMapping			TINYINT 			PATH "$.RoleMapping" 
		, IsTest				TINYINT 			PATH "$.IsTest" 
		 )) as tmpTable;
     
     -- Update SubscriberGroup
    UPDATE Temp_Subscriber
    SET SubscriberGroup =  CASE
							WHEN SubscriberType =  0 THEN 1
                            WHEN SubscriberType =  1 THEN 2
                        END;
     -- Update subscriber
	UPDATE CTS_Admin.Subscriber AS sub
		INNER JOIN Temp_Subscriber AS tmp ON tmp.SubscriberID = sub.SubscriberID
    SET    	sub.SubscriberPrefix 	= 	tmp.IBCUserNamePrefix,
			sub.SubscriberType 		= 	tmp.SubscriberType,
			sub.IsTest 				= 	tmp.IsTest
   WHERE 	sub.SubscriberStatus <> -1;
     
     -- Update subscriber mapping
    UPDATE CTS_DataCenter.MappingSubscriberSite AS map
		INNER JOIN Temp_Subscriber AS tmp ON tmp.SiteID = map.SiteID 
											AND tmp.SubscriberID = map.SubscriberID
    SET     map.RoleMapping 		= 	tmp.RoleMapping,
			map.SubscriberType 		= 	tmp.SubscriberType,
			map.SubscriberGroupID 	= 	tmp.SubscriberGroup,
			map.SiteName 			= 	tmp.SiteName
    WHERE 	map.SubscriberStatus <> -1;

    DROP TEMPORARY TABLE IF EXISTS Temp_Subscriber;
            
END$$
DELIMITER ;