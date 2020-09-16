DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_Subscriber_Insert $$


CREATE PROCEDURE `CTS_DC_Subscriber_Insert`(
			IN  ip_SubscriberList 	JSON
		, 	OUT op_ErrorMessage 	VARCHAR(200)
)
sp: BEGIN
	/*
		Created:	20200911@Roger.Le
		Task :		Function add new subscriber
		DB:			CTS_DataCenter && CTS_Admin
		Original: 
		Revisions:
			- 20200911@Roger.Le: Created [Redmine ID: #138102]
            
		Param's Explanation:
	*/
    
    DECLARE lv_CurrentTime DATETIME DEFAULT CURRENT_TIME();
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    -- SubscriberType: 0 => Credit, 1 => Licensees
    -- IsAction: 1 => create new Subscriber, 2 => create new MappingSubscriberSite
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
		, 	IsAction 				INT DEFAULT 0
        
        , 	PRIMARY KEY	Temp_Subscriber(SiteID)
        , 	INDEX		IX_Subscriber(SiteID, SubscriberName)
        ,	INDEX		IX_Subscriber_SubscriberName(SubscriberName)
        ,	INDEX		IX_Subscriber_IsAction(IsAction) 
    );
 
	INSERT INTO Temp_Subscriber(SiteID, Site, IBCUserNamePrefix, SubscriberType, SubscriberName, RoleMapping, IsTest)
	SELECT 
			SiteID
		,	Site
        ,	IBCUserNamePrefix 
        ,	SubscriberType
        ,	SubscriberName
        ,	RoleMapping
        ,	IsTest
	FROM JSON_TABLE(ip_SubscriberList,
		 "$[*]" COLUMNS(
		  SiteID				INT	 UNSIGNED		PATH "$.SiteID" 
		, Site 					VARCHAR(50) 		PATH "$.Site"
		, IBCUserNamePrefix		VARCHAR(30)			PATH "$.IBCUserNamePrefix" 
        , SubscriberType		SMALLINT 			PATH "$.SubscriberType" 
		, SubscriberName		VARCHAR(50) 		PATH "$.SubscriberName" 
		, RoleMapping			TINYINT 			PATH "$.RoleMapping" 
		, IsTest				TINYINT 			PATH "$.IsTest" 
		 )) as tmpTable;
		

    -- check SubscriberName into Subscriber
    IF ( EXISTS (	SELECT 1 
				FROM CTS_Admin.Subscriber AS sub
					INNER JOIN Temp_Subscriber AS tmp ON tmp.SubscriberName = sub.SubscriberName)) THEN
		SET op_ErrorMessage = 'Subscriber exist';
		LEAVE sp;
	END IF;
    
	-- check SubscriberName into MappingSubscriberSite
    IF ( EXISTS (	SELECT 1 
				FROM CTS_DataCenter.MappingSubscriberSite AS map
					INNER JOIN Temp_Subscriber AS tmp ON tmp.SiteID = map.SiteID AND tmp.SubscriberName = map.SubscriberName
                    WHERE map.SubscriberStatus <> -1)) THEN
		SET op_ErrorMessage = 'Mapping subscriber exist';
		LEAVE sp;
	END IF;
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    -- validate SubscriberGroup
    #UPDATE Temp_Subscriber AS tmp
		#INNER JOIN CTS_DataCenter.SubscriberGroup AS sub ON tmp.SubscriberGroup = sub.SubscriberGroupID
    #SET     tmp.SubscriberGroup = sub.SubscriberGroupID;
    
    -- Update SubscriberGroup
    UPDATE Temp_Subscriber
    SET SubscriberGroup =  CASE
							WHEN SubscriberType =  0 THEN 1
                            WHEN SubscriberType =  1 THEN 2
                        END;
   
    -- Create new subscriber
    UPDATE 	Temp_Subscriber AS tmp
	LEFT JOIN	CTS_Admin.Subscriber AS sub 
		ON  tmp.SubscriberName = sub.SubscriberName
	SET	tmp.IsAction = 2
    WHERE sub.SubscriberName IS NULL;
            
    INSERT INTO CTS_Admin.Subscriber(SubscriberName, SubscriberPrefix, SubscriberType, SubscriberStatus, CreatedDate, CreatedBy, IsTest)
    SELECT 
		tmp.SubscriberName
        , tmp.IBCUserNamePrefix
        , tmp.SubscriberType
        , 1
        , lv_CurrentTime
        , ip_UserID
        , tmp.IsTest
	FROM Temp_Subscriber AS tmp
	WHERE tmp.IsAction = 2;
    
    -- Create mapping
    UPDATE 	Temp_Subscriber AS tmp
	INNER JOIN	CTS_Admin.Subscriber AS sub 
		ON  tmp.SubscriberName = sub.SubscriberName
	SET	tmp.SubscriberID = sub.SubscriberID;
            
    UPDATE 	Temp_Subscriber AS tmp
	LEFT JOIN	CTS_DataCenter.MappingSubscriberSite AS map 
		ON tmp.SiteID = map.SiteID 
			AND tmp.SubscriberName = map.SubscriberName
	SET	tmp.IsAction = 1
    WHERE map.SiteID IS NULL 
			AND map.SubscriberName IS NULL;
            
    INSERT INTO CTS_DataCenter.MappingSubscriberSite(SubscriberID, SubscriberName, RoleMapping, SubscriberType, SubscriberStatus, SubscriberGroupID, SiteID, SiteName)
    SELECT
			tmp.SubscriberID
        ,	tmp.SubscriberName
        ,	tmp.RoleMapping
        ,	tmp.SubscriberType
        ,	1
        ,	tmp.SubscriberGroup
        ,	tmp.SiteID
        ,	tmp.Site
    FROM Temp_Subscriber AS tmp
    WHERE tmp.IsAction = 1;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Subscriber;
    
END$$
DELIMITER ;