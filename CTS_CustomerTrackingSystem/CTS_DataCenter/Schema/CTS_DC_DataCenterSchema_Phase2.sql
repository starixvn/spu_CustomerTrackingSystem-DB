/*
Creator: 20191217@CaseyHuynh
Task:	 	CTS_Schema
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
	#1. [20191217@CaseyHuynh][#125530]: Add Column LastLoginDate column to table CTSCustomer.
    
Reviewer:
	#1. Harvey: 
*/

/* ==========================PHASE 2===================================*/
#1. [20191217@CaseyHuynh][#125530]
ALTER TABLE		CTS_DataCenter.CTSCustomer
ADD COLUMN		LastLoginTime1	TIMESTAMP(4);