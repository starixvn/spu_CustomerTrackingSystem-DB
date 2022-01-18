import mysql.connector as mysql
from config import config


class DBHelper:

    connectionMaster = None;
    connectionReplica = None;
    connectionArchive = None;

    cursorMaster = None;
    cursorReplica = None;
    cursorArchive = None;
        
    def initCursor(self,serverName):
        if serverName == "master":
            dbConfigMaster = config['mysql_master'];
            self.connectionMaster = mysql.connect(host=dbConfigMaster['host'],
                                            user = dbConfigMaster['user'],
                                            password = dbConfigMaster['password'],
                                            db = dbConfigMaster['db'],
                                            port = dbConfigMaster['port'],
                                            auth_plugin='mysql_native_password');
            self.cursorMaster = self.connectionMaster.cursor();
        elif  serverName == "replica" :
            dbConfigReplica = config['mysql_replica'];
            self.connectionReplica = mysql.connect(host=dbConfigReplica['host'],
                                            user = dbConfigReplica['user'],
                                            password = dbConfigReplica['password'],
                                            db = dbConfigReplica['db'],
                                            port = dbConfigReplica['port'],
                                            auth_plugin='mysql_native_password');
            self.cursorReplica = self.connectionReplica.cursor();
        elif  serverName == "archive" :
            dbConfigArchive= config['mysql_archive'];
            self.connectionArchive = mysql.connect(host=dbConfigArchive['host'],
                                            user = dbConfigArchive['user'],
                                            password = dbConfigArchive['password'],
                                            db = dbConfigArchive['db'],
                                            port = dbConfigArchive['port'],
                                            auth_plugin='mysql_native_password');
            self.cursorArchive = self.connectionArchive.cursor();
       
    def exec(self, serverName, query, params, isGetFirst):  
        sp_result = None
        if serverName.lower() == "master":
            self.initCursor("master")
            self.cursorMaster = self.connectionMaster.cursor()
            self.cursorMaster.callproc(query)
            sp_result = self.cursorMaster.stored_results()
            for item in sp_result:
                result = item.fetchall()
                self.closeCursor("master")
                if isGetFirst:
                    return result[0][0]
                else:
                    return result

        elif  serverName.lower() == "replica" :
            self.initCursor("replica")
            self.cursorReplica.callproc(query)
            sp_result = self.cursorReplica.stored_results()
            for item in sp_result:
                result = item.fetchall()
                self.closeCursor("replica")
                if isGetFirst:
                    return result[0][0]
                else:
                    return result

        elif  serverName.lower() == "archive" :
            self.initCursor("archive")
            self.cursorArchive.callproc(query)
            sp_result = self.cursorArchive.stored_results()
            for item in sp_result:
                result = item.fetchall()
                self.closeCursor("archive")
                if isGetFirst:
                    return result[0][0]
                else:
                    return result

    def closeCursor(self,serverName):
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