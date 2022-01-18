apt-get install python3-venv
cd /var/cts/
mkdir monitor
python3 --version
cd monitor

python3 -m venv cts_env
source cts_env/bin/activate
pip3 install --upgrade pip3
pip3 install wheel
pip3 install python-telegram-bot
pip3 install mysql-connector-python
pip3 install cryptography
pip3 install paramiko

deactivate