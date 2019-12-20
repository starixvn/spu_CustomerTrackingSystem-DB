
/*
Server: DBFRAUD
DB: FPS_ADMIN
*/


SELECT	sub.SubscriberID
		, sub.SubscriberName
		, sub.IBCUserName_Prefix	AS SubscriberPrefix
		, sub.IntegrationDate 
		, sub.IsActive				AS SubscriberStatus
		, (CASE WHEN SubscriberName IN ('CN88') THEN 0
			   WHEN SubscriberName IN ('CTMAX') THEN 2
			   ELSE sub.EnableSysId 
		  END)	AS SubscriberType
		, GETDATE() AS CreatedDate
		, NULL AS CreatedBy
		, sub.IsTest
FROM	dbo.Subscribers AS sub WITH(NOLOCK);

SELECT	sub.SubscriberID
		,', ''' + sub.SubscriberName + ''''
		,', ''' + ISNULL(sub.IBCUserName_Prefix,'null') + ''''	AS SubscriberPrefix
		, ', ''' + ISNULL(CONVERT(Varchar,sub.IntegrationDate,120),'') + ''''
		, ',' +	CAST(sub.IsActive AS CHAR(1))				AS SubscriberStatus
		, ',' + (CASE WHEN SubscriberName IN ('CN88') THEN '0'
				   WHEN SubscriberName IN ('CTMAX') THEN '1'
				   ELSE CAST(sub.EnableSysId AS CHAR(1))
				 END)	AS SubscriberType
		, ', ''' + ISNULL(CONVERT(Varchar,GETDATE(),120),'') + ''''
		, ',null,' AS CreatedBy
		, ',' + CAST(sub.IsTest AS CHAR(1))
	
FROM	dbo.Subscribers AS sub WITH(NOLOCK);





SELECT	',('
		+ CAST(sub.SubscriberID AS VARCHAR(20))
		+ ', ''' + sub.SubscriberName 
		+ ''', ''' + ISNULL(sub.IBCUserName_Prefix,'') 
		+ ''', ''' + CONVERT(Varchar,ISNULL(sub.IntegrationDate,'2001-01-01'),120)
		+ ''', ' + CAST(sub.IsActive AS CHAR(1))
		+ ', ' +(CASE WHEN SubscriberName IN ('CN88') THEN '0'
				   WHEN SubscriberName IN ('CTMAX') THEN '2'
				   ELSE CAST(sub.EnableSysId AS CHAR(1))
				 END)
		+ ','' ' + ISNULL(CONVERT(Varchar,GETDATE(),120),'')
		+ ''',null'
		+ ',' + CAST(sub.IsTest AS CHAR(1))
		+ ')'
FROM	dbo.Subscribers AS sub WITH(NOLOCK);
