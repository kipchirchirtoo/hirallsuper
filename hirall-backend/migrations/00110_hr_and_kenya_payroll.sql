-- ==============================================================================
-- 00110_hr_and_kenya_payroll.sql
-- Human Resources, Attendance, Shifts & Kenyan Statutory Payroll (PAYE, NSSF, SHIF, Housing Levy)
-- ==============================================================================

-- 1. Employees Master
CREATE TABLE IF NOT EXISTS employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Optional link to login user
    employee_number VARCHAR(64) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    national_id VARCHAR(50) NOT NULL,
    kra_pin VARCHAR(50) NOT NULL, -- Required for statutory PAYE
    nssf_number VARCHAR(50),
    shif_number VARCHAR(50),      -- Social Health Insurance Fund
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    job_title VARCHAR(100) NOT NULL, -- 'CASHIER', 'STOREKEEPER', 'WAITER', 'CHEF', 'BARTENDER', 'MANAGER'
    basic_salary NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    housing_allowance NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    transport_allowance NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    bank_name VARCHAR(100),
    bank_account_number VARCHAR(100),
    employment_status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE', 'ON_LEAVE', 'TERMINATED'
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_emp_num UNIQUE (organization_id, employee_number)
);

CREATE INDEX IF NOT EXISTS idx_employees_branch ON employees(branch_id, employment_status);

-- 2. Biometric / PIN Attendance Logs
CREATE TABLE IF NOT EXISTS attendance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    clock_in TIMESTAMPTZ NOT NULL,
    clock_out TIMESTAMPTZ,
    total_hours NUMERIC(5, 2),
    overtime_hours NUMERIC(5, 2) DEFAULT 0.00,
    source VARCHAR(32) NOT NULL DEFAULT 'POS_TERMINAL', -- 'POS_TERMINAL', 'BIOMETRIC_DEVICE', 'MANUAL'
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_logs(employee_id, clock_in);

-- 3. Kenyan Statutory Payroll Runs & Payslips
CREATE TABLE IF NOT EXISTS payroll_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    payroll_month INT NOT NULL, -- 1-12
    payroll_year INT NOT NULL,  -- e.g. 2026
    total_gross_pay NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    total_paye_tax NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    total_nssf NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    total_shif NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    total_housing_levy NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    total_net_pay NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    status VARCHAR(32) NOT NULL DEFAULT 'DRAFT', -- 'DRAFT', 'APPROVED', 'PAID'
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payroll_period UNIQUE (organization_id, payroll_year, payroll_month)
);

CREATE TABLE IF NOT EXISTS payslips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payroll_run_id UUID NOT NULL REFERENCES payroll_runs(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    
    -- Earnings
    basic_salary NUMERIC(12, 4) NOT NULL,
    allowances NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    overtime_pay NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    gross_pay NUMERIC(12, 4) NOT NULL,
    
    -- Kenya Statutory Deductions
    paye_tax NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,       -- KRA Pay As You Earn
    nssf_tier1 NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,     -- NSSF Tier 1
    nssf_tier2 NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,     -- NSSF Tier 2
    shif_deduction NUMERIC(12, 4) NOT NULL DEFAULT 0.0000, -- SHIF (2.75% of gross)
    housing_levy NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,   -- Affordable Housing Levy (1.5%)
    salary_advance_deduction NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    
    net_pay NUMERIC(12, 4) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
