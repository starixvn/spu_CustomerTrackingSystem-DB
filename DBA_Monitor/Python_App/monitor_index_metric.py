from db.dbHelper import DBHelper

db =  DBHelper()

metrics_table_master = db.exec("master",'DBA_Monitor_TableMetric_Get',None,True)
db.exec("archive",'DBA_Monitor_TableMetric_Insert',(metrics_table_master,'master',),True)

metrics_table_replica = db.exec("replica",'DBA_Monitor_TableMetric_Get',None,True)
db.exec("archive",'DBA_Monitor_TableMetric_Insert',(metrics_table_replica,'replica',),True)

metrics_table_archive = db.exec("archive",'DBA_Monitor_TableMetric_Get',None,True)
db.exec("archive",'DBA_Monitor_TableMetric_Insert',(metrics_table_archive,'archive',),True)
