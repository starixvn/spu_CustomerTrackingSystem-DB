import paramiko
from config import config

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
    def exec(self, serverName, command):
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

