from db.dbHelper import DBHelper

db =  DBHelper()

metrics_sp_master = db.exec("master",'DBA_Monitor_SPMetric_Get',None,True)
db.exec("archive",'DBA_Monitor_SPMetric_Insert',(metrics_sp_master,'master',),True)

metrics_sp_replica = db.exec("replica",'DBA_Monitor_SPMetric_Get',None,True)
db.exec("archive",'DBA_Monitor_SPMetric_Insert',(metrics_sp_replica,'replica',),True)

metrics_sp_archive = db.exec("archive",'DBA_Monitor_SPMetric_Get',None,True)
db.exec("archive",'DBA_Monitor_SPMetric_Insert',(metrics_sp_archive,'archive',),True)


