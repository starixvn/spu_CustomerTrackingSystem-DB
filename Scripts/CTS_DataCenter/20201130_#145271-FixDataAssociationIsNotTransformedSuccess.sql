/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Created: 20201130@CaseyHuynh
Task: 	 Fix Transform Account and Association to CTSCustomer
DB: 	 CTS_DataCenter
*/
USE CTS_DataCenter;
DROP PROCEDURE IF EXISTS Iss145277_ReTransformAssocition;

DELIMITER $$
CREATE DEFINER='ctsOwner' PROCEDURE Iss145277_ReTransformAssocition(IN ip_Batch INT)
SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20201130@CaseyHuynh
		Task: 	 Fix Transform Account and Association to CTSCustomer.
		DB:			
		Original:

		Revisions:
			- 20201130@CaseyHuynh: Fix Transform Account and Association to CTSCustomer.[RedmineID : #145277]
	*/    
	
    DECLARE vrFromAccountID BIGINT ;
    DECLARE vrToAccountID BIGINT DEFAULT 0;   
	DECLARE vrMaxAccountID BIGINT DEFAULT 0;   
    
	SET vrFromAccountID = 1; # (SELECT vValue FROM CTS_Adhoc.SystemSetting WHERE ID = 145277); #6553746;
    SET vrToAccountID =vrFromAccountID;
    
    SET	vrMaxAccountID = (SELECT Max(AccountID)	FROM DCS_DataCenter.Account);
    
    SELECT vrFromAccountID, vrMaxAccountID;
    #step 1: get data to CTS_Adhoc.Iss145271Association
    WHILE vrToAccountID < vrMaxAccountID
    DO		
			SET vrToAccountID  = vrFromAccountID + ip_Batch;
            
			INSERT INTO CTS_Adhoc.Iss145271Association (AccountID, DeviceID)
			SELECT  	ass.AccountID, ass.DeviceID
			FROM		DCS_DataCenter.Account AS acc
			INNER JOIN 	DCS_DataCenter.Association AS ass
						ON acc.AccountID = ass.AccountID
			WHERE 		acc.AccountID BETWEEN vrFromAccountID AND vrToAccountID
						AND acc.IsCTSTransformed = 1
						AND ass.IsCTSTransformed < 1;
            
            UPDATE 	CTS_Adhoc.SystemSetting 
            SET 	vValue = IFNULL(vrToAccountID,vValue)
            WHERE	ID = 145277;
            
			SET vrFromAccountID  = vrToAccountID + 1;
            
    END WHILE;
	
	#Step 2: Update IsCTSTransfromed = 0
    UPDATE 		DCS_DataCenter.Association AS ass
    INNER JOIN 	CTS_Adhoc.Iss145271Association AS iss
				ON ass.AccountID = iss.AccountID
					AND ass.DeviceID = iss.DeviceID
	SET 		ass.IsCTSTransformed = 0;
	    
END ;;
DELIMITER ;

#Execution 
CALL Iss145277_ReTransformAssocition(10000);

DROP PROCEDURE IF EXISTS Iss145277_ReTransformAssocition;
