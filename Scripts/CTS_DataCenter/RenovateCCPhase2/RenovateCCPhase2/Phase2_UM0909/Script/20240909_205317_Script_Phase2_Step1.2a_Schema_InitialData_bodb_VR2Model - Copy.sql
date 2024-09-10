/*<info serverAlias="DBVR2-bodb_VR2Model" databaseType="1"></info>*/
/*
		Created:	20240910@Jonas.Huynh
		Task:		Initial Data - Backup Data
		DB:			bodb_VR2Model

		Param's Expanation:
		
		Example:
			
		Revisions: 
			- 20240910@Jonas.Huynh:		Initial Writing [Redmine ID: #205317]
*/
	USE bodb_VR2Model;

	DECLARE @GENERAL_LASTSCANNEDROW		TINYINT = 1;
	DECLARE @BYSPORT_LASTSCANNEDROW		TINYINT = 2;

	UPDATE cc WITH(ROWLOCK, UPDLOCK)
	SET 	cc.[Value] = 0
	FROM dbo.CustomerClassification_Parameter AS cc
	WHERE cc.[DataId] IN (@GENERAL_LASTSCANNEDROW, @BYSPORT_LASTSCANNEDROW);