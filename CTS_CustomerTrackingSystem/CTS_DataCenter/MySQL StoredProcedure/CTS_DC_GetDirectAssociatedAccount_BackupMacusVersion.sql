DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DC_GetDirectAssociatedAccount_Macus$$
CREATE DEFINER=`fps`@`%` PROCEDURE CTS_DC_GetDirectAssociatedAccount_Macus (IN ip_custIDs JSON)
BEGIN
	/*
		Created:	20191226@Marcus
		Task:		Get Direct Assocation with account
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):                
	*/
	         
       /* Parse Json */
       DECLARE json_items BIGINT UNSIGNED DEFAULT 0;
       DECLARE _index     BIGINT UNSIGNED DEFAULT 0;
       
       SELECT JSON_LENGTH(ip_custIDs) INTO  json_items;
       DROP TEMPORARY TABLE IF EXISTS jsonTemporary;
       CREATE TEMPORARY TABLE IF NOT EXISTS jsonTemporary
        (CustID BIGINT UNSIGNED NOT NULL, UserName VARCHAR(50));
        
       WHILE _index < json_items DO
			INSERT INTO jsonTemporary (CustID, UserName)
			VALUES (JSON_EXTRACT(ip_custIDs, CONCAT('$[',_index,'].CustId')), REPLACE(JSON_EXTRACT(ip_custIDs, CONCAT('$[',_index,'].LoginId')),'"',''));
			SET _index := _index + 1;
        END WHILE;
       
       
        DROP TEMPORARY TABLE IF EXISTS Temp_Association;
		CREATE TEMPORARY TABLE Temp_Association 
		(	Tag						INT	
			, CTSCustID				BIGINT UNSIGNED
            , SubscriberID			INT UNSIGNED
            , LoginId				VARCHAR(50) 
			, CustID                INT UNSIGNED
           	, Subscriber			VARCHAR(50)
           
		); 
         
        SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
        
        INSERT INTO Temp_Association(Tag, CTSCustID, SubscriberID, LoginId, CustID, Subscriber)
		SELECT 	0
				, cus.CTSCustID 
				, sub.SubscriberID
                , tmpTable.UserName
				, cus.CustID
				, sub.SubscriberName AS 'Subscriber'		
		FROM jsonTemporary AS tmpTable
		INNER JOIN	CTSCustomer AS cus ON tmpTable.CustID = cus.CustID 
		INNER JOIN  CTS_Admin.Subscriber AS sub ON cus.SubscriberID= sub.SubscriberID;
       
        
        INSERT INTO Temp_Association(Tag, CTSCustID, SubscriberID,	LoginId, CustID, Subscriber)
		SELECT 	0
				, cus.CTSCustID 
				, sub.SubscriberID
                , tmpTable.UserName
				, cus.CustID
				, sub.SubscriberName AS 'Subscriber'		
		FROM jsonTemporary AS tmpTable
		INNER JOIN	CTSCustomer AS cus ON tmpTable.UserName = cus.UserName 
		INNER JOIN  CTS_Admin.Subscriber AS sub ON cus.SubscriberID= sub.SubscriberID
        WHERE  tmpTable.CustID = 0;          
        
        INSERT INTO Temp_Association(Tag, CTSCustID, SubscriberID, LoginId, CustID, Subscriber)
		SELECT 	0
				, cus.CTSCustID 
				, sub.SubscriberID
                , tmpTable.UserName	
				, cus.CustID
				, sub.SubscriberName AS 'Subscriber'		
		FROM jsonTemporary AS tmpTable
		INNER JOIN	CTSCustomer AS cus ON tmpTable.UserName = cus.UserName2
		INNER JOIN  CTS_Admin.Subscriber AS sub ON cus.SubscriberID= sub.SubscriberID
        WHERE  tmpTable.CustID = 0 AND cus.UserName IS NULL ;   
        
		 /*Update Tag: 1: BlackFlaged, 2: Flagged*/
		UPDATE Temp_Association as ass
		SET ass.Tag = CASE WHEN IFNULL(	(SELECT 	1
										 FROM		CTS_DataCenter.CustEvidence AS ced
										 INNER JOIN	CTS_DataCenter.Evidence	AS  evd
													ON ced.EvidenceID = evd.EvidenceID
										 WHERE 	ced.SubscriberID		= ass.SubscriberID
													AND ced.CTSCustID		= ass.CTSCustID                                
													AND evd.EvidenceCode	= 100
													AND evd.EvidenceGroupID	= 99
													AND ced.IsRetracted		= 0
													AND ced.Level = 1
										 LIMIT 1),0) = 0 THEN 
											IFNULL(	(  SELECT  	2
													FROM		CTS_DataCenter.CustEvidence AS ced
													INNER JOIN	CTS_DataCenter.Evidence	AS  evd
																ON ced.EvidenceID = evd.EvidenceID
													WHERE 	ced.SubscriberID		= ass.SubscriberID
																AND ced.CTSCustID	= ass.CTSCustID                          
																AND ced.IsRetracted	= 0
																AND ced.Level = 1
													LIMIT 1),0)
						ELSE
											IFNULL(	(SELECT 	1
												 FROM		CTS_DataCenter.CustEvidence AS ced
												 INNER JOIN	CTS_DataCenter.Evidence	AS  evd
															ON ced.EvidenceID = evd.EvidenceID
												 WHERE 	ced.SubscriberID		= ass.SubscriberID
														AND ced.CTSCustID		= ass.CTSCustID                                
														AND evd.EvidenceCode	= 100
														AND evd.EvidenceGroupID	= 99
														AND ced.IsRetracted		= 0
														AND ced.Level = 1
												 LIMIT 1),0)
						END;
		
	   	/*Return result*/	
		SELECT ass.Tag
			   , ass.CTSCustID
			   , ass.Subscriber
               , ass.LoginId
			   , ass. CustID
		FROM Temp_Association AS ass;
		   
	DROP TEMPORARY TABLE Temp_Association;     
	DROP TEMPORARY TABLE jsonTemporary;
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;