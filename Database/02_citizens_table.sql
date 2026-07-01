CREATE TABLE citizens (
    -- Links directly to the user_id in the users table
    user_id UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    
    address TEXT,
    date_of_birth DATE,
    
    -- Added from bottom ALTER statements
    fcm_token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER set_citizens_updated_at
BEFORE UPDATE ON citizens
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
