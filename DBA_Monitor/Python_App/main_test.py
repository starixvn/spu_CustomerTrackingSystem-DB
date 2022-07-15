from dbtask.dbTask import DBTaskHelper
from ssh.sshHelper import SSHHandler

import os

print(os.path.basename("/tmp/bk/qwe"))


task = DBTaskHelper()

ssh = SSHHandler()


ssh = SSHHandler()


sshSourceOpt = {
                "serverIP": "10.18.200.70",
                "user": "dba_cts_master", 
                "keyFile": "keyfiles/dba_cts_master_rsa_private_key",
            }

#ssh.Exec_Command(sshSourceOpt,"docker run --rm -i -v /volumes/cts_master_mysql80/data:/var/lib/mysql -v /volumes/cts_master_mysql80/binlog:/var/log/mysql/binlog -v /tmp/bk/AH3CJH:/xtrabackup_backupfiles --network cts_network_local perconalab/percona-xtrabackup:8.0.25-17 xtrabackup --host=cts_master_mysql80 --user=aries.vn --password=password --compress-threads=1 --parallel=2 --compress --backup");
#print("aa");
#ssh.SCP_GetFile_Recursive(sshSourceOpt,'/tmp/bk/*','./backup/QAQEZW/')

#os.rename("./backup/QAQEZW","./backup/aaaa")

#task.BackupByID(1);


task.Recover(7,6,5,"/tmp/bk/2022_07_27/BKInc_2022_07_27-06_47","/tmp/bk",["/tmp/bk/2022_07_27/BKInc_2022_07_27-06_53","/tmp/bk/2022_07_27/BKInc_2022_07_27-06_57"],False)
#print("Ok 1");
#task.BackupByID(2);
#print("Ok 2");
#task.BackupByID(3);
#print("Ok 3");
#task.BackupByID(4);
#print("Ok 4");
#task.BackupByID(3);
#print("Ok 3");
#task.BackupByID(4);
#print("Ok 4");



















