from db.dbHelper import DBHelper
from datetime import datetime

class Collector:
    db =  None

    def __init__(self):
        self.db =  DBHelper()
    
    def MonitorIndexMetric(self, serverName):  
        try:
            metricsIndex = self.db.Exec(serverName,'DBA_Monitor_IndexMetric_Get',None,True)
            self.db.Exec("archive",'DBA_Monitor_IndexMetric_Insert',(metricsIndex,serverName,),True)
        except Exception as ex:
            print("Datetime: ",datetime.now())
            print("Server: ",serverName)
            print("Error Message: ",ex)

    def MonitorTableMetric(self, serverName): 
        try: 
            metricsTable = self.db.Exec(serverName,'DBA_Monitor_TableMetric_Get',None,True)
            self.db.Exec("archive",'DBA_Monitor_TableMetric_Insert',(metricsTable,serverName,),True)
        except Exception as ex:
            print("Datetime: ",datetime.now())
            print("Server: ",serverName)
            print("Error Message: ",ex)

    def MonitorSPMetric(self, serverName): 
        try:  
            metricsSP = self.db.Exec(serverName,'DBA_Monitor_SPMetric_Get',None,True)
            self.db.Exec("archive",'DBA_Monitor_SPMetric_Insert',(metricsSP,serverName,),True)
        except Exception as ex:
            print("Datetime: ",datetime.now())
            print("Server: ",serverName)
            print("Error Message: ",ex)

    def close(self):
        self.db.close()