BEGIN;

CREATE OR REPLACE FUNCTION principal.record_decision(
    p_request_id uuid,
    p_decision text,
    p_previous_status text,
    p_remarks text,
    p_actor text
) RETURNS void
LANGUAGE plpgsql
-- SECURITY INVOKER because backend API role ksrerp already has standard UPDATE/INSERT access
AS $$
DECLARE
    v_current_decision text;
BEGIN
    -- 1. Lock the row to prevent concurrent race conditions
    SELECT decision INTO v_current_decision
    FROM principal.approval_requests
    WHERE id = p_request_id
    FOR UPDATE;

    -- Handle nonexistent request ID
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Request ID % not found', p_request_id;
    END IF;

    -- Handle concurrency/duplicate decision check
    IF v_current_decision IS DISTINCT FROM p_previous_status THEN
        RAISE EXCEPTION 'Status mismatch. Expected %, but currently %', p_previous_status, v_current_decision;
    END IF;

    -- 2. Update the request
    UPDATE principal.approval_requests
    SET decision = p_decision,
        remarks = COALESCE(p_remarks, remarks),
        updated_at = NOW()
    WHERE id = p_request_id;

    -- 3. Insert the audit trail
    INSERT INTO principal.approval_decisions (
        source_type, source_id, decision, previous_status, remarks, decided_by
    ) VALUES (
        'approval_request', p_request_id::text, p_decision, p_previous_status, p_remarks, p_actor
    );
END;
$$;

COMMIT;
