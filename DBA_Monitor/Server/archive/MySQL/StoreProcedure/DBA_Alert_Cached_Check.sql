/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Alert_Cached_Check`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Alert_Cached_Check`(
		IN ip_ServerID 		INT
    ,	IN ip_Type 			VARCHAR(50)
    ,	IN ip_ThreadID 		BIGINT
    ,	IN ip_IsAlert		BIT
)
    SQL SECURITY INVOKER
sp: BEGIN
	DECLARE lv_Cached INT;
    
	IF ip_IsAlert = 0 THEN
		DELETE 
		FROM HealthCheck_Alert_Cached
		WHERE ServerID = ip_ServerID
			AND HealthCheckType = ip_Type;
		SELECT  0 AS IsCached;
        LEAVE sp;
	END IF;
    
    SELECT ID
    INTO lv_Cached
    FROM HealthCheck_Alert_Cached
		WHERE ServerID = ip_ServerID
			AND HealthCheckType = ip_Type
            AND ThreadID = ip_ThreadID
	LIMIT 1;
    
    IF lv_Cached IS NOT NULL THEN
		SELECT  1 AS IsCached;
        LEAVE sp;
    END IF;
    
    SELECT 0 AS IsCached;
    INSERT INTO HealthCheck_Alert_Cached(ServerID,HealthCheckType,ThreadID)
    VALUES(ip_ServerID, ip_Type,ip_ThreadID);
END$$
DELIMITER ;
