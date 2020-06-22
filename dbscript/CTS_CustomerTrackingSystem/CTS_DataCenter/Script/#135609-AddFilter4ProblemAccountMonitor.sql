/*
Created: 20200518@lex.khuat
		Task:		Update robot description from Green to Human [Redmine ID: #133934]
		DB:			CTS_DataCenter
		Original:
		Revisions:
/*

/****=====Step=====****/

# Init subscribergroup data
SET @INSERT_TIME = CURRENT_TIMESTAMP();
INSERT INTO CTS_DataCenter.SubscriberGroup(SubscriberGroupName, SubscriberGroupDesc, ParentID, DisplayOrder, IsActive, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy)
VALUES
('Credit', 'All credit subscribers', 0, 1, 1, @INSERT_TIME, null, @INSERT_TIME, null),
('Licensees', 'All licensee subscribers', 0, 2, 1, @INSERT_TIME, null, @INSERT_TIME, null),
('CN88', 'All CN88 subscribers', 0, 3, 1, @INSERT_TIME, null, @INSERT_TIME, null);

/*====================*/