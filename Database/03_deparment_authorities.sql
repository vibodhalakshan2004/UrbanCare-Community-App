-- 1. Create the Departments Table 
CREATE TABLE departments (
    department_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    responsible_issue_types TEXT[], 
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create the Authorities (Using the final overriding version from your script)
CREATE TABLE authorities (
    -- Links back to users table (1:1 Inheritance)
    authority_id UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Links to the department table (1:N Association)
    department_id UUID REFERENCES departments(department_id),
    
    badge_number VARCHAR(50) UNIQUE NOT NULL,
    total_points INT DEFAULT 0,
    resolved_count INT DEFAULT 0,
    avg_resolution_hours FLOAT,
    fcm_token TEXT
);

CREATE TRIGGER set_authorities_updated_at 
BEFORE UPDATE ON authorities 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();
