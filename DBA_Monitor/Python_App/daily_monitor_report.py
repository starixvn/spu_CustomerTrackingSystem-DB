from db.dbHelper import DBHelper
from ssh.sshHelper import SSHHelper
from message.messHelper import MessageHelper

db =  DBHelper()
ssh = SSHHelper()
telegram = MessageHelper()

message_daily_report = '<b>CTS Database Monitor Daily Report</b>\n'
currMessGroupName = ''

messageSetting = db.exec("archive",'MonDB.DBA_Monitor_DailyReport_GetSetting();',None,False)

for setting in messageSetting:
    subMessage = ''

    if currMessGroupName != setting[1]:
        currMessGroupName = setting[1]
        message_daily_report = message_daily_report + "\n"  + currMessGroupName + "\n" 
    
    messageMetricScript = setting[4]
    serverName = setting[5]
    scriptType = setting[6]

    if scriptType == 'SQL':
        subMessage = db.exec(serverName,messageMetricScript,None,True)
    elif scriptType == 'Bash':
        subMessage = ssh.exec(serverName,messageMetricScript)
        
    subMessage = subMessage.replace("\\n","\n")
    message_daily_report = message_daily_report + subMessage +  "\n"


messageSumary = db.exec("master",'MonDB.DBA_Monitor_DailyReport_Sumary();',None,False)
if messageSumary != None:
    telegram.sendMessage(messageSumary)




