create or replace trigger SATURN.wt_swtetbl_aft_upd_db
  after update on saturn.swtetbl
  FOR EACH ROW

DECLARE
   l_email_subproc gwrmail.gwrmail_type%TYPE := 'NDACK';
   l_emal_process  gwrmail.gwrmail_process%TYPE := 'FACTS';
   l_message       VARCHAR2(2000);
   l_success       BOOLEAN;
   l_instance_name VARCHAR2(100);
   l_test_email    swtetbl.swtetbl_e_mail%TYPE;
   l_majr_code     sgbstdn.sgbstdn_majr_code_1%TYPE;
   --*****************************************************************************
   --
   --  University of South Florida
   --  Student Information System
   --  Program Unit Information
   --
   --  General Information
   --  -------------------
   --  Program Unit Name  : wt_swtetbl_aft_upd_db
   --  Process Associated : FACTS
   --  Business Logic :
   --   Updates sgbstdn table.
   --  Documentation Links:
   --   n/a
   --
   --
   -- Audit Trail
   -- -----------
   --  Src   USF
   --  Ver   Ver  Package    Date         User      Reason For Change
   -- -----  ---  ---------  -----------  ------    -----------------------
   --   8.3   A   08-000339  12-APR-2010  RVOGETI   The following functions are now called from
   --                                               package WSAKEMAL instead of from WSAKETBL:
   --                                               f_get_email_subj, f_get_smtp_addr,
   --                                               f_get_mime_type, f_get_sender_email
   --         C   O7-000604  22-AUG-2007  MROBERTS  Modified for issue 2405.
   --                                               The ID should be passed to the emailing
   --                                               procedure, rather than the SSN because the
   --                                               rules for the NDACK email use the spriden table
   --                                               and spriden id.  The wsakemal.wf_fetch_val_db was
   --                                               throwing an oracle error because no rows were found,
   --                                               and the email built just said "Dear," with no name.
   --   6.1   B   O6-4312    28-APR-2006  Arunion   Mods for tracking #2659.
   --   6.0   A   O6-004013  05-JUL-2005  MSHARMA   Initial Creation
   --
   --
   --*****************************************************************************
   --
BEGIN
   IF :NEW.swtetbl_credit_card_accept_ind<>:OLD.swtetbl_credit_card_accept_ind
   THEN
   UPDATE swbxapp
          SET swbxapp_credit_card_accept_ind = :NEW.swtetbl_credit_card_accept_ind,
              swbxapp_user                   = USER,
              swbxapp_crdt_card_date         = :NEW.swtetbl_crdt_card_date
            WHERE swbxapp_document_id = :NEW.swtetbl_xml_document_name;
   END IF;
	 IF :NEW.swtetbl_grad_appl_ind = 'N'
      AND nvl(:NEW.swtetbl_credit_card_accept_ind,'N') <> 'N'
      AND nvl(:OLD.swtetbl_credit_card_accept_ind,'N') = 'N' THEN
      l_instance_name := wsaketbl.f_get_instance_name;
      IF l_instance_name <> 'PROD' THEN
         l_test_email := 'Admissionstest@admin.usf.edu';
      ELSE
         l_test_email := substr(:NEW.swtetbl_e_mail,
                                1,
                                35);
      END IF;
			 UPDATE sgbstdn a
         SET a.sgbstdn_rate_code     = 
				 (select a.swrrule_value from SWRRULE a	where a.swrrule_business_area = 'FACTS' and a.swrrule_default_value = SUBSTR(:NEW.swtetbl_conf_numb,1,2)
             and a.swrrule_rule =  'ND_PAID_RATE_CODE' ),
             a.sgbstdn_activity_date = SYSDATE
       WHERE a.sgbstdn_pidm =
             (SELECT b.swbxapp_pidm
                FROM swbxapp b
               WHERE b.swbxapp_conf_numb = :NEW.swtetbl_conf_numb)
         AND a.sgbstdn_term_code_eff = :NEW.swtetbl_ent_term_code;
      IF SQL%ROWCOUNT > 0 THEN
         SELECT a.sgbstdn_majr_code_1
           INTO l_majr_code
           FROM sgbstdn a
          WHERE a.sgbstdn_pidm =
                (SELECT b.swbxapp_pidm
                   FROM swbxapp b
                  WHERE b.swbxapp_conf_numb = :NEW.swtetbl_conf_numb)
            AND a.sgbstdn_term_code_eff = :NEW.swtetbl_ent_term_code;
-- Arunion 4/28/06 Mods Begin
         IF l_majr_code = 'SPC' THEN
-- Arunion 4/28/06 Mods End
            l_email_subproc := 'NDACK';
         ELSE
            l_email_subproc := 'NDACKNOMJR';
         END IF;
         wsakemal.wp_main_email_db(:NEW.swtetbl_id,
                                   :NEW.swtetbl_seq,
                                   l_emal_process,
                                   l_email_subproc,
                                   wsakemal.f_get_mime_type(l_email_subproc),
                                   wsakemal.f_get_sender_email(l_email_subproc),
                                   l_test_email,
                                   wsakemal.f_get_smtp_addr(l_email_subproc),
                                   wsakemal.f_get_email_subj(l_email_subproc),
                                   l_message,
                                   l_success);
      END IF;
   END IF;
END wt_swtetbl_aft_upd_db;
/
