import json
from unittest import result
from db.dbHelper import DBHandler
from datetime import  datetime, timezone, timedelta
from config import config
from message.messHelper import MessageHelper
from ssh.sshHelper import SSHHandler
from pathlib import Path
import string    
import random    
import os
import shutil

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
        mess = '''<b>DB Task Error</b>\n{text}'''.format(text=text)
        self.tele.SendTelegramMessage(self.telegramOpt,mess);

    def RandomStr(self,number):  
        ran = ''.join(random.choices(string.ascii_uppercase + string.digits, k = number))    
        return str(ran)

    def sizeof_fmt(self,num, suffix="B"):
        for unit in ["", "K", "M", "G", "T", "P", "E", "Z"]:
            if abs(num) < 1024.0:
                return f"{num:3.1f}{unit}{suffix}"
            num /= 1024.0
        return f"{num:.1f}Yi{suffix}"

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
            partitionLocalPath = '''/var/cts/monitor/archivepartitionfiles/{desTable}.ibd'''.format(desTable=desTable)
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
            query = 'truncate table mysql.slow_log;'
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

    def GetHealthCheckStorageConfig(self):
        try:
            listConfig = self.db.Call_SP(self.connArchiveOpt,'DBA_HealthCheck_Storage_Get',())
            return listConfig;  
        except Exception as ex:
            raise Exception(("GetHealthCheckStorageConfig",ex))

    
    def CheckAlertCached(self,serverID,type,threadID,isAlert):
        try:
            isCached = self.db.Call_SP(self.connArchiveOpt,'DBA_Alert_Cached_Check',(serverID,type,threadID,isAlert))
            if isCached[0][0]['IsCached'] == 1:
                return True;
            return False;
        except Exception as ex:
            raise Exception(("CheckAlertCached",ex)) 

    def HealthCheckStorage(self,configOjb):
        try:
            notificationMetaDataStr = configOjb['NotificationMetaData']
            notificationMetaData = json.loads(notificationMetaDataStr)

            self.telegramOpt = {
                "token": notificationMetaData['token'],
                "chat_id": notificationMetaData['chat_id']
            }

            sshOpt = {
                "serverIP": configOjb['ServerIP'],
                "user": configOjb['SSHUser'], 
                "keyFile": configOjb['SSHKey_File'],
            }

            command = '''df -h {filesystem} --output=size,avail,used,pcent | tail -1 | awk '{op}print $1"|"$2"|"$3"|"$4{cl}' '''.format(filesystem=configOjb['FileSystem'],op="{",cl="}")

            result = self.ssh.Exec_Command(sshOpt,command)

            resultArr = result.split("|")

            size = resultArr[0]
            avail = resultArr[1]
            used = resultArr[2]
            pcent =  int(resultArr[3].replace("%", ""))
            threshold = int(configOjb['Threshold'])

            messText ='''<b>Disk Usage Alert</b>\nServer Name: {serverName} - {serverIP}\nDisk Size: {size}\nDisk Avail: {avail}\nDisk Used: {used}\nMessage: Disk Usage was over {pcent}%'''.format(serverName=configOjb['ServerName'],
                                                                serverIP=configOjb['ServerIP'],
                                                                size=size,
                                                                avail=avail,
                                                                used=used,
                                                                pcent=pcent)

            if pcent >= threshold:
                isCached = self.CheckAlertCached(configOjb['ServerID'],'HealthCheckStorage', 0, 1);
                if isCached == False:
                    self.UpdateServerStatus(configOjb['ServerID'],"HealthCheckStorage - Alerting")
                    self.tele.SendTelegramMessage(self.telegramOpt,messText);
                return;

            self.CheckAlertCached(configOjb['ServerID'],'HealthCheckStorage', 0, 0);
        except Exception as ex:
            self.WriteLog(("HealthCheckStorage",ex))

    def HealthCheckStorageJob(self):
        configs = self.GetHealthCheckStorageConfig()
        for config in configs[0]:
            self.HealthCheckStorage(config)
    
    def GetHealthCheckMemoryConfig(self):
        try:
            listConfig = self.db.Call_SP(self.connArchiveOpt,'DBA_HealthCheck_Memory_Get',())
            return listConfig;  
        except Exception as ex:
            raise Exception(("GetHealthCheckMemoryConfig",ex))

    def HealthCheckMemory(self,configOjb):
        try:
            notificationMetaDataStr = configOjb['NotificationMetaData']
            notificationMetaData = json.loads(notificationMetaDataStr)

            self.telegramOpt = {
                "token": notificationMetaData['token'],
                "chat_id": notificationMetaData['chat_id']
            }

            sshOpt = {
                "serverIP": configOjb['ServerIP'],
                "user": configOjb['SSHUser'], 
                "keyFile": configOjb['SSHKey_File'],
            }


            commandMem = '''free | awk '{op}print $2"|"$3{clo}' '''.format(op="/^Mem:/{",clo="}")
            commandSwap = '''free | awk '{op}print $2"|"$3{clo}' '''.format(op="/^Swap:/{",clo="}")

            resultMem = self.ssh.Exec_Command(sshOpt,commandMem)
            resultSwap = self.ssh.Exec_Command(sshOpt,commandSwap)

            resultMemArr = resultMem.split("|")
            resultSwapArr = resultSwap.split("|")

            sizeMem = int(resultMemArr[0])
            usedMem = int(resultMemArr[1])

            sizeSwap = int(resultSwapArr[0])
            usedSwap = int(resultSwapArr[1])

            threshold = int(configOjb['Threshold'])

            pcent= ((usedMem + usedSwap)/(sizeMem + sizeSwap))*100;

            messText ='''<b>Memory Usage Alert</b>\nServer Name: {serverName} - {serverIP}\nMem Size: {sizeMem}\nMem Used: {usedMem}\nSwap Size: {sizeSwap}\nSwap Used: {usedSwap}\nMessage: Memory Usage was over {pcent}%'''.format(serverName=configOjb['ServerName'],
                                                                serverIP=configOjb['ServerIP'],
                                                                sizeMem= self.sizeof_fmt(sizeMem),
                                                                usedMem= self.sizeof_fmt(usedMem),
                                                                sizeSwap= self.sizeof_fmt(sizeSwap),
                                                                usedSwap= self.sizeof_fmt(usedSwap),
                                                                pcent=round(pcent,0))

            if pcent >= threshold:
                isCached = self.CheckAlertCached(configOjb['ServerID'],'HealthCheckMemory', 0, 1);
                if isCached == False:
                    self.UpdateServerStatus(configOjb['ServerID'],"HealthCheckMemory - Alerting")
                    self.tele.SendTelegramMessage(self.telegramOpt,messText);
                return;

            self.CheckAlertCached(configOjb['ServerID'],'HealthCheckMemory', 0, 0);
        except Exception as ex:
            self.WriteLog(("HealthCheckMemory",ex))
            
    def HealthCheckMemoryJob(self):
        configs = self.GetHealthCheckMemoryConfig()
        for config in configs[0]:
            self.HealthCheckMemory(config)
    
    def GetHealthCheckReplicationConfig(self):
        try:
            listConfig = self.db.Call_SP(self.connArchiveOpt,'DBA_HealthCheck_Replication_Get',())
            return listConfig;  
        except Exception as ex:
            raise Exception(("GetHealthCheckReplicationConfig",ex))

    def CheckReplicationStatus(self,mysqlOpt):
        try:
            errorConnection = None
            errorCoordinator = None
            errorWorker = None
            query = '''SELECT IFNULL((SELECT TIMESTAMPDIFF(MINUTE,LAST_PROCESSED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP, LAST_PROCESSED_TRANSACTION_END_BUFFER_TIMESTAMP) FROM performance_schema.replication_applier_status_by_coordinator LIMIT 1),0) AS DelayMinute;'''
            queryResult = self.db.Execute(mysqlOpt,query)
            delayMinute = queryResult[0]['DelayMinute']


            query = '''SELECT (SELECT LAST_ERROR_MESSAGE  FROM performance_schema.replication_connection_status WHERE SERVICE_STATE != 'ON' LIMIT 1) AS Error_Connection
	                ,  (SELECT LAST_ERROR_MESSAGE  FROM performance_schema.replication_applier_status_by_coordinator WHERE SERVICE_STATE != 'ON' LIMIT 1) AS Error_Coordinator
                    ,  (SELECT LAST_ERROR_MESSAGE  FROM performance_schema.replication_applier_status_by_worker WHERE SERVICE_STATE != 'ON' LIMIT 1) AS Error_Worker;'''

            queryResult = self.db.Execute(mysqlOpt,query)

            errorConnection = queryResult[0]['Error_Connection']
            errorCoordinator = queryResult[0]['Error_Coordinator']
            errorWorker = queryResult[0]['Error_Worker']
            
            return (delayMinute,errorConnection,errorCoordinator,errorWorker)

        except Exception as ex:
            raise Exception(("CheckReplicationStatus",ex,(ex)))


    def HealthCheckReplication(self,configOjb):
        try:
            notificationMetaDataStr = configOjb['NotificationMetaData']
            notificationMetaData = json.loads(notificationMetaDataStr)

            self.telegramOpt = {
                "token": notificationMetaData['token'],
                "chat_id": notificationMetaData['chat_id']
            }

            mysqlOpt = {
                "host": configOjb['ServerIP'],
                "user": configOjb['MysqlUser'], 
                "password": configOjb['MysqlPassword'],
                "db": 'performance_schema',
                "port": configOjb['ServerPort']
            }


            status  = self.CheckReplicationStatus(mysqlOpt)
            threshold = int(configOjb['Threshold'])
            
            error = None
            if status[1]:
                error = status[1]
            elif status[2]:
                error = status[2]
            elif status[3]:
                error = status[3]

            messText ='''<b>Replication Delay</b>\nServer Name: {serverName} - {serverIP}\nMessage: Delay was over {delayMintute}min'''.format(serverName=configOjb['ServerName'],
                                                                serverIP=configOjb['ServerIP'],
                                                                delayMintute=status[0])
            
            messError ='''<b>Replication Error</b>\nServer Name: {serverName} - {serverIP}\nMessage: {error}'''.format(serverName=configOjb['ServerName'],
                                                                serverIP=configOjb['ServerIP'],
                                                                error=error)
            
            if error:
                isCached = self.CheckAlertCached(configOjb['ServerID'],'HealthCheckReplication', 0, 1);
                if isCached == False:
                    self.UpdateServerStatus(configOjb['ServerID'],"HealthCheckReplication - Alerting")
                    self.tele.SendTelegramMessage(self.telegramOpt,messError);
                return
                
            if status[0] >= threshold:
                isCached = self.CheckAlertCached(configOjb['ServerID'],'HealthCheckReplication', 0, 1);
                if isCached == False:
                    self.UpdateServerStatus(configOjb['ServerID'],"HealthCheckReplication - Alerting")
                    self.tele.SendTelegramMessage(self.telegramOpt,messText);
                return
            
            

            self.CheckAlertCached(configOjb['ServerID'],'HealthCheckReplication', 0, 0);
        except Exception as ex:
            self.WriteLog(("HealthCheckReplication",ex))

    def HealthCheckReplicationJob(self):
        configs = self.GetHealthCheckReplicationConfig()
        for config in configs[0]:
            self.HealthCheckReplication(config)

    def CheckBigQueryConfig(self):
        try:
            listConfig = self.db.Call_SP(self.connArchiveOpt,'DBA_HealthCheck_BigQuery_Get',())
            return listConfig;  
        except Exception as ex:
            raise Exception(("CheckBigQueryConfig",ex))

    def CheckQueryRunning(self,mysqlOpt,threshold,thresholdApp,thresholdRowLocked):
        try:
            query = '''SELECT  trx.trx_mysql_thread_id AS 'ThreadID'
                        ,	TIMESTAMPDIFF(SECOND, trx.trx_started, NOW()) AS 'Latency'
                        ,	trx.trx_tables_locked AS 'Table Locked'
                        ,	trx.trx_rows_locked AS 'Row Locked'
                        ,	trx.trx_rows_modified AS 'Row Modified'
                        ,	(SELECT sta.DIGEST_TEXT FROM performance_schema.events_statements_current AS sta WHERE sta.THREAD_ID = thd.THREAD_ID AND EVENT_NAME = 'statement/sql/call_procedure') AS SPName
                        ,	CASE	WHEN trx.trx_query IS NOT NULL  THEN trx.trx_query ELSE thd.PROCESSLIST_INFO END AS 	'Query' 
                        ,	trx.trx_state AS 'Tran State'
                        ,	thd.PROCESSLIST_STATE AS 'Thread State'
                        ,	trx.trx_started AS 'Start Time'
                        ,	thd.PROCESSLIST_USER AS 'User'
                        ,   thd.PROCESSLIST_HOST AS 'Host'
                        ,	trx.trx_isolation_level AS 'Isolation'
                    FROM  INFORMATION_SCHEMA.INNODB_TRX AS trx 
                    LEFT JOIN performance_schema.threads AS thd ON trx.trx_mysql_thread_id =  thd.PROCESSLIST_ID
                    WHERE 	thd.PROCESSLIST_USER != 'repl_neo4j'
                        AND ((thd.PROCESSLIST_USER LIKE '%.vn' AND TIMESTAMPDIFF(SECOND, trx.trx_started, NOW()) > {threshold})
                            OR(thd.PROCESSLIST_USER NOT LIKE '%.vn' AND TIMESTAMPDIFF(SECOND, trx.trx_started, NOW()) > {thresholdApp}))
                        OR trx.trx_rows_locked > {thresholdRowLocked}
                        OR trx.trx_rows_modified > {thresholdRowLocked};
                    '''.format(threshold=threshold,thresholdApp=thresholdApp,thresholdRowLocked=thresholdRowLocked)

            queryResult = self.db.Execute(mysqlOpt,query)


            return queryResult

        except Exception as ex:
            raise Exception(("CheckQueryRunning",ex,(ex)))

    def CheckBigQuery(self,configOjb):
        try:
            notificationMetaDataStr = configOjb['NotificationMetaData']
            notificationMetaData = json.loads(notificationMetaDataStr)

            self.telegramOpt = {
                "token": notificationMetaData['token'],
                "chat_id": notificationMetaData['chat_id']
            }

            mysqlOpt = {
                "host": configOjb['ServerIP'],
                "user": configOjb['MysqlUser'], 
                "password": configOjb['MysqlPassword'],
                "db": "performance_schema",
                "port": configOjb['ServerPort']
            }
            threshold = int(configOjb['Threshold'])
            thresholdApp = int(configOjb['ThresholdApp'])
            thresholdRowLocked = int(configOjb['ThresholdRowLocked'])
   
            bigQueryList  = self.CheckQueryRunning(mysqlOpt,threshold,thresholdApp,thresholdRowLocked)

            if len(bigQueryList) == 0:
                self.CheckAlertCached(configOjb['ServerID'],'CheckBigQuery', 0, 0);
                return

            for queryInfo in bigQueryList:
                sp=queryInfo["SPName"]   
                if sp is not None:
                    sp = sp.replace("<","&lt;").replace(">","&gt;")
                    
                queryText=queryInfo["Query"]        
                if queryText is not None:
                    queryText = queryText.replace("<","&lt;").replace(">","&gt;")
                messText ='''<b>Big Query</b>\nServer Name: {serverName} - {serverIP}\nLatency: {latency}\nTable Locked: {tblLocked}\nRow Locked: {rowLocked}\nRow Modified: {rowModified}\nUser: {user}\nHost: {host}\nSPName: {sp}\nQueryText: {queryText}'''.format(serverName=configOjb['ServerName'],
                                                                serverIP=configOjb['ServerIP'],
                                                                latency=queryInfo["Latency"],
                                                                tblLocked=queryInfo["Table Locked"],
                                                                rowLocked=queryInfo["Row Locked"],
                                                                rowModified=queryInfo["Row Modified"],
                                                                user=queryInfo["User"],
                                                                host=queryInfo["Host"],
                                                                sp=sp,
                                                                queryText=queryText)
      
                isCached = self.CheckAlertCached(configOjb['ServerID'],'CheckBigQuery', queryInfo["ThreadID"], 1);
                if isCached == False:
                    self.tele.SendTelegramMessage(self.telegramOpt,messText);
        except Exception as ex:
            self.WriteLog(("CheckBigQuery",ex))

    def CheckBigQueryJob(self):
        configs = self.CheckBigQueryConfig()
        for config in configs[0]:
            self.CheckBigQuery(config)

    def GetServerMonitor(self):
        try:
            listConfig = self.db.Call_SP(self.connArchiveOpt,'DBA_Monitor_Config_Get',())
            return listConfig;  
        except Exception as ex:
            raise Exception(("GetServerMonitor",ex))

    def MonitorJob(self):
        configs = self.GetServerMonitor()
        for config in configs[0]:
            self.InsertMetric(config)

    def CheckBackupLock(self,connOpt):
        try:
            query = ''' SELECT 1 AS HasBackupLock FROM performance_schema.metadata_locks WHERE OBJECT_TYPE = "BACKUP LOCK";'''
            hasBackupLock = self.db.Execute(connOpt,query)
            if hasBackupLock and hasBackupLock[0]['HasBackupLock'] == 1:
                return True;
            return False;
        except Exception as ex:
            raise Exception(("CheckBackupLock",ex))

    def GetMetric(self,mysqlOpt):
        if self.CheckBackupLock(mysqlOpt) == True:
            return ['[]','[]','[]']

        query ='''
                SELECT (SELECT JSON_ARRAYAGG(JSON_OBJECT(
                        'Object_Schema', metric.Object_Schema 
                    ,	'Object_Name', metric.Object_Name 
                    ,	'Object_Type', metric.Object_Type 
                    ,	'Count_Star', metric.Count_Star  
                    ,	'Sum_Timer_Wait', metric.Sum_Timer_Wait  
                    ,	'Min_Timer_Wait', metric.Min_Timer_Wait  
                    ,	'Avg_Timer_Wait', metric.Avg_Timer_Wait  
                    ,	'Max_Timer_Wait', metric.Max_Timer_Wait  
                    ,	'Count_Statements', metric.Count_Statements  
                    ,	'Sum_Statements_Wait', metric.Sum_Statements_Wait  
                    ,	'Min_Statements_Wait', metric.Min_Statements_Wait  
                    ,	'Avg_Statements_Wait', metric.Avg_Statements_Wait  
                    ,	'Max_Statements_Wait', metric.Max_Statements_Wait  
                    ,	'Sum_Lock_Time', metric.Sum_Lock_Time  
                    ,	'Sum_Errors', metric.Sum_Errors  
                    ,	'Sum_Warnings', metric.Sum_Warnings  
                    ,	'Sum_Rows_Affected', metric.Sum_Rows_Affected  
                    ,	'Sum_Rows_Sent', metric.Sum_Rows_Sent  
                    ,	'Sum_Rows_Examined', metric.Sum_Rows_Examined  
                    ,	'Sum_Created_Tmp_Disk_Tables', metric.Sum_Created_Tmp_Disk_Tables  
                    ,	'Sum_Created_Tmp_Tables', metric.Sum_Created_Tmp_Tables  
                    ,	'Sum_Select_Full_Join', metric.Sum_Select_Full_Join  
                    ,	'Sum_Select_Full_Range_Join', metric.Sum_Select_Full_Range_Join  
                    ,	'Sum_Select_Range', metric.Sum_Select_Range  
                    ,	'Sum_Select_Range_Check', metric.Sum_Select_Range_Check  
                    ,	'Sum_Select_Scan', metric.Sum_Select_Scan  
                    ,	'Sum_Sort_Merge_Passes', metric.Sum_Sort_Merge_Passes  
                    ,	'Sum_Sort_Range', metric.Sum_Sort_Range  
                    ,	'Sum_Sort_Rows', metric.Sum_Sort_Rows  
                    ,	'Sum_Sort_Scan', metric.Sum_Sort_Scan  
                    ,	'Sum_No_Index_Used', metric.Sum_No_Index_Used  
                    ,	'Sum_No_Good_Index_Used', metric.Sum_No_Good_Index_Used  
                    ,	'Sum_CPU_Time', 0 )) 
                FROM  	performance_schema.events_statements_summary_by_program AS metric) AS SP,
                (SELECT	JSON_ARRAYAGG(JSON_OBJECT(
                        'Object_Type', Object_Type
                    ,	'Object_Schema', Object_Schema 
                    ,	'Object_Name', Object_Name 
                    ,	'Count_Star', Count_Star  
                    ,	'Sum_Timer_Wait', Sum_Timer_Wait  
                    ,	'Min_Timer_Wait', Min_Timer_Wait  
                    ,	'Avg_Timer_Wait', Avg_Timer_Wait  
                    ,	'Max_Timer_Wait', Max_Timer_Wait  
                    ,	'Count_Read', Count_Read  
                    ,	'Sum_Timer_Read', Sum_Timer_Read  
                    ,	'Sum_Timer_Read', Min_Timer_Read  
                    ,	'Avg_Timer_Read', Avg_Timer_Read  
                    ,	'Max_Timer_Read', Max_Timer_Read  
                    ,	'Count_Write', Count_Write  
                    ,	'Sum_Timer_Write', Sum_Timer_Write  
                    ,	'Min_Timer_Write', Min_Timer_Write  
                    ,	'Avg_Timer_Write', Avg_Timer_Write  
                    ,	'Max_Timer_Write', Max_Timer_Write  
                    ,	'Count_Fetch', Count_Fetch  
                    ,	'Sum_Timer_Fetch', Sum_Timer_Fetch  
                    ,	'Min_Timer_Fetch', Min_Timer_Fetch  
                    ,	'Avg_Timer_Fetch', Avg_Timer_Fetch  
                    ,	'Max_Timer_Fetch', Max_Timer_Fetch  
                    ,	'Count_Insert', Count_Insert  
                    ,	'Sum_Timer_Insert', Sum_Timer_Insert  
                    ,	'Min_Timer_Insert', Min_Timer_Insert  
                    ,	'Avg_Timer_Insert', Avg_Timer_Insert  
                    ,	'Max_Timer_Insert', Max_Timer_Insert  
                    ,	'Count_Update', Count_Update  
                    ,	'Sum_Timer_Update', Sum_Timer_Update  
                    ,	'Min_Timer_Update', Min_Timer_Update  
                    ,	'Avg_Timer_Update', Avg_Timer_Update  
                    ,	'Max_Timer_Update', Max_Timer_Update  
                    ,	'Count_Delete', Count_Delete  
                    ,	'Sum_Timer_Delete', Sum_Timer_Delete  
                    ,	'Min_Timer_Delete', Min_Timer_Delete  
                    ,	'Avg_Timer_Delete', Avg_Timer_Delete  
                    ,	'Max_Timer_Delete', Max_Timer_Delete )) 
                FROM performance_schema.table_io_waits_summary_by_table
                WHERE OBJECT_SCHEMA NOT IN ('performance_schema','mysql')) AS Tbl,
                (SELECT	JSON_ARRAYAGG(JSON_OBJECT(
                        'Object_Type', Object_Type
                    ,	'Object_Schema', Object_Schema 
                    ,	'Object_Name', Object_Name 
                    ,	'Index_Name', Index_Name 
                    ,	'Count_Star', Count_Star  
                    ,	'Sum_Timer_Wait', Sum_Timer_Wait  
                    ,	'Min_Timer_Wait', Min_Timer_Wait  
                    ,	'Avg_Timer_Wait', Avg_Timer_Wait  
                    ,	'Max_Timer_Wait', Max_Timer_Wait  
                    ,	'Count_Read', Count_Read  
                    ,	'Sum_Timer_Read', Sum_Timer_Read  
                    ,	'Sum_Timer_Read', Min_Timer_Read  
                    ,	'Avg_Timer_Read', Avg_Timer_Read  
                    ,	'Max_Timer_Read', Max_Timer_Read  
                    ,	'Count_Write', Count_Write  
                    ,	'Sum_Timer_Write', Sum_Timer_Write  
                    ,	'Min_Timer_Write', Min_Timer_Write  
                    ,	'Avg_Timer_Write', Avg_Timer_Write  
                    ,	'Max_Timer_Write', Max_Timer_Write  
                    ,	'Count_Fetch', Count_Fetch  
                    ,	'Sum_Timer_Fetch', Sum_Timer_Fetch  
                    ,	'Min_Timer_Fetch', Min_Timer_Fetch  
                    ,	'Avg_Timer_Fetch', Avg_Timer_Fetch  
                    ,	'Max_Timer_Fetch', Max_Timer_Fetch  
                    ,	'Count_Insert', Count_Insert  
                    ,	'Sum_Timer_Insert', Sum_Timer_Insert  
                    ,	'Min_Timer_Insert', Min_Timer_Insert  
                    ,	'Avg_Timer_Insert', Avg_Timer_Insert  
                    ,	'Max_Timer_Insert', Max_Timer_Insert  
                    ,	'Count_Update', Count_Update  
                    ,	'Sum_Timer_Update', Sum_Timer_Update  
                    ,	'Min_Timer_Update', Min_Timer_Update  
                    ,	'Avg_Timer_Update', Avg_Timer_Update  
                    ,	'Max_Timer_Update', Max_Timer_Update  
                    ,	'Count_Delete', Count_Delete  
                    ,	'Sum_Timer_Delete', Sum_Timer_Delete  
                    ,	'Min_Timer_Delete', Min_Timer_Delete  
                    ,	'Avg_Timer_Delete', Avg_Timer_Delete  
                    ,	'Max_Timer_Delete', Max_Timer_Delete )) 
                FROM performance_schema.table_io_waits_summary_by_index_usage
                WHERE OBJECT_SCHEMA NOT IN ('performance_schema','mysql')) AS Idx;
            '''
        metric = self.db.Execute(mysqlOpt,query)

        query='''TRUNCATE TABLE  performance_schema.events_statements_summary_by_program;'''
        self.db.Execute(mysqlOpt,query)
        query='''TRUNCATE TABLE  performance_schema.table_io_waits_summary_by_table;'''
        self.db.Execute(mysqlOpt,query)

        return [metric[0]['SP'],metric[0]['Tbl'],metric[0]['Idx']];

    def InsertMetric(self,configOjb):
        try:
            mysqlOpt = {
                "host": configOjb['ServerIP'],
                "user": configOjb['MysqlUser'], 
                "password": configOjb['MysqlPassword'],
                "db": "performance_schema",
                "port": configOjb['ServerPort']
            }
            serverID = int(configOjb['ServerID'])
        
            metrics = self.GetMetric(mysqlOpt)
            sp = metrics[0]
            tbl = metrics[1]
            idx = metrics[2]

            self.db.Call_SP(self.connArchiveOpt,'DBA_Monitor_SPMetric_Insert',(sp,serverID))
            self.db.Call_SP(self.connArchiveOpt,'DBA_Monitor_TableMetric_Insert',(tbl,serverID))
            self.db.Call_SP(self.connArchiveOpt,'DBA_Monitor_IndexMetric_Insert',(idx,serverID))

        except Exception as ex:
            self.WriteLog(("InsertMetric"))

    def UpdateBackupStatus(self,bkID, bkType, lsn, folder,time,date):
        try:
            self.db.Call_SP(self.connArchiveOpt,'DBA_Backup_Incremental_UpdateInfo',(bkID,bkType,lsn,folder,time,date))
        except Exception as ex:
            raise Exception(("UpdateBackupStatus",ex))

    def GetServerInfo(self,serverID):
        try:
            info =  self.db.Call_SP(self.connArchiveOpt,'DBA_ServerInfo_GetByID',(serverID,))
            return info[0][0];
        except Exception as ex:
            raise Exception(("GetServerInfo",ex))

    def CheckDiskSize(self,sshOpt,folder,threshold):
        try:
            command = '''df {folder} --output=avail | tail -1 | awk '{op}print $1{cl}' '''.format(folder=folder,op="{",cl="}")
            result = self.ssh.Exec_Command(sshOpt,command)
            avai = int(result)

            if threshold > (avai/1024/1024):
                return False;
            return True
        except Exception as ex:
            raise Exception(("CheckDiskSize",ex))

    def GetUID(self,sshOpt):
        try:
            command = '''echo $UID'''
            result = self.ssh.Exec_Command(sshOpt,command)
            UID = int(result)
            return UID
        except Exception as ex:
            raise Exception(("GetUID",ex))

    def BackupByID(self, bkID):
        try:   
            configOjb = self.db.Call_SP(self.connArchiveOpt,'DBA_Backup_Config_GetByID',(bkID,))
            if len(configOjb[0]) == 0:
                print("Not Found")
                return;
            configOjb = configOjb[0][0];

            notificationMetaData = json.loads(configOjb['NotificationMetaData'])

            self.telegramOpt = {
                "token": notificationMetaData["token"],
                "chat_id": notificationMetaData["chat_id"],
            }

            sshSourceOpt = {
                "serverIP": configOjb['Source_ServerIP'],
                "user": configOjb['Source_SSHUser'], 
                "keyFile": configOjb['Source_SSHKey_File'],
            }
            sourceUID = self.GetUID(sshSourceOpt);
            sshSourceOpt["uid"] = sourceUID;

            sshDesOpt = {
                "serverIP": configOjb['Des_ServerIP'],
                "user": configOjb['Des_SSHUser'], 
                "keyFile": configOjb['Des_SSHKey_File'],
            }

            desUID = self.GetUID(sshDesOpt);
            sshDesOpt["uid"] = desUID;

            if self.CheckDiskSize(sshSourceOpt,configOjb["Source_Folder"],configOjb["DiskThreshold"]) == False:
                raise Exception("Source Folder isn't have enough storage to backup!!!")
            
            if self.CheckDiskSize(sshDesOpt,configOjb["Des_RootFolder"],configOjb["DiskThreshold"]) == False:
                raise Exception("Des Folder isn't have enough storage to backup!!!")

            messText ='''<b>Full Backup</b>\nSource Server: {sourceServer}\nStorage Server: {storageServer}'''.format(sourceServer=configOjb['Source_ServerName'],storageServer=configOjb['Des_ServerName'], folder=configOjb['Des_Folder'])

            self.UpdateServerStatus(configOjb['Source_ServerID'],"Backup")
            self.tele.SendTelegramMessage(self.telegramOpt,messText +  "\nStatus: <b>Running</b>");

            resultPath = self.Backup(bkID,sshSourceOpt,configOjb['Source_MysqlUser'],configOjb['Source_MysqlPassword'],
                                    configOjb["Source_DataPath"], configOjb["Source_BinlogPath"], configOjb["Source_Folder"],
                                    configOjb["Source_ContainerName"], configOjb["Source_ContainerNetwork"], configOjb["Source_XtrabackupImageName"],
                                    sshDesOpt,configOjb["Des_Folder"],configOjb["Des_FolderName"],configOjb["BackupType"],configOjb["LastLSN"],configOjb["LastFolder"],
                                    configOjb["CurrTime"],configOjb["CurrDate"])
            
            self.UpdateServerStatus(configOjb['Source_ServerID'],"None")
            self.tele.SendTelegramMessage(self.telegramOpt,messText +  "\nFolder: " + resultPath + "\nStatus: <b>Done</b>");

        except Exception as ex:
            self.WriteLog(("BackupFull", ex)) 

    def Backup(self, bkID,sourceSSHOpt,sourceMysqlUser,sourceMysqlPass,sourceDBPath,sourceBinLogPath,sourceBKPath,sourceContainerName,sourceContainerNetwork,xtrabackupImageName,desSSHOpt,desBKPath,desFolderName,bkType,lsn,lastFolder,currTime, currDate):
        try:
            isOneHost = False
            bkOpt = ''
            resultPath = ""

            if sourceSSHOpt['serverIP'] == desSSHOpt['serverIP']:
                isOneHost = True;
                sourceBKPath = desBKPath
                
            if bkType == 'Incremental_Inc':
                bkOpt = '''--target-dir=/xtrabackup_backupfiles --incremental-lsn={lsn}'''.format(lsn=lsn)
                   
            if isOneHost == True:
                    sourceBKPath = sourceBKPath = '''{sourceBKPath}/{desFolderName}'''.format(sourceBKPath=sourceBKPath,desFolderName=desFolderName)
            else:
                tempFolder = self.RandomStr(6);
                sourceBKPath = '''{sourceBKPath}/{tempFolder}'''.format(sourceBKPath=sourceBKPath,tempFolder=tempFolder)

            cmdCreateSourceFolderPath = '''mkdir -p {sourceBKPath}'''.format(sourceBKPath=sourceBKPath)
            self.ssh.Exec_Command(sourceSSHOpt,cmdCreateSourceFolderPath)

            resultPath = sourceBKPath

            cmdBK = '''docker run --rm -i -v {sourceDBPath}:/var/lib/mysql -v {sourceBinLogPath}:/var/log/mysql/binlog -v {sourceBKPath}:/xtrabackup_backupfiles --network {sourceContainerNetwork} {xtrabackupImageName} xtrabackup --host={sourceContainerName} --user={sourceMysqlUser} --password={sourceMysqlPass} --compress-threads=1 --parallel=2 --compress --backup {bkOpt}'''.format(
                    sourceDBPath=sourceDBPath,
                    sourceBinLogPath=sourceBinLogPath,
                    sourceBKPath=sourceBKPath,
                    sourceContainerNetwork=sourceContainerNetwork,
                    xtrabackupImageName=xtrabackupImageName,
                    sourceContainerName=sourceContainerName,
                    sourceMysqlUser=sourceMysqlUser,
                    sourceMysqlPass=sourceMysqlPass,
                    bkOpt=bkOpt)

            self.ssh.Exec_Command(sourceSSHOpt,cmdBK)

            cmdChown = '''docker run --rm -i -v {sourceBKPath}:/tmp {xtrabackupImageName} chown -R {uid}:{uid} /tmp'''.format(sourceBKPath=sourceBKPath,xtrabackupImageName=xtrabackupImageName,uid=sourceSSHOpt["uid"])
            self.ssh.Exec_Command(sourceSSHOpt,cmdChown)

            cmdGetLSN = '''grep -r "to_lsn" {sourceBKPath}/xtrabackup_checkpoints | awk '{op}print $3{clo}' '''.format(sourceBKPath=sourceBKPath,op="{",clo="}")
            LSN = int(self.ssh.Exec_Command(sourceSSHOpt,cmdGetLSN))

            if isOneHost == False:
                Path("/var/cts/monitor/backup").mkdir(parents=True, exist_ok=True)
                self.ssh.SCP_GetFile_Recursive(sourceSSHOpt,sourceBKPath,"/var/cts/monitor/backup")
                
                localPath = '''/var/cts/monitor/backup/{tempFolder}'''.format(tempFolder=tempFolder)
                localRenamePath = '''/var/cts/monitor/backup/{desFolderName}'''.format(desFolderName=desFolderName)
                os.rename(localPath,localRenamePath)

                cmdCreatDesFolderPath = '''mkdir -p {desBKPath}'''.format(desBKPath=desBKPath)
                self.ssh.Exec_Command(desSSHOpt,cmdCreatDesFolderPath)

                self.ssh.SCP_UpFile_Recursive(desSSHOpt,localRenamePath,desBKPath)
                resultPath = '''{desBKPath}/{desFolderName}'''.format(desBKPath=desBKPath,desFolderName=desFolderName);

                cmdDeleteFolderBK = '''rm -r {sourceBKPath}'''.format(sourceBKPath=sourceBKPath)
                self.ssh.Exec_Command(sourceSSHOpt,cmdDeleteFolderBK)

                if os.path.exists(localRenamePath):
                    shutil.rmtree(localRenamePath)

            self.UpdateBackupStatus(bkID,bkType,LSN,desBKPath,currTime, currDate)

            if bkType == 'Incremental_Full' and lastFolder != None and len(lastFolder) > 0:
                cmdDeleteFolderBK = '''rm -r {lastFolder}'''.format(lastFolder=lastFolder)
                self.ssh.Exec_Command(desSSHOpt,cmdDeleteFolderBK)

            return resultPath;
        except Exception as ex:
            self.WriteLog(("BackupFull", ex)) 

    def Recover(self,localServerID, sourceServerID,desServerID, baseFolder,desFolder, incFolderList, isFullBK):
        try:
            sourceServerInfo = self.GetServerInfo(sourceServerID)
            sourceSSHOpt = {
                "serverIP": sourceServerInfo['ServerIP'],
                "user": sourceServerInfo['SSHUser'], 
                "keyFile": sourceServerInfo['SSHKey_File'],
            }

            xtrabackupImageName = sourceServerInfo['XtrabackupImageName'];

            desServerInfo = self.GetServerInfo(desServerID)
            desSSHOpt = {
                "serverIP": desServerInfo['ServerIP'],
                "user": desServerInfo['SSHUser'], 
                "keyFile": desServerInfo['SSHKey_File'],
            }

            localServerInfo = self.GetServerInfo(localServerID)
            localSSHOpt = {
                "serverIP": localServerInfo['ServerIP'],
                "user": localServerInfo['SSHUser'], 
                "keyFile": localServerInfo['SSHKey_File'],
            }
            

            tempFolder = self.RandomStr(6);

            localTempPath = '''/var/cts/monitor/backup/{tempFolder}'''.format(tempFolder=tempFolder)
            localBasePath = '''{localTempPath}/base'''.format(localTempPath=localTempPath)
            localIncPath = '''{localTempPath}/inc'''.format(localTempPath=localTempPath)

            cmdCreateFolderBK = '''mkdir -p {localBasePath}'''.format(localBasePath=localBasePath)
            self.ssh.Exec_Command(localSSHOpt,cmdCreateFolderBK)
            print(cmdCreateFolderBK)
            cmdCreateFolderBK = '''mkdir -p {localIncPath}'''.format(localIncPath=localIncPath)
            self.ssh.Exec_Command(localSSHOpt,cmdCreateFolderBK)
            print(cmdCreateFolderBK)

            baseFolderName = os.path.basename(baseFolder)
            print(baseFolderName)
            localBaseFolderPath= '''{localBasePath}/{baseFolderName}'''.format(localBasePath=localBasePath,baseFolderName=baseFolderName)
            print(localBaseFolderPath)
            self.ssh.SCP_GetFile_Recursive(sourceSSHOpt,baseFolder,localBasePath)

            cmdDeCompress = '''docker run --rm -it --user $(id -u):$(id -g) -v {localBaseFolderPath}:/xtrabackup_backupfiles {xtrabackupImageName} xtrabackup --decompress --remove-original  --parallel=4'''.format(localBaseFolderPath=localBaseFolderPath,xtrabackupImageName=xtrabackupImageName)
            
            if isFullBK == True:
                cmdPrepare = '''docker run --rm -it --user $(id -u):$(id -g) -v {localBaseFolderPath}:/xtrabackup_backupfiles {xtrabackupImageName} xtrabackup --prepare'''.format(localBaseFolderPath=localBaseFolderPath,xtrabackupImageName=xtrabackupImageName)
            else:
                cmdPrepare = '''docker run --rm -it --user $(id -u):$(id -g) -v {localBaseFolderPath}:/xtrabackup_backupfiles {xtrabackupImageName} xtrabackup --prepare --apply-log-only'''.format(localBaseFolderPath=localBaseFolderPath,xtrabackupImageName=xtrabackupImageName)
            
            os.system(cmdDeCompress)
            os.system(cmdPrepare)
            
            if isFullBK == True:
                self.ssh.SCP_UpFile_Recursive(desSSHOpt,localBaseFolderPath,desFolder)
                if os.path.exists(localTempPath): shutil.rmtree(localTempPath)
                return

            for incFolder in incFolderList:
                self.ssh.SCP_GetFile_Recursive(sourceSSHOpt,incFolder,localIncPath)
                print(incFolder)
                incFolderName = os.path.basename(incFolder)
                print(incFolderName)
                localIncFolderPath= '''{localIncPath}/{incFolderName}'''.format(localIncPath=localIncPath,incFolderName=incFolderName)
                print(localIncFolderPath)
                cmdDeCompress = '''docker run --rm -it --user $(id -u):$(id -g) -v {localIncFolderPath}:/xtrabackup_backupfiles {xtrabackupImageName} xtrabackup --decompress --remove-original  --parallel=4'''.format(localIncFolderPath=localIncFolderPath,xtrabackupImageName=xtrabackupImageName)
                cmdPrepare = '''docker run --rm -it --user $(id -u):$(id -g) -v {localBaseFolderPath}:/tmp/base -v {localIncFolderPath}:/tmp/inc {xtrabackupImageName} xtrabackup --prepare --apply-log-only --target-dir=/tmp/base --incremental-dir=/tmp/inc'''.format(localBaseFolderPath=localBaseFolderPath,localIncFolderPath=localIncFolderPath,xtrabackupImageName=xtrabackupImageName)
                print(cmdDeCompress)
                print(cmdPrepare)
                os.system(cmdDeCompress)
                os.system(cmdPrepare)

            self.ssh.SCP_UpFile_Recursive(desSSHOpt,localBaseFolderPath,desFolder)
            if os.path.exists(localTempPath): shutil.rmtree(localTempPath)

        except Exception as ex:
            raise Exception(("Recover",ex))
        

    def close(self):
        self.db.close()
        self.ssh.close()
        self.tele.close()
