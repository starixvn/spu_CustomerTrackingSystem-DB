/*<info serverAlias="DBVR2-bodb_VR2Model" databaseType="1"></info>*/
/*
		Created:	20240809@Victoria.Le
		Task:		Initial Data - Backup Data
		DB:			bodb_VR2Model

		Param's Expanation:
		
		Example:
			
		Revisions: 
			- 20240809@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/
	DROP TABLE IF EXISTS #tmpRawData;
	CREATE TABLE #tmpRawData (CategoryID INT,OldCategoryID INT);
	
	INSERT INTO #tmpRawData (CategoryID, OldCategoryID)
	VALUES 	(40100,201),
			(40300,202),
			(40500,203),
			(40600,204),
			(40200,205),
			(40400,206),
			(40700,1001),
			(40701,1002);
			
	UPDATE cc WITH(ROWLOCK, UPDLOCK)
	SET 	cc.CategoryID_new 		= CASE WHEN temp1.CategoryID IS NOT NULL THEN temp1.CategoryID ELSE cc.CategoryID END
		,	cc.CurrentCategory_new 	= CASE WHEN temp2.CategoryID IS NOT NULL THEN temp2.CategoryID ELSE cc.CurrentCategory END
		,	cc.CategoryID_bk	 	= cc.CategoryID
		,	cc.CurrentCategory_bk 	= cc.CurrentCategory
	FROM dbo.CustomerClassification_Rule AS cc
		LEFT JOIN #tmpRawData AS temp1 ON temp1.OldCategoryID = cc.CategoryID
		LEFT JOIN #tmpRawData AS temp2 ON temp2.OldCategoryID = cc.CurrentCategory;
		
	UPDATE cc WITH(ROWLOCK, UPDLOCK)
	SET 	cc.CategoryID_new 		= CASE WHEN temp1.CategoryID IS NOT NULL THEN temp1.CategoryID ELSE cc.CategoryID END
		,	cc.CurrentCategory_new 	= CASE WHEN temp2.CategoryID IS NOT NULL THEN temp2.CategoryID ELSE cc.CurrentCategory END
		,	cc.CategoryID_bk	 	= cc.CategoryID
		,	cc.CurrentCategory_bk 	= cc.CurrentCategory
	FROM dbo.CustomerClassification_BySport_Rule AS cc
		LEFT JOIN #tmpRawData AS temp1 ON temp1.OldCategoryID = cc.CategoryID
		LEFT JOIN #tmpRawData AS temp2 ON temp2.OldCategoryID = cc.CurrentCategory;
	
	UPDATE cc WITH(ROWLOCK, UPDLOCK)
	SET 	cc.CategoryID_new 			= CASE WHEN temp1.CategoryID IS NOT NULL THEN temp1.CategoryID ELSE cc.CategoryID END
		,	cc.CurrentCategoryId_new 	= CASE WHEN temp2.CategoryID IS NOT NULL THEN temp2.CategoryID ELSE cc.CurrentCategoryId END
		,	cc.CategoryID_bk	 		= cc.CategoryID
		,	cc.CurrentCategoryId_bk		= cc.CurrentCategoryId
	FROM dbo.CustomerClassification AS cc
		LEFT JOIN #tmpRawData AS temp1 ON temp1.OldCategoryID = cc.CategoryID
		LEFT JOIN #tmpRawData AS temp2 ON temp2.OldCategoryID = cc.CurrentCategoryId;
		
	UPDATE cc WITH(ROWLOCK, UPDLOCK)
	SET 	cc.CategoryID_new 			= CASE WHEN temp1.CategoryID IS NOT NULL THEN temp1.CategoryID ELSE cc.CategoryID END
		,	cc.CurrentCategoryId_new 	= CASE WHEN temp2.CategoryID IS NOT NULL THEN temp2.CategoryID ELSE cc.CurrentCategoryId END
		,	cc.CategoryID_bk	 		= cc.CategoryID
		,	cc.CurrentCategoryId_bk 	= cc.CurrentCategoryId
	FROM dbo.CustomerClassification_bysport AS cc
		LEFT JOIN #tmpRawData AS temp1 ON temp1.OldCategoryID = cc.CategoryID
		LEFT JOIN #tmpRawData AS temp2 ON temp2.OldCategoryID = cc.CurrentCategoryId;
