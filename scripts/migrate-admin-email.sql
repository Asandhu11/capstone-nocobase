-- Rename the original course-project administrator without changing its
-- password, permissions, or associated records. Safe to run more than once.
DO $$
BEGIN
  IF to_regclass('public.users') IS NOT NULL THEN
    UPDATE public.users
       SET email = 'admin@nocobase.com'
     WHERE id = 1
       AND username = 'nocobase'
       AND email = 'admin@nocobase.local';
  END IF;
END;
$$;
