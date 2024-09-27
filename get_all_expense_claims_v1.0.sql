-- FUNCTION: public.get_all_expense_claims(integer, integer)

-- DROP FUNCTION IF EXISTS public.get_all_expense_claims(integer, integer);

CREATE OR REPLACE FUNCTION public.get_all_expense_claims(
	p_login_emp_id integer,
	p_employee_id integer,
	OUT p_return_id integer,
	OUT p_message character varying,
	OUT all_expense_claims refcursor)
    RETURNS record
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    employee_count INTEGER;
    v_chk_priv BOOLEAN;
BEGIN
    v_chk_priv := sf_get_role_privilege(p_login_emp_id, 5, 'is_view', COALESCE(sf_get_role_id(p_login_emp_id), 0));

    IF v_chk_priv = false THEN
        p_return_id := 0;
        p_message := 'You don''t have privileges, please contact the admin!';
        RETURN;
    END IF;

    IF p_employee_id IS NULL THEN
        OPEN all_expense_claims FOR
            SELECT 
                ERC.employee_id,
                TRIM(COALESCE(EPD.first_name, '') || ' ' || COALESCE(EPD.last_name, '')) AS employee_name,
                DM.department_name,
                ERC.submission_date,
                ERC.expense_type_id,
                EEM.expense_category,
                ERC.project_id,
                PD.project_name,
                ERC.cost_centres_id,
                ECC.cost_center_name,
                ERC.expense_date,
                ERC.amount,
                ERC.currency_id,
                CM.currency_code,
                CM.currency_symbol,
                ERC.attachment,
                ERC.purpose_of_expense,
                ERC.comments,
                ERC.description,
                get_reporting_or_employee_name(ERC.approver_1_id) AS manager_name,
                ERC.approve1_status_id AS manager_approval_status,
                get_reporting_or_employee_name(ERC.approver_2_id) AS l2_manager_name,
                ERC.approve2_status_id AS l2_manager_approval_status,
                get_reporting_or_employee_name(ERC.approver_3_id) AS hr_manager_name,
                ERC.approve3_status_id AS hr_manager_approval_status,
                CASE
                    WHEN ERC.approve1_status_id = 1 AND ERC.approve2_status_id = 1 AND ERC.approve3_status_id = 1 THEN 'pending'
                    WHEN ERC.approve1_status_id = 2 AND ERC.approve2_status_id = 2 AND ERC.approve3_status_id = 2 THEN 'approved'
                    WHEN ERC.approve1_status_id = 3 AND ERC.approve2_status_id = 3 AND ERC.approve3_status_id = 3 THEN 'rejected'
                    WHEN ERC.approve1_status_id = 2 AND ERC.approve2_status_id = 2 AND ERC.approve3_status_id = 0 THEN 'partially approved'
                    WHEN ERC.approve1_status_id = 2 AND ERC.approve2_status_id = 2 AND ERC.approve3_status_id = 3 THEN 'Rejected from HR END'
                    WHEN ERC.approve1_status_id = 2 AND ERC.approve2_status_id = 3 THEN 'Rejected from L2 manager END'
                    WHEN ERC.approve1_status_id = 3 THEN 'Rejected from manager END'
                    ELSE 'unknown'
                END AS approval_status
            FROM Expense_req_claim ERC
            LEFT JOIN employee_profile_details EPD ON ERC.employee_id = EPD.employee_id
            LEFT JOIN department_master DM ON EPD.department_id = DM.department_id
            LEFT JOIN emp_expense_master EEM ON ERC.expense_type_id = EEM.expense_type_id 
            LEFT JOIN project_details PD ON ERC.project_id = PD.project_id
            LEFT JOIN currency_master CM ON ERC.currency_id = CM.currency_id
            LEFT JOIN expense_cost_centres ECC ON ERC.cost_centres_id = ECC.cost_centres_id
            WHERE 
                (p_login_emp_id = 79 AND ERC.approve1_status_id::text LIKE '%2%' AND ERC.approve2_status_id::text LIKE '%2%')
                OR
                (p_login_emp_id = 78 AND ERC.approve1_status_id = 2);
    ELSE
        SELECT COUNT(*) INTO employee_count FROM employee_profile_details
        WHERE employee_id = p_employee_id;

        IF employee_count = 0 THEN
            RAISE EXCEPTION 'Employee ID % not found.', p_employee_id;
        END IF;

        OPEN all_expense_claims FOR
            SELECT 
                ERC.employee_id,
                TRIM(COALESCE(EPD.first_name, '') || ' ' || COALESCE(EPD.last_name, '')) AS employee_name,
                DM.department_name,
                ERC.submission_date,
                ERC.expense_type_id,
                EEM.expense_category,
                ERC.project_id,
                PD.project_name,
                ERC.cost_centres_id,
                ECC.cost_center_name,
                ERC.expense_date,
                ERC.amount,
                ERC.currency_id,
                CM.currency_code,
                CM.currency_symbol,
                ERC.attachment,
                ERC.purpose_of_expense,
                ERC.comments,
                ERC.description,
                get_reporting_or_employee_name(ERC.approver_1_id) AS manager_name,
                ERC.approve1_status_id AS manager_approval_status,
                get_reporting_or_employee_name(ERC.approver_2_id) AS l2_manager_name,
                ERC.approve2_status_id AS l2_manager_approval_status,
                get_reporting_or_employee_name(ERC.approver_3_id) AS hr_manager_name,
                ERC.approve3_status_id AS hr_manager_approval_status,
                CASE
                    WHEN ERC.approve1_status_id = 1 AND ERC.approve2_status_id = 1 AND ERC.approve3_status_id = 1 THEN 'pending'
                    WHEN ERC.approve1_status_id = 2 AND ERC.approve2_status_id = 2 AND ERC.approve3_status_id = 2 THEN 'approved'
                    WHEN ERC.approve1_status_id = 3 AND ERC.approve2_status_id = 3 AND ERC.approve3_status_id = 3 THEN 'rejected'
                    WHEN ERC.approve1_status_id = 2 AND ERC.approve2_status_id = 2 AND ERC.approve3_status_id = 0 THEN 'partially approved'
                    WHEN ERC.approve1_status_id = 2 AND ERC.approve2_status_id = 2 AND ERC.approve3_status_id = 3 THEN 'Rejected from HR END'
                    WHEN ERC.approve1_status_id = 2 AND ERC.approve2_status_id = 3 THEN 'Rejected from L2 manager END'
                    WHEN ERC.approve1_status_id = 3 THEN 'Rejected from manager END'
                    ELSE 'unknown'
                END AS approval_status
            FROM Expense_req_claim ERC
            LEFT JOIN employee_profile_details EPD ON ERC.employee_id = EPD.employee_id
            LEFT JOIN department_master DM ON EPD.department_id = DM.department_id
            LEFT JOIN emp_expense_master EEM ON ERC.expense_type_id = EEM.expense_type_id 
            LEFT JOIN project_details PD ON ERC.project_id = PD.project_id
            LEFT JOIN currency_master CM ON ERC.currency_id = CM.currency_id
            LEFT JOIN expense_cost_centres ECC ON ERC.cost_centres_id = ECC.cost_centres_id
            WHERE ERC.employee_id = p_employee_id
            AND (
                (p_login_emp_id = 79 AND ERC.approve1_status_id::text LIKE '%2%' AND ERC.approve2_status_id::text LIKE '%2%')
                OR
                (p_login_emp_id = 78 AND ERC.approve1_status_id = 2)
            );
    END IF;

    p_return_id := 1; -- Assuming success
    p_message := 'Success';

EXCEPTION
    WHEN OTHERS THEN
        -- Handle errors
        CALL ERROR_LOG_SP(SQLSTATE, SQLERRM, 'get_all_expense_claims');
        RAISE INFO '%', 'Error: ' || SQLERRM; 
END;
$BODY$;

ALTER FUNCTION public.get_all_expense_claims(integer, integer)
    OWNER TO rajasundar;
