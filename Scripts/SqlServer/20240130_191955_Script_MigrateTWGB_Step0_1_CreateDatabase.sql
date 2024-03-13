/*<info serverAlias="DBCTS-WASAVerse" executers="" viewers="" isFunction="0"></info>*/
/*
	Creator:	20240130@Victoria.Le
	Task:		Create new database so that can support SQL Server Log Shipping for CTS
	Server:		DB061 & DB062
	
	Revisions:
			- 20240130@Victoria.Le: Initial Writing - Step 0 - 1 [Redmine: #191955]	
*/

USE	master;
GO

CREATE DATABASE	WASAVerse
	ON	PRIMARY (
			NAME		= N'WASAVerse'
		,	FILENAME	= N'H:\USER_DB\WASAVerse\WASAVerse.mdf'
		,	SIZE		= 128MB
		,	MAXSIZE		= UNLIMITED
		,	FILEGROWTH	= 128MB
		)
	,	FILEGROUP DATA DEFAULT (
			NAME		= N'DATA'
		,	FILENAME	= N'H:\USER_DB\WASAVerse\data_01.ndf'
		,	SIZE		= 128MB
		,	MAXSIZE		= UNLIMITED
		,	FILEGROWTH	= 128MB
		)
	,	FILEGROUP DATA_TWGB (
			NAME		= N'DATA_TWGB'
		,	FILENAME	= N'H:\USER_DB\WASAVerse\data_twgb_01.ndf'
		,	SIZE		= 256MB
		,	MAXSIZE		= UNLIMITED
		,	FILEGROWTH	= 256MB
		)
	,	FILEGROUP DATA_TWGB_BK (
			NAME		= N'DATA_TWGB_BK'
		,	FILENAME	= N'H:\USER_DB\WASAVerse\data_twgb_bk_01.ndf'
		,	SIZE		= 256MB
		,	MAXSIZE		= UNLIMITED
		,	FILEGROWTH	= 256MB
		)
	,	FILEGROUP IDX (
			NAME		= N'IDX'
		,	FILENAME	= N'H:\USER_DB\WASAVerse\idx_01.ndf'
		,	SIZE		= 128MB
		,	MAXSIZE		= UNLIMITED
		,	FILEGROWTH	= 128MB
		)
	,	FILEGROUP IDX_TWGB (
			NAME		= N'IDX_TWGB'
		,	FILENAME	= N'H:\USER_DB\WASAVerse\idx_twgb_01.ndf'
		,	SIZE		= 128MB
		,	MAXSIZE		= UNLIMITED
		,	FILEGROWTH	= 128MB
		)
	,	FILEGROUP IDX_TWGB_BK (
			NAME		= N'IDX_TWGB_BK'
		,	FILENAME	= N'H:\USER_DB\WASAVerse\idx_twgb_bk_01.ndf'
		,	SIZE		= 128MB
		,	MAXSIZE		= UNLIMITED
		,	FILEGROWTH	= 128MB
		)
	LOG ON (
		NAME		= N'WASAVerse_log'
	,	FILENAME	= N'H:\USER_DB\WASAVerse\WASAVerse_log.ldf'
	,	SIZE		= 2GB
	,	MAXSIZE		= 2048GB
	,	FILEGROWTH	= 128MB
	);
GO