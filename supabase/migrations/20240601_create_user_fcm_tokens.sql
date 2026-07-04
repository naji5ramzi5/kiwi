-- Create table for storing user FCM tokens
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    token TEXT NOT NULL UNIQUE,
    device_type TEXT NOT NULL CHECK (device_type IN ('web', 'android', 'ios')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Create policy for users to insert their own tokens
CREATE POLICY "Users can insert their own FCM tokens"
ON public.user_fcm_tokens
FOR INSERT
TO authenticated
USING (true)
WITH CHECK (auth.uid() = user_id);

-- Create policy for users to update their own tokens
CREATE POLICY "Users can update their own FCM tokens"
ON public.user_fcm_tokens
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Create policy for users to delete their own tokens
CREATE POLICY "Users can delete their own FCM tokens"
ON public.user_fcm_tokens
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- Create policy for users to select their own tokens
CREATE POLICY "Users can select their own FCM tokens"
ON public.user_fcm_tokens
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Create index for faster lookups by user_id
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON public.user_fcm_tokens(user_id);

-- Create index for faster lookups by token
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_token ON public.user_fcm_tokens(token);

-- Trigger to automatically update updated_at column
CREATE TRIGGER update_user_fcm_tokens_updated_at
BEFORE UPDATE ON public.user_fcm_tokens
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Comment on table
COMMENT ON TABLE public.user_fcm_tokens IS 'Store FCM tokens for users to enable push notifications';