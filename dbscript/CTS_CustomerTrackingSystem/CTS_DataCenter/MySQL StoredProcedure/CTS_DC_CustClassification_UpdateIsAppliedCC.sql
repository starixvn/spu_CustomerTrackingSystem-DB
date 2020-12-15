/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_UpdateIsAppliedCC`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_UpdateIsAppliedCC`(IN ip_ProcessedCustList JSON, OUT op_ErrorMessage VARCHAR(200))
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201214@Irena.Vo 
		Task:		Update IsAppliedCC = 1 from Customer List are updated CustomerClass in mainDB successfully (VVIP, Robot, Special CC, PA, Normal)
		DB:			CTS_DataCenter
		Original:
		Revisions:
           - 20201214@Irena.Vo: Created [RedmineID: #145951]
           
		Param's Explanation (filtered by):		
			set @op_ErrorMessage = '0';
				call CTS_DataCenter.CTS_DC_CustClassification_UpdateIsAppliedCC('[{"CustId":"43600895","ScannedTime":"2020-10-02 00:00:00"}]', @op_ErrorMessage);
			select @op_ErrorMessage;
	*/   
   
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ProcessedCustList;    
	CREATE TEMPORARY TABLE Temp_ProcessedCustList 
    (	  
			CustID              BIGINT UNSIGNED PRIMARY KEY 
        ,   ScannedTime         DATETIME
        , 	INDEX 				IX_Temp_ProcessedCustList_ScannedTime(ScannedTime)       
     );
    
    INSERT INTO Temp_ProcessedCustList(CustID, ScannedTime)
	SELECT DISTINCT 	temp.CustID
					, 	temp.ScannedTime
	FROM JSON_TABLE(ip_ProcessedCustList,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, ScannedTime		DATETIME		    PATH "$.ScannedTime"
		 )) AS temp;
     
    UPDATE CTS_DataCenter.CTSCustomerClassification_History AS his
    INNER JOIN Temp_ProcessedCustList AS temp ON temp.CustID = his.CustID
    SET his.IsAppliedCC = 1
    WHERE his.IsAppliedCC = 0 AND his.LastModifiedDate <= temp.ScannedTime;
   
END$$

DELIMITER ;