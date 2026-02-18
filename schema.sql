BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "ai_responses" (
	"response_id"	INTEGER,
	"request_id"	INTEGER,
	"response_text"	TEXT,
	"response_length"	INTEGER,
	"generation_time"	REAL,
	"model_version"	TEXT,
	PRIMARY KEY("response_id" AUTOINCREMENT),
	FOREIGN KEY("request_id") REFERENCES "writing_requests"("request_id")
);
CREATE TABLE IF NOT EXISTS "user_actions" (
	"action_id"	INTEGER,
	"response_id"	INTEGER,
	"user_id"	INTEGER,
	"action_type"	TEXT,
	"timestamp"	DATETIME,
	"edits_made"	INTEGER,
	PRIMARY KEY("action_id"),
	FOREIGN KEY("response_id") REFERENCES "ai_responses"("response_id"),
	FOREIGN KEY("user_id") REFERENCES "users"("user_id")
);
CREATE TABLE IF NOT EXISTS "users" (
	"user_id"	INTEGER,
	"username"	TEXT,
	"email"	TEXT,
	"signup_date"	DATE,
	"subscription_type"	TEXT,
	"total_requests"	INTEGER,
	PRIMARY KEY("user_id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "writing_requests" (
	"request_id"	INTEGER,
	"user_id"	INTEGER,
	"request_text"	TEXT,
	"request_category"	TEXT,
	"timestamp"	DATETIME,
	"prompt_length"	INTEGER,
	PRIMARY KEY("request_id" AUTOINCREMENT),
	FOREIGN KEY("user_id") REFERENCES "users"("user_id")
);
COMMIT;
