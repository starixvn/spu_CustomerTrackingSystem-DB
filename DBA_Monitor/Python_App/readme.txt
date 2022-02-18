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
deactivate