-- Create tables manually if Hibernate fails

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Spreadsheets table
CREATE TABLE IF NOT EXISTS spreadsheets (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Sheets table
CREATE TABLE IF NOT EXISTS sheets (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    spreadsheet_id BIGINT NOT NULL,
    order_index INTEGER DEFAULT 0,
    row_count INTEGER DEFAULT 1000,
    column_count INTEGER DEFAULT 26,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (spreadsheet_id) REFERENCES spreadsheets(id) ON DELETE CASCADE
);

-- Cells table
CREATE TABLE IF NOT EXISTS cells (
    id BIGSERIAL PRIMARY KEY,
    sheet_id BIGINT NOT NULL,
    row_index INTEGER NOT NULL,
    column_index INTEGER NOT NULL,
    cell_value TEXT,
    FOREIGN KEY (sheet_id) REFERENCES sheets(id) ON DELETE CASCADE,
    UNIQUE(sheet_id, row_index, column_index)
);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_sheet_row_col ON cells(sheet_id, row_index, column_index);

-- Media table
CREATE TABLE IF NOT EXISTS media (
    id BIGSERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    content_type VARCHAR(255),
    file_size BIGINT,
    file_path VARCHAR(500) NOT NULL,
    spreadsheet_id BIGINT NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (spreadsheet_id) REFERENCES spreadsheets(id) ON DELETE CASCADE
);

-- Permissions table
CREATE TABLE IF NOT EXISTS spreadsheet_permissions (
    id BIGSERIAL PRIMARY KEY,
    spreadsheet_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    permission_type VARCHAR(50) NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (spreadsheet_id) REFERENCES spreadsheets(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(spreadsheet_id, user_id)
);

-- Insert default admin user
INSERT INTO users (username, email, password) 
VALUES ('admin', 'admin@example.com', '$2a$10$slYQm6mSLkx5.2hGqG2CdOdP5bCItGqF3rKl3w0Z8PdJGYvNjLKZi')
ON CONFLICT (username) DO NOTHING;

-- Insert test user
INSERT INTO users (username, email, password) 
VALUES ('testuser', 'test@example.com', '$2a$10$slYQm6mSLkx5.2hGqG2CdOdP5bCItGqF3rKl3w0Z8PdJGYvNjLKZi')
ON CONFLICT (username) DO NOTHING;
