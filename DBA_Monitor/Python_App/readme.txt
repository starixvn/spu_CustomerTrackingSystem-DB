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