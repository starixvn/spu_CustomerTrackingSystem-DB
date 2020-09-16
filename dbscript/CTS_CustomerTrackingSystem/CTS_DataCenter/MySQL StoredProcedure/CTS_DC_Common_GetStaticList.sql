DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Common_GetStaticList$$
CREATE PROCEDURE CTS_DataCenter.CTS_DC_Common_GetStaticList(IN ip_ListID INT, IN ip_Status BOOL)
BEGIN
/*
		Created:	20191219@CaseyHuynh	
		Task:		CTS_DC_GetStaticList
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
                
	*/    
   SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
   
   SELECT	sl.ListID
			, sl.ItemID
			, sl.ListName 
            , sl.ListNameDisplay
            , sl.ItemName
            , sl.ItemNameDisplay
            , sl.PriorityOrder
            , sl.Status
            , sl.Description
            , sl.CreatedDate
	FROM	CTS_DataCenter.StaticList	AS sl
    WHERE	sl.ListID = ip_ListID
			AND sl.Status = ip_Status;
	
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$
DELIMITER ;
