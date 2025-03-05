START TRANSACTION;

CREATE SCHEMA IF NOT EXISTS rl;

DROP TABLE IF EXISTS rl.user;
DROP TABLE IF EXISTS rl.laboratory;


CREATE TABLE rl.user (
    user_id GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(64) NOT NULL,
    password_validation VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    student_nr VARCHAR(16) UNIQUE,
);

CREATE TABLE rl.token (
    token_validation VARCHAR(255) NOT NULL,
    user_id INT NOT NULL REFERENCES rl.user(user_id),
    last_used_at BIGINT NOT NULL,
    PRIMARY KEY (token_validation, user_id)
);



COMMIT;