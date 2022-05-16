import json
from db.dbHelper import DBHandler
from datetime import  datetime, timezone, timedelta
from config import config
from message.messHelper import MessageHelper
from ssh.sshHelper import SSHHandler
import string    
import random    
import os

class DBTaskHelper:
    db =  None
    ssh = None
    connArchiveOpt = {}
    tempTablePrefix = None
    tele = None
    telegramOpt = {}
    
    def __init__(self):
        self.db =  DBHandler()
        self.ssh = SSHHandler()
        self.tele = MessageHelper()
        dbConfigArchive = config['mysql_archive'];
        self.connArchiveOpt['host']= dbConfigArchive['host'];
        self.connArchiveOpt['user'] = dbConfigArchive['user'];
        self.connArchiveOpt['password'] =  dbConfigArchive['password'];
        self.connArchiveOpt['db'] = dbConfigArchive['db'];
        self.connArchiveOpt['port'] = dbConfigArchive['port'];

        self.tempTablePrefix = "_" + self.RandomStr(6)

    def WriteLog(self,message):
        nowUTC7 = (datetime.now(timezone.utc) + timedelta(hours=7)).strftime("%Y-%m-%d %H:%M:%S")
        text = '''{date}: {message}
               '''.format(date=nowUTC7,message=message)
        print(text)
        mess = '''<b>Archiving Partition Error</b>\n{text}'''.format(text=text)
        self.tele.SendTelegramMessage(self.telegramOpt,mess);

    def RandomStr(self,number):  
        ran = ''.join(random.choices(string.ascii_uppercase + string.digits, k = number))    
        return str(ran)

    def GetArchiveConfig(self,runType):
        try:
            listConfig = self.db.Call_SP(self.connArchiveOpt,'DBA_Archive_Config_Get',(runType,))
            return listConfig;  
        except Exception as ex:
            raise Exception(("GetArchiveConfig",ex)) 
    
    def GetDropPartitionConfig(self):
        try:
            listConfig = self.db.Call_SP(self.connArchiveOpt,'DBA_DropPartition_Config_Get',())
            return listConfig;  
        except Exception as ex:
            raise Exception(("GetDropPartitionConfig",ex)) 
    
    def GetReOrganizePartitionConfig(self):
        try:
            listConfig = self.db.Call_SP(self.connArchiveOpt,'DBA_ReOrganizePartition_Config_Get',())
            return listConfig;  
        except Exception as ex:
            raise Exception(("GetReOrganizePartitionConfig",ex)) 

    def GetSlowLogConfig(self):
        try:
            listConfig = self.db.Call_SP(self.connArchiveOpt,'DBA_SlowLog_Config_Get',())
            return listConfig;  
        except Exception as ex:
            raise Exception(("GetSlowLogConfig",ex)) 
    
    def GetFragmentationTableConfig(self):
        try:
            listConfig = self.db.Call_SP(self.connArchiveOpt,'DBA_FragmentationTable_Config_Get',())
            return listConfig;  
        except Exception as ex:
            raise Exception(("GetFragmentationTableConfig",ex)) 

    def CheckPartitionExist(self,connOpt,database,tableName,keepDataRange):
        try:
            query = ''' SELECT 1 AS HasPartition, PARTITION_NAME, PARTITION_DESCRIPTION, TABLE_ROWS
                        FROM information_schema.partitions
                        WHERE TABLE_CATALOG = "def"
	                    AND TABLE_SCHEMA = "{database}"
                        AND TABLE_NAME = "{tableName}"
                        AND PARTITION_DESCRIPTION = YEARWEEK(DATE_SUB(DATE_ADD(NOW(), INTERVAL 11 HOUR), INTERVAL {keepDataRange} DAY)) + 1;
                    '''.format(database=database,tableName=tableName,keepDataRange=keepDataRange).replace('\t'," ").replace('\n'," ")
            hasPartition = self.db.Execute(connOpt,query)
            if hasPartition and hasPartition[0]['HasPartition'] == 1:
                return (True,hasPartition[0]['PARTITION_NAME'], int(hasPartition[0]['PARTITION_DESCRIPTION']), hasPartition[0]['TABLE_ROWS']);
            return (False,'');
        except Exception as ex:
            raise Exception(("CheckPartitionExist",ex,database,tableName,keepDataRange)) 

    def CheckPartitionExistByName(self,connOpt,database,tableName,partitionName):
        try:
            query = ''' SELECT 1 AS HasPartition
                        FROM information_schema.partitions
                        WHERE TABLE_CATALOG = "def"
	                    AND TABLE_SCHEMA = "{database}"
                        AND TABLE_NAME = "{tableName}"
                        AND PARTITION_NAME = "{partitionName}";
                    '''.format(database=database,tableName=tableName,partitionName=partitionName).replace('\t'," ").replace('\n'," ")
            hasPartition = self.db.Execute(connOpt,query)
            if hasPartition and hasPartition[0]['HasPartition'] == 1:
                return True;
            return False;
        except Exception as ex:
            raise Exception(("CheckPartitionExistByName",ex,database,tableName,partitionName))

    def CheckSchemaTableSync(self,connOpt, database, tableName, tempTableName):
        try:
            query =  '''SELECT IF(COUNT(1)>0,0,1) AS Synced 
                        FROM (SELECT column_name,ordinal_position, data_type,column_type,COUNT(1) rowcount 
                              FROM information_schema.columns
                              WHERE  (TABLE_CATALOG = "def" AND table_schema="{database}" AND table_name="{tableName}")
                                  OR (TABLE_CATALOG = "def" AND table_schema="{database}" AND table_name="{tempTableName}")
                              GROUP BY column_name,ordinal_position,data_type,column_type
                              HAVING COUNT(1)=1
                        ) AS tbl;'''.format(database=database,tableName=tableName,tempTableName=tempTableName).replace('\t'," ").replace('\n'," ")
            synced = self.db.Execute(connOpt,query)

            if synced and synced[0]['Synced'] == 1:
                return True;
            return False;
        except Exception as ex:
            raise Exception(("CheckSchemaTableSync",ex, database, tableName, tempTableName)) 
    
    def GetDefineTable(self,connOpt,database,table):
        try:
            strSchema = self.db.Execute(connOpt,'SHOW CREATE TABLE ' + database + "." + table)
            return strSchema[0]['Create Table'];  
        except Exception as ex:
            raise Exception(("GetDefineTable",ex,database,table)) 

    def CreateArchiveTableTemp(self,connOpt,queryText,database,tableName):
        try:
            self.db.Execute(connOpt,queryText)
            query =  '''ALTER TABLE {database}.{tableName} REMOVE PARTITIONING;
                        ALTER TABLE {database}.{tableName} DISCARD TABLESPACE;'''.format(database=database,tableName=tableName).replace('\t'," ").replace('\n'," ")
            self.db.Execute(connOpt,query)            
        except Exception as ex:
            raise Exception(("CreateArchiveTableTemp",ex,queryText,database,tableName)) 

    def CopyPartitionToDes(self,sourceSSHOpt,sourceDBPath, sourceDatabase,sourceTable,desSSHOpt,desContainerName,desDBPath,desDataFileOwner,desDatabase,desTable,partitionName,partitionDelimiter):
        try:
            
            partitionSourcePath = '''{sourceDBPath}/{sourceDatabase}/{sourceTable}{partitionDelimiter}{partitionName}.ibd'''.format(sourceDBPath=sourceDBPath,sourceDatabase=sourceDatabase,sourceTable=sourceTable,partitionDelimiter=partitionDelimiter,partitionName=partitionName)
            partitionDesPath = '''{desDBPath}/{desDatabase}/{desTable}.ibd'''.format(desDBPath=desDBPath,desDatabase=desDatabase,desTable=desTable)
            partitionLocalPath = '''archivepartitionfiles/{desTable}.ibd'''.format(desTable=desTable)
            cmdChmod = '''docker exec {desContainerName} chmod 660 /var/lib/mysql/{desDatabase}/{desTable}.ibd'''.format(desContainerName=desContainerName,desDatabase=desDatabase,desTable=desTable)
            cmdChown = '''docker exec {desContainerName} chown mysql.mysql /var/lib/mysql/{desDatabase}/{desTable}.ibd'''.format(desContainerName=desContainerName,desDatabase=desDatabase,desTable=desTable)

            self.ssh.SCP_GetFile(sourceSSHOpt,partitionSourcePath,partitionLocalPath)
            self.ssh.SCP_UpFile(desSSHOpt,partitionLocalPath,partitionDesPath)

            self.ssh.Exec_Command(desSSHOpt,cmdChmod)
            self.ssh.Exec_Command(desSSHOpt,cmdChown)

            if os.path.exists(partitionLocalPath):
                os.remove(partitionLocalPath)

        except Exception as ex:
            raise Exception(("CopyPartitionToDes",ex,sourceDBPath, sourceDatabase,sourceTable,desContainerName,desDBPath,desDataFileOwner,desDatabase,desTable,partitionName,partitionDelimiter)) 

    def ImportPartition(self,connOpt,table):
        try:
            query = '''ALTER TABLE {table} IMPORT TABLESPACE;'''.format(table=table).replace('\n'," ")
            self.db.Execute(connOpt,query);
        except Exception as ex:
            raise Exception(("ImportPartition",ex,table)) 
    
    def SyncIndex(self,connOpt,desDatabase, desTable,tempTable):
        try:
            query =  '''WITH CTE_Index AS (
                        SELECT DISTINCT INDEX_NAME
                        FROM INFORMATION_SCHEMA.STATISTICS AS sourc
                        WHERE sourc.TABLE_CATALOG = "def"
                            AND sourc.TABLE_SCHEMA = "{desDatabase}"
                            AND sourc.TABLE_NAME = "{tempTable}"
                            AND sourc.INDEX_NAME != "PRIMARY"
                            AND NOT EXISTS(SELECT *
                                        FROM INFORMATION_SCHEMA.STATISTICS AS des
                                        WHERE des.TABLE_CATALOG = "def"
                                                AND des.TABLE_SCHEMA = "{desDatabase}"
                                                AND des.TABLE_NAME = "{desTable}"
                                                AND des.INDEX_NAME = sourc.INDEX_NAME)
                        )
                        SELECT GROUP_CONCAT(CONCAT("ALTER TABLE ", "{tempTable}", " DROP INDEX ", INDEX_NAME,";") SEPARATOR " " ) AS Script
                        FROM CTE_Index;
                    '''.format(tempTable=tempTable,desDatabase=desDatabase,desTable=desTable).replace('\t'," ").replace('\n'," ")
            scrpt = self.db.Execute(connOpt,query);

            if scrpt[0]['Script']:
                self.db.Execute(connOpt,scrpt[0]['Script'])
        except Exception as ex:
            raise Exception(("SyncIndex",ex,desDatabase, desTable,tempTable)) 
    
    def CheckIndexSync(self,connOpt,desDatabase, desTable,tempDatabase,tempTable):
        try:
            query =  '''SELECT IF(COUNT(1)>0,0,1) AS Synced
                        FROM INFORMATION_SCHEMA.STATISTICS AS sourc
                        WHERE sourc.TABLE_CATALOG = "def"
                            AND sourc.TABLE_SCHEMA = "{desDatabase}"
                            AND sourc.TABLE_NAME = "{desTable}"
                            AND sourc.INDEX_NAME != "PRIMARY"
                            AND NOT EXISTS(SELECT *
                                           FROM INFORMATION_SCHEMA.STATISTICS AS des
                                           WHERE des.TABLE_CATALOG = "def"
                                                AND des.TABLE_SCHEMA = "{tempDatabase}"
                                                AND des.TABLE_NAME = "{tempTable}"
                                                AND des.INDEX_NAME = sourc.INDEX_NAME);
                    '''.format(tempDatabase=tempDatabase,tempTable=tempTable,desDatabase=desDatabase,desTable=desTable).replace('\t'," ").replace('\n'," ")
            synced = self.db.Execute(connOpt,query);

            if synced and synced[0]['Synced'] == 1:
                return True;
            return False;
        except Exception as ex:
            raise Exception(("CheckIndexSync",ex,desDatabase, desTable,tempDatabase,tempTable)) 

    def ReorganizePartiton(self,configOjb,tableName,partitionName,partitionDes,partitionMax):
        try:
            query =  '''ALTER TABLE {tableName}
                        REORGANIZE PARTITION {partitionMax} INTO ( 
                        PARTITION {partitionName} VALUES LESS THAN ({partitionDes}), 
                        PARTITION {partitionMax} VALUES LESS THAN (MAXVALUE)
                );'''.format(tableName=tableName,partitionName=partitionName,partitionDes=partitionDes,partitionMax=partitionMax).replace('\t'," ").replace('\n'," ")
            self.db.Execute(configOjb,query);
        except Exception as ex:
            raise Exception(("ReorganizePartiton",ex,tableName,partitionName,partitionDes))
    
    def ExchangePartiton(self,configOjb,tableName,partitionName,tableTemp):
        try:
            query = '''ALTER TABLE {tableName} EXCHANGE PARTITION {partitionName} WITH TABLE {tableTemp};
                    '''.format(tableName=tableName,partitionName=partitionName,tableTemp=tableTemp).replace('\t'," ").replace('\n'," ")
            self.db.Execute(configOjb,query);
        except Exception as ex:
            raise Exception(("ExchangePartiton",ex,tableName,partitionName))

    def FlushTable(self,configOjb,tableName):
        try:
            query = '''FLUSH TABLES {tableName} FOR EXPORT; UNLOCK TABLES;
                    '''.format(tableName=tableName).replace('\t'," ").replace('\n'," ")
            self.db.Execute(configOjb,query);
        except Exception as ex:
            raise Exception(("FlushTable",ex,tableName))

    def DropPartiton(self,configOjb,tableName,partitionName):
        try:
            query = '''ALTER TABLE {tableName} DROP PARTITION {partitionName};
                    '''.format(tableName=tableName,partitionName=partitionName).replace('\t'," ").replace('\n'," ")
            self.db.Execute(configOjb,query);
        except Exception as ex:
            raise Exception(("DropPartiton",ex,(ex,tableName,partitionName)))
    
    def DropTable(self,configOjb,tableName):
        try:
            query = '''DROP TABLE {tableName};'''.format(tableName=tableName).replace('\t'," ").replace('\n'," ")
            self.db.Execute(configOjb,query);
        except Exception as ex:
            raise Exception(("DropTable",ex,(ex,tableName)))

    def UpdateServerStatus(self,serverID, status):
        try:
            if serverID > 0:
                query = '''Update MonDB.MysqlServer Set DBATaskStatus = "{status}" WHERE ID = {serverID};'''.format(status=status,serverID=serverID)
                self.db.Execute(self.connArchiveOpt,query);
        except Exception as ex:
            raise Exception(("UpdateServerStatus",ex,(ex,serverID,status)))

    def UpdateLastExecuted(self,jobID, date):
        try:
            if date and jobID:
                query = '''Update MonDB.ArchivePartitionJob Set LastExecuted = "{date}" WHERE ID = {jobID};'''.format(jobID=jobID,date=date)
                self.db.Execute(self.connArchiveOpt,query);
        except Exception as ex:
            raise Exception(("UpdateLastExecuted",ex,(ex,jobID,date)))
    
    def UpdateDropPartitionLastExecuted(self,jobID, date):
        try:
            if date and jobID:
                query = '''Update MonDB.DropPartitionJob Set LastExecuted = "{date}" WHERE ID = {jobID};'''.format(jobID=jobID,date=date)
                self.db.Execute(self.connArchiveOpt,query);
        except Exception as ex:
            raise Exception(("UpdateDropPartitionLastExecuted",ex,(ex,jobID,date)))
    
    def UpdateReOrganizePartitionLastExecuted(self,jobID, date):
        try:
            if date and jobID:
                query = '''Update MonDB.ReOrganizePartitionJob Set LastExecuted = "{date}" WHERE ID = {jobID};'''.format(jobID=jobID,date=date)
                self.db.Execute(self.connArchiveOpt,query);
        except Exception as ex:
            raise Exception(("UpdateReOrganizePartitionLastExecuted",ex,(ex,jobID,date)))
    
    def UpdateSlowLogLastExecuted(self,jobID, date):
        try:
            if date and jobID:
                query = '''Update MonDB.SlowLogJob Set LastExecuted = "{date}" WHERE ID = {jobID};'''.format(jobID=jobID,date=date)
                self.db.Execute(self.connArchiveOpt,query);
        except Exception as ex:
            raise Exception(("UpdateSlowLogLastExecuted",ex,(ex,jobID,date)))
    
    def UpdateFragmentationTableLastExecuted(self,jobID, date):
        try:
            if date and jobID:
                query = '''Update MonDB.FragmentationTableJob Set LastExecuted = "{date}" WHERE ID = {jobID};'''.format(jobID=jobID,date=date)
                self.db.Execute(self.connArchiveOpt,query);
        except Exception as ex:
            raise Exception(("UpdateFragmentationTableLastExecuted",ex,(ex,jobID,date)))


    def ArchivePartition(self,configOjb):
        try:
            tempTableName = configOjb['Source_Table'] + self.tempTablePrefix;
            
            notificationMetaDataStr = configOjb['NotificationMetaData']
            notificationMetaData = json.loads(notificationMetaDataStr)

            sourceMysqlOpt = {
                "host": configOjb['Source_ServerIP'],
                "user": configOjb['Source_MysqlUser'], 
                "password": configOjb['Source_MysqlPassword'],
                "db": configOjb['Source_Database'],
                "port": configOjb['Source_ServerPort']
            }

            sourceMasterMysqlOpt = {
                "host": configOjb['SourceMaster_ServerIP'],
                "user": configOjb['SourceMaster_MysqlUser'], 
                "password": configOjb['SourceMaster_MysqlPassword'],
                "db": configOjb['Source_Database'],
                "port": configOjb['SourceMaster_ServerPort']
            }

            sourceSSHOpt = {
                "serverIP": configOjb['Source_ServerIP'],
                "user": configOjb['Source_SSHUser'], 
                "keyFile": configOjb['Source_SSHKey_File'],
            }

            desMysqlOpt = {
                "host": configOjb['Des_ServerIP'],
                "user": configOjb['Des_MysqlUser'], 
                "password": configOjb['Des_MysqlPassword'],
                "db": configOjb['Des_Database'],
                "port": configOjb['Des_ServerPort']
            }

            desSSHOpt = {
                "serverIP": configOjb['Des_ServerIP'],
                "user": configOjb['Des_SSHUser'], 
                "keyFile": configOjb['Des_SSHKey_File'],
            }

            self.telegramOpt = {
                "token": notificationMetaData['token'],
                "chat_id": notificationMetaData['chat_id']
            }

            self.UpdateServerStatus(configOjb['Source_ServerID'],"Archiving - Running")
            self.UpdateServerStatus(configOjb['Des_ServerID'],"Archiving - Running")

            messText ='''<b>Archiving Partition Data</b>\n\nSource Server: {sourceServer}\nSource Table: {sourceDatabase}.{sourceTable}\n\nDestination Server: {desServer}\nDestination Table: {desDatabase}.{desTable}\n\nPartition Name: {partitionName}\n\nStatus: <b>Running</b>'''.format(sourceServer=configOjb['Source_ServerName'],
                                                        sourceDatabase=configOjb['Source_Database'],
                                                        sourceTable=configOjb['Source_Table'],

                                                        desServer=configOjb['Des_ServerName'],
                                                        desDatabase=configOjb['Des_Database'],
                                                        desTable=configOjb['Des_Table'],
                                                        
                                                        partitionName=configOjb['PartitionName'])
            self.tele.SendTelegramMessage(self.telegramOpt,messText);
            #Check source partition exist
            partition_info = self.CheckPartitionExist(sourceMysqlOpt, configOjb['Source_Database'],configOjb['Source_Table'], configOjb['KeepDataRange']);
            if partition_info[0] == False:
                raise Exception("Source partition isn't exist")
            partitionName = partition_info[1];
            partitionDes = partition_info[2];
            partitionRow = partition_info[3];

            #Check des partition isn't exist
            if self.CheckPartitionExist(desMysqlOpt, configOjb['Des_Database'],configOjb['Des_Table'], configOjb['KeepDataRange'])[0] == True:
                raise Exception("Des partition is exist")

            strSchema = self.GetDefineTable(sourceMysqlOpt,configOjb['Source_Database'], configOjb['Source_Table'])
            strSchema = strSchema.replace(configOjb['Source_Table'], tempTableName,1)
            self.CreateArchiveTableTemp(desMysqlOpt,strSchema,configOjb['Des_Database'],tempTableName)
            
            if self.CheckSchemaTableSync(desMysqlOpt,configOjb['Des_Database'], configOjb['Des_Table'],tempTableName) == False:
                raise Exception("Source and Des schemas aren't sync")

            self.FlushTable(sourceMysqlOpt,configOjb['Source_Table'])

            self.CopyPartitionToDes(sourceSSHOpt,
                                    configOjb['Source_DataPath'],
                                    configOjb['Source_Database'],
                                    configOjb['Source_Table'],

                                    desSSHOpt, 
                                    configOjb['Des_ContainerName'],
                                    configOjb['Des_DataPath'],
                                    configOjb['Des_DataFileOwner'],
                                    configOjb['Des_Database'],
                                    tempTableName,

                                    partitionName,
                                    configOjb['PartitionDelimiter'])
            
            self.ImportPartition(desMysqlOpt,tempTableName)

            if self.CheckIndexSync(desMysqlOpt,configOjb['Des_Database'], configOjb['Des_Table'],configOjb['Des_Database'],tempTableName) == False:
                raise Exception("Source and Des index aren't sync")

            self.SyncIndex(desMysqlOpt,configOjb['Des_Database'], configOjb['Des_Table'],tempTableName)

            self.ReorganizePartiton(desMysqlOpt,configOjb['Des_Table'],partitionName,partitionDes,configOjb['PartitionMax'])

            self.ExchangePartiton(desMysqlOpt,configOjb['Des_Table'],partitionName,tempTableName)
            
            self.DropTable(desMysqlOpt,tempTableName)

            if configOjb['HasDropPartitionSourceTable'] == 1:
                self.DropPartiton(sourceMasterMysqlOpt,configOjb['Source_Table'],partitionName)
            
            self.UpdateServerStatus(configOjb['Source_ServerID'],"None")
            self.UpdateServerStatus(configOjb['Des_ServerID'],"None")
            self.UpdateLastExecuted(configOjb['JobID'],configOjb['CurrentDate'])

            messText ='''<b>Archiving Partition Data</b>\n\nSource Server: {sourceServer}\nSource Table: {sourceDatabase}.{sourceTable}\n\nDestination Server: {desServer}\nDestination Table: {desDatabase}.{desTable}\n\nPartition Name: {partitionName}\nPartition Total Row: {partitionRow}\n\n\nStatus: <b>Processed</b>'''.format(sourceServer=configOjb['Source_ServerName'],
                                                        sourceDatabase=configOjb['Source_Database'],
                                                        sourceTable=configOjb['Source_Table'],

                                                        desServer=configOjb['Des_ServerName'],
                                                        desDatabase=configOjb['Des_Database'],
                                                        desTable=configOjb['Des_Table'],
                                                        
                                                        partitionName=partitionName,
                                                        partitionRow=partitionRow)
            self.tele.SendTelegramMessage(self.telegramOpt,messText);

        except Exception as ex:
            self.WriteLog(("ArchivePartition",ex))

    def ArchiveJob(self,runType):
        configs = self.GetArchiveConfig(runType)
        for config in configs[0]:
            self.ArchivePartition(config)

    def DropPartitionByConfig(self,configOjb):
        try:
            notificationMetaDataStr = configOjb['NotificationMetaData']
            notificationMetaData = json.loads(notificationMetaDataStr)

            mysqlOpt = {
                "host": configOjb['ServerIP'],
                "user": configOjb['MysqlUser'], 
                "password": configOjb['MysqlPassword'],
                "db": configOjb['Database'],
                "port": configOjb['ServerPort']
            }

            self.telegramOpt = {
                "token": notificationMetaData['token'],
                "chat_id": notificationMetaData['chat_id']
            }
            messText ='''<b>Drop Partition</b>\n\nServer: {server}\nTable: {database}.{table}\nPartition Name: {partitionName} {partitionDate}\n\nStatus: '''.format(server=configOjb['ServerName'],
                                                        database=configOjb['Database'],
                                                        table=configOjb['Table'],

                                                        partitionName=configOjb['PartitionName'],
                                                        partitionDate=configOjb['PartitionDate'])

            self.UpdateServerStatus(configOjb['ServerID'],"Drop Partition - Running")

            #Check source partition exist
            partition_info = self.CheckPartitionExistByName(mysqlOpt, configOjb['Database'],configOjb['Table'], configOjb['PartitionName']);
            if partition_info == False:
                messText = messText + "<b>Partition isn't exist</b>"
                self.UpdateServerStatus(configOjb['ServerID'],"None")
                self.UpdateDropPartitionLastExecuted(configOjb['JobID'],configOjb['CurrentDate'])
                self.tele.SendTelegramMessage(self.telegramOpt,messText);
                return

            self.DropPartiton(mysqlOpt,configOjb['Table'],configOjb['PartitionName'])
            
            self.UpdateServerStatus(configOjb['ServerID'],"None")

            self.UpdateDropPartitionLastExecuted(configOjb['JobID'],configOjb['CurrentDate'])

            messText = messText +  "<b>Processed</b>"

            self.tele.SendTelegramMessage(self.telegramOpt,messText);

        except Exception as ex:
            self.WriteLog(("DropPartitionByConfig",ex))

    def DropPartitionJob(self):
        configs = self.GetDropPartitionConfig()
        for config in configs[0]:
            self.DropPartitionByConfig(config)

    def ReOrganizePartitionByConfig(self,configOjb):
        try:
            notificationMetaDataStr = configOjb['NotificationMetaData']
            notificationMetaData = json.loads(notificationMetaDataStr)

            mysqlOpt = {
                "host": configOjb['ServerIP'],
                "user": configOjb['MysqlUser'], 
                "password": configOjb['MysqlPassword'],
                "db": configOjb['Database'],
                "port": configOjb['ServerPort']
            }

            self.telegramOpt = {
                "token": notificationMetaData['token'],
                "chat_id": notificationMetaData['chat_id']
            }
            messText ='''<b>ReOrganizePartition Partition</b>\n\nServer: {server}\nTable: {database}.{table}\nPartition Name: {partitionName} {partitionDate}\n\nStatus: '''.format(server=configOjb['ServerName'],
                                                        database=configOjb['Database'],
                                                        table=configOjb['Table'],

                                                        partitionName=configOjb['PartitionName'],
                                                        partitionDate=configOjb['PartitionDate'])

            self.UpdateServerStatus(configOjb['ServerID'],"ReOrganizePartition Partition - Running")

            #Check source partition exist
            partition_info = self.CheckPartitionExistByName(mysqlOpt, configOjb['Database'],configOjb['Table'], configOjb['PartitionName']);
            if partition_info == True:
                messText = messText + "<b>Partition existed</b>"
                self.UpdateServerStatus(configOjb['ServerID'],"None")
                self.UpdateReOrganizePartitionLastExecuted(configOjb['JobID'],configOjb['CurrentDate'])
                self.tele.SendTelegramMessage(self.telegramOpt,messText);
                return

            self.ReorganizePartiton(mysqlOpt,configOjb['Table'],configOjb['PartitionName'],configOjb['PartitionDes'],configOjb['PartitionMax'])
            
            self.UpdateServerStatus(configOjb['ServerID'],"None")

            self.UpdateReOrganizePartitionLastExecuted(configOjb['JobID'],configOjb['CurrentDate'])
            
            messText = messText +  "<b>Processed</b>"

            self.tele.SendTelegramMessage(self.telegramOpt,messText);

        except Exception as ex:
            self.WriteLog(("ReOrganizePartitionByConfig",ex))

    def ReOrganizePartitionJob(self):
        configs = self.GetReOrganizePartitionConfig()
        for config in configs[0]:
            self.ReOrganizePartitionByConfig(config)

    def GetSlowLog(self,connOpt):
        try:
            query = 'SELECT Start_Time,User_Host,Query_Time,Lock_Time,Rows_Sent,Rows_Examined,DB,Last_Insert_ID,Insert_ID,Server_ID,Sql_Text,Thread_ID FROM mysql.slow_log;'
            data = self.db.Execute(connOpt,query)
            return json.dumps(data, indent=4, sort_keys=True, default=str)
        except Exception as ex:
            raise Exception(("GetSlowLog",ex))

    def InsertSlowLog(self,logs,serverID):
        try:
            self.db.Call_SP(self.connArchiveOpt,'DBA_SlowLog_Insert',(logs,serverID,))
        except Exception as ex:
            raise Exception(("InsertSlowLog",ex))

    def TruncateSlowLog(self,connOpt):
        try:
            query = 'SET sql_log_bin = OFF;truncate table mysql.slow_log;'
            self.db.Execute(connOpt,query)
        except Exception as ex:
            raise Exception(("TruncateSlowLog",ex))

    def ArchiveSlowLog(self,configOjb):
        try:
            notificationMetaDataStr = configOjb['NotificationMetaData']
            notificationMetaData = json.loads(notificationMetaDataStr)

            mysqlOpt = {
                "host": configOjb['ServerIP'],
                "user": configOjb['MysqlUser'], 
                "password": configOjb['MysqlPassword'],
                "db": "mysql",
                "port": configOjb['ServerPort']
            }

            self.telegramOpt = {
                "token": notificationMetaData['token'],
                "chat_id": notificationMetaData['chat_id']
            }


            self.UpdateServerStatus(configOjb['ServerID'],"Move Slow Log - Running")

            dataLogs = self.GetSlowLog(mysqlOpt)

            self.InsertSlowLog(dataLogs,configOjb['ServerID'])

            self.TruncateSlowLog(mysqlOpt)
            
            self.UpdateServerStatus(configOjb['ServerID'],"None")

            self.UpdateSlowLogLastExecuted(configOjb['JobID'],configOjb['CurrentDate'])

        except Exception as ex:
            self.WriteLog(("ArchiveSlowLog",ex))

    def SlowLogJob(self):
        configs = self.GetSlowLogConfig()
        for config in configs[0]:
            self.ArchiveSlowLog(config)
    
    def RebuildTable(self,connOpt,tableName):
        try:
            query =  '''ALTER TABLE {tableName} ENGINE=INNODB;'''.format(tableName=tableName)
            self.db.Execute(connOpt,query);
        except Exception as ex:
            raise Exception(("RebuildTable",ex,tableName))

    def FragmentationTable(self,configOjb):
        try:
            notificationMetaDataStr = configOjb['NotificationMetaData']
            notificationMetaData = json.loads(notificationMetaDataStr)

            mysqlOpt = {
                "host": configOjb['ServerIP'],
                "user": configOjb['MysqlUser'], 
                "password": configOjb['MysqlPassword'],
                "db": configOjb['Database'],
                "port": configOjb['ServerPort']
            }

            self.telegramOpt = {
                "token": notificationMetaData['token'],
                "chat_id": notificationMetaData['chat_id']
            }

            self.UpdateServerStatus(configOjb['ServerID'],"Rebuild Table - Running")

            self.RebuildTable(mysqlOpt,configOjb['TableName'])

            self.UpdateServerStatus(configOjb['ServerID'],"None")

            self.UpdateFragmentationTableLastExecuted(configOjb['JobID'],configOjb['CurrentDate'])
        except Exception as ex:
            self.WriteLog(("DropPartitionByConfig",ex))

    def FragmentationTableJob(self):
        configs = self.GetFragmentationTableConfig()
        for config in configs[0]:
            self.FragmentationTable(config)

    def close(self):
        self.db.close()
        self.ssh.close()
        self.tele.close()
