//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

//cursors
#define Default_Cursor	0
#define Client_Cursor	1
#define Server_Cursor	2
//conversions
#define TEXT_CONV		1
#define RSC_FILE_CONV	2
#define NUMBER_CONV		3
//column flag values:
#define IS_NUMERIC		1
#define IS_BINARY		2
#define IS_NOT_NULL		4
#define IS_PRIMARY_KEY	8
#define IS_UNSIGNED		16
//types
#define TINYINT		1
#define SMALLINT	2
#define MEDIUMINT	3
#define INTEGER		4
#define BIGINT		5
#define DECIMAL		6
#define FLOAT		7
#define DOUBLE		8
#define DATE		9
#define DATETIME	10
#define TIMESTAMP	11
#define TIME		12
#define STRING		13
#define BLOB		14
// TODO: Investigate more recent type additions and see if I can handle them. - Nadrew

#define FAILED_DB_CONNECTION_CUTOFF 5

SUBSYSTEM_DEF(dbcore)
	name = "Database"
	flags = SS_TICKER
	wait = 10
	init_order = 95
	priority = 16

	var/initialized = FALSE
	var/dbi
	var/sqladdress = "localhost"
	var/sqlport = "3306"
	var/sqlfdbkdb = "test"
	var/sqlfdbklogin = "root"
	var/sqlfdbkpass = ""
	var/sqlfdbktableprefix = "erro_"
	var/default_cursor = Default_Cursor
	var/_db_con = null

	var/failed_db_connections = 0

/datum/subsystem/dbcore/Initialize(start_timeofday)
	. = ..()
	if(!config.sql_enabled)
		can_fire = 0
		return
	dbi = "dbi:mysql:[sqlfdbkdb]:[sqladdress]:[sqlport]"
	Connect()
	initialized = TRUE

/datum/subsystem/dbcore/can_vv_get(var_name)
	return FALSE

/datum/subsystem/dbcore/vv_edit_var(var_name, var_value)
	return FALSE

/datum/subsystem/dbcore/CanProcCall(procname)
	return FALSE

/datum/subsystem/dbcore/proc/Connect(dbi_handler=src.dbi, user_handler=src.sqlfdbklogin, password_handler=src.sqlfdbkpass, cursor_handler=Default_Cursor)
	if(failed_db_connections >= FAILED_DB_CONNECTION_CUTOFF)	//If it failed to establish a connection more than 5 times in a row, don't bother attempting to connect anymore.
		return FALSE
	if(!config.sql_enabled)
		return FALSE
	if(IsConnected())
		return TRUE
	default_cursor = cursor_handler
	_dm_db_connect(_db_con, dbi_handler, user_handler, password_handler, default_cursor, null)
	if(IsConnected())
		failed_db_connections = 0
		return TRUE
	var/message = "DB failed to connect! Failed connections: [++failed_db_connections]. SQL error: " + SSdbcore.ErrorMsg()
	message_admins(message)
	log_admin(message)
	return FALSE

/datum/subsystem/dbcore/proc/Disconnect()
	return _dm_db_close(_db_con)

/datum/subsystem/dbcore/proc/Quote(str)
	return _dm_db_quote(_db_con,str)

/datum/subsystem/dbcore/proc/ErrorMsg()
	return _dm_db_error_msg(_db_con)

/datum/subsystem/dbcore/proc/SelectDB(database_name,dbi)
	if(IsConnected())
		Disconnect()
	return Connect("[dbi?"[dbi]":"dbi:mysql:[database_name]:[sqladdress]:[sqlport]"]", sqlfdbklogin, sqlfdbkpass)

/datum/subsystem/dbcore/proc/NewQuery(sql_query, cursor_handler=src.default_cursor)
	return new /datum/db_query(sql_query, _db_con, cursor_handler)

/datum/subsystem/dbcore/proc/IsConnected()
	if(!config.sql_enabled)
		return 0
	var/success = _dm_db_is_connected(_db_con)
	return success

/datum/subsystem/dbcore/Recover()
	dbi = SSdbcore.dbi
	sqladdress = SSdbcore.sqladdress
	sqlport = SSdbcore.sqlport
	sqlfdbkdb = SSdbcore.sqlfdbkdb
	sqlfdbklogin = SSdbcore.sqlfdbklogin
	sqlfdbkpass = SSdbcore.sqlfdbkpass
	sqlfdbktableprefix = SSdbcore.sqlfdbktableprefix
	_db_con = SSdbcore._db_con

