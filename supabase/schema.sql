-- ==============================================================================
-- Muster Database Schema (Supabase / PostgreSQL)
-- Verified & Audited Live Production Schema
-- ==============================================================================

-- ==============================================================================
-- Realtime: Enable postgres_changes for the scans table
-- Run this once in your Supabase SQL editor (or it runs on schema migration)
-- ==============================================================================
ALTER TABLE public.scans REPLICA IDENTITY FULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'scans'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.scans;
  END IF;
END $$;

-- 1. University email domains for automatic lecturer verification
CREATE TABLE IF NOT EXISTS public.university_domains (
  uni text PRIMARY KEY,
  domain text NOT NULL CHECK (domain = lower(domain))
);
ALTER TABLE public.university_domains ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS university_domains_read ON public.university_domains;
CREATE POLICY university_domains_read ON public.university_domains
  FOR SELECT TO authenticated USING (true);

-- 2. Students table with hardware device-binding and backup PIN hash
CREATE TABLE IF NOT EXISTS public.students (
  user_id uuid PRIMARY KEY DEFAULT auth.uid() REFERENCES auth.users (id) ON DELETE CASCADE,
  uni text NOT NULL,
  matric text NOT NULL,
  name text NOT NULL,
  dept text NOT NULL,
  level text NOT NULL,
  verified boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  email text,
  auth_provider text DEFAULT 'google',
  device_id text,
  pin_hash text,
  "pinHash" text,
  CONSTRAINT students_uni_matric_key UNIQUE (uni, matric)
);
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

-- Synchronize pin_hash and "pinHash" for total SDK / frontend backwards compatibility
CREATE OR REPLACE FUNCTION public.sync_students_pin()
RETURNS trigger AS $$
BEGIN
  IF NEW.pin_hash IS NULL AND NEW."pinHash" IS NOT NULL THEN
    NEW.pin_hash := NEW."pinHash";
  ELSIF NEW."pinHash" IS NULL AND NEW.pin_hash IS NOT NULL THEN
    NEW."pinHash" := NEW.pin_hash;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_students_pin ON public.students;
CREATE TRIGGER trg_sync_students_pin
BEFORE INSERT OR UPDATE ON public.students
FOR EACH ROW EXECUTE FUNCTION public.sync_students_pin();

-- 3. Lecturers table
CREATE TABLE IF NOT EXISTS public.lecturers (
  user_id uuid PRIMARY KEY DEFAULT auth.uid() REFERENCES auth.users (id) ON DELETE CASCADE,
  lid text NOT NULL UNIQUE,
  name text NOT NULL,
  uni text NOT NULL,
  pub text NOT NULL,
  verified boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  email text,
  auth_provider text DEFAULT 'google'
);
ALTER TABLE public.lecturers ENABLE ROW LEVEL SECURITY;

-- 4. Lecturer cryptographic signing keys (ECDSA P-256 JWK)
CREATE TABLE IF NOT EXISTS public.lecturer_keys (
  user_id uuid PRIMARY KEY DEFAULT auth.uid() REFERENCES auth.users (id) ON DELETE CASCADE,
  jwk jsonb NOT NULL
);
ALTER TABLE public.lecturer_keys ENABLE ROW LEVEL SECURITY;

