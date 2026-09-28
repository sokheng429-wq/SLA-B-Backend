-- =============================================================================
-- B'Groceries Hyperstore - Multi-Department Service Desk Platform
-- Database Migration V1: Core Configurable Data Model & Marketing Department Seed
-- =============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. DEPARTMENTS (Configurable Service Desks)
CREATE TABLE IF NOT EXISTS departments (
    id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name_en VARCHAR(100) NOT NULL,
    name_kh VARCHAR(150) NOT NULL,
    description_en TEXT,
    description_kh TEXT,
    icon VARCHAR(100) DEFAULT 'folder',
    lead_user_id BIGINT,
    backup_user_id BIGINT,
    operating_hours_start TIME NOT NULL DEFAULT '08:00:00',
    operating_hours_end TIME NOT NULL DEFAULT '17:00:00',
    daily_cutoff_time TIME NOT NULL DEFAULT '15:00:00',
    work_days VARCHAR(50) NOT NULL DEFAULT 'MON,TUE,WED,THU,FRI,SAT',
    monthly_rush_quota INT NOT NULL DEFAULT 3,
    auto_approve_hours INT NOT NULL DEFAULT 48,
    auto_approve_promo_hours INT NOT NULL DEFAULT 24,
    max_revision_rounds INT NOT NULL DEFAULT 2,
    change_request_tat_days INT NOT NULL DEFAULT 3,
    ticket_seq_current BIGINT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. USERS (Company Wide Users & Authentication)
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name_en VARCHAR(100) NOT NULL,
    full_name_kh VARCHAR(150),
    email VARCHAR(100),
    phone VARCHAR(30),
    company_role VARCHAR(50) NOT NULL DEFAULT 'REQUESTER', -- REQUESTER, ADMIN, EXECUTIVE
    primary_department_id VARCHAR(50) REFERENCES departments(id) ON DELETE SET NULL,
    avatar_url VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Foreign key constraints on departments for lead & backup
ALTER TABLE departments
    DROP CONSTRAINT IF EXISTS fk_dept_lead,
    DROP CONSTRAINT IF EXISTS fk_dept_backup;

ALTER TABLE departments
    ADD CONSTRAINT fk_dept_lead FOREIGN KEY (lead_user_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_dept_backup FOREIGN KEY (backup_user_id) REFERENCES users(id) ON DELETE SET NULL;

-- 4. DEPARTMENT MEMBERS (RBAC per Department)
CREATE TABLE IF NOT EXISTS department_members (
    id BIGSERIAL PRIMARY KEY,
    department_id VARCHAR(50) NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    dept_role VARCHAR(50) NOT NULL, -- DESK_OPS, ASSIGNEE, LEAD, MANAGER
    is_primary BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (department_id, user_id)
);

-- 5. SERVICE CATALOG (Configurable per Department)
CREATE TABLE IF NOT EXISTS service_catalog (
    id BIGSERIAL PRIMARY KEY,
    department_id VARCHAR(50) NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL UNIQUE,
    name_en VARCHAR(150) NOT NULL,
    name_kh VARCHAR(200) NOT NULL,
    category_en VARCHAR(100) NOT NULL,
    category_kh VARCHAR(150) NOT NULL,
    standard_tat_days INT NOT NULL DEFAULT 2,
    standard_tat_hours INT,
    rush_tat_hours INT NOT NULL DEFAULT 24,
    review_sla_hours INT NOT NULL DEFAULT 4,
    deliverable_specs_en TEXT,
    deliverable_specs_kh TEXT,
    default_priority VARCHAR(10) NOT NULL DEFAULT 'P3',
    brief_requirements_en TEXT,
    brief_requirements_kh TEXT,
    brief_schema JSONB DEFAULT '[]'::jsonb, -- dynamic input fields
    responsible_lead_title_en VARCHAR(100),
    responsible_lead_title_kh VARCHAR(150),
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. WORKFLOW STATUSES (Configurable per Department)
CREATE TABLE IF NOT EXISTS workflow_statuses (
    id BIGSERIAL PRIMARY KEY,
    department_id VARCHAR(50) NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    status_key VARCHAR(50) NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    name_kh VARCHAR(150) NOT NULL,
    step_order INT NOT NULL,
    is_timer_running BOOLEAN NOT NULL DEFAULT true,
    is_review_stage BOOLEAN NOT NULL DEFAULT false,
    is_terminal BOOLEAN NOT NULL DEFAULT false,
    badge_color VARCHAR(30) DEFAULT 'gray',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (department_id, status_key)
);

-- 7. WORKFLOW TRANSITIONS (State Machine & Permissions)
CREATE TABLE IF NOT EXISTS workflow_transitions (
    id BIGSERIAL PRIMARY KEY,
    department_id VARCHAR(50) NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    from_status_id BIGINT NOT NULL REFERENCES workflow_statuses(id) ON DELETE CASCADE,
    to_status_id BIGINT NOT NULL REFERENCES workflow_statuses(id) ON DELETE CASCADE,
    transition_name_en VARCHAR(100) NOT NULL,
    transition_name_kh VARCHAR(150) NOT NULL,
    allowed_roles VARCHAR(100) NOT NULL, -- e.g. 'DESK_OPS,LEAD,MANAGER'
    requires_comment BOOLEAN NOT NULL DEFAULT false,
    increments_revision BOOLEAN NOT NULL DEFAULT false,
    is_rejection BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. SLA POLICIES (Configurable Priority Rules per Department)
CREATE TABLE IF NOT EXISTS sla_policies (
    id BIGSERIAL PRIMARY KEY,
    department_id VARCHAR(50) NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    priority_tier VARCHAR(10) NOT NULL, -- P1, P2, P3, P4
    name_en VARCHAR(100) NOT NULL,
    name_kh VARCHAR(150) NOT NULL,
    initial_response_minutes INT NOT NULL,
    tat_hours INT,
    tat_business_days INT,
    approver_role VARCHAR(50) NOT NULL,
    alert_delay_threshold_hours INT NOT NULL,
    alert_recipient_role VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (department_id, priority_tier)
);

-- 9. ESCALATION RULES (Configurable Escalation Levels per Department)
CREATE TABLE IF NOT EXISTS escalation_rules (
    id BIGSERIAL PRIMARY KEY,
    department_id VARCHAR(50) NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    escalation_level INT NOT NULL, -- 1, 2, 3, 4
    name_en VARCHAR(100) NOT NULL,
    name_kh VARCHAR(150) NOT NULL,
    trigger_delay_hours INT NOT NULL,
    target_role VARCHAR(100) NOT NULL,
    resolution_sla_hours INT NOT NULL,
    action_required_en TEXT,
    action_required_kh TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (department_id, escalation_level)
);

-- 10. BUSINESS CALENDAR HOLIDAYS (Admin-Managed)
CREATE TABLE IF NOT EXISTS business_calendar_holidays (
    id BIGSERIAL PRIMARY KEY,
    holiday_date DATE NOT NULL UNIQUE,
    name_en VARCHAR(150) NOT NULL,
    name_kh VARCHAR(200) NOT NULL,
    is_recurring BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 11. TICKETS (Core Service Desk Ticket)
CREATE TABLE IF NOT EXISTS tickets (
    id BIGSERIAL PRIMARY KEY,
    ticket_number VARCHAR(50) NOT NULL UNIQUE,
    department_id VARCHAR(50) NOT NULL REFERENCES departments(id),
    service_catalog_id BIGINT NOT NULL REFERENCES service_catalog(id),
    requester_id BIGINT NOT NULL REFERENCES users(id),
    requester_department_id VARCHAR(50) REFERENCES departments(id),
    assignee_id BIGINT REFERENCES users(id),
    current_status_id BIGINT NOT NULL REFERENCES workflow_statuses(id),
    priority VARCHAR(10) NOT NULL DEFAULT 'P3',
    is_rush BOOLEAN NOT NULL DEFAULT false,
    rush_gm_approved BOOLEAN NOT NULL DEFAULT false,
    title VARCHAR(255) NOT NULL,
    brief_data JSONB DEFAULT '{}'::jsonb,
    parent_ticket_id BIGINT REFERENCES tickets(id) ON DELETE SET NULL, -- for Change Request link
    is_change_request BOOLEAN NOT NULL DEFAULT false,
    revision_count INT NOT NULL DEFAULT 0,
    max_revision_rounds INT NOT NULL DEFAULT 2,
    
    -- SLA Clock Timestamps
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    brief_checked_at TIMESTAMP WITH TIME ZONE,
    sla_start_at TIMESTAMP WITH TIME ZONE,
    sla_target_at TIMESTAMP WITH TIME ZONE,
    first_response_at TIMESTAMP WITH TIME ZONE,
    review_started_at TIMESTAMP WITH TIME ZONE,
    auto_approve_target_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Pausing & Escalation
    is_paused BOOLEAN NOT NULL DEFAULT false,
    current_pause_started_at TIMESTAMP WITH TIME ZONE,
    total_paused_minutes INT NOT NULL DEFAULT 0,
    escalation_level INT NOT NULL DEFAULT 0,
    
    -- Stakeholder Feedback
    csat_score INT CHECK (csat_score >= 1 AND csat_score <= 5),
    csat_comment TEXT,
    csat_submitted_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 12. TICKET SLA LOGS (Audit Trail, Pauses, Escalations, Status Changes)
CREATE TABLE IF NOT EXISTS ticket_sla_logs (
    id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL, -- SUBMITTED, BRIEF_CHECKED, BRIEF_REJECTED, SLA_STARTED, PAUSED, RESUMED, REVISION_REQUESTED, AUTO_APPROVED, ESCALATED, COMPLETED
    from_status_id BIGINT REFERENCES workflow_statuses(id),
    to_status_id BIGINT REFERENCES workflow_statuses(id),
    actor_id BIGINT REFERENCES users(id),
    paused_minutes INT DEFAULT 0,
    reason TEXT,
    snapshot_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 13. TICKET COMMENTS
CREATE TABLE IF NOT EXISTS ticket_comments (
    id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id),
    message TEXT NOT NULL,
    is_internal BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 14. TICKET ATTACHMENTS
CREATE TABLE IF NOT EXISTS ticket_attachments (
    id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100),
    version_round INT NOT NULL DEFAULT 1,
    uploaded_by BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 15. IN-APP NOTIFICATIONS
CREATE TABLE IF NOT EXISTS in_app_notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ticket_id BIGINT REFERENCES tickets(id) ON DELETE CASCADE,
    title_en VARCHAR(200) NOT NULL,
    title_kh VARCHAR(250) NOT NULL,
    message_en TEXT NOT NULL,
    message_kh TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL, -- SLA_WARNING, ESCALATION, ASSIGNED, BRIEF_REJECTED, AUTO_APPROVED, COMMENT
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 16. RUSH QUOTA USAGE (Monthly Tracking per Requesting Dept)
CREATE TABLE IF NOT EXISTS rush_quota_usage (
    id BIGSERIAL PRIMARY KEY,
    requesting_department_id VARCHAR(50) NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    target_department_id VARCHAR(50) NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    year_month VARCHAR(7) NOT NULL, -- e.g. '2026-09'
    used_count INT NOT NULL DEFAULT 0,
    gm_approved_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (requesting_department_id, target_department_id, year_month)
);

-- =============================================================================
-- SEED DATA: DEPARTMENTS (Marketing configured + Other departments empty)
-- =============================================================================

INSERT INTO departments (id, code, name_en, name_kh, description_en, description_kh, icon, operating_hours_start, operating_hours_end, daily_cutoff_time, work_days, monthly_rush_quota, auto_approve_hours, auto_approve_promo_hours, max_revision_rounds, change_request_tat_days)
VALUES 
('dept-mkt', 'MKT', 'Marketing & Communications', 'ផ្នែកទីផ្សារ និងទំនាក់ទំនង', 'Creative design, multimedia, campaigns, PR, digital promotions and brand governance.', 'ការរចនាម៉ូត ការផ្សព្វផ្សាយ ពាណិជ្ជកម្ម និងយុទ្ធនាការទីផ្សារ', 'palette', '08:00:00', '17:00:00', '15:00:00', 'MON,TUE,WED,THU,FRI,SAT', 3, 48, 24, 2, 3),
('dept-it',  'IT',  'Information Technology', 'ផ្នែកបច្ចេកវិទ្យាព័ត៌មាន (IT)', 'Hardware, software, POS support, network and system administration.', 'ការគ្រប់គ្រងប្រព័ន្ធបច្ចេកវិទ្យា ឧបករណ៍ និងជំនួយការបច្ចេកទេស', 'cpu', '08:00:00', '17:00:00', '16:00:00', 'MON,TUE,WED,THU,FRI,SAT', 5, 72, 24, 3, 2),
('dept-pur', 'PUR', 'Purchasing & Sourcing', 'ផ្នែកលទ្ធកម្ម និងទិញទំនិញ', 'Supplier sourcing, purchase orders, vendor quotations and delivery contracts.', 'ការបញ្ជាទិញទំនិញ ទំនាក់ទំនងអ្នកផ្គត់ផ្គង់ និងកិច្ចសន្យា', 'shopping-cart', '08:00:00', '17:00:00', '15:00:00', 'MON,TUE,WED,THU,FRI', 3, 48, 24, 2, 3),
('dept-fin', 'FIN', 'Finance & Accounting', 'ផ្នែកហិរញ្ញវត្ថុ និងគណនេយ្យ', 'Invoices, payments, expense settlements, financial audits and budgets.', 'ការទូទាត់ វិក្កយបត្រ របាយការណ៍ហិរញ្ញវត្ថុ និងសវនកម្ម', 'dollar-sign', '08:00:00', '17:00:00', '15:00:00', 'MON,TUE,WED,THU,FRI', 3, 48, 24, 2, 3),
('dept-hr',  'HR',  'Human Resources', 'ផ្នែកធនធានមនុស្ស (HR)', 'Recruitment, employee onboarding, training, payroll and HR policies.', 'ការជ្រើសរើសបុគ្គលិក បៀវត្ស និងការគ្រប់គ្រងធនធានមនុស្ស', 'users', '08:00:00', '17:00:00', '15:00:00', 'MON,TUE,WED,THU,FRI', 3, 48, 24, 2, 3),
('dept-ops', 'OPS', 'Store Operations', 'ផ្នែកប្រតិបត្តិការផ្សារទំនើប', 'Floor management, inventory display, customer service and cashiers.', 'ប្រតិបត្តិការផ្ទាល់នៅផ្សារ ការរៀបចំទំនិញ និងសេវាកម្មអតិថិជន', 'store', '07:30:00', '21:00:00', '17:00:00', 'MON,TUE,WED,THU,FRI,SAT,SUN', 5, 24, 12, 1, 1)
ON CONFLICT (id) DO NOTHING;

-- Seed Default Admin and Demo Users if not present
INSERT INTO users (username, password_hash, full_name_en, full_name_kh, email, phone, company_role, primary_department_id)
VALUES
('admin_staff', '$2a$10$wN1r2yD96s7O/1xek.9V0O2aXf7eE5n4G8tJ6vK9pL3mN7bQ1w2e.', 'System Administrator', 'អ្នកគ្រប់គ្រងប្រព័ន្ធ', 'admin.support@bgroceries.com', '+855 70 999 468', 'ADMIN', 'dept-it'),
('ramean_mkt', '$2a$10$wN1r2yD96s7O/1xek.9V0O2aXf7eE5n4G8tJ6vK9pL3mN7bQ1w2e.', 'Ramean Oeun', 'អឿន រាមៀន', 'ramean.design@bgroceries.com', '+855 12 345 678', 'REQUESTER', 'dept-mkt'),
('sarah_mkt',  '$2a$10$wN1r2yD96s7O/1xek.9V0O2aXf7eE5n4G8tJ6vK9pL3mN7bQ1w2e.', 'Sarah Chen', 'សារ៉ា ចិន', 'sarah.creative@bgroceries.com', '+855 12 888 999', 'REQUESTER', 'dept-mkt'),
('mkt_manager', '$2a$10$wN1r2yD96s7O/1xek.9V0O2aXf7eE5n4G8tJ6vK9pL3mN7bQ1w2e.', 'Marketing Manager', 'ប្រធានគ្រប់គ្រងផ្នែកទីផ្សារ', 'mkt.head@bgroceries.com', '+855 12 555 444', 'REQUESTER', 'dept-mkt'),
('gm_executive', '$2a$10$wN1r2yD96s7O/1xek.9V0O2aXf7eE5n4G8tJ6vK9pL3mN7bQ1w2e.', 'General Manager', 'អគ្គនាយកប្រតិបត្តិ', 'gm@bgroceries.com', '+855 12 111 222', 'EXECUTIVE', 'dept-ops')
ON CONFLICT (username) DO NOTHING;

-- Assign Department Memberships for Marketing
INSERT INTO department_members (department_id, user_id, dept_role, is_primary)
SELECT 'dept-mkt', u.id, 'LEAD', true FROM users u WHERE u.username = 'sarah_mkt'
ON CONFLICT (department_id, user_id) DO NOTHING;

INSERT INTO department_members (department_id, user_id, dept_role, is_primary)
SELECT 'dept-mkt', u.id, 'ASSIGNEE', true FROM users u WHERE u.username = 'ramean_mkt'
ON CONFLICT (department_id, user_id) DO NOTHING;

INSERT INTO department_members (department_id, user_id, dept_role, is_primary)
SELECT 'dept-mkt', u.id, 'MANAGER', true FROM users u WHERE u.username = 'mkt_manager'
ON CONFLICT (department_id, user_id) DO NOTHING;

-- Link Marketing Leads
UPDATE departments 
SET lead_user_id = (SELECT id FROM users WHERE username = 'sarah_mkt'),
    backup_user_id = (SELECT id FROM users WHERE username = 'mkt_manager')
WHERE id = 'dept-mkt';

-- =============================================================================
-- SEED DATA: MARKETING 5-STEP WORKFLOW STATUSES & PAUSE STATUS
-- =============================================================================

INSERT INTO workflow_statuses (department_id, status_key, name_en, name_kh, step_order, is_timer_running, is_review_stage, is_terminal, badge_color)
VALUES
('dept-mkt', 'SUBMITTED', 'Submitted', 'បានដាក់ស្នើ', 1, false, false, false, 'blue'),
('dept-mkt', 'BRIEF_CHECK', 'Brief Check', 'ត្រួតពិនិត្យឯកសារសង្ខេប', 2, false, false, false, 'amber'),
('dept-mkt', 'IN_PRODUCTION', 'In Production', 'កំពុងដំណើរការផលិត', 3, true, false, false, 'purple'),
('dept-mkt', 'IN_REVIEW', 'In Review', 'កំពុងត្រួតពិនិត្យផ្ទៀងផ្ទាត់', 4, true, true, false, 'indigo'),
('dept-mkt', 'APPROVED_DELIVERED', 'Approved / Delivered', 'បានអនុម័ត / ប្រគល់ជូន', 5, false, false, true, 'emerald'),
('dept-mkt', 'WAITING_FOR_REQUESTER', 'Waiting for Requester', 'រង់ចាំព័ត៌មានពីអ្នកស្នើ', 90, false, false, false, 'orange'),
('dept-mkt', 'REJECTED', 'Rejected', 'បដិសេធ (ឯកសារមិនគ្រប់)', 99, false, false, true, 'rose')
ON CONFLICT (department_id, status_key) DO NOTHING;

-- Marketing Allowed Transitions
INSERT INTO workflow_transitions (department_id, from_status_id, to_status_id, transition_name_en, transition_name_kh, allowed_roles, requires_comment, increments_revision, is_rejection)
SELECT 
    'dept-mkt', s1.id, s2.id, 'Validate Brief', 'ចាប់ផ្ដើមត្រួតពិនិត្យ Brief', 'DESK_OPS,LEAD,MANAGER', false, false, false
FROM workflow_statuses s1, workflow_statuses s2 
WHERE s1.department_id = 'dept-mkt' AND s1.status_key = 'SUBMITTED' 
  AND s2.department_id = 'dept-mkt' AND s2.status_key = 'BRIEF_CHECK';

INSERT INTO workflow_transitions (department_id, from_status_id, to_status_id, transition_name_en, transition_name_kh, allowed_roles, requires_comment, increments_revision, is_rejection)
SELECT 
    'dept-mkt', s1.id, s2.id, 'Approve Brief & Start Production', 'យល់ព្រម Brief & ចាប់ផ្ដើមផលិត', 'DESK_OPS,LEAD,MANAGER', false, false, false
FROM workflow_statuses s1, workflow_statuses s2 
WHERE s1.department_id = 'dept-mkt' AND s1.status_key = 'BRIEF_CHECK' 
  AND s2.department_id = 'dept-mkt' AND s2.status_key = 'IN_PRODUCTION';

INSERT INTO workflow_transitions (department_id, from_status_id, to_status_id, transition_name_en, transition_name_kh, allowed_roles, requires_comment, increments_revision, is_rejection)
SELECT 
    'dept-mkt', s1.id, s2.id, 'Reject Brief (Incomplete)', 'បដិសេធ Brief (ខ្វះព័ត៌មាន)', 'DESK_OPS,LEAD,MANAGER', true, false, true
FROM workflow_statuses s1, workflow_statuses s2 
WHERE s1.department_id = 'dept-mkt' AND s1.status_key = 'BRIEF_CHECK' 
  AND s2.department_id = 'dept-mkt' AND s2.status_key = 'REJECTED';

INSERT INTO workflow_transitions (department_id, from_status_id, to_status_id, transition_name_en, transition_name_kh, allowed_roles, requires_comment, increments_revision, is_rejection)
SELECT 
    'dept-mkt', s1.id, s2.id, 'Submit for Stakeholder Review', 'ដាក់ជូនត្រួតពិនិត្យផ្ទៀងផ្ទាត់', 'ASSIGNEE,LEAD,MANAGER', false, false, false
FROM workflow_statuses s1, workflow_statuses s2 
WHERE s1.department_id = 'dept-mkt' AND s1.status_key = 'IN_PRODUCTION' 
  AND s2.department_id = 'dept-mkt' AND s2.status_key = 'IN_REVIEW';

INSERT INTO workflow_transitions (department_id, from_status_id, to_status_id, transition_name_en, transition_name_kh, allowed_roles, requires_comment, increments_revision, is_rejection)
SELECT 
    'dept-mkt', s1.id, s2.id, 'Request Revision', 'ស្នើសុំកែប្រែ (Revision)', 'REQUESTER,LEAD,MANAGER', true, true, false
FROM workflow_statuses s1, workflow_statuses s2 
WHERE s1.department_id = 'dept-mkt' AND s1.status_key = 'IN_REVIEW' 
  AND s2.department_id = 'dept-mkt' AND s2.status_key = 'IN_PRODUCTION';

INSERT INTO workflow_transitions (department_id, from_status_id, to_status_id, transition_name_en, transition_name_kh, allowed_roles, requires_comment, increments_revision, is_rejection)
SELECT 
    'dept-mkt', s1.id, s2.id, 'Approve & Deliver Assets', 'អនុម័ត & ប្រគល់ឯកសារសម្រេច', 'REQUESTER,LEAD,MANAGER', false, false, false
FROM workflow_statuses s1, workflow_statuses s2 
WHERE s1.department_id = 'dept-mkt' AND s1.status_key = 'IN_REVIEW' 
  AND s2.department_id = 'dept-mkt' AND s2.status_key = 'APPROVED_DELIVERED';

INSERT INTO workflow_transitions (department_id, from_status_id, to_status_id, transition_name_en, transition_name_kh, allowed_roles, requires_comment, increments_revision, is_rejection)
SELECT 
    'dept-mkt', s1.id, s2.id, 'Pause Clock (Wait for Requester Info)', 'ផ្អាកនាឡិកា (រង់ចាំព័ត៌មានបន្ថែម)', 'ASSIGNEE,LEAD,MANAGER', true, false, false
FROM workflow_statuses s1, workflow_statuses s2 
WHERE s1.department_id = 'dept-mkt' AND s1.status_key = 'IN_PRODUCTION' 
  AND s2.department_id = 'dept-mkt' AND s2.status_key = 'WAITING_FOR_REQUESTER';

INSERT INTO workflow_transitions (department_id, from_status_id, to_status_id, transition_name_en, transition_name_kh, allowed_roles, requires_comment, increments_revision, is_rejection)
SELECT 
    'dept-mkt', s1.id, s2.id, 'Resume Production', 'បន្តដំណើរការផលិត', 'ASSIGNEE,LEAD,MANAGER', false, false, false
FROM workflow_statuses s1, workflow_statuses s2 
WHERE s1.department_id = 'dept-mkt' AND s1.status_key = 'WAITING_FOR_REQUESTER' 
  AND s2.department_id = 'dept-mkt' AND s2.status_key = 'IN_PRODUCTION';

-- =============================================================================
-- SEED DATA: MARKETING SERVICE CATALOG (18 Items from Deck & RACI Excel)
-- =============================================================================

INSERT INTO service_catalog (
    department_id, code, name_en, name_kh, category_en, category_kh,
    standard_tat_days, standard_tat_hours, rush_tat_hours, review_sla_hours,
    deliverable_specs_en, deliverable_specs_kh, default_priority,
    responsible_lead_title_en, responsible_lead_title_kh,
    brief_requirements_en, brief_requirements_kh, brief_schema, sort_order
)
VALUES
(
    'dept-mkt', 'MKT-DES-01',
    'Social Media Graphics - Static', 'រូបភាពបណ្ដាញសង្គមទោល (Static Graphics)',
    'Creative & Design', 'ការរចនា និងគំនិតច្នៃប្រឌិត',
    2, 16, 24, 4,
    'PNG, JPG, 1080x1080px (1:1), 1080x1920px (9:16), layered PSD',
    'PNG, JPG, 1080x1080px (1:1), 1080x1920px (9:16), layered PSD',
    'P3', 'Graphic Designer / Creative Lead', 'អ្នករចនាក្រាហ្វិក / ប្រធានផ្នែកច្នៃប្រឌិត',
    'Visual theme, exact copy/headline, high-res product packshots, promo offer details',
    'ប្រធានបទរូបភាព អត្ថបទចំណងជើង រូបផលិតផលច្បាស់ និងព័ត៌មានប្រូម៉ូសិន',
    '[{"id":"headline","label":"Headline / Copy","type":"text","required":true},{"id":"dimensions","label":"Placement / Dimension","type":"select","options":["1080x1080 (Square)","1080x1920 (Story)","Facebook Banner"],"required":true},{"id":"product_packshot","label":"Product Packshot URL","type":"file","required":true}]'::jsonb,
    1
),
(
    'dept-mkt', 'MKT-DES-02',
    'Social Media Carousel (5-10 slides)', 'ផ្ទាំងរូបភាពរំកិលបណ្ដាញសង្គម (Carousel 5-10 Slides)',
    'Creative & Design', 'ការរចនា និងគំនិតច្នៃប្រឌិត',
    3, 24, 24, 4,
    'Set of 5-10 square slides (1080x1080px) in PNG + source PSD/AI',
    'ផ្ទាំងរូបភាពការ៉េ ៥-១០ សន្លឹក (1080x1080px) ជាប្រភេទ PNG + PSD/AI ដើម',
    'P3', 'Trade Designer / Production Lead', 'អ្នករចនាពាណិជ្ជកម្ម / ប្រធានផ្នែកផលិត',
    'Slide-by-slide copy outline, SKU barcodes, discount mechanics, hero product imagery',
    'ខ្លឹមសារលម្អិតតាមផ្ទាំង Barcode ទំនិញ លក្ខខណ្ឌបញ្ចុះតម្លៃ និងរូបផលិតផលចម្បង',
    '[{"id":"slide_count","label":"Number of Slides","type":"number","required":true},{"id":"slide_content","label":"Content per Slide","type":"textarea","required":true}]'::jsonb,
    2
),
(
    'dept-mkt', 'MKT-DES-03',
    'Weekly Promotional Catalog (8-16 pages)', 'កាតាឡុកប្រូម៉ូសិនប្រចាំសប្ដាហ៍ (៨-១៦ ទំព័រ)',
    'Creative & Design', 'ការរចនា និងគំនិតច្នៃប្រឌិត',
    5, 40, 48, 8,
    'Hi-Res Interactive PDF, InDesign package, print-ready CMYK files',
    'PDF គុណភាពខ្ពស់ កញ្ចប់ InDesign និងឯកសារ CMYK សម្រាប់បោះពុម្ព',
    'P3', 'Senior Designer / Desktop Publisher', 'អ្នករចនាជាន់ខ្ពស់ / អ្នករៀបចំទំព័រ',
    'Final signed-off SKU pricing list (Excel), high-res item photos, category hierarchy',
    'បញ្ជីតម្លៃទំនិញអនុម័តរួច (Excel) រូបភាពច្បាស់ និងការបែងចែកក្រុមទំនិញ',
    '[{"id":"sku_file","label":"Approved SKU Pricing Excel","type":"file","required":true},{"id":"page_count","label":"Number of Pages","type":"select","options":["8 Pages","12 Pages","16 Pages"],"required":true}]'::jsonb,
    3
),
(
    'dept-mkt', 'MKT-DES-04',
    'In-Store Signage & POSM Posters', 'ស្លាកសញ្ញា និងផ្ទាំងរូបភាពក្នុងផ្សារ (POSM / Poster)',
    'Creative & Design', 'ការរចនា និងគំនិតច្នៃប្រឌិត',
    3, 24, 24, 4,
    'Print-ready PDF (CMYK, 300 DPI, 3mm bleed), AI source vector',
    'PDF សម្រាប់បោះពុម្ព (CMYK, 300 DPI, 3mm bleed), AI source vector',
    'P3', 'Packaging Specialist / Brand Lead', 'អ្នកជំនាញការវេចខ្ចប់ / ប្រធានម៉ាកសញ្ញា',
    'Print dimensions, dielines, mandatory regulatory texts, price lock dates, barcode',
    'ទំហំបោះពុម្ព គំរូកាត់កម្រាស់ អត្ថបទច្បាប់កំណត់ កាលបរិច្ឆេទតម្លៃ និងបារកូដ',
    '[{"id":"posm_type","label":"POSM Type","type":"select","options":["Gondola End","Wobbler","Shelf Talker","Standee","Entrance Banner"],"required":true},{"id":"dimensions","label":"Exact Dimensions (W x H mm)","type":"text","required":true}]'::jsonb,
    4
),
(
    'dept-mkt', 'MKT-DES-05',
    'Private Label Packaging Design', 'ការរចនាការវេចខ្ចប់ទំនិញផ្ទាល់ខ្លួន (Packaging Design)',
    'Creative & Design', 'ការរចនា និងគំនិតច្នៃប្រឌិត',
    7, 56, 72, 8,
    'Vector AI, PDF proof, 3D Mockup renders, Pantone spot callouts',
    'Vector AI, គំរូ PDF, រូបភាព 3D Mockup និងកូដពណ៌ Pantone',
    'P4', 'Packaging Specialist / Brand Lead', 'អ្នកជំនាញការវេចខ្ចប់ / ប្រធានម៉ាកសញ្ញា',
    'Legal ingredient lists, nutritional facts, packaging diecut template, FDA/HALAL tags',
    'បញ្ជីគ្រឿងផ្សំតាមច្បាប់ តារាងអាហារូបត្ថម្ភ ប្លង់កាត់ប្រអប់ វិញ្ញាបនបត្រ FDA/HALAL',
    '[{"id":"diecut_template","label":"Die-cut Template (CAD/AI)","type":"file","required":true},{"id":"legal_approval","label":"Regulatory / Legal Approval Doc","type":"file","required":true}]'::jsonb,
    5
),
(
    'dept-mkt', 'MKT-VID-01',
    'Short-Form Promo Video (Reels/TikTok 15-30s)', 'វីដេអូខ្លីផ្សព្វផ្សាយ (Reels / TikTok ១៥-៣០ វិនាទី)',
    'Multimedia & Video', 'ពហុព័ត៌មាន និងវីដេអូ',
    3, 24, 24, 4,
    'MP4 (H.264), 1080x1920 (9:16), 60fps, captioned SRT subtitles',
    'MP4 (H.264), 1080x1920 (9:16), 60fps, អក្សររត់ SRT ខ្មែរ/អង់គ្លេស',
    'P3', 'Video Producer / Motion Designer', 'អ្នកផលិតវីដេអូ / អ្នកចលនាក្រាហ្វិក',
    'Recipe/story script, sound hook choice, featured ingredients, store filming access',
    'ស្គ្រីបដំណើររឿង ភ្លេងជ្រើសរើស គ្រឿងផ្សំផលិតផល និងការអនុញ្ញាតថតក្នុងផ្សារ',
    '[{"id":"script","label":"Script / Story Outline","type":"textarea","required":true},{"id":"filming_location","label":"Filming Location in Store","type":"text","required":true}]'::jsonb,
    6
),
(
    'dept-mkt', 'MKT-VID-02',
    'Full Campaign Hero Video (60-90s)', 'វីដេអូចម្បងសម្រាប់យុទ្ធនាការ (Hero Video ៦០-៩០ វិនាទី)',
    'Multimedia & Video', 'ពហុព័ត៌មាន និងវីដេអូ',
    5, 40, 48, 8,
    'Master 4K & 1080p ProRes / MP4 with audio stem mix & clean versions',
    'មេឯកសារ 4K & 1080p ProRes / MP4 រួមទាំងសំឡេងបំបែក និងកំណែគ្មានអក្សរ',
    'P2', 'Video Producer / Motion Designer', 'អ្នកផលិតវីដេអូ / អ្នកចលនាក្រាហ្វិក',
    'Full storyboard, talent consent forms, voiceover script, brand guidelines',
    'Storyboard ពេញលេញ លិខិតយល់ព្រមពីតួសម្ដែង អត្ថបទបញ្ចូលសំឡេង និងគោលការណ៍ម៉ាក',
    '[{"id":"storyboard","label":"Approved Storyboard PDF","type":"file","required":true},{"id":"voiceover_script","label":"Voiceover Script (KH/EN)","type":"textarea","required":true}]'::jsonb,
    7
),
(
    'dept-mkt', 'MKT-VID-03',
    'Product Photography - High Res', 'ការថតរូបផលិតផលច្បាស់កម្រិតខ្ពស់ (Studio Packshots)',
    'Multimedia & Video', 'ពហុព័ត៌មាន និងវីដេអូ',
    4, 32, 48, 6,
    'Raw TIFF + Master JPG (Adobe RGB, 4K resolution, transparent PNG cutouts)',
    'TIFF ដើម + JPG មេ (Adobe RGB, 4K resolution, រូបកាត់ផ្ទៃក្រោយ PNG)',
    'P3', 'Studio Photographer / Food Stylist', 'អ្នកថតរូបស្ទូឌីយោ / អ្នកតុបតែងម្ហូប',
    'Sample product availability, prop requirements, mood board references, shot count',
    'ទំនិញគំរូជាក់ស្ដែង ឧបករណ៍តុបតែង គំរូ Moodboard និងចំនួនប្លង់ថត',
    '[{"id":"item_count","label":"Total Number of Products","type":"number","required":true},{"id":"moodboard","label":"Reference Moodboard","type":"file","required":true}]'::jsonb,
    8
),
(
    'dept-mkt', 'MKT-CPY-01',
    'Article & Press Release Copy (KH/EN)', 'អត្ថបទសារព័ត៌មាន និងផ្សព្វផ្សាយ (KH/EN)',
    'Copywriting & Content', 'ការសរសេរអត្ថបទ និងខ្លឹមសារ',
    2, 16, 24, 3,
    'Google Docs / Word with character counts, emojis & CTA variants',
    'Google Docs / Word រួមមានចំនួនតួអក្សរ រូប Emoji និងជម្រើស Call To Action',
    'P3', 'Senior Copywriter / Content Lead', 'អ្នកសរសេរអត្ថបទជាន់ខ្ពស់ / ប្រធានខ្លឹមសារ',
    'Key selling proposition, tone of voice, promo redemption rules, mandatory tags',
    'ចំណុចលេចធ្លោនៃផលិតផល សំនៀងសរសេរ លក្ខខណ្ឌប្រូម៉ូសិន និង Tag ចាំបាច់',
    '[{"id":"topic","label":"Topic & Objectives","type":"text","required":true},{"id":"language","label":"Language","type":"select","options":["Khmer Only","English Only","Bilingual KH & EN"],"required":true}]'::jsonb,
    9
),
(
    'dept-mkt', 'MKT-CPY-02',
    'Brand Identity & Guidelines Document', 'ឯកសារគោលការណ៍ម៉ាកសញ្ញា (Brand Guidelines)',
    'Copywriting & Content', 'ការសរសេរអត្ថបទ និងខ្លឹមសារ',
    10, 80, 72, 16,
    'Master Vector AI, SVG, PNG logos, Typography kit, PDF Brand Book',
    'Vector AI, SVG, PNG និមិត្តសញ្ញា ហ្វុនអក្សរ និងសៀវភៅគោលការណ៍ម៉ាក PDF',
    'P4', 'Brand Director / Art Director', 'នាយកម៉ាកសញ្ញា / នាយកសិល្បៈ',
    'Brand positioning statement, core values, typography licenses, color swatches',
    'ទស្សនវិស័យម៉ាកសញ្ញា តម្លៃស្នូល អាជ្ញាប័ណ្ណហ្វុន និងកូដពណ៌ស្តង់ដារ',
    '[{"id":"brand_scope","label":"Brand Scope & Deliverables","type":"textarea","required":true}]'::jsonb,
    10
),
(
    'dept-mkt', 'MKT-REV-01',
    'Minor Creative Revisions / Price Adjustments', 'ការកែសម្រួលក្រាហ្វិកតូចតាច / ប្តូរតម្លៃ (Minor Revision)',
    'Creative & Design', 'ការរចនា និងគំនិតច្នៃប្រឌិត',
    1, 8, 4, 2,
    'Updated export files matching original format specifications',
    'ឯកសារកែសម្រួលថ្មីស្របតាមលក្ខណៈបច្ចេកទេសដើម',
    'P3', 'Assigned Original Specialist', 'អ្នកជំនាញដើមដែលបានចាត់តាំង',
    'Specific ticket reference ID, exact text/price corrections, rationale',
    'លេខកូដសំបុត្រដើម កន្លែងកែប្រែជាក់លាក់ និងហេតុផល',
    '[{"id":"original_ticket","label":"Original Ticket Number","type":"text","required":true},{"id":"change_description","label":"Specific Corrections Needed","type":"textarea","required":true}]'::jsonb,
    11
),
(
    'dept-mkt', 'MKT-CMP-01',
    'Monthly Promotional Campaign (360 Execution)', 'យុទ្ធនាការប្រូម៉ូសិនប្រចាំខែ (360 Campaign)',
    'Campaigns & Strategy', 'យុទ្ធនាការ និងយុទ្ធសាស្ត្រ',
    5, 40, 48, 16,
    'Master Deck (PPTX/PDF), Gantt Schedule, Media Budget Allocation',
    'Master Deck (PPTX/PDF), តារាង Gantt ពេលវេលា និងការបែងចែកថវិកាផ្សព្វផ្សាយ',
    'P2', 'Head of Marketing / Campaign Lead', 'ប្រធានផ្នែកទីផ្សារ / ប្រធានយុទ្ធនាការ',
    'Commercial sales targets, vendor co-funding commitments, promo mechanics',
    'គោលដៅលក់ពាណិជ្ជកម្ម ថវិកាសហការពីអ្នកផ្គត់ផ្គង់ និងលក្ខខណ្ឌប្រូម៉ូសិន',
    '[{"id":"campaign_budget","label":"Total Campaign Budget ($)","type":"number","required":true},{"id":"start_date","label":"Go-Live Launch Date","type":"date","required":true}]'::jsonb,
    12
),
(
    'dept-mkt', 'MKT-DIG-01',
    'Paid Digital Ads Setup & Optimization', 'ការរៀបចំ និងគ្រប់គ្រងពាណិជ្ជកម្មឌីជីថល (Paid Ads)',
    'Digital Marketing', 'ទីផ្សារឌីជីថល',
    3, 24, 24, 4,
    'Live Ad Campaign IDs, Tracking UTM matrix, Audience demographic map',
    'លេខសម្គាល់យុទ្ធនាការ Ads, តារាងតាមដាន UTM និងកំណត់ក្រុមអតិថិជនគោលដៅ',
    'P3', 'Digital Media / Paid Ads Specialist', 'អ្នកជំនាញផ្សព្វផ្សាយឌីជីថល / Paid Ads',
    'Approved ad spend budget, target ROAS/CPA, geographic store radius geotargeting',
    'កញ្ចប់ថវិកាផ្សាយដែលបានអនុម័ត គោលដៅ ROAS/CPA និងកាំទីតាំងជុំវិញសាខា',
    '[{"id":"ad_budget","label":"Ad Spend Budget ($)","type":"number","required":true},{"id":"channels","label":"Channels","type":"select","options":["Meta (FB/IG)","TikTok Ads","Google Search/PMax"],"required":true}]'::jsonb,
    13
),
(
    'dept-mkt', 'MKT-DIG-02',
    'E-Commerce Banners & Home Carousel', 'បដាពាណិជ្ជកម្មលើ Website / App (Banners & Carousel)',
    'Digital Marketing', 'ទីផ្សារឌីជីថល',
    2, 16, 24, 4,
    'WebP, PNG, SVG icons, optimized for <150KB web load speed',
    'WebP, PNG, SVG icons កម្រិតទំហំក្រោម <150KB សម្រាប់ដំណើរការលឿន',
    'P3', 'Digital UI Designer', 'អ្នករចនា UI ឌីជីថល',
    'Destination Deeplink URL, click-to-action (CTA) text, target audience segment',
    'តំណភ្ជាប់ Deeplink ក្នុង App អត្ថបទប៊ូតុងចុច (CTA) និងក្រុមអតិថិជនគោលដៅ',
    '[{"id":"deeplink","label":"App Deeplink / Web URL","type":"text","required":true},{"id":"banner_slot","label":"Banner Slot Location","type":"select","options":["Home Hero Carousel","Flash Sale Banner","Category Top"],"required":true}]'::jsonb,
    14
),
(
    'dept-mkt', 'MKT-CRM-01',
    'CRM Email & App Push Notification', 'ការផ្ញើសារ App Push និង Email ទៅកាន់សមាជិក (CRM Blast)',
    'Digital Marketing', 'ទីផ្សារឌីជីថល',
    1, 8, 4, 2,
    'Configured CRM blast schedule, short URLs with tracking parameters',
    'កាលវិភាគបញ្ជូនសារ CRM, តំណភ្ជាប់ខ្លី Short URL ជាមួយ tracking code',
    'P3', 'CRM Executive', 'មន្ត្រីប្រតិបត្តិ CRM',
    'Exact character-capped copy (<160 chars for SMS), recipient cohort ID criteria',
    'អក្សរកំណត់ចំនួនតួ (<១៦០ តួសម្រាប់ SMS) និងលក្ខខណ្ឌជ្រើសរើសសមាជិក',
    '[{"id":"push_title","label":"Push Title (<50 chars)","type":"text","required":true},{"id":"push_body","label":"Push Body (<150 chars)","type":"textarea","required":true}]'::jsonb,
    15
),
(
    'dept-mkt', 'MKT-TRD-01',
    'Trade Gondola End & Category Setup', 'ការរៀបចំក្បាលកោះ Gondola End & ស្តង់ដារទំនិញ',
    'Trade Marketing', 'ទីផ្សារពាណិជ្ជកម្មក្នុងផ្សារ',
    5, 40, 48, 8,
    'Co-op Brand Pack, Compliance checklist, Store Layout Allocation Plan',
    'កញ្ចប់ម៉ាកសហការ បញ្ជីផ្ទៀងផ្ទាត់ និងប្លង់ទីតាំងក្នុងផ្សារ',
    'P3', 'Trade Marketing Manager', 'អ្នកគ្រប់គ្រងទីផ្សារពាណិជ្ជកម្ម',
    'Signed vendor sponsorship MOU, co-op budget proof, high-res partner logos',
    'កិច្ចសន្យាឧបត្ថម្ភពីអ្នកផ្គត់ផ្គង់ ភស្តុតាងថវិកា និង Logo ដៃគូច្បាស់',
    '[{"id":"vendor_name","label":"Vendor / Brand Partner","type":"text","required":true},{"id":"store_branch","label":"Store Branches","type":"text","required":true}]'::jsonb,
    16
),
(
    'dept-mkt', 'MKT-PR-01',
    'Crisis PR & Official Statement', 'សេចក្តីថ្លែងការណ៍បន្ទាន់ / ដោះស្រាយវិបត្តិ (Crisis PR)',
    'PR & Corporate Affairs', 'ទំនាក់ទំនងសាធារណៈ',
    1, 4, 2, 1,
    'Official Statement PDF, FAQ Script for CS team, Social holding statement',
    'សេចក្តីថ្លែងការណ៍ផ្លូវការ PDF ស្គ្រីបឆ្លើយសំណួរសម្រាប់ផ្នែក CS និងសារបណ្ដាញសង្គម',
    'P1', 'PR Director / Corporate Affairs', 'នាយកទំនាក់ទំនងសាធារណៈ / កិច្ចការសាជីវកម្ម',
    'Incident report, legal counsel clearance, executive committee sign-off',
    'របាយការណ៍ហេតុការណ៍ ការយល់ព្រមពីមេធាវី និងការចុះហត្ថលេខាពីគណៈនាយក',
    '[{"id":"incident_summary","label":"Incident Details","type":"textarea","required":true},{"id":"legal_clearance","label":"Legal Clearance Attachment","type":"file","required":true}]'::jsonb,
    17
),
(
    'dept-mkt', 'MKT-REP-01',
    'Weekly Marketing Dashboard & Insights', 'របាយការណ៍ និងស្ថិតិទីផ្សារប្រចាំសប្ដាហ៍ (Dashboard & KPI)',
    'Marketing Operations', 'ប្រតិបត្តិការទីផ្សារ',
    4, 32, 48, 6,
    'Interactive Looker/PowerBI Dashboard link + Executive PPT Summary',
    'តំណភ្ជាប់ Looker/PowerBI Dashboard + ស្លាយសង្ខេបប្រតិបត្តិ PPTX',
    'P3', 'Data Analyst / Growth Marketer', 'អ្នកវិភាគទិន្នន័យ / ទីផ្សារកំណើន',
    'Monthly revenue totals, POS basket size data, verified media expenditure figures',
    'ទិន្នន័យចំណូលសរុប ទំហំកន្ត្រកទិញទំនិញ POS និងតួលេខចំណាយផ្សាយជាក់ស្ដែង',
    '[{"id":"reporting_period","label":"Reporting Period","type":"text","required":true}]'::jsonb,
    18
)
ON CONFLICT (code) DO NOTHING;

-- =============================================================================
-- SEED DATA: MARKETING SLA POLICIES (P1 to P4)
-- =============================================================================

INSERT INTO sla_policies (department_id, priority_tier, name_en, name_kh, initial_response_minutes, tat_hours, tat_business_days, approver_role, alert_delay_threshold_hours, alert_recipient_role)
VALUES
('dept-mkt', 'P1', 'Critical / Urgent', 'បន្ទាន់កម្រិតធ្ងន់ធ្ងរ (P1)', 0, 4, 0, 'EXECUTIVE', 2, 'GM_EXECUTIVE'),
('dept-mkt', 'P2', 'High Priority', 'អាទិភាពខ្ពស់ (P2)', 30, 8, 1, 'MARKETING_DIRECTOR', 1, 'MARKETING_DIRECTOR'),
('dept-mkt', 'P3', 'Medium (Standard)', 'អាទិភាពមធ្យម - ស្តង់ដារ (P3)', 120, 24, 2, 'MARKETING_MANAGER', 4, 'MARKETING_LEAD'),
('dept-mkt', 'P4', 'Low / Routine', 'អាទិភាពទាប - ទម្លាប់ធម្មតា (P4)', 240, 40, 5, 'LEAD', 24, 'DEPARTMENT_LEAD')
ON CONFLICT (department_id, priority_tier) DO NOTHING;

-- =============================================================================
-- SEED DATA: MARKETING ESCALATION RULES (Level 1 to Level 4)
-- =============================================================================

INSERT INTO escalation_rules (department_id, escalation_level, name_en, name_kh, trigger_delay_hours, target_role, resolution_sla_hours, action_required_en, action_required_kh)
VALUES
(
    'dept-mkt', 1, 'Level 1: Minor Delay', 'កម្រិត ១: យឺតយ៉ាវកម្រិតស្រាល', 0,
    'PRIMARY_RESOLVER', 24,
    'Notify primary resolver and direct supervisor; review blocker reason.',
    'ជូនដំណឹងដល់អ្នកទទួលខុសត្រូវផ្ទាល់ និងប្រធានក្រុម ដើម្បីដោះស្រាយបញ្ហាស្ទះ។'
),
(
    'dept-mkt', 2, 'Level 2: Moderate Delay', 'កម្រិត ២: យឺតយ៉ាវកម្រិតមធ្យម', 24,
    'CREATIVE_LEAD', 4,
    'Alert Creative Lead and Marketing Manager; reallocate production queue or split task.',
    'ជូនដំណឹងដល់ប្រធានផ្នែកច្នៃប្រឌិត និងប្រធានទីផ្សារ ដើម្បីបែងចែកភារកិច្ចឡើងវិញ។'
),
(
    'dept-mkt', 3, 'Level 3: Major Delay', 'កម្រិត ៣: យឺតយ៉ាវកម្រិតធ្ងន់ធ្ងរ', 48,
    'MARKETING_MANAGER', 8,
    'Escalate to Marketing Director; engage backup specialist or activate overtime agency.',
    'បញ្ជូនទៅប្រធានទីផ្សារធំ ប្រើប្រាស់បុគ្គលិកបម្រុង ឬផ្ទេរការងារទៅ Agency បន្ទាន់។'
),
(
    'dept-mkt', 4, 'Level 4: Critical / Crisis', 'កម្រិត ៤: វិបត្តិធ្ងន់ធ្ងរ ឬប៉ះពាល់ការបើកសាខា', 72,
    'GM_EXECUTIVE', 2,
    'Emergency executive intervention with GM and Head of Commercial; immediate print recall/fast-track.',
    'កិច្ចប្រជុំបន្ទាន់ជាមួយអគ្គនាយកប្រតិបត្តិ (GM) និងនាយកពាណិជ្ជកម្ម ដើម្បីដោះស្រាយជាបន្ទាន់។'
)
ON CONFLICT (department_id, escalation_level) DO NOTHING;

-- =============================================================================
-- SEED DATA: CAMBODIAN PUBLIC HOLIDAYS 2026/2027
-- =============================================================================

INSERT INTO business_calendar_holidays (holiday_date, name_en, name_kh, is_recurring)
VALUES
('2026-01-01', 'International New Year Day', 'ទិវាចូលឆ្នាំសកល', true),
('2026-01-07', 'Victory over Genocide Day', 'ទិវាជ័យជម្នះលើរបបប្រល័យពូជសាសន៍', true),
('2026-03-08', 'International Women Day', 'ទិវាអន្តរជាតិនារី', true),
('2026-04-14', 'Khmer New Year Day 1', 'ពិធីបុណ្យចូលឆ្នាំថ្មីប្រពៃណីជាតិ ថ្ងៃទី១', false),
('2026-04-15', 'Khmer New Year Day 2', 'ពិធីបុណ្យចូលឆ្នាំថ្មីប្រពៃណីជាតិ ថ្ងៃទី២', false),
('2026-04-16', 'Khmer New Year Day 3', 'ពិធីបុណ្យចូលឆ្នាំថ្មីប្រពៃណីជាតិ ថ្ងៃទី៣', false),
('2026-05-01', 'International Labor Day', 'ទិវាពលកម្មអន្តរជាតិ', true),
('2026-05-14', 'King Sihamoni Birthday', 'ព្រះរាជពិធីបុណ្យចម្រើនព្រះជន្ម ព្រះមហាក្សត្រ', true),
('2026-09-24', 'Constitutional Day', 'ទិវាប្រកាសរដ្ឋធម្មនុញ្ញ', true),
('2026-10-10', 'Pchum Ben Day 1', 'ពិធីបុណ្យភ្ជុំបិណ្ឌ ថ្ងៃទី១', false),
('2026-10-11', 'Pchum Ben Day 2', 'ពិធីបុណ្យភ្ជុំបិណ្ឌ ថ្ងៃទី២', false),
('2026-10-12', 'Pchum Ben Day 3', 'ពិធីបុណ្យភ្ជុំបិណ្ឌ ថ្ងៃទី៣', false),
('2026-10-29', 'King Coronation Day', 'ព្រះរាជពិធីគ្រងព្រះបរមរាជសម្បត្តិ', true),
('2026-11-09', 'National Independence Day', 'ទិវាបុណ្យឯករាជ្យជាតិ', true),
('2026-11-23', 'Water Festival Day 1', 'ព្រះរាជពិធីបុណ្យអុំទូក ថ្ងៃទី១', false),
('2026-11-24', 'Water Festival Day 2', 'ព្រះរាជពិធីបុណ្យអុំទូក ថ្ងៃទី២', false),
('2026-11-25', 'Water Festival Day 3', 'ព្រះរាជពិធីបុណ្យអុំទូក ថ្ងៃទី៣', false)
ON CONFLICT (holiday_date) DO NOTHING;
