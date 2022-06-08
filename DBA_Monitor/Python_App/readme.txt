#install python virtual environment
apt-get install python3-venv

#create deploy folder 
cd /var/cts/
mkdir monitor
cd monitor

#create virtual environment folder 
python3 -m venv cts_env

#install third party, libs inside virtual environment 
source cts_env/bin/activate
pip install --upgrade pip
pip3 install wheel
pip3 install python-telegram-bot
pip3 install mysql-connector-python
pip3 install cryptography
pip3 install paramiko
pip3 install scp

deactivate


#mkdir keyfiles
#mkdir archivepartitionfiles

#create user 
	+Replica
		dba_cts_replica 	password
		sudo adduser dba_cts_replica
		sudo adduser dba_cts_replica docker
		
		ssh-keygen -t rsa
		mv /home/dba_cts_replica/.ssh/id_rsa /home/dba_cts_replica/.ssh/dba_cts_replica_rsa_private_key
		mv /home/dba_cts_replica/.ssh/id_rsa.pub /home/dba_cts_replica/.ssh/authorized_keys
		
		chmod 600 /home/dba_cts_replica/.ssh/dba_cts_replica_rsa_private_key
		chmod 600 /home/dba_cts_replica/.ssh/authorized_keys
	+Archive
		
		dba_cts_archive		password
		sudo adduser dba_cts_archive 
		sudo adduser dba_cts_archive docker
		
		ssh-keygen -t rsa
		mv /home/dba_cts_archive/.ssh/id_rsa /home/dba_cts_archive/.ssh/dba_cts_archive_rsa_private_key
		mv /home/dba_cts_archive/.ssh/id_rsa.pub /home/dba_cts_archive/.ssh/authorized_keys
		
		chmod 600 /home/dba_cts_archive/.ssh/dba_cts_archive_rsa_private_key
		chmod 600 /home/dba_cts_archive/.ssh/authorized_keys

	+Archive
		
		dba_cts_aws		password
		sudo adduser dba_cts_aws 
		
		ssh-keygen -t rsa
		mv /home/dba_cts_aws/.ssh/id_rsa /home/dba_cts_aws/.ssh/dba_cts_aws_rsa_private_key
		mv /home/dba_cts_aws/.ssh/id_rsa.pub /home/dba_cts_aws/.ssh/authorized_keys
		
		chmod 600 /home/dba_cts_aws/.ssh/dba_cts_aws_rsa_private_key
		chmod 600 /home/dba_cts_aws/.ssh/authorized_keys
		chmod 600 /var/cts/monitor/keyfiles/dba_cts_aws_rsa_private_key

#check connect ssh key file
ssh -i /var/cts/monitor/keyfiles/dba_cts_aws_rsa_private_key dba_cts_aws@xx.xx.xx.xx ls


/var/cts/monitor/cts_env/bin/python /var/cts/monitor/main_test.py
