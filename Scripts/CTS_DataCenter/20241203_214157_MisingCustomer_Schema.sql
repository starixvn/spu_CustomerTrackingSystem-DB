/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20241213@Jonas.Huynh
Task:	 	Add column
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20241213@Jonas.Huynh: Created [Redmine ID: #214157]
Reviewer:
*/

USE CTS_DataCenter;

/*Add column*/
ALTER TABLE CTS_DataCenter.JobMonitoring_IncorrectData 
ADD COLUMN IsResolved	BIT(1) DEFAULT 0;
    
/*Init params*/
INSERT INTO `CTS_DataCenter`.`StaticList`(`ListID`,`ItemID`,`ListName`,`ListNameDisplay`,`ItemName`,`ItemNameDisplay`,`ItemValue`,`ItemDefaultValue`,`ItemParentItemID`,`PriorityOrder`,`Status`,`Description`,`CreatedDate`) VALUES
(20,4,'Job Monitoring IssueType','Job Monitoring IssueType','New Customer - Total Unresolved Missing Customers','New Customer - Total Unresolved Missing Customers',null,null,null,null,1,null, NOW()),
(20,50,'Job Monitoring IssueType','Job Monitoring IssueType','Reactivated Customer - Missing','Reactivated Customer - Missing',null,null,null,null,1,null, NOW()),
(20,203,'Job Monitoring IssueType','Job Monitoring IssueType','Classification - Excessive Gerneral Normal Insert','Classification - Excessive Gerneral Normal Insert',null,null,null,null,1,null, NOW()),
(20,204,'Job Monitoring IssueType','Job Monitoring IssueType','Classification - Excessive BySport Normal Insert','Classification - Excessive BySport Normal Insert',null,null,null,null,1,null, NOW()),
(20,102,'Job Monitoring IssueType','Job Monitoring IssueType','Realtime Classification - Excessive Gerneral Changes','Realtime Classification - Excessive Gerneral Changes',null,null,null,null,1,null, NOW()),
(20,103,'Job Monitoring IssueType','Job Monitoring IssueType','Realtime Classification - Excessive BySport Changes','Realtime Classification - Excessive BySport Changes',null,null,null,null,1,null, NOW());

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES
(185,'JobMonitoring_MissingCustomer_LastScanID','JobMonitoring_MissingCustomer_LastScanID','BIGINT UNSIGNED','0'),
(186,'JobMonitoring_ReactivatedCustomerLastScannedTime','JobMonitoring_ReactivatedCustomerLastScannedTime','BIGINT UNSIGNED', CURRENT_TIMESTAMP(3));

/*Update param*/
SELECT MAX(ID)
INTO @lv_MaxID
FROM CTS_DataCenter.JobMonitoring_IncorrectData;

UPDATE CTS_DataCenter.SystemParameter
SET ParameterValue = @lv_MaxID
WHERE ParameterID = 185;
