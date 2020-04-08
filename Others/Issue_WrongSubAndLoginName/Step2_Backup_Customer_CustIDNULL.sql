# 1, Create Table Backup
	CREATE TABLE IF NOT EXISTS CTS_DataCenter.zzzIssueLoginName_CTSCustomer (
		CTSCustID			BIGINT	UNSIGNED	AUTO_INCREMENT
		, SubscriberID		INT		UNSIGNED
		, CustID			INT		UNSIGNED
		, CustSubID			INT		UNSIGNED
		, UserName			VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		, UserName2			VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        , SiteID			INT
		, Site				VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		, RoleID			TINYINT
		, Currency			VARCHAR(10)
		, CurrencyID		INT		
		, SRecommend		INT		UNSIGNED
		, MRecommend		INT		UNSIGNED	
		, Recommend			INT		UNSIGNED
        , LastLoginTime		TIMESTAMP(4)
        , CreatedDate		DATETIME
		, PRIMARY KEY	PK_CTSCustomer_CTSCustID(CTSCustID)    
		, UNIQUE KEY	UK_CTSCustomer_SubscriberID_UserName_UserName2(SubscriberID, UserName, UserName2)
		, INDEX			IX_CTSCustomer_UserName_UserName2(UserName, UserName2)
		, INDEX			IX_CTSCustomer_UserName2(UserName2)
		, INDEX			IX_CTSCustomer_CustID_CustSubID(CustID, CustSubID)
		, FULLTEXT 		IX_FullText_CTSCustomer_UserName_UserName2 (UserName,UserName2)
	) ENGINE=INNODB AUTO_INCREMENT=1;

#2. Call SP Copy to CTSCustomer;
CALL CTS_DataCenter.zzzIssueLoginName_CTSCustomer();