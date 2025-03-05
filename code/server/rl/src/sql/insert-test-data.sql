START TRANSACTION;

-- Insert test users
INSERT INTO rl.user (username, password_validation, email, student_nr, created_at)
VALUES
    ('admin', 'hashed_password_123', 'admin@example.com', 'A00001', NOW()),
    ('professor1', 'hashed_password_456', 'professor1@example.com', 'P00001', NOW()),
    ('student1', 'hashed_password_789', 'student1@example.com', 'S00001', NOW()),
    ('student2', 'hashed_password_012', 'student2@example.com', 'S00002', NOW());

-- Insert test tokens
INSERT INTO rl.token (token_validation, user_id, created_at, last_used_at)
VALUES
    ('token_123', 1, NOW(), NOW()),
    ('token_456', 2, NOW(), NOW()),
    ('token_789', 3, NOW(), NOW());

-- Insert test groups
INSERT INTO rl.group (group_name, group_description, created_at, owner_id)
VALUES
    ('Physics 101', 'Introduction to Physics Laboratory Class', NOW(), 2),
    ('Electronics Lab', 'Advanced Electronics Laboratory', NOW(), 2),
    ('Study Group A', 'Student study group for Physics', NOW(), 3);

-- Insert user-group relationships
INSERT INTO rl.user_group (user_id, group_id)
VALUES
    (2, 1), -- professor1 in Physics 101
    (3, 1), -- student1 in Physics 101
    (4, 1), -- student2 in Physics 101
    (3, 3), -- student1 in Study Group A
    (4, 3); -- student2 in Study Group A

-- Insert laboratories
INSERT INTO rl.laboratory (lab_name, lab_duration, created_at, owner_id)
VALUES
    ('Pendulum Experiment', 30, NOW(), 2),
    ('Circuit Analysis', 45, NOW(), 2),
    ('Wave Motion', 60, NOW(), 2);

-- Insert group-laboratory relationships
INSERT INTO rl.group_laboratory (group_id, lab_id)
VALUES
    (1, 1), -- Physics 101 - Pendulum Experiment
    (1, 3), -- Physics 101 - Wave Motion
    (2, 2); -- Electronics Lab - Circuit Analysis

-- Insert some waiting queue entries
INSERT INTO rl.lab_waiting_queue (user_id, lab_id)
VALUES
    (3, 1), -- student1 waiting for Pendulum Experiment
    (4, 2); -- student2 waiting for Circuit Analysis

-- Insert lab sessions
INSERT INTO rl.lab_session (lab_id, owner_id, start_time, end_time)
VALUES
    (1, 3, NOW() - INTERVAL '1 hour', NOW()),
    (2, 4, NOW(), NOW() + INTERVAL '45 minutes');

-- Insert app invites
INSERT INTO rl.app_invite (invite_code, owner_id, created_at, last_used_at, group_id)
VALUES
    ('PHYS101-2024', 2, NOW(), NOW(), 1),
    ('ELEC-LAB-2024', 2, NOW(), NOW(), 2);

-- Insert hardware
INSERT INTO rl.hardware (hw_name, hw_serial_num, status, mac_address, ip_address, created_at)
VALUES
    ('Pendulum Sensor', 'PS001', 'ACTIVE', '00:1A:2B:3C:4D:5E', '192.168.1.100', NOW()),
    ('Circuit Board', 'CB001', 'ACTIVE', '00:1A:2B:3C:4D:5F', '192.168.1.101', NOW()),
    ('Wave Generator', 'WG001', 'ACTIVE', '00:1A:2B:3C:4D:60', '192.168.1.102', NOW());

-- Insert hardware-laboratory relationships
INSERT INTO rl.hardware_laboratory (hw_id, lab_id)
VALUES
    (1, 1), -- Pendulum Sensor - Pendulum Experiment
    (2, 2), -- Circuit Board - Circuit Analysis
    (3, 3); -- Wave Generator - Wave Motion

COMMIT; 