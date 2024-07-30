/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_DeviceEvolution_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_DeviceEvolution_Insert`(
    IN ip_DeviceEvolutionJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20240729@Jonathan.Doan
	    Task : Change Data Flow Ver. 6
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20240729@Jonathan.Doan: Created [RedmineID: #206403]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Transform_DeviceEvolution_Insert('[{"ID":2,"EvolveByID":1,"DeviceID":1}]');
	*/
    
    
    
END$$

DELIMITER ;