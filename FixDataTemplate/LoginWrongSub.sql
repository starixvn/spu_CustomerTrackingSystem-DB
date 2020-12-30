/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Created: 20201130@CaseyHuynh
Task: 	 This is template for fix data of Transaction Login Wrong Subscriber (ex: Customer is IBCIndo BUT Longin by Maxbet)
DB: 	 CTS_DataCenter
*/
USE CTS_DataCenter;
DROP PROCEDURE IF EXISTS IssHotfixID_FixDataLoginWrongSub;

DELIMITER $$
CREATE DEFINER='ctsOwner' PROCEDURE IssHotfixID_FixDataLoginWrongSub()
SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20201130@CaseyHuynh
		Task: 	 Fix Data wrong Sub  Customer IBCIndo( 13659, 13658) login by Subscriber Alpha, MaxBet(2,130)
		DB:			
		Original:

		Revisions:
	*/    
	
    USE CTS_Adhoc;
    CREATE TABLE IssHotfixID_SubscriberMap
    (
		SubscriberID_Valid		INT
        , SubscriberName_Valid	VARCHAR(50)
        , SubscriberPrefix_Valid	VARCHAR(30)
        , SubscriberID_Invalid		INT
        , SubscriberName_Invalid	VARCHAR(50)
        , SubscriberPrefix_Invalid	VARCHAR(30)
    );
    
    CREATE TABLE IssHotfixID_CTSCustomerValid
    (
		CTSCustID		BIGINT UNSIGNED
        , SubsriberID 	INT
        , SiteID		INT			
        , UserName		VARCHAR(50)
        , UserName2		VARCHAR(50)
        , LastLoginTime DATETIME
    );
    
    CREATE TABLE IssHotfixID_AccountInvalid
    (
		AccountID				BIGINT UNSIGNED
        , SubsriberID 			INT	
        , LoginName				VARCHAR(50)
        , LastLoginTime 		DATETIME
        , CorrectedAccountID 	BIGINT UNSIGNED
		, CorrectedSubscriberID BIGINT UNSIGNED
    );
        
     CREATE TABLE IssHotfixID_AccountInvalid
    (
		AccountID				BIGINT UNSIGNED
        , SubsriberID 			INT	
        , LoginName				VARCHAR(50)
        , LastLoginTime 		TIMESTAMP(4)
        , CorrectedAccountID 	BIGINT UNSIGNED # NOT NULL IF Duplicate Account
		, CorrectedSubscriberID BIGINT UNSIGNED # NOT NULL IF Duplicate Account
        , CorrectLastLoginTime 	TIMESTAMP(4)
        , ActType				TINYINT			# -1: Remove Account by Duplicate Account
    );
    
    
	    
END ;;
DELIMITER ;

#Execution 
CALL Iss145277_ReTransformAssocition(10000);

DROP PROCEDURE IF EXISTS Iss145277_ReTransformAssocition;
