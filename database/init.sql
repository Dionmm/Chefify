-- Initialize Chefify database
-- This script runs before the recipes.sql schema file

-- Create any necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set timezone
SET timezone = 'UTC';

-- Create initial user if needed (postgres user should already exist from environment variables)
-- Additional database setup can be added here as needed