/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220519@Aries.Nguyen
    Task:	    Init cust info: IsLicensee, IsInternal [Redmine ID: #202204]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`)
VALUES (1000, 'InitDataCustomerInfo', 'InitDataCustomerInfo', 'BIGINT', 0);


USE CTS_DataCenter;
delimiter |
CREATE EVENT EV_CTS_DataCenter_InitDataCustomerInfo
    ON SCHEDULE
      EVERY 20 SECOND
    DO
      BEGIN
			CALL CTS_DataCenter.CTS_DC_CustInfo_Init(2000); 
      END |

delimiter ;


