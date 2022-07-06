import mysql.connector as mysql
from config import config
from datetime import datetime

class DBHandler:
    connection = None;
    cursorQuery = None;

    def InitConnection(self, connOpt):
        self.connection = mysql.connect(host=connOpt['host'],
                                        user = connOpt['user'],
                                        password = connOpt['password'],
                                        db = connOpt['db'],
                                        port = connOpt['port'],
                                        auth_plugin='mysql_native_password',
                                        autocommit = True);
        self.cursorQuery = self.connection.cursor(dictionary=True);

    def CloseConnection(self):
        self.cursorQuery.close()
        self.connection.close()


    def Call_SP(self, connOpt, spName, params):
            self.InitConnection(connOpt)
            self.cursorQuery.callproc(spName,params)
            sp_result = self.cursorQuery.stored_results()
            result = [list.fetchall() for list in sp_result]
            self.CloseConnection()
            return result;
    
    def Execute(self, connOpt, queryText):
            self.InitConnection(connOpt)
            self.cursorQuery.execute(queryText)
            result = self.cursorQuery.fetchall()
            self.CloseConnection()
            return result;

    def close(self):
       self.CloseConnection(self)
        

class DBHelper:

    connectionMaster = None;
    connectionReplica = None;
    connectionArchive = None;

    cursorMaster = None;
    cursorReplica = None;
    cursorArchive = None;

    def InitCursor(self,serverName):
        if serverName == "master":
            dbConfigMaster = config['mysql_master'];
            self.connectionMaster = mysql.connect(host=dbConfigMaster['host'],
                                            user = dbConfigMaster['user'],
                                            password = dbConfigMaster['password'],
                                            db = dbConfigMaster['db'],
                                            port = dbConfigMaster['port'],
                                            auth_plugin='mysql_native_password',
                                            autocommit = True);
            self.cursorMaster = self.connectionMaster.cursor();
        elif  serverName == "replica" :
            dbConfigReplica = config['mysql_replica'];
            self.connectionReplica = mysql.connect(host=dbConfigReplica['host'],
                                            user = dbConfigReplica['user'],
                                            password = dbConfigReplica['password'],
                                            db = dbConfigReplica['db'],
                                            port = dbConfigReplica['port'],
                                            auth_plugin='mysql_native_password',
                                            autocommit = True);
            self.cursorReplica = self.connectionReplica.cursor();
        elif  serverName == "archive" :
            dbConfigArchive= config['mysql_archive'];
            self.connectionArchive = mysql.connect(host=dbConfigArchive['host'],
                                            user = dbConfigArchive['user'],
                                            password = dbConfigArchive['password'],
                                            db = dbConfigArchive['db'],
                                            port = dbConfigArchive['port'],
                                            auth_plugin='mysql_native_password',
                                            autocommit = True);
            self.cursorArchive = self.connectionArchive.cursor();
       
    def Exec(self, serverName, query, params, isGetFirst):  
        sp_result = None
        if serverName.lower() == "master":
            self.InitCursor("master")
            if params == None:
                self.cursorMaster.callproc(query)
            else:
                self.cursorMaster.callproc(query,params)
            sp_result = self.cursorMaster.stored_results()
            for item in sp_result:
                result = item.fetchall()
                self.CloseCursor("master")
                if isGetFirst:
                    return result[0][0]
                else:
                    return result

        elif  serverName.lower() == "replica" :
            self.InitCursor("replica")
            if params == None:
                self.cursorReplica.callproc(query)
            else:
                self.cursorReplica.callproc(query,params)
            sp_result = self.cursorReplica.stored_results()
            for item in sp_result:
                result = item.fetchall()
                self.CloseCursor("replica")
                if isGetFirst:
                    return result[0][0]
                else:
                    return result

        elif  serverName.lower() == "archive" :
            self.InitCursor("archive")
            if params == None:
                self.cursorArchive.callproc(query)
            else:
                self.cursorArchive.callproc(query,params)
            sp_result = self.cursorArchive.stored_results()
            for item in sp_result:
                result = item.fetchall()
                self.CloseCursor("archive")
                if isGetFirst:
                    return result[0][0]
                else:
                    return result

    def CloseCursor(self,serverName):
        if serverName.lower() == "master":
            self.cursorMaster.close()
            self.connectionMaster.close()
        elif  serverName.lower() == "replica" :
            self.cursorReplica.close()
            self.connectionReplica.close()
        elif  serverName.lower() == "archive" :
            self.cursorArchive.close()  
            self.connectionArchive.close()

    def close(self):
        self.cursorMaster.close()
        self.cursorReplica.close()
        self.cursorArchive.close()

        self.connectionMaster.close()
        self.connectionReplica.close()
        self.connectionArchive.close()