/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220614@Casey.Huynh
    Task:	    Renovate PA process [Redmine ID: #172561]
    DBName:		CTS_Admin, CTS_DataCenter,CTS_Archive
*/

USE CTS_DataCenter;

#=========GET REMOVE PA LIST===============

DROP  TEMPORARY TABLE IF EXISTS Temp_RemovePA;
CREATE TEMPORARY TABLE Temp_RemovePA (CustID INT UNSIGNED PRIMARY KEY);

INSERT INTO Temp_RemovePA(CustID)
SELECT DISTINCT h.CustID 
FROM CTS_DataCenter.CTSCustomerClassification_History h
WHERE InsertDate >= '2022-06-14 00:00:00' AND SourceTypeID IN (33,34);

#=========UPDATE   rd.IsDisabled = 0 FOR ALL===============
UPDATE CTS_DataCenter.RobotDetection AS rd
SET rd.IsDisabled = 0;

#=========UPDATE   rd.IsDisabled = 1 FOR REMOVE ALL PA (NOT EXISTS ANY PA IN CTS_DataCenter.CTSCustomerClassification)===============
UPDATE CTS_DataCenter.RobotDetection AS rd
INNER JOIN Temp_RemovePA AS tmp ON rd.CustID = tmp.CustID
SET rd.IsDisabled = 1
WHERE NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomerClassification cls WHERE tmp.CustID = cls.CustID AND cls.SportGroupID = 0);

#===================================
UPDATE CTS_DataCenter.CTSCustomerClassification AS cls
INNER JOIN CTS_DataCenter.RobotDetection AS rd ON rd.CustID = cls.CustID AND rd.IsDisabled = 0 AND cls.CategoryID IN (61, 163, 164)
SET cls.IsFromAI = 1;
