source  /var/cts/ansible/py3.10_env/bin/activate && cd /var/cts/ansible/
deactivate


list-hosts
	ansible all --list-hosts

ping all hosts
	ansible all -m ping

ping special host
	ansible archive59 -m ping

	
Check the free memory or memory usage 
	ansible all -a "free -h"
	
Check listening ports
	ansible archive59 -m listen_ports_facts

Check the free disk size
	ansible all -a "df -h" 
	ansible archive59 -a "df -h" 
	
	
Install docker 
	ansible-playbook playbook_install_docker.yaml -K --limit archive59
	
Create user ansible	
	ansible-playbook playbook_create_ansible_user.yaml -K --limit archive59

Get OS info
	ansible-playbook playbook_get_os_info.yaml -K --limit archive59

Pull all images
	ansible-playbook playbook_docker_pull_image.yaml -K --limit archive59 
	
Pull all images
	ansible-playbook playbook_create_pmmserver_container.yaml -K --limit archive59

Check software installed
	ansible-playbook playbook_checklist.yaml -K --limit archive59	
	
-Roles
	-OS Level
		+Create user ansible
			+ansible-playbook -i 10.18.200.71, -u cts_ansible_test11 -k -K playbook_create_ansible_user.yaml
			+sudo chmod 600 cts_ansible_test11_replica71_rsa_private_key

		+Install python, venv
			+ansible-playbook playbook_install_python310.yaml -K --limit archive59

		+Setup python interpreter ansible user
			+set value for the path variable 
			+ansible-playbook playbook_create_pythoninterpreter_env.yaml -K --limit archive59

		+Install docker, compose, pull images
			+ansible-playbook playbook_install_docker.yaml -K --limit archive59
			+ansible-playbook playbook_docker_pull_image.yaml -K --limit archive59
			+ansible-playbook playbook_docker_overplay_network.yaml -K --limit archive59
	-DB
		+Create mysql container
			+ansible-playbook playbook_create_mysql_container.yaml -K --limit archive59

		+Create mysql-router
		

ansible cts_dev72 -a "docker network ls" -b -K
ansible cts_dev72 -a "docker network rm dba_server_overlay" -b -K
ansible cts_dev72 -a "tail /var/log/syslog -n100" -b -K























