connect to $tenant_db_name ;
set schema $tenant_ontology ;

-- table to store the aliases of attribute instances inside key class
create table alias
(
	key_class_id INTEGER NOT NULL,
	alias_name VARCHAR (512) NOT NULL,
	language CHAR(3) NOT NULL,
	parent_id INTEGER NOT NULL,
	
	CONSTRAINT alias_pkey PRIMARY KEY (key_class_id, alias_name),

	CONSTRAINT alias_parent_id_alias_name_key UNIQUE (parent_id, alias_name),
	
	CONSTRAINT alias_key_class_id_fkey FOREIGN KEY (key_class_id) REFERENCES key_class (key_class_id)
	ON UPDATE RESTRICT ON DELETE CASCADE,

	CONSTRAINT alias_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES key_class (key_class_id)
	ON UPDATE RESTRICT ON DELETE CASCADE
);

GRANT ALTER ON TABLE $tenant_ontology.alias TO USER $tenant_db_user ;



alter table object_type add column config BLOB(10M) NOT NULL default BLOB('e30=');
reorg table object_type;



alter table key_class alter column mandatory set data type INTEGER;
reorg table key_class;

alter table key_class add column flags SMALLINT NOT NULL default 0;
reorg table key_class;

-- TODO: 
-- insert into key_class row 0 for __root
-- (key_class_id, key_class_name, datatype, mandatory, sensitive, comment, config, flags, parent_id) 
-- values 
-- (0, '__root', 1, 0, 1, 'Reserved Key Class', BLOB('e30='), 0, 0, 0, 0);
-- reorg table key_class;

alter table key_class add column parent_id INTEGER NOT NULL default 0;
reorg table key_class;


-- **************************************************************************************************
-- delete unused tables
-- **************************************************************************************************
drop table db_restore;
drop table db_backup;

-- **************************************************************************************************
-- create indexes on date fields
-- **************************************************************************************************
create index ix_audit_api_activity_date ON audit_api_activity(date);
create index ix_audit_integration_activity_date ON audit_integration_activity(date);
create index ix_audit_login_activity_date ON audit_login_activity(date);
create index ix_audit_ontology_date ON audit_ontology(date);
create index ix_audit_processed_files_date ON audit_processed_files(date);
create index ix_audit_system_activity_date ON audit_system_activity(date);
create index ix_audit_user_activity_date ON audit_user_activity(date);
create index ix_error_log_date ON error_log(date);
create index ix_processed_file_date on processed_file(date);
-- **************************************************************************************************
-- delete all db2 storage tables and recreate new two tables
-- **************************************************************************************************
drop table pageparams;
drop table docparams;
drop table runtime_page;
drop table runtime_doc;

--replace mongo DB2 tables
create table runtime_doc
(
	TRANSACTION_ID         VARCHAR(256) NOT NULL,
	INITIAL_START_TIME     BIGINT,
	FILE_NAME              VARCHAR(1024),
	ORG_CONTENT            BLOB(250M) INLINE LENGTH 5120,
	UTF_CONTENT            BLOB(250M),
	PDF_CONTENT            BLOB(250M),
	WDS_CONTENT            BLOB(250M),
	DOC_PARAMS             BLOB(10M),
	FLAGS                  BIGINT       NOT NULL DEFAULT 0,
	API                    SMALLINT     NOT NULL DEFAULT 0,
	COMPLETED              SMALLINT     NOT NULL DEFAULT 0,
	FAILED                 SMALLINT     NOT NULL DEFAULT 0,
	DOCUMENTACCURACY       INTEGER      NOT NULL DEFAULT 0,
	COMPLETED_OCR_PAGES    INTEGER      NOT NULL DEFAULT 0,
	OCR_PAGES_VERIFIED     SMALLINT     NOT NULL DEFAULT 0,
	PROGRESS               DECIMAL(5,2),
	PARTIAL_COMPLETE_PAGES INTEGER      NOT NULL DEFAULT 0,
	COMPLETED_PAGES        INTEGER      NOT NULL DEFAULT 0,
	VERIFIED               SMALLINT     NOT NULL DEFAULT 0,
	USER_ID                INTEGER      NOT NULL DEFAULT 0,
	PDF                    SMALLINT     NOT NULL DEFAULT 0,
	PDF_SUCCESS            SMALLINT     NOT NULL DEFAULT 0,
	PDF_ERROR_LIST         VARCHAR(1024),
	PDF_PARAMS             BLOB(1M),
	UTF8                   SMALLINT     NOT NULL DEFAULT 0,
	UTF8_SUCCESS           SMALLINT     NOT NULL DEFAULT 0,
	UTF8_ERROR_LIST        VARCHAR(1024),
	UTF8_PARAMS            BLOB(1M),
	TITLE_LIST             VARCHAR(32000),
	ALIAS_LIST             BLOB(1M),

	CONSTRAINT runtime_doc_pkey PRIMARY KEY (TRANSACTION_ID)
);

create index IX_INITIAL_START_TIME ON runtime_doc(INITIAL_START_TIME);

create table runtime_page
(
	TRANSACTION_ID VARCHAR(256) NOT NULL,
	PAGE_ID        SMALLINT     NOT NULL,
	JPG_CONTENT    BLOB(250M),
	PAGE_UUID      VARCHAR(256),
	PAGE_PARAMS    BLOB(10M),
	FLATTENEDJSON  BLOB(10M),
	GOODLETTERS    INTEGER      NOT NULL DEFAULT 0,
	ALLLETTERS     INTEGER      NOT NULL DEFAULT 0,
	COMPLETE       SMALLINT     NOT NULL DEFAULT 0,
	OCR_CONFIDENCE VARCHAR(20),
	LANGUAGES      VARCHAR(256),
	FLAGS          BIGINT       NOT NULL DEFAULT 0,
	BAGOFWORDS     BLOB(1M),
	HEADER_LIST    BLOB(1M),
	FOUNDKEYLIST   VARCHAR(1024),
	DEFINEDKEYLIST VARCHAR(1024),

	CONSTRAINT runtime_page_transaction_id_fkey FOREIGN KEY (TRANSACTION_ID) REFERENCES runtime_doc (TRANSACTION_ID)
	ON UPDATE RESTRICT ON DELETE CASCADE,

	CONSTRAINT runtime_page_pkey PRIMARY KEY (TRANSACTION_ID, PAGE_ID)
);

-- End of new tables for db2 storage
