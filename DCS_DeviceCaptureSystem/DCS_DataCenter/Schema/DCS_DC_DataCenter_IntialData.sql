/*
Creator: 20190521@Casey.Huynh
Task:    Data Center - Initial Data
Server:  
DBName:	DCS_DataCenter

Reviewer: 
*/

USE DCS_DataCenter;
INSERT INTO DCS_DataCenter.ActionResult(ActionResultID, ActionResultKey, ActionStatus, CreatedDate)
VALUES (0,'',0,'2011-01-01')
		, (1521261242,'login -> successfully',1,'2011-01-01')
        , (1862328242,'success',1,'2011-01-01')
        , (3686301690,'successfully',1,'2011-01-01')
        , (2250713929,'fail',0,'2011-01-01');

INSERT INTO DCS_DataCenter.OS(OSName, CreatedDate)
VALUES('','2011-01-01');

INSERT INTO DCS_DataCenter.Browser(BrowserName, CreatedDate)
VALUES('','2011-01-01');

INSERT INTO DCS_DataCenter.UserAgent(UserAgentID, UserAgent, BrowserID, OSID, OS, Browser, CreatedDate)
VALUES(0,'',1,1,'','','2011-01-01');

INSERT INTO DCS_DataCenter.Device(DeviceID, DeviceKey, FirstDeviceCode, UserAgentID, FirstTransID, CreatedDate, DeviceStatus, InsertTime)
VALUES(0,0,'',0,0,'2011-01-01',0,'2011-01-01');

INSERT INTO DCS_DataCenter.TransStatus(TransStatusName, StatusValue, Notes, IsTransformed, CreatedDate)
VALUES('Valid Transaction', b'0','', 1,CURRENT_DATE())
			,('Invalid Subscriber', b'1', 'Handle At SP DCS_DC_TransformData_UnhandleSubscriberAction', 0, CURRENT_DATE())
			,( 'Invalid Action Result', b'10', 'Handle At SP DCS_DC_TransformData_UnhandleSubscriberAction', 0,CURRENT_DATE())
            ,('Invalid Devicode_Empty', b'100', 'Handle At Web', 1,CURRENT_DATE())
            ,('Invalid Login Name', b'1000', 'Handle At Web', 0,CURRENT_DATE())
            ,('Invalid DI', b'10000', 'Handle At Web', 1,CURRENT_DATE());

