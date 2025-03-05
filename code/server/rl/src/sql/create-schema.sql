START TRANSACTION;

CREATE SCHEMA IF NOT EXISTS rl;

DROP TABLE IF EXISTS rl.user CASCADE;
DROP TABLE IF EXISTS rl.token CASCADE;
DROP TABLE IF EXISTS rl.group CASCADE;
DROP TABLE IF EXISTS rl.laboratory CASCADE;
DROP TABLE IF EXISTS rl.lab_waiting_queue CASCADE;
DROP TABLE IF EXISTS rl.lab_session CASPRIMARY KEYCADE;
DROP TABLE IF EXISTS rl.group_laboratory CASCADE;

CREATE TABLE rl.user (
    user_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    password_validation VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    student_nr INT UNIQUE,
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE rl.token (
    token_validation VARCHAR(255) NOT NULL,
    user_id INT NOT NULL REFERENCES rl.user(user_id),
    created_at TIMESTAMP NOT NULL,
    last_used_at TIMESTAMP NOT NULL, -- see about bigint and timestamp
    PRIMARY KEY (token_validation, user_id)
);

-- Groups can be general groups, classes or student groups
CREATE TABLE rl.group (
    group_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_name VARCHAR(255) NOT NULL,
    group_description TEXT,
    created_at TIMESTAMP NOT NULL,
    owner_id INT NOT NULL REFERENCES rl.user(user_id)
);

CREATE TABLE rl.user_group (
    user_id INT NOT NULL REFERENCES rl.user(user_id),
    group_id INT NOT NULL REFERENCES rl.group(group_id),
    PRIMARY KEY (user_id, group_id)
);

CREATE TABLE rl.laboratory (
    lab_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lab_name VARCHAR(255) NOT NULL,
    lab_duration INT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    owner_id INT NOT NULL REFERENCES rl.user(user_id)
);

-- Waiting queue for a lab
CREATE TABLE rl.lab_waiting_queue (
    user_id INT NOT NULL REFERENCES rl.user(user_id),
    lab_id INT NOT NULL REFERENCES rl.laboratory(lab_id),
    PRIMARY KEY (user_id, lab_id)
);

CREATE TABLE rl.lab_session (
    session_id INT GENERATED ALWAYS AS IDENTITY,
    lab_id INT NOT NULL REFERENCES rl.laboratory(lab_id),
    owner_id INT NOT NULL REFERENCES rl.user(user_id),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    PRIMARY KEY (session_id, lab_id, owner_id)
);

CREATE TABLE rl.group_laboratory (
    group_id INT NOT NULL REFERENCES rl.group(group_id),
    lab_id INT NOT NULL REFERENCES rl.laboratory(lab_id),
    PRIMARY KEY (group_id, lab_id)
);

CREATE TABLE rl.app_invite (
    invite_id INT GENERATED ALWAYS AS IDENTITY,
    invite_code VARCHAR(255) NOT NULL,
    -- email VARCHAR(255) NOT NULL, -- TODO: see to add specific invited email
    owner_id INT NOT NULL REFERENCES rl.user(user_id),
    created_at TIMESTAMP NOT NULL,
    last_used_at TIMESTAMP NOT NULL,
    group_id INT NOT NULL REFERENCES rl.group(group_id),
    PRIMARY KEY (invite_id, owner_id, group_id)
);

CREATE TABLE rl.hardware (
    hw_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hw_name VARCHAR(255) NOT NULL,
    hw_serial_num VARCHAR(255) NOT NULL,
    status VARCHAR(255) NOT NULL,
    mac_address VARCHAR(255) NOT NULL,
    ip_address VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE rl.hardware_laboratory (
    hw_id INT NOT NULL REFERENCES rl.hardware(hw_id),
    lab_id INT NOT NULL REFERENCES rl.laboratory(lab_id),
    PRIMARY KEY (hw_id, lab_id)
);

COMMIT;