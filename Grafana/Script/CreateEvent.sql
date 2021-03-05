USE MonDB;
delimiter |
CREATE EVENT EV_Monitor_SPMetric_Insert
    ON SCHEDULE
      EVERY 30 MINUTE
    DO
      BEGIN
         CALL MonDB.DBA_Monitor_SPMetric_Insert();
    END |
delimiter ;
