/*
Creator: 20191217@CaseyHuynh
Task:	 	CTS_Schema
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
	#1. [20191217@CaseyHuynh][#125530]: Add LastLoginDate column to table CTSCustomer.
    #2. [20191217@CaseyHuynh][#125534]: Create StaticList table
    #3. [20191217@Harvey.Nguyen][#125530]: Add CreatedDate column to table CTSCustomer
    #4. [20191220@CaseyHuynh][#125844]: Inplement Mapping Subscriber and Site
    
Reviewer:
	#1. Harvey: 
*/

/* ==========================PHASE 2===================================*/
#1. [20191217@CaseyHuynh][#125530]
ALTER TABLE		CTS_DataCenter.CTSCustomer
ADD COLUMN		LastLoginTime	TIMESTAMP(4);

ALTER TABLE		CTS_DataCenter.CTSCustomer
ADD COLUMN		CreatedDate		DATETIME;

#
# ===================================================
CREATE TABLE IF NOT EXISTS CTS_DataCenter.StaticList
(
	ListID				INT
    , ItemID			SMALLINT
    , ListName			VARCHAR(100)
    , ListNameDisplay	VARCHAR(200)
    , ItemName			VARCHAR(100)
    , ItemNameDisplay	VARCHAR(200)
    , PriorityOrder		SMALLINT
    , Status			BOOL
    , Description		VARCHAR(200)    
    , CreatedDate		DATETIME
    
    , PRIMARY KEY PK_StaticList_ListID_ItemID(ListID, ItemID)
) ;

	DROP TABLE CTS_DataCenter.MappingSubscriberSite;
	CREATE TABLE IF NOT EXISTS CTS_DataCenter.MappingSubscriberSite(
		SiteID				BIGINT	UNSIGNED
		, SiteName			VARCHAR(50)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		, SubscriberID		INT
		, SubscriberName	VARCHAR(50)
        , RoleIDMapping		INT
		, UNIQUE KEY	PK_MappingSubscriberSite_SubscriberID(SiteID, SubscriberID)    
	) ENGINE=INNODB;
#==========INITIAL DATA====================================================
INSERT INTO CTS_DataCenter.StaticList(ListID, ItemID, ListName, ListNameDisplay, ItemName, ItemNameDisplay, PriorityOrder, Status, Description, CreatedDate)
VALUES	  (1,1, 'Profile Status_Licensee'	, 'Status', 'Active'	, 'Active'		, 1, 1, 'Profile Status Item', CURRENT_DATE() )
		, (1,2, 'Profile Status_Licensee'	, 'Status', 'Locked'	, 'Locked'		, 2, 1, 'Profile Status Item', CURRENT_DATE() )
        , (1,3, 'Profile Status_Licensee'	, 'Status', 'Closed'	, 'Closed'		, 3, 1, 'Profile Status Item', CURRENT_DATE() )
        , (1,4, 'Profile Status_Licensee'	, 'Status', 'Archived'	, 'Archived'	, 4, 1, 'Profile Status Item', CURRENT_DATE() )
        , (1,5, 'Profile Status_MBC'		, 'Status', 'Open'		, 'Open'		, 1, 1, 'Profile Status Item', CURRENT_DATE() )
        , (1,6, 'Profile Status_MBC'		, 'Status', 'Closed'	, 'Closed'		, 2, 1, 'Profile Status Item', CURRENT_DATE() )
        , (1,7, 'Profile Status_MBC'		, 'Status', 'Suspended'	, 'Suspended'	, 3, 1, 'Profile Status Item', CURRENT_DATE() )
        , (1,8, 'Profile Status_MBC'		, 'Status', 'Disabled'	, 'Disabled'	, 4, 1, 'Profile Status Item', CURRENT_DATE() )
        , (1,9, 'Profile Status_CN88'		, 'Status', 'Active'	, 'Active'		, 1, 1, 'Profile Status Item', CURRENT_DATE() )
        , (1,10, 'Profile Status_CN88'		, 'Status', 'View Only'	, 'View Only'	, 2, 1, 'Profile Status Item', CURRENT_DATE() )
        , (1,11, 'Profile Status_CN88'		, 'Status', 'Suspended'	, 'Suspended'	, 3, 1, 'Profile Status Item', CURRENT_DATE() )
        , (1,12, 'Profile Status_CN88'		, 'Status', 'Inactive'	, 'Inactive'	, 4, 1, 'Profile Status Item', CURRENT_DATE() )
        , (4,1, 'Association Type'			, 'Association Type', 'Device'	, 'Device'	, 1, 1, 'Profile Status Item', CURRENT_DATE() )
        , (4,2, 'Association Type'			, 'Association Type', 'IP'		, 'IP'		, 2, 1, 'Profile Status Item', CURRENT_DATE() )
        ;

#=========================
/*
Licensee: Active, Locked, Closed, Archived
MBC: Open, Closed, Suspended, Disabled
CN88: Active, View Only, Suspended, Inactive*/