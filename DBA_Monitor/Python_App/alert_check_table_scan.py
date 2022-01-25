from db.dbHelper import DBHelper
from message.messHelper import MessageHelper

db =  DBHelper()
telegram = MessageHelper()

messageSettingList = db.exec("master",'MonDB.DBA_Monitor_TableScan_Check();',None,False)


for message in messageSettingList:
    if message[0] == None:
        continue
    telegram.sendMessage(message[0].replace("\\n","\n"))

messageSettingList = db.exec("replica",'MonDB.DBA_Monitor_TableScan_Check();',None,False)
for message in messageSettingList:
    if message[0] == None:
        continue
    telegram.sendMessage(message[0].replace("\\n","\n"))