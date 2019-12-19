/*
Creator: 20191217@CaseyHuynh
Task:	 	DCS_Schema
Server:  	Slave
DBName:		DCS_DataCenter

Revisions: 
	#1. [20191217@CaseyHuynh][#125530]: Add Column LastLoginTime column to table CTSCustomer.
    
Reviewer:
	#1. Harvey: 
*/
#1. [20191217@CaseyHuynh][#125530]
ALTER TABLE		DCS_DataCenter.Account
ADD COLUMN		LastLoginTime	TIMESTAMP(4);