-- Add profile edit limit columns
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS name_change_count INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone_changed BOOLEAN DEFAULT FALSE;
