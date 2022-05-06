import paramiko
from scp import SCPClient
from config import config

class SSHHandler:
    connection = None;
    cursorQuery = None;

    def InitConnection(self, sshOpt):
        keyFile = paramiko.RSAKey.from_private_key_file(sshOpt["keyFile"])
        self.connection = paramiko.SSHClient()
        self.connection.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self.connection.connect( hostname = sshOpt["serverIP"], username = sshOpt["user"], pkey = keyFile )

    def Exec_Command(self,sshOpt,command):
        self.InitConnection(sshOpt)
        result = ""
        (ssh_stdin, ssh_stdout, ssh_stderr) = self.connection.exec_command(command)
        for line in ssh_stdout.readlines():
                result = result + line.rstrip()
        self.CloseConnection()
        return result

    def SCP_GetFile(self,sshOpt,sourcePath,desPath):
        self.InitConnection(sshOpt)
        cmdScp = SCPClient(self.connection.get_transport())
        cmdScp.get(sourcePath, desPath)
        cmdScp.close()
        self.CloseConnection()
    
    def SCP_UpFile(self,sshOpt,sourcePath,desPath):
        self.InitConnection(sshOpt)
        cmdScp = SCPClient(self.connection.get_transport())
        cmdScp.put(sourcePath, desPath)

        cmdScp.close()
        self.CloseConnection()
    
    def CloseConnection(self):
        self.connection.close()

    def close(self):
       self.CloseConnection(self)

class SSHHelper:

    connectionMaster = None
    connectionReplica = None

    def __init__(self):
        sshConfigMaster = config['ssh_master']
        self.connectionMaster = paramiko.SSHClient();
        self.connectionMaster.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self.connectionMaster.connect(sshConfigMaster['host'], 
                                 username=sshConfigMaster['user'], 
                                 password=sshConfigMaster['password'])

        sshConfigReplica = config['ssh_replica']
        self.connectionReplica = paramiko.SSHClient();
        self.connectionReplica.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self.connectionReplica.connect(sshConfigReplica['host'], 
                                 username=sshConfigReplica['user'], 
                                 password=sshConfigReplica['password'])

    def Exec(self, serverName, command):
        if serverName.lower() == "master":
            (ssh_stdin, ssh_stdout, ssh_stderr) = self.connectionMaster.exec_command(command)
            for line in ssh_stdout.readlines():
                return line.rstrip()
        elif  serverName.lower() == "replica" :
            (ssh_stdin, ssh_stdout, ssh_stderr) = self.connectionReplica.exec_command(command)
            for line in ssh_stdout.readlines():
                return line.rstrip()
        
    def close(self):
        self.connectionMaster.close()
        self.connectionReplica.close()

