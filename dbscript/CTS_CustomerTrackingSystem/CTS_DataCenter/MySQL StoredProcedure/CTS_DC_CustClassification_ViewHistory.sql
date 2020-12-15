/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_ViewHistory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_ViewHistory`(IN ip_CustID BIGINT, OUT op_ErrorMessage VARCHAR(200))
    SQL SECURITY INVOKER
BEGIN
   /*
		Created:	20201214@Irena.Vo
		Task:		View History for customer category in CTS
		DB:			CTS_DataCenter
		Original:
		Revisions:
           - 20201214@Irena.Vo: Created [RedmineID: #145951]
           
		Param's Explanation (filtered by):		
			set @op_ErrorMessage = '0';
				call CTS_DataCenter.CTS_DC_CustClassification_ViewHistory(43600889, @op_ErrorMessage);
			select @op_ErrorMessage;

	*/   
		DECLARE EXIT HANDLER FOR SQLEXCEPTION 
		BEGIN         
			GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
		END;
        
		DROP TEMPORARY TABLE IF EXISTS Temp_ClassificationHistory;    
		CREATE TEMPORARY TABLE Temp_ClassificationHistory 
		(	  
				RowOrder                SMALLINT UNSIGNED 
            ,	LastModifiedDate    	DATETIME
			,   CategoryID          	SMALLINT UNSIGNED
			,   TargetCC            	TINYINT
			,   SourceTypeID        	SMALLINT UNSIGNED
			,   FromCategoryID			SMALLINT UNSIGNED
			,   ToCategoryID			SMALLINT UNSIGNED
			,   TurnOverRM          	DECIMAL(20,4)
			,   WinlossRM           	DECIMAL(20,4)
			,   Margin                  DECIMAL(20,4)
			,   BetCount            	BIGINT
			,   ActiveDays          	INT
			,   LastXDaysMargin         DECIMAL(20,4)
			,   ProbationPeriodWinloss  DECIMAL(20,4)
			,   LastModifiedBy      	INT UNSIGNED
			, 	INDEX 					IX_Temp_ClassificationHistory_RowOrder_LastModifiedDate(RowOrder, LastModifiedDate)       
		 );
  
        -- Get History List
        INSERT INTO Temp_ClassificationHistory
        (RowOrder, TargetCC, CategoryID, SourceTypeID, LastModifiedDate, FromCategoryID, ToCategoryID
        , TurnOverRM, WinlossRM, Margin, BetCount, ActiveDays, LastXDaysMargin, ProbationPeriodWinloss, LastModifiedBy)
        SELECT  @row_no := IF(@prev_val1 = his.TargetCC AND @prev_val2 = his.CategoryID, @row_no + 1, 1) AS RowOrder
				,  	@prev_val1 := his.TargetCC AS TargetCC
				,	@prev_val2 := CASE  WHEN  his.CategoryID = 151 THEN 51
										WHEN  his.CategoryID IN (72, 152) THEN 52
										WHEN  his.CategoryID IN (73, 153) THEN 53
										WHEN  his.CategoryID IN (74, 154) THEN 54 
										WHEN  his.CategoryID IN (75, 155) THEN 55
										WHEN  his.CategoryID IN (76, 156) THEN 56
										WHEN  his.CategoryID IN (77, 157) THEN 57
										WHEN  his.CategoryID IN (78, 158) THEN 58
										WHEN  his.CategoryID IN (79, 159) THEN 59
										WHEN  his.CategoryID = 80 THEN 60
										ELSE  his.CategoryID   
									END
				,  	his.SourceTypeID
                ,  	his.LastModifiedDate
				,	his.FromCategoryID	
				,	his.ToCategoryID	
				,	his.TurnOverRM  
                ,   CASE WHEN his.TurnOverRM = 0 THEN 0
						 ELSE (his.WinlossRM/ his.TurnOverRM) * 100
					END AS Margin
				,	his.WinlossRM
				,	his.BetCount 
				,	his.ActiveDays
				,	his.LastXDaysMargin
				,	his.ProbationPeriodWinloss
				,	his.LastModifiedBy   
		FROM CTS_DataCenter.CTSCustomerClassification_History AS his
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.ParentID IN (50, 200) AND his.CategoryID = cc.CategoryID,
		  (SELECT @row_no := 0) x,
		  (SELECT @prev_val1 := 0) y1,
          (SELECT @prev_val2 := 0) y2
		WHERE his.CustID = ip_CustID
		ORDER BY his.LastModifiedDate ASC;
       
        -- Only get Records in the first created
        DELETE temp
        FROM Temp_ClassificationHistory AS temp
        WHERE temp.RowOrder > 1;
    
        -- Return results
        IF EXISTS (SELECT 1 FROM CTS_DataCenter.PinCustomerCategory WHERE CustID = ip_CustID) THEN
			SELECT 1 AS IsPinCategory;
		ELSE 
            SELECT 0 AS IsPinCategory;
	    END IF;
        
      	SELECT         temp.LastModifiedDate AS CreatedTime
					,   CASE WHEN temp.CategoryID = 0 THEN '-'
                             ELSE cc1.CategoryName
						END CategoryName
                    ,   CASE WHEN temp.TargetCC = -1 THEN '-'
							 ELSE temp.TargetCC
					    END AS CustomerClass
                    ,   CASE WHEN temp.FromCategoryID IN (201, 202, 205) AND temp.ToCategoryID IN (203, 204, 206) THEN CONCAT(s.ItemName,' - ',cc2.CategoryName,' to ',cc3.CategoryName)
                             WHEN temp.FromCategoryID IN (203, 204) AND temp.ToCategoryID = 206 THEN CONCAT(s.ItemName,' - ',cc2.CategoryName,' to ',cc3.CategoryName)
                             ELSE s.ItemName
						END AS SourceTypeName
					,   temp.TurnOverRM AS TurnOver
					,   temp.WinlossRM AS Winloss
                    ,   temp.Margin
					,   temp.BetCount
					,   temp.ActiveDays
					,   temp.LastXDaysMargin
					,   temp.ProbationPeriodWinloss
					,   u.UserName AS CreatedBy
		FROM Temp_ClassificationHistory AS temp
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cc1 ON cc1.ParentID IN (50, 200) AND temp.CategoryID = cc1.CategoryID
	    LEFT JOIN CTS_DataCenter.CustomerCategory AS cc2 ON cc2.ParentID IN (50, 200) AND temp.FromCategoryID = cc2.CategoryID
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cc3 ON cc3.ParentID IN (50, 200) AND temp.ToCategoryID = cc3.CategoryID
        INNER JOIN CTS_DataCenter.StaticList AS s ON s.ListID = 4 AND temp.SourceTypeID = s.ItemID
        INNER JOIN CTS_Admin.CTSUser AS u ON temp.LastModifiedBy = u.UserID
		ORDER BY temp.LastModifiedDate DESC, temp.CategoryID DESC;
END$$

DELIMITER ;