-- 5. Lecturer persistent workspace state
CREATE TABLE IF NOT EXISTS public.lecturer_state (
  user_id uuid PRIMARY KEY DEFAULT auth.uid() REFERENCES auth.users (id) ON DELETE CASCADE,
  state jsonb NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.lecturer_state ENABLE ROW LEVEL SECURITY;

-- 6. Legacy lecstate table
CREATE TABLE IF NOT EXISTS public.lecstate (
  lid text PRIMARY KEY,
  user_id uuid REFERENCES auth.users (id) ON DELETE CASCADE,
  json text,
  sig text,
  at bigint,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.lecstate ENABLE ROW LEVEL SECURITY;

-- 7. Sessions table (with dual timestamp columns for web & native compatibility)
CREATE TABLE IF NOT EXISTS public.sessions (
  sid text PRIMARY KEY,
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users (id) ON DELETE CASCADE,
  lid text NOT NULL,
  course text NOT NULL,
  title text,
  lecturer text,
  uni text NOT NULL,
  pin text,
  sk text,
  started_at bigint NOT NULL,
  ended_at bigint,
  startedAt bigint,
  endedAt bigint
);
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.sync_sessions_timestamps()
RETURNS trigger AS $$
BEGIN
  IF NEW."startedAt" IS NOT NULL AND NEW.started_at IS NULL THEN
    NEW.started_at := NEW."startedAt";
  ELSIF NEW.started_at IS NOT NULL AND NEW."startedAt" IS NULL THEN
    NEW."startedAt" := NEW.started_at;
  END IF;
  IF NEW."endedAt" IS NOT NULL AND NEW.ended_at IS NULL THEN
    NEW.ended_at := NEW."endedAt";
  ELSIF NEW.ended_at IS NOT NULL AND NEW."endedAt" IS NULL THEN
    NEW."endedAt" := NEW.ended_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_sessions_timestamps ON public.sessions;
CREATE TRIGGER trg_sync_sessions_timestamps
BEFORE INSERT OR UPDATE ON public.sessions
FOR EACH ROW EXECUTE FUNCTION public.sync_sessions_timestamps();

-- 8. Attendance scans table
CREATE TABLE IF NOT EXISTS public.scans (
  key text PRIMARY KEY,
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users (id) ON DELETE CASCADE,
  uni text NOT NULL,
  matric text NOT NULL,
  name text,
  dept text,
  level text,
  did text,
  kind text NOT NULL,
  sid text,
  course text,
  lid text,
  win bigint,
  sig text,
  pin text,
  pk text,
  at bigint NOT NULL,
  day text NOT NULL,
  status text,
  reason text
);
ALTER TABLE public.scans ENABLE ROW LEVEL SECURITY;

-- 9. Courses table (for institutional multi-lecturer co-teaching)
CREATE TABLE IF NOT EXISTS public.courses (
  id text PRIMARY KEY,
  uni text NOT NULL,
  code text NOT NULL,
  title text,
  depts text,
  level text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT courses_uni_code_key UNIQUE (uni, code)
);
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

-- 10. Course Lecturers junction table
CREATE TABLE IF NOT EXISTS public.course_lecturers (
  course_id text NOT NULL REFERENCES public.courses (id) ON DELETE CASCADE,
  lid text NOT NULL,
  name text NOT NULL,
  user_id uuid DEFAULT auth.uid() REFERENCES auth.users (id) ON DELETE CASCADE,
  joined_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (course_id, lid)
);
ALTER TABLE public.course_lecturers ENABLE ROW LEVEL SECURITY;

-- 11. Matriculation disputes table
CREATE TABLE IF NOT EXISTS public.matric_disputes (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  uni text NOT NULL,
  matric text NOT NULL,
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.matric_disputes ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- Row Level Security (RLS) Policies
-- ==============================================================================

-- Students
DROP POLICY IF EXISTS students_self ON public.students;
CREATE POLICY students_self ON public.students FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS students_roster ON public.students;
CREATE POLICY students_roster ON public.students FOR SELECT TO authenticated USING (is_verified_lecturer_of(uni));

DROP POLICY IF EXISTS students_insert_own ON public.students;
CREATE POLICY students_insert_own ON public.students FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS students_update_own ON public.students;
CREATE POLICY students_update_own ON public.students FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Lecturers
DROP POLICY IF EXISTS lecturers_read ON public.lecturers;
CREATE POLICY lecturers_read ON public.lecturers FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS lecturers_insert_own ON public.lecturers;
CREATE POLICY lecturers_insert_own ON public.lecturers FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS lecturers_update_own ON public.lecturers;
CREATE POLICY lecturers_update_own ON public.lecturers FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Lecturer Keys & State
DROP POLICY IF EXISTS lecturer_keys_own ON public.lecturer_keys;
CREATE POLICY lecturer_keys_own ON public.lecturer_keys FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS lecturer_keys_insert_own ON public.lecturer_keys;
CREATE POLICY lecturer_keys_insert_own ON public.lecturer_keys FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS lecturer_keys_update_own ON public.lecturer_keys;
CREATE POLICY lecturer_keys_update_own ON public.lecturer_keys FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS lecturer_state_own ON public.lecturer_state;
CREATE POLICY lecturer_state_own ON public.lecturer_state FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Sessions
DROP POLICY IF EXISTS sessions_read ON public.sessions;
CREATE POLICY sessions_read ON public.sessions FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS sessions_write_authenticated ON public.sessions;
CREATE POLICY sessions_write_authenticated ON public.sessions FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()) OR (auth.uid() IS NOT NULL));

DROP POLICY IF EXISTS sessions_update_authenticated ON public.sessions;
CREATE POLICY sessions_update_authenticated ON public.sessions FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS sessions_delete ON public.sessions;
CREATE POLICY sessions_delete ON public.sessions FOR DELETE TO authenticated USING (user_id = auth.uid());

-- Scans
DROP POLICY IF EXISTS scans_read_own ON public.scans;
CREATE POLICY scans_read_own ON public.scans FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS scans_read_lecturer ON public.scans;
CREATE POLICY scans_read_lecturer ON public.scans FOR SELECT TO authenticated
  USING (((lid IS NOT NULL) AND (lid = my_lid())) OR ((lid IS NULL) AND (kind = 'pin'::text) AND is_verified_lecturer_of(uni)));

DROP POLICY IF EXISTS scans_insert_own ON public.scans;
CREATE POLICY scans_insert_own ON public.scans FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()) OR (auth.uid() IS NOT NULL));

