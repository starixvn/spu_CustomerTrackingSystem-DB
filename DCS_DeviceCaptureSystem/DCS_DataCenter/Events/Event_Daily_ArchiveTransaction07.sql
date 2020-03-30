delimiter |
DROP EVENT IF EXISTS Event_Daily_ArchiveTransaction07;
/*
	Created: 20200330@Terry.Nguyen
	Task : Archive Data From Transaction07 to Transaction_BK01
	DB: DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/
CREATE EVENT Event_Daily_MoveTransaction
    ON SCHEDULE
		EVERY 1 DAY
		STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY + INTERVAL 1 HOUR)
        #EVERY 5 MINUTE
        #STARTS '2020-03-30 14:53:00'
        ON COMPLETION PRESERVE ENABLE
    COMMENT 'Archive data from Transaction07 to Transaction_BK01 with package size = 1000'
    DO
      BEGIN		
        CALL `DCS_DataCenter`.`DCS_DC_ArchiveData_FromTransaction07`(1000);       
      END |

delimiter ;