from db.dbHelper import DBHelper
from message.messHelper import MessageHelper
from ssh.sshHelper import SSHHelper
from datetime import datetime

class Alertor:
    db = None
    mess = None
    ssh = None

    def __init__(self):
        self.db =  DBHelper()
        self.mess =  MessageHelper()
        self.ssh =  SSHHelper()

    def CheckBigQuery(self,serverName):
        try:
            messageInfo = self.db.Exec(serverName,'MonDB.DBA_Monitor_BigQuery_Check();',None,False)
            for info in messageInfo:
                if info[0] == None:
                    continue
                self.mess.SendMessage(info[0].replace("\\n","\n"))
        except Exception as ex:
            print("Datetime: ",datetime.now())
            print("Server: ",serverName)
            print("Error Message: ",ex)
    
    def CheckTableScan(self,serverName):
        try:
            messageInfo = self.db.Exec(serverName,'MonDB.DBA_Monitor_TableScan_Check();',None,False)
            for info in messageInfo:
                if info[0] == None:
                    continue
                self.mess.SendMessage(info[0].replace("\\n","\n"))
        except Exception as ex:
            print("Datetime: ",datetime.now())
            print("Server: ",serverName)
            print("Error Message: ",ex)
    
    def DailyMonitorReport(self):
        try:
            messageDailyReport = '<b>CTS Database Monitor Daily Report</b>\n'
            currMessGroupName = ''

            messageSetting = self.db.Exec("archive",'MonDB.DBA_Monitor_DailyReport_GetSetting();',None,False)

            for setting in messageSetting:
                subMessage = ''

                if currMessGroupName != setting[1]:
                    currMessGroupName = setting[1]
                    messageDailyReport = messageDailyReport + "\n"  + currMessGroupName + "\n" 
                
                messageMetricScript = setting[4]
                serverName = setting[5]
                scriptType = setting[6]

                if scriptType == 'SQL':
                    subMessage = self.db.Exec(serverName,messageMetricScript,None,True)
                elif scriptType == 'Bash':
                    subMessage = self.ssh.Exec(serverName,messageMetricScript)
                    
                subMessage = subMessage.replace("\\n","\n")
                messageDailyReport = messageDailyReport + subMessage +  "\n"

            self.mess.SendMessage(messageDailyReport)
            messageSumary = self.db.Exec("master",'MonDB.DBA_Monitor_DailyReport_Sumary();',None,False)
            if messageSumary != None:
                self.mess.SendMessage(messageSumary)
        except Exception as ex:
            print("Datetime: ",datetime.now())
            print("Server: ",serverName)
            print("Error Message: ",ex)
    
    def close(self):
        self.db.close()
        self.mess.close()
        self.ssh.close()