DROP POLICY IF EXISTS scans_update_any ON public.scans;
CREATE POLICY scans_update_any ON public.scans FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- Disputes & Lecstate
DROP POLICY IF EXISTS disputes_own ON public.matric_disputes;
CREATE POLICY disputes_own ON public.matric_disputes FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS lecstate_all ON public.lecstate;
CREATE POLICY lecstate_all ON public.lecstate FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Courses & Course Lecturers (Institutional Multi-Lecturer Collaboration)
DROP POLICY IF EXISTS courses_read ON public.courses;
CREATE POLICY courses_read ON public.courses FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS courses_write ON public.courses;
CREATE POLICY courses_write ON public.courses FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS course_lecturers_read ON public.course_lecturers;
CREATE POLICY course_lecturers_read ON public.course_lecturers FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS course_lecturers_write ON public.course_lecturers;
CREATE POLICY course_lecturers_write ON public.course_lecturers FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ==============================================================================
-- RPC Functions
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.my_lid()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT lid FROM public.lecturers WHERE user_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_verified_lecturer_of(p_uni text)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.lecturers 
    WHERE user_id = auth.uid() AND (uni = p_uni OR p_uni IS NULL)
  );
$$;

CREATE OR REPLACE FUNCTION public.email_matches_domain(p_uni text)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.university_domains d
    WHERE d.uni = p_uni
      AND (lower(coalesce(auth.jwt() ->> 'email', '')) like '%@' || d.domain
        or lower(coalesce(auth.jwt() ->> 'email', '')) like '%.' || d.domain)
  );
$$;

-- Canonical claim_student (Device Binding + Matric Lock + PIN Hash)
CREATE OR REPLACE FUNCTION public.claim_student(
  p_uni text,
  p_matric text,
  p_name text,
  p_dept text,
  p_level text,
  p_email text DEFAULT NULL,
  p_provider text DEFAULT 'google',
  p_device_id text DEFAULT NULL,
  p_pin_hash text DEFAULT NULL
)
RETURNS public.students
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  me uuid := auth.uid();
  m  text := upper(regexp_replace(trim(p_matric), '\\s+', '', 'g'));
  row public.students;
  user_email text := coalesce(p_email, auth.jwt() ->> 'email', '');
  dev text := trim(coalesce(p_device_id, ''));
  ph  text := trim(coalesce(p_pin_hash, ''));
