/*<info serverAlias="CTSMain-MonDB" databaseType="2"></info>*/
/*
	Created: 20210303@Aries.Nguyen
	Task: 	 Create event [Redmine ID: #149662]
	DB: 	 MonDB
*/

USE MonDB;
delimiter |
CREATE EVENT EV_Monitor_SPMetric_Insert
    ON SCHEDULE
      EVERY 5 MINUTE
    DO
      BEGIN
         CALL MonDB.DBA_Monitor_SPMetric_Insert();
    END |
delimiter ;








