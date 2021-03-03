1. Install grafana
	+docker pull grafana/grafana
	+docker run -d -p 3000:3000 --name grafana grafana/grafana

2. Create Grafana Data Source
	+Source Type: Mysql
	+Name: CTS - Mysql ****Required****
	+User/Pass: ....

3. Create mysql user
	+CreateUserForGrafana.sql