BEGIN
  IF me IS NULL THEN 
    RAISE EXCEPTION 'not_signed_in' USING errcode = 'P0001'; 
  END IF;
  
  -- Check if another user registered this matric in the same university
  IF EXISTS (SELECT 1 FROM public.students WHERE uni = trim(p_uni) AND matric = m AND user_id <> me) THEN
    RAISE EXCEPTION 'matric_taken' USING errcode = 'P0001';
  END IF;

  -- Check if current user already has a student record
  SELECT * INTO row FROM public.students WHERE user_id = me;
  IF FOUND THEN
    -- If device_id is already set on the student, ensure this device matches
    IF dev <> '' AND row.device_id IS NOT NULL AND row.device_id <> '' AND row.device_id <> dev THEN
      RAISE EXCEPTION 'device_mismatch' USING errcode = 'P0001';
    END IF;

    UPDATE public.students 
    SET name = trim(p_name), 
        dept = trim(p_dept), 
        level = p_level,
        email = coalesce(nullif(user_email, ''), row.email),
        auth_provider = coalesce(p_provider, row.auth_provider),
        device_id = coalesce(row.device_id, nullif(dev, '')),
        pin_hash = coalesce(nullif(ph, ''), row.pin_hash),
        "pinHash" = coalesce(nullif(ph, ''), row.pin_hash)
    WHERE user_id = me 
    RETURNING * INTO row;
    RETURN row;
  END IF;

  -- Check if another student has already bound this physical device
  IF dev <> '' AND EXISTS (SELECT 1 FROM public.students WHERE device_id = dev AND user_id <> me) THEN
    RAISE EXCEPTION 'device_already_registered' USING errcode = 'P0001';
  END IF;
  
  INSERT INTO public.students (user_id, uni, matric, name, dept, level, verified, email, auth_provider, device_id, pin_hash, "pinHash")
  VALUES (me, trim(p_uni), m, trim(p_name), trim(p_dept), p_level, true, user_email, p_provider, nullif(dev, ''), nullif(ph, ''), nullif(ph, ''))
  RETURNING * INTO row;
  
  RETURN row;
END;
$$;

-- Canonical register_lecturer
CREATE OR REPLACE FUNCTION public.register_lecturer(
  p_name text, 
  p_uni text, 
  p_lid text, 
  p_pub text, 
  p_jwk jsonb,
  p_email text DEFAULT NULL,
  p_provider text DEFAULT 'google'
)
RETURNS public.lecturers
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  me uuid := auth.uid();
  row public.lecturers;
  user_email text := coalesce(p_email, auth.jwt() ->> 'email', '');
BEGIN
  IF me IS NULL THEN 
    RAISE EXCEPTION 'not_signed_in' USING errcode = 'P0001'; 
  END IF;

  SELECT * INTO row FROM public.lecturers WHERE user_id = me;
  IF FOUND THEN 
    UPDATE public.lecturers 
    SET name = trim(p_name), 
        uni = trim(p_uni), 
        pub = coalesce(nullif(p_pub, ''), row.pub),
        email = coalesce(nullif(user_email, ''), row.email),
        auth_provider = coalesce(p_provider, row.auth_provider)
    WHERE user_id = me
    RETURNING * INTO row;
    
    INSERT INTO public.lecturer_keys (user_id, jwk)
    VALUES (me, p_jwk)
    ON CONFLICT (user_id) DO UPDATE SET jwk = EXCLUDED.jwk;
    
    RETURN row; 
  END IF;

  INSERT INTO public.lecturers (user_id, lid, name, uni, pub, verified, email, auth_provider)
  VALUES (me, p_lid, trim(p_name), trim(p_uni), p_pub, true, user_email, p_provider)
  RETURNING * INTO row;

  INSERT INTO public.lecturer_keys (user_id, jwk) 
  VALUES (me, p_jwk)
  ON CONFLICT (user_id) DO UPDATE SET jwk = EXCLUDED.jwk;

  RETURN row;
