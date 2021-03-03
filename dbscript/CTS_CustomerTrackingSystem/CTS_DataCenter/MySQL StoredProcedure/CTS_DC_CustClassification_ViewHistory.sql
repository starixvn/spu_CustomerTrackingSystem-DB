/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_ViewHistory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_ViewHistory`(IN ip_CustID BIGINT)
    SQL SECURITY INVOKER
BEGIN
  /*
		Created:	20201214@Irena.Vo
		Task:		View History for customer category in CTS
		DB:			CTS_DataCenter
		Original:
		Revisions:
            - 20201214-20210105@Irena.Vo: Created. Update logic SP [RedmineID: #145951]
			- 20210226@Irena.Vo: Get TaggingType flag for log [RedmineID: #150454]
           
		Param's Explanation (filtered by):		
			call CTS_DataCenter.CTS_DC_CustClassification_ViewHistory(43600889);
	*/   
       SELECT        temp.ID
					,	temp.LastModifiedDate AS CreatedTime
					,   CASE WHEN temp.CategoryID IS NULL THEN '-'
                             ELSE cc1.CategoryName
						END CategoryName
                    ,   CASE WHEN temp.TargetCC IN (-1, -99) THEN '-' -- -1: Remove, -99: No mapping CC
							 ELSE temp.TargetCC
					    END AS CustomerClass
					,	temp.CategoryID
                    ,   CASE WHEN temp.FromCategoryID IN (201, 202, 205) AND temp.ToCategoryID IN (203, 204, 206) THEN CONCAT(s.ItemName,' - ',cc2.CategoryName,' to ',cc3.CategoryName)
                             WHEN temp.FromCategoryID IN (203, 204) AND temp.ToCategoryID = 206 THEN CONCAT(s.ItemName,' - ',cc2.CategoryName,' to ',cc3.CategoryName)
                             ELSE s.ItemNameDisplay
						END AS SourceTypeName
					, 	s.ItemID AS SourceTypeID
                    ,   CASE WHEN tag.CategoryID IS NULL THEN '' -- no display
							 ELSE CASE WHEN temp.TaggingType = 0 THEN 'Yes'-- 0: display Yes
									   ELSE 'No'-- 1: display No
								  END
						END AS TaggingType
					,   temp.TurnOverRM AS TurnOver
                    ,   temp.WinlossRM AS WinLoss
                    ,	 CASE WHEN temp.TurnOverRM = 0 THEN 0
							  ELSE (temp.WinlossRM/ temp.TurnOverRM) * 100
					     END AS Margin
					,   temp.BetCount
					,   temp.ActiveDays 
					,   temp.LastXDaysMargin
					,   temp.ProbationPeriodWinloss
					,   u.UserName AS CreatedBy
		FROM CTS_DataCenter.CTSCustomerClassification_History AS temp
        LEFT JOIN CTS_DataCenter.TaggingToCategory AS tag ON tag.CategoryID = temp.CategoryID
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cc1 ON temp.CategoryID = cc1.CategoryID
	    LEFT JOIN CTS_DataCenter.CustomerCategory AS cc2 ON temp.FromCategoryID = cc2.CategoryID
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cc3 ON temp.ToCategoryID = cc3.CategoryID
        INNER JOIN CTS_DataCenter.StaticList AS s ON s.ListID = 4 AND temp.SourceTypeID = s.ItemID
        INNER JOIN CTS_Admin.CTSUser AS u ON temp.LastModifiedBy = u.UserID
        WHERE temp.CustID = ip_CustID AND temp.IsDataChanged = 1
		ORDER BY temp.ID DESC;
END$$

DELIMITER ;