/datum/db_query
	var/sql // The sql query being executed.
	var/default_cursor
	var/list/columns //list of DB Columns populated by Columns()
	var/list/conversions
	var/list/item[0]  //list of data values populated by NextRow()

	var/db_connection
	var/_db_query

#undef FAILED_DB_CONNECTION_CUTOFF

/datum/db_query/New(sql_query, connection_handler, cursor_handler)
	if(sql_query)
		src.sql = sql_query
	if(connection_handler)
		src.db_connection = connection_handler
	if(cursor_handler)
		src.default_cursor = cursor_handler
	_db_query = _dm_db_new_query()
	return ..()

/datum/db_query/vv_edit_var(var_name, var_value)
	return FALSE

/datum/db_query/CanProcCall(procname)
	return FALSE

/datum/db_query/proc/Connect()
	SSdbcore.Connect()

/datum/db_query/proc/Execute(sql_query=src.sql, cursor_handler=default_cursor)
	Close()
	return _dm_db_execute(_db_query,sql_query,db_connection,cursor_handler,null)

/datum/db_query/proc/NextRow()
	return _dm_db_next_row(_db_query,item,conversions)

/datum/db_query/proc/RowsAffected()
	return _dm_db_rows_affected(_db_query)

/datum/db_query/proc/RowCount()
	return _dm_db_row_count(_db_query)

/datum/db_query/proc/ErrorMsg()
	return _dm_db_error_msg(_db_query)

/datum/db_query/proc/Columns()
	if(!columns)
		columns = _dm_db_columns(_db_query,/datum/db_column)
	return columns

/datum/db_query/proc/GetRowData()
	var/list/columns = Columns()
	var/list/results
	if(columns.len)
		results = list()
		for(var/C in columns)
			results += C
			var/datum/db_column/cur_col = columns[C]
			results[C] = src.item[(cur_col.position+1)]
	return results

/datum/db_query/proc/Close()
	item.len = 0
	columns = null
	conversions = null
	return _dm_db_close(_db_query)

/datum/db_query/proc/Quote(str)
	return SSdbcore.Quote(str)

/datum/db_query/proc/SetConversion(column, conversion)
	if(istext(column)) column = columns.Find(column)
	if(!conversions) conversions = new/list(column)
	else if(conversions.len < column) conversions.len = column
	conversions[column] = conversion


/datum/db_column
	var/name
	var/table
	var/position //1-based index into item data
	var/sql_type
	var/flags
	var/length
	var/max_length

/datum/db_column/New(name_handler, table_handler, position_handler, type_handler, flag_handler, length_handler, max_length_handler)
	src.name = name_handler
	src.table = table_handler
	src.position = position_handler
	src.sql_type = type_handler
	src.flags = flag_handler
	src.length = length_handler
	src.max_length = max_length_handler
	return ..()

/datum/db_column/vv_edit_var(var_name, var_value)
	return FALSE

/datum/db_column/CanProcCall(procname)
	return FALSE

/datum/db_column/proc/SqlTypeName(type_handler=src.sql_type)
	switch(type_handler)
		if(TINYINT) return "TINYINT"
		if(SMALLINT) return "SMALLINT"
		if(MEDIUMINT) return "MEDIUMINT"
		if(INTEGER) return "INTEGER"
		if(BIGINT) return "BIGINT"
		if(FLOAT) return "FLOAT"
		if(DOUBLE) return "DOUBLE"
		if(DATE) return "DATE"
		if(DATETIME) return "DATETIME"
		if(TIMESTAMP) return "TIMESTAMP"
		if(TIME) return "TIME"
		if(STRING) return "STRING"
		if(BLOB) return "BLOB"


#undef Default_Cursor
#undef Client_Cursor
#undef Server_Cursor
#undef TEXT_CONV
#undef RSC_FILE_CONV
#undef NUMBER_CONV
#undef IS_NUMERIC
#undef IS_BINARY
#undef IS_NOT_NULL
#undef IS_PRIMARY_KEY
#undef IS_UNSIGNED
#undef TINYINT
#undef SMALLINT
#undef MEDIUMINT
#undef INTEGER
#undef BIGINT
#undef DECIMAL
#undef FLOAT
#undef DOUBLE
#undef DATE
#undef DATETIME
#undef TIMESTAMP
#undef TIME
#undef STRING
#undef BLOB
