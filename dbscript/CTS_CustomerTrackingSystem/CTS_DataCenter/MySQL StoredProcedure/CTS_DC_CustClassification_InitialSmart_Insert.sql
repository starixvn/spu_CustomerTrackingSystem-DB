/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_InitialSmart_Insert`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_InitialSmart_Insert`(
		IN 	ip_CustInfo 		JSON
    ,   OUT op_IsCustExist 	    TINYINT
)
SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20240530@Thomas.Nguyen
		Task:	 	Customer Initial Smart - Insert data after getting from TW
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20240530@Thomas.Nguyen: Created [Redmine ID: #199345]

		Example:
			CALL CTS_DC_CustClassification_InitialSmart_Insert (@ip_CustInfo:='[{"CustID":1275,"Probability":0.1419399977,"PredictTime":"2024-05-30T03:02:26"},{"CustID":1277,"Probability":0.7015600204,"PredictTime":"2024-05-30T03:03:26"},{"CustID":1280,"Probability":0.7505900264,"PredictTime":"2024-05-31T03:02:26"},{"CustID":1282,"Probability":0.7498900294,"PredictTime":"2024-05-30T07:02:26"}]');
	*/
	DECLARE lv_CreatedDate DATETIME(3);
    
	SET lv_CreatedDate = CURRENT_TIMESTAMP(3);

	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE Temp_Customer(
			CustID 				BIGINT NOT NULL PRIMARY KEY
		,   Probability 		DECIMAL(8,4)
		,   PredictTime 	    DATETIME(3)
	);

	INSERT IGNORE INTO Temp_Customer(CustID, Probability, PredictTime)
    SELECT	tmp.CustID
		,	tmp.Probability
		,	tmp.PredictTime
    FROM JSON_TABLE(ip_CustInfo,
                        "$[*]" COLUMNS (CustID          	BIGINT			UNSIGNED	PATH "$.CustID"
									,	Probability			DECIMAL(8,4)				PATH "$.Probability"
                                    ,   PredictTime		    DATETIME(3)					PATH "$.PredictTime"                                           
                                )) AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.IsInternal = 0;

	IF EXISTS (	SELECT 1
				FROM CTS_DataCenter.Customer_InitialSmart AS cs
					INNER JOIN Temp_Customer AS tmp	ON tmp.CustID = cs.CustID) THEN
		INSERT INTO CTS_DataCenter.Customer_InitialSmart_Log (CustID, Probability, PredictTime, InsertedTime)
		SELECT	tmp.CustID
			,	tmp.Probability
			,	tmp.PredictTime
            ,   lv_CreatedDate
		FROM CTS_DataCenter.Customer_InitialSmart AS cs
			INNER JOIN Temp_Customer AS tmp	ON tmp.CustID = cs.CustID;

        SET op_IsCustExist = 1;
    ELSE 
        SET op_IsCustExist = 0;
	END IF;

    INSERT IGNORE INTO CTS_DataCenter.Customer_InitialSmart (CustID, Probability, PredictTime, InsertedTime)
    SELECT	tmp.CustID
		,	tmp.Probability
		,	tmp.PredictTime
        ,   lv_CreatedDate
	FROM Temp_Customer AS tmp;
	
END$$
DELIMITER ;