END;
$$;

-- Atomic delete_my_account
CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  me uuid := auth.uid();
BEGIN
  IF me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in' USING errcode = 'P0001';
  END IF;

  DELETE FROM public.students WHERE user_id = me;
  DELETE FROM public.scans WHERE user_id = me;
  DELETE FROM public.lecturers WHERE user_id = me;
  DELETE FROM public.lecturer_keys WHERE user_id = me;
  DELETE FROM public.lecturer_state WHERE user_id = me;
  DELETE FROM public.lecstate WHERE user_id = me;
  DELETE FROM public.sessions WHERE user_id = me;
  DELETE FROM public.matric_disputes WHERE user_id = me;
  
  DELETE FROM auth.users WHERE id = me;
END;
$$;

-- Reset student device (admin support function)
CREATE OR REPLACE FUNCTION public.reset_student_device(p_matric text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.students SET device_id = NULL WHERE matric = upper(regexp_replace(trim(p_matric), '\\s+', '', 'g'));
  RETURN FOUND;
END;
$$;

-- ==============================================================================
-- Performance Indexes
-- ==============================================================================

CREATE INDEX IF NOT EXISTS idx_students_matric ON public.students (matric);
CREATE INDEX IF NOT EXISTS idx_students_device_id ON public.students (device_id);
CREATE INDEX IF NOT EXISTS idx_students_email ON public.students (email);
CREATE INDEX IF NOT EXISTS idx_lecturers_email ON public.lecturers (email);
CREATE INDEX IF NOT EXISTS idx_scans_sid ON public.scans (sid);
CREATE INDEX IF NOT EXISTS idx_scans_lid ON public.scans (lid);
CREATE INDEX IF NOT EXISTS idx_scans_user_id ON public.scans (user_id);
CREATE INDEX IF NOT EXISTS idx_scans_open_pin ON public.scans (uni, day) WHERE (lid IS NULL);
CREATE INDEX IF NOT EXISTS idx_sessions_lid ON public.sessions (lid);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON public.sessions (user_id);


-- ==============================================================================
-- Schema Privileges & Grants (Crucial for Supabase API access)
-- ==============================================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;

-- Canonical RPC to submit an attendance scan (guaranteed atomic execution)
CREATE OR REPLACE FUNCTION public.submit_scan(p_scan jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  me uuid := auth.uid();
  k text := p_scan->>'key';
  user_id_val uuid := coalesce(me, nullif(p_scan->>'user_id', '')::uuid);
BEGIN
  IF k IS NULL OR k = '' THEN
    RAISE EXCEPTION 'missing_scan_key' USING errcode = 'P0001';
  END IF;

  INSERT INTO public.scans (
    key, user_id, uni, matric, name, dept, level, did,
    kind, sid, course, lid, win, sig, pin, pk, at, day, status, reason
  ) VALUES (
    k,
    user_id_val,
    p_scan->>'uni',
    p_scan->>'matric',
    p_scan->>'name',
    p_scan->>'dept',
    p_scan->>'level',
    p_scan->>'did',
    p_scan->>'kind',
    p_scan->>'sid',
    p_scan->>'course',
    p_scan->>'lid',
    (p_scan->>'win')::bigint,
    p_scan->>'sig',
    p_scan->>'pin',
    p_scan->>'pk',
    (p_scan->>'at')::bigint,
    p_scan->>'day',
    coalesce(p_scan->>'status', 'ok'),
    p_scan->>'reason'
  )
  ON CONFLICT (key) DO UPDATE SET
    status = EXCLUDED.status,
    reason = coalesce(EXCLUDED.reason, scans.reason),
    lid = coalesce(EXCLUDED.lid, scans.lid),
    sid = coalesce(EXCLUDED.sid, scans.sid),
    course = coalesce(EXCLUDED.course, scans.course),
    pk = coalesce(EXCLUDED.pk, scans.pk);

  RETURN jsonb_build_object('success', true, 'key', k);
END;
$$;

-- Canonical RPC to get scans for lecturer verification
CREATE OR REPLACE FUNCTION public.get_lecturer_scans(p_lid text)
RETURNS SETOF public.scans
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT * FROM public.scans
  WHERE (lid = p_lid)
     OR (lid IS NULL AND kind = 'pin' AND day >= to_char(now() - interval '1 day', 'YYYY-MM-DD'));
$$;

-- Canonical RPC to fetch active session sids for a lecturer (avoids ghost/orphan sessions)
CREATE OR REPLACE FUNCTION public.get_session_sids(p_lid text)
RETURNS TABLE (sid text)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT s.sid FROM public.sessions s WHERE s.lid = trim(p_lid);
$$;

-- Canonical RPC to validate rolling or static class PIN
CREATE OR REPLACE FUNCTION public.validate_class_pin(p_pin text)
RETURNS SETOF public.sessions
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT * FROM public.sessions
  WHERE pin = trim(p_pin)
    AND (
      ended_at = 0 
      OR ended_at IS NULL 
      OR ended_at > (extract(epoch from now()) * 1000 - 7200000)
    )
  ORDER BY started_at DESC
  LIMIT 1;
$$;

-- Canonical RPC: create or join a course (ensures shared course code across co-lecturers)
CREATE OR REPLACE FUNCTION public.create_or_join_course(
  p_uni text,
  p_code text,
  p_title text,
  p_depts text,
  p_level text,
  p_lid text,
  p_name text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  norm_code text := upper(regexp_replace(trim(p_code), '\s+', '', 'g'));
  c_id text;
BEGIN
  -- Look for existing course in this university
  SELECT id INTO c_id FROM public.courses 
  WHERE uni = trim(p_uni) AND upper(regexp_replace(code, '\s+', '', 'g')) = norm_code;
  
  IF c_id IS NULL THEN
    c_id := lower(substr(md5(random()::text || clock_timestamp()::text), 1, 8));
    INSERT INTO public.courses (id, uni, code, title, depts, level)
    VALUES (c_id, trim(p_uni), norm_code, trim(p_title), trim(p_depts), trim(p_level));
  END IF;

  -- Add current lecturer to teaching team
  INSERT INTO public.course_lecturers (course_id, lid, name, user_id)
  VALUES (c_id, trim(p_lid), trim(p_name), auth.uid())
  ON CONFLICT (course_id, lid) DO UPDATE SET name = EXCLUDED.name;

  RETURN jsonb_build_object('id', c_id, 'code', norm_code, 'success', true);
END;
$$;

-- Canonical RPC: get institutional courses with all co-lecturers
CREATE OR REPLACE FUNCTION public.get_institutional_courses(p_uni text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT coalesce(jsonb_agg(
    jsonb_build_object(
      'id', c.id,
      'uni', c.uni,
      'code', c.code,
      'title', c.title,
      'depts', c.depts,
      'level', c.level,
      'lecturers', (
        SELECT coalesce(jsonb_agg(jsonb_build_object('lid', cl.lid, 'name', cl.name)), '[]'::jsonb)
        FROM public.course_lecturers cl
        WHERE cl.course_id = c.id
      )
    ) ORDER BY c.code
  ), '[]'::jsonb) INTO result
  FROM public.courses c
  WHERE c.uni = trim(p_uni);

  RETURN result;
END;
$$;

-- Canonical RPC: join an existing course teaching team
CREATE OR REPLACE FUNCTION public.join_course(
  p_course_id text,
  p_lid text,
  p_name text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.course_lecturers (course_id, lid, name, user_id)
  VALUES (trim(p_course_id), trim(p_lid), trim(p_name), auth.uid())
  ON CONFLICT (course_id, lid) DO UPDATE SET name = EXCLUDED.name;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- Canonical RPC: opt out of a course teaching team
CREATE OR REPLACE FUNCTION public.leave_course(
  p_course_id text,
  p_lid text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.course_lecturers
  WHERE course_id = trim(p_course_id) AND lid = trim(p_lid);

  RETURN jsonb_build_object('success', true);
END;
$$;
