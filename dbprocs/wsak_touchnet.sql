CREATE OR REPLACE PACKAGE baninst1.wsak_touchnet IS
  --
  --*****************************************************************************
  --
  --  University of South Florida
  --  Student Information System
  --  Program Unit Information
  --
  --  General Information
  --  -------------------
  --  Program Unit Name  : wsak_touchnet
  --  Process Associated : FACTS Upload process
  --  Business Logic :
  --   This package processes facts application payment from SSB.
  --  Documentation Links:
  --   This should be a URL link to the location of the Functional and
  --   Technical specifications for the project to which the Program Unit
  --   is attached.
  --
  --
  -- Audit Trail
  -- -----------
  --  Src   USF
  --  Ver   Ver  Package    Date         User    Reason For Change
  -- -----  ---  ---------  -----------  ------  -----------------------
  -- #2
  --  7.3    A   O7-000693  05/13/08    VBANGALO  Initial Creation
  --  7.3    B   O7-000761  10/23/08    VBANGALO  Modified code to include
  --                                              Sarasota and Lakeland
  --                                              campus for self service.
  --         C   O7-000815  02/18/09    VBANGALO  1. Modified code to display
  --                                              pending application fee only when the
  --                                              it is pending for require fee payemtn(decsion code is RM)
  --                                              OR application is cancelled for non payment (decsion code is CM)
  --                                              AND application end date is not passed.
  --                                              2. Also modified code to get admr fee code from sorxref.
  --         D   O7-000894  09/01/09    VBANGALO  Added procedure p_get_appln_fee_info to
  --                                              include SCM payment links.
  --         E   O7-000925  11/13/09    RFTURNER  Modified procedure load_credit_payment_info to
  --                                              use Flexible Parameter Passing
  --         F   O7-000947  12/15/09   RVOGETI    Modified the following for FSD 09-0211
  --                                              1. Added global variables for pay site and fee amt
  --                                              2. Added global constants for Polytechnic URLs
  --                                              3. Modified p_get_appln_fee_info
  --                                              4. Modified f_get_lvl_coll_code
  --                                              5. Modified to use global_name view instead of v$instance
  --                                              6. Modified p_check_rules
  --  na     G   O8-000512  02/27/11    VBANGALO  1. Changed code to have UPAY site in mixed case.
  --  na     H   O8-000525  04/01/11    VBANGALO  Removed 'successful' check to make tlink to work.
	--  na     I   OASBAN-106 04/22/13    VBANGALO  Added "VZCA post submission" functionality
  --************************************************************************************************************************
  -- To Make sure all rules are set, run p_check_rules. If it gives exception then
  -- check rules.
  -- this package checks rule table under FACTS for flollowing rules:
  --UPAY_SITE_<INSTANCE>
  --UPAY_UG_SITE_ID
  --UPAY_GR_SITE_ID
  --UPAY_STPT_GR_SITE_ID
  --UPAY_STPT_UG_SITE_ID
  --UPAY_ND_SITE_ID
  --UG_APP_FEE_AMT
  --GR_APP_FEE_AMT
  --ND_APP_FEE_AMT
  --STPT_UG_APP_FEE_AMT
  --STPT_GR_APP_FEE_AMT
  --UPAY_SM_GR_SITE_ID
  --UPAY_SM_UG_SITE_ID
  --SM_UG_APP_FEE_AMT'
  --SM_GR_APP_FEE_AMT'
  -- following constant values are used
  -- in ApplicationDataLoad.java to get Upay Site Information
  gc_ug_stpt  CONSTANT VARCHAR2(20) := 'UGSTPT';
  gc_gr_stpt  CONSTANT VARCHAR2(20) := 'GRSTPT';
  gc_nd_tampa CONSTANT VARCHAR2(20) := 'NDTAMPA';
  gc_ug_tampa CONSTANT VARCHAR2(20) := 'UGTAMPA';
  gc_gr_tampa CONSTANT VARCHAR2(20) := 'GRTAMPA';
  gc_ug_sm    CONSTANT VARCHAR2(20) := 'UGSM';
  gc_gr_sm    CONSTANT VARCHAR2(20) := 'GRSM';
  -- 7.3F Start
  gc_ug_usfp CONSTANT VARCHAR2(20) := 'UGUSFP';
  gc_gr_usfp CONSTANT VARCHAR2(20) := 'GRUSFP';
  -- 7.3F End
  -- end of required values in ApplicationDataLoad.java

  PROCEDURE p_check_rules;
  /**
    Loads credit card information payment details
  */
  PROCEDURE load_credit_payment_info
  (
    name_array  IN owa.vc_arr
   ,value_array IN owa.vc_arr
  );

  PROCEDURE p_disp_pending_apps;
  PROCEDURE p_start_debug(p_dest VARCHAR2 DEFAULT 'web');
  PROCEDURE p_stop_debug;
  PROCEDURE p_disp_pending_apps(p_pidm_in NUMBER);
  PROCEDURE p_get_appln_fee_info
  (
    p_col_levl_i VARCHAR2
   ,p_site_o     OUT VARCHAR2
   ,p_site_id_o  OUT VARCHAR2
   ,p_amt_out    OUT VARCHAR2
  );

END;
/
CREATE OR REPLACE PACKAGE BODY baninst1.wsak_touchnet IS

  pidm NUMBER;
  curr_release CONSTANT VARCHAR2(10) := '5.5';
  -- local variables
  gv_cureent_term     sarchkl.sarchkl_term_code_entry%TYPE := wf_current_term_db;
  gv_posting_key      VARCHAR2(500) DEFAULT NULL;
  gv_tpg_trans_id     VARCHAR2(500) DEFAULT NULL;
  gv_pmt_status       VARCHAR2(500) DEFAULT NULL;
  gv_pmt_amt          VARCHAR2(500) DEFAULT NULL;
  gv_pmt_date         VARCHAR2(500) DEFAULT NULL;
  gv_name_on_acct     VARCHAR2(500) DEFAULT NULL;
  gv_acct_addr        VARCHAR2(500) DEFAULT NULL;
  gv_acct_city        VARCHAR2(500) DEFAULT NULL;
  gv_acct_state       VARCHAR2(500) DEFAULT NULL;
  gv_acct_zip         VARCHAR2(500) DEFAULT NULL;
  gv_card_type        VARCHAR2(500) DEFAULT NULL;
  gv_ext_trans_id     VARCHAR2(500) DEFAULT NULL;
  gv_upay_site_id     VARCHAR2(500) DEFAULT NULL;
  gv_sys_tracking_id  VARCHAR2(500) DEFAULT NULL;
  gv_bank_name        VARCHAR2(100) DEFAULT NULL;
  gv_bank_addr1       VARCHAR2(500) DEFAULT NULL;
  gv_bank_addr2       VARCHAR2(500) DEFAULT NULL;
  gv_bank_routing_num VARCHAR2(500) DEFAULT NULL;
  gv_rec_pmt_type     VARCHAR2(500) DEFAULT NULL;

  gv_instance  VARCHAR2(100);
  gv_pidm      sarchkl.sarchkl_pidm%TYPE;
  gv_term_code sarchkl.sarchkl_term_code_entry%TYPE;
  gv_appln_no  sarchkl.sarchkl_appl_no%TYPE;
  gv_levl_code sovlcur.sovlcur_levl_code%TYPE;
  gv_debug     BOOLEAN := FALSE;
  gv_web       BOOLEAN := FALSE;
  -- p_init_variables..
  gv_site_id VARCHAR2(20);
  gv_fee_amt NUMBER(10, 2) := 20; -- this needs to be populated from table
  gv_site    VARCHAR2(200);

  -- local constants
  -- ver C start
  --gv_app_fee_chklist_code VARCHAR2(10) := NULL;
  -- ver C end
  gv_upay_site_url   VARCHAR2(200) := NULL;
  gv_upay_ug_site_id VARCHAR2(200);
  gv_upay_gr_site_id VARCHAR2(200);

  gv_upay_nd_site_id VARCHAR2(200);

  gv_ug_app_fee_amt VARCHAR2(200);
  gv_gr_app_fee_amt VARCHAR2(200);

  gv_nd_app_fee_amt VARCHAR2(200);

  gv_upay_stpt_gr_site_id VARCHAR2(200);

  gv_upay_stpt_ug_site_id VARCHAR2(200);

  gv_stpt_ug_app_fee_amt VARCHAR2(200);
  gv_stpt_gr_app_fee_amt VARCHAR2(200);

  gv_upay_sm_ug_site_id VARCHAR2(200);
  gv_upay_sm_gr_site_id VARCHAR2(200);
  gv_sm_ug_app_fee_amt  VARCHAR2(200);
  gv_sm_gr_app_fee_amt  VARCHAR2(200);
  -- 7.3F Start
  gv_upay_usfp_ug_site_id VARCHAR2(200);
  gv_upay_usfp_gr_site_id VARCHAR2(200);
  gv_usfp_ug_app_fee_amt  VARCHAR2(200);
  gv_usfp_gr_app_fee_amt  VARCHAR2(200);
  -- 7.3 F End

  lc_undergraduate_code CONSTANT VARCHAR2(2) := 'UG';
  lc_graduate_code      CONSTANT VARCHAR2(2) := 'GR';
  lc_stpt_camp_code     CONSTANT VARCHAR2(2) := 'P';
  lc_tampa_camp_code    CONSTANT VARCHAR2(2) := 'T';
  -- 7.3 B start
  lc_sarasota_camp_code CONSTANT VARCHAR2(2) := 'S';
  lc_lakeland_camp_code CONSTANT VARCHAR2(2) := 'L';
  -- 7.3 B end
  lc_segment_seperator CONSTANT VARCHAR2(1) := '~';
  lc_app_needs_review  CONSTANT VARCHAR2(2) := 'NR';
  -- ver C start
  gc_checklist_xlabel  CONSTANT VARCHAR2(7) := 'SARCHKL';
  gc_xref_qlfr_facts   CONSTANT VARCHAR2(5) := 'FACTS';
  gc_xref_qlfr_factsgr CONSTANT VARCHAR2(7) := 'FACTSGR';
  gc_xref_edival_fee   CONSTANT VARCHAR2(3) := 'FEE';
  -- ver C end
  /* test pidms need to pay
    1 1742991 U05145015 071234
    2 2649591 U54227800 123456
    -- muliple apps for a term
    1 706895  U87781368 071234
  2 2346571 U51940306 071234
  3 2609346 U87309183 071234
  4 2671549 U90214003 071234
  5 2681579 U00004657 123456
          */
  CURSOR pending_app_fee_c IS
  /*
                                    TODO: owner="vbangalo" created="2/17/2009"
                                    text="change gv_app_fee_chklist_code"
                                    */
    SELECT DISTINCT h.sovlcur_pidm      pidm
                   ,h.sovlcur_term_code term_code
                   ,h.sovlcur_key_seqno app_no
                   ,h.sovlcur_levl_code levl_code
                   ,k.stvlevl_desc      levl
                   ,n.stvcoll_desc      coll
                   ,j.stvdegc_desc      deg
                   ,h.sovlcur_camp_code camp_code
                   ,o.stvcamp_desc      campus
                   ,p.spriden_id        id
                    -- ver C start
                   ,h.sovlcur_admt_code admit_code
                   ,r.spbpers_citz_code citz_code
    -- ver C end
      FROM sarchkl a
          ,stvapdc c
          ,sovlcur h
          ,stvcoll n
          ,stvdegc j
          ,stvlevl k
          ,stvcamp o
          ,spriden p
          ,sorxref q
           -- ver C start
          ,spbpers r
    --WHERE a.sarchkl_admr_code = gv_app_fee_chklist_code --gc_xref_edival_fee
     WHERE a.sarchkl_term_code_entry >= gv_cureent_term
          -- ver c end
       AND a.sarchkl_receive_date IS NULL
       AND a.sarchkl_pidm = gv_pidm
       AND r.spbpers_pidm = a.sarchkl_pidm
       AND h.sovlcur_pidm = a.sarchkl_pidm
       AND h.sovlcur_key_seqno = a.sarchkl_appl_no
       AND h.sovlcur_lmod_code = 'ADMISSIONS'
       AND h.sovlcur_term_code = a.sarchkl_term_code_entry
       AND n.stvcoll_code = h.sovlcur_coll_code
       AND j.stvdegc_code = h.sovlcur_degc_code
       AND k.stvlevl_code = h.sovlcur_levl_code
       AND o.stvcamp_code = h.sovlcur_camp_code
       AND p.spriden_pidm = a.sarchkl_pidm
       AND p.spriden_change_ind IS NULL
          -- ver c start
       AND a.sarchkl_admr_code = q.sorxref_banner_value
       AND q.sorxref_xlbl_code = gc_checklist_xlabel
       AND q.sorxref_edi_value = gc_xref_edival_fee
       AND q.sorxref_edi_qlfr = (CASE
             WHEN k.stvlevl_code = lc_graduate_code THEN
              gc_xref_qlfr_factsgr
             ELSE
              gc_xref_qlfr_facts
           END)
    -- ver c end
     ORDER BY h.sovlcur_levl_code
             ,h.sovlcur_term_code
             ,h.sovlcur_key_seqno;

  TYPE lv_pending_tab_typ IS TABLE OF pending_app_fee_c%ROWTYPE INDEX BY BINARY_INTEGER;
  lv_pending_tab_rec lv_pending_tab_typ;
  PROCEDURE p_debug(p_message VARCHAR2) IS
  BEGIN
    IF gv_debug THEN
      IF gv_web THEN
        htp.print(p_message);
      ELSE
        dbms_output.put_line(p_message);
      END IF;
    END IF;
  END;
  FUNCTION f_get_xref_val_db
  (
    p_xlbl_code  sorxref.sorxref_xlbl_code%TYPE
   ,p_edi_qlfr   sorxref.sorxref_edi_qlfr%TYPE
   ,p_edi_val    sorxref.sorxref_edi_value%TYPE
   ,p_banner_val sorxref.sorxref_banner_value%TYPE
  ) RETURN VARCHAR2 IS
    l_xref_val sorxref.sorxref_edi_value%TYPE := NULL;
    --Cursor to get banner value
    CURSOR get_xref_banner_val_c IS
      SELECT a.sorxref_banner_value
        FROM sorxref a
       WHERE a.sorxref_xlbl_code = p_xlbl_code
         AND a.sorxref_edi_qlfr = p_edi_qlfr
         AND a.sorxref_edi_value = p_edi_val;
    --Cursor to get edi value
    CURSOR get_xref_edi_val_c IS
      SELECT a.sorxref_edi_value
        FROM sorxref a
       WHERE a.sorxref_xlbl_code = p_xlbl_code
         AND a.sorxref_edi_qlfr = p_edi_qlfr
         AND a.sorxref_banner_value = p_banner_val;
  BEGIN
    IF p_banner_val IS NULL AND p_edi_val IS NOT NULL THEN
      OPEN get_xref_banner_val_c;
      FETCH get_xref_banner_val_c
        INTO l_xref_val;
      CLOSE get_xref_banner_val_c;
    ELSIF p_banner_val IS NOT NULL AND p_edi_val IS NULL THEN
      OPEN get_xref_edi_val_c;
      FETCH get_xref_edi_val_c
        INTO l_xref_val;
      CLOSE get_xref_edi_val_c;
    END IF;
    RETURN l_xref_val;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN l_xref_val;
  END f_get_xref_val_db;

  PROCEDURE p_start_debug(p_dest VARCHAR2 DEFAULT 'web') IS
  BEGIN
    gv_debug := TRUE;
    IF lower(p_dest) = 'web' THEN
      gv_web := TRUE;
    ELSE
      gv_web := FALSE;
    END IF;
  END;
  PROCEDURE p_stop_debug IS
  BEGIN
    gv_debug := FALSE;
  END;
  FUNCTION f_get_swrrule_val
  (
    p_bus_area swrrule.swrrule_business_area%TYPE
   ,p_rule     swrrule.swrrule_rule%TYPE
  ) RETURN VARCHAR2 IS
    l_rule_val swrrule.swrrule_value%TYPE;
  BEGIN
    SELECT a.swrrule_value
      INTO l_rule_val
      FROM swrrule a
     WHERE a.swrrule_business_area = p_bus_area
       AND a.swrrule_rule = p_rule;
    RETURN l_rule_val;
  END;
  PROCEDURE p_get_appln_fee_info
  (
    p_col_levl_i VARCHAR2
   ,p_site_o     OUT VARCHAR2
   ,p_site_id_o  OUT VARCHAR2
   ,p_amt_out    OUT VARCHAR2
  ) IS
  BEGIN
    p_site_o := gv_upay_site_url;
  
    IF p_col_levl_i = gc_ug_tampa THEN
      p_site_id_o := gv_upay_ug_site_id;
      p_amt_out   := gv_ug_app_fee_amt;
    ELSIF p_col_levl_i = gc_gr_tampa THEN
      p_site_id_o := gv_upay_gr_site_id;
      p_amt_out   := gv_gr_app_fee_amt;
    ELSIF p_col_levl_i = gc_nd_tampa THEN
      p_site_id_o := gv_upay_nd_site_id;
      p_amt_out   := gv_nd_app_fee_amt;
    ELSIF p_col_levl_i = gc_ug_stpt THEN
      p_site_id_o := gv_upay_stpt_ug_site_id;
      p_amt_out   := gv_stpt_ug_app_fee_amt;
    ELSIF p_col_levl_i = gc_gr_stpt THEN
      p_site_id_o := gv_upay_stpt_gr_site_id;
      p_amt_out   := gv_stpt_gr_app_fee_amt;
    ELSIF p_col_levl_i = gc_ug_sm THEN
      p_site_id_o := gv_upay_sm_ug_site_id;
      p_amt_out   := gv_sm_ug_app_fee_amt;
    ELSIF p_col_levl_i = gc_gr_sm THEN
      p_site_id_o := gv_upay_sm_gr_site_id;
      p_amt_out   := gv_sm_gr_app_fee_amt;
      -- 7.3F Start
    ELSIF p_col_levl_i = gc_ug_usfp THEN
      p_site_id_o := gv_upay_usfp_ug_site_id;
      p_amt_out   := gv_usfp_ug_app_fee_amt;
    ELSIF p_col_levl_i = gc_gr_usfp THEN
      p_site_id_o := gv_upay_usfp_gr_site_id;
      p_amt_out   := gv_usfp_gr_app_fee_amt;
      -- 7.3F End
    END IF;
  END;

  PROCEDURE p_get_appln_fee_info(p_pending_rec_i pending_app_fee_c%ROWTYPE /*, p_site_id_o OUT VARCHAR2,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              p_amt_out OUT VARCHAR2*/) IS
    FUNCTION f_get_lvl_coll_code RETURN VARCHAR2 IS
      lv_return VARCHAR2(20);
    BEGIN
      IF upper(p_pending_rec_i.camp_code) = lc_stpt_camp_code AND
         p_pending_rec_i.levl_code = lc_undergraduate_code THEN
        lv_return := gc_ug_stpt;
      ELSIF upper(p_pending_rec_i.camp_code) = lc_stpt_camp_code AND
            p_pending_rec_i.levl_code = lc_graduate_code THEN
        lv_return := gc_gr_stpt;
      ELSIF upper(p_pending_rec_i.camp_code) = lc_sarasota_camp_code AND
            p_pending_rec_i.levl_code = lc_undergraduate_code THEN
        lv_return := gc_ug_sm;
      ELSIF upper(p_pending_rec_i.camp_code) = lc_sarasota_camp_code AND
            p_pending_rec_i.levl_code = lc_graduate_code THEN
        lv_return := gc_gr_sm;
        -- 7.3F Start
      ELSIF upper(p_pending_rec_i.camp_code) = lc_lakeland_camp_code AND
            p_pending_rec_i.levl_code = lc_undergraduate_code THEN
        lv_return := gc_ug_usfp;
      ELSIF upper(p_pending_rec_i.camp_code) = lc_lakeland_camp_code AND
            p_pending_rec_i.levl_code = lc_graduate_code THEN
        lv_return := gc_gr_usfp;
        -- 7.3F End
      ELSIF upper(p_pending_rec_i.camp_code) = lc_tampa_camp_code AND
            p_pending_rec_i.levl_code = lc_undergraduate_code THEN
        lv_return := gc_ug_tampa;
      ELSIF upper(p_pending_rec_i.camp_code) = lc_tampa_camp_code AND
            p_pending_rec_i.levl_code = lc_graduate_code THEN
        lv_return := gc_gr_tampa;
      END IF;
    
      RETURN lv_return;
    END;
  BEGIN
    p_get_appln_fee_info(f_get_lvl_coll_code, gv_site, gv_site_id,
                         gv_fee_amt);
  END;
  -- ver C start
  /*
   Function f_is_ok_to_diplay return true/false based on
   application decssion code RM/CM.
  
   Returns true if final decission code is RM or decision code
   is CM and the end date for the application termIs >= sysdate
   else for any other decsion code returns false.
  
  */
  FUNCTION f_is_ok_to_diplay
  (
    p_pidm_in        sarchkl.sarchkl_pidm%TYPE
   ,p_term_code_in   sarchkl.sarchkl_term_code_entry%TYPE
   ,p_levl_in        swratrm.swratrm_level_code%TYPE
   ,p_citz_in        swratrm.swratrm_citz_code%TYPE
   ,p_admit_type_in  swratrm.swratrm_admt_type%TYPE
   ,p_app_no_in      sarchkl.sarchkl_appl_no%TYPE
   ,p_campus_code_in swratrm.swratrm_campus%TYPE
  ) RETURN BOOLEAN IS
    lv_result        BOOLEAN := FALSE;
    lv_sarappd_decsn sarappd%ROWTYPE; -- sarappd.sarappd_apdc_code%type := null;
    lv_app_end_date  DATE;
    CURSOR app_term_end_date_c IS
    -- get the application term end date
      SELECT a.swratrm_end_date
        FROM swratrm a
       WHERE a.swratrm_term_code = p_term_code_in -- '200901'
         AND (a.swratrm_campus = p_campus_code_in OR
             a.swratrm_campus IS NULL) -- 'T'
         AND (a.swratrm_level_code = p_levl_in OR
             a.swratrm_level_code IS NULL) -- 'UG'
         AND (a.swratrm_citz_code = p_citz_in OR
             a.swratrm_citz_code IS NULL) -- 'P'
         AND (a.swratrm_admt_type = p_admit_type_in OR
             a.swratrm_admt_type IS NULL); --'FS'
  BEGIN
    -- get the final decission code for the application
    lv_sarappd_decsn := wsaketbl.f_max_sarappd_rec(l_pidm => p_pidm_in,
                                                   l_ent_term_code => p_term_code_in,
                                                   p_appl_no => p_app_no_in);
    -- if application is pending because application fee is not paid, retur true.
    IF nvl(f_get_swrrule_val(gc_xref_qlfr_facts, 'REQ_FEE_DECSN_UGGR'), 'b') =
       nvl(lv_sarappd_decsn.sarappd_apdc_code, 'a') THEN
      lv_result := TRUE;
      -- if application is cancelled because application fee is not paid and the
      -- application term end date is not passed return true
    ELSIF nvl(f_get_swrrule_val(gc_xref_qlfr_facts, 'CANCEL_AP_DECSN_UGGR'),
              'b') = nvl(lv_sarappd_decsn.sarappd_apdc_code, 'a') THEN
      IF app_term_end_date_c%ISOPEN THEN
        CLOSE app_term_end_date_c;
      END IF;
      OPEN app_term_end_date_c;
      FETCH app_term_end_date_c
        INTO lv_app_end_date;
      lv_result := trunc(lv_app_end_date) >= trunc(SYSDATE);
      --   END IF;
    END IF;
    RETURN lv_result;
  END;
  -- ver C end

  FUNCTION f_has_pending_appfee RETURN BOOLEAN IS
    lv_has_pending_fees BOOLEAN := FALSE;
  BEGIN
    OPEN pending_app_fee_c;
    FETCH pending_app_fee_c BULK COLLECT
      INTO lv_pending_tab_rec;
    CLOSE pending_app_fee_c;
    lv_has_pending_fees := lv_pending_tab_rec.count > 0;
    -- ver C start
    -- return false if any one of pening application is not ok to display.
    IF lv_has_pending_fees THEN
      lv_has_pending_fees := FALSE;
      FOR idx IN lv_pending_tab_rec.first .. lv_pending_tab_rec.last
      LOOP
        lv_has_pending_fees := f_is_ok_to_diplay(p_pidm_in => lv_pending_tab_rec(idx).pidm,
                                                 p_term_code_in => lv_pending_tab_rec(idx)
                                                                    .term_code,
                                                 p_levl_in => lv_pending_tab_rec(idx)
                                                               .levl_code,
                                                 p_citz_in => lv_pending_tab_rec(idx)
                                                               .citz_code,
                                                 p_admit_type_in => lv_pending_tab_rec(idx)
                                                                     .admit_code,
                                                 p_app_no_in => lv_pending_tab_rec(idx)
                                                                 .app_no,
                                                 p_campus_code_in => lv_pending_tab_rec(idx)
                                                                      .camp_code);
        IF lv_has_pending_fees THEN
          EXIT;
        END IF;
      
      END LOOP;
    END IF;
    -- ver C end
    RETURN lv_has_pending_fees;
  
  END;
  PROCEDURE p_validate_params IS
  BEGIN
    NULL;
  END;
  PROCEDURE p_check_rules IS
    lv_debug BOOLEAN;
    lv_web   BOOLEAN;
  BEGIN
    lv_debug := gv_debug;
    lv_web   := gv_web;
    gv_debug := TRUE;
    gv_web   := FALSE;
    htp.print('All rules are defined!');
    p_debug('gv_instance is ' || gv_instance);
    -- ver C start
    --p_debug('gv_app_fee_chklist_code  is ' || gv_app_fee_chklist_code);
    -- ver C end
    p_debug('gv_upay_site_url (UPAY_SITE_' || gv_instance || ') is ' ||
            gv_upay_site_url);
    p_debug('gv_upay_ug_site_id is ' || gv_upay_ug_site_id);
    p_debug('gv_upay_gr_site_id  is ' || gv_upay_gr_site_id);
    p_debug('gv_upay_nd_site_id  is ' || gv_upay_nd_site_id);
    p_debug('gv_ug_app_fee_amt is ' || gv_ug_app_fee_amt);
    p_debug('gv_gr_app_fee_amt is ' || gv_gr_app_fee_amt);
    p_debug('gv_nd_app_fee_amt  is ' || gv_nd_app_fee_amt);
    p_debug('gv_upay_stpt_gr_site_id  is ' || gv_upay_stpt_gr_site_id);
    p_debug('gv_upay_stpt_ug_site_id  is ' || gv_upay_stpt_ug_site_id);
    p_debug('gv_stpt_ug_app_fee_amt  is ' || gv_stpt_ug_app_fee_amt);
    p_debug('gv_stpt_gr_app_fee_amt  is ' || gv_stpt_gr_app_fee_amt);
    -- 7.3F Start
    p_debug('gv_upay_usfp_ug_site_id  is ' || gv_upay_usfp_ug_site_id);
    p_debug('gv_upay_usfp_gr_site_id is ' || gv_upay_usfp_gr_site_id);
    p_debug('gv_usfp_ug_app_fee_amt is ' || gv_usfp_ug_app_fee_amt);
    p_debug('gv_usfp_gr_app_fee_amt is ' || gv_usfp_gr_app_fee_amt);
  
    -- 7.3F End
    gv_debug := lv_debug;
    gv_web   := lv_web;
    IF --gv_app_fee_chklist_code IS NULL OR
     gv_upay_site_url IS NULL OR gv_upay_ug_site_id IS NULL OR
     gv_upay_nd_site_id IS NULL OR gv_ug_app_fee_amt IS NULL OR
     gv_gr_app_fee_amt IS NULL OR gv_upay_stpt_gr_site_id IS NULL OR
     gv_upay_stpt_ug_site_id IS NULL OR gv_stpt_ug_app_fee_amt IS NULL OR
     gv_stpt_gr_app_fee_amt IS NULL THEN
      RAISE no_data_found;
    END IF;
    dbms_output.put_line('All rules are defined!');
  
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('Rules required Not defined ' ||
                           substr(SQLERRM, 1, 100));
      htp.print('Rules required Not defined ' || substr(SQLERRM, 1, 100));
  END;

  PROCEDURE p_display_no_pending IS
  BEGIN
    htp.br;
    htp.print('Currently you do not have any pending Application Fee for payment.');
    htp.print('<br/>');
    htp.br;
  END;

  PROCEDURE p_display_apps IS
    lv_prev_term_code VARCHAR2(100) := '1';
    lv_prev_appln     VARCHAR2(100) := '1';
    lv_cur_term_code  VARCHAR2(100) := '1';
    lv_cur_appln      VARCHAR2(100) := '1';
    FUNCTION f_is_new_app RETURN BOOLEAN IS
    BEGIN
      RETURN(lv_prev_term_code <> lv_cur_term_code) OR(lv_prev_appln <>
                                                       lv_cur_appln);
    
    END f_is_new_app;
  BEGIN
    -- initialize variables..
    -- htp.print('<html>');
    -- htp.print('<body>');
    twbkfrmt.p_tableopen('DATADISPLAY',
                         'summary="This table displays a list pending applications" cellspacing="10"');
    twbkfrmt.p_tablerowopen();
    twbkfrmt.p_tabledatalabel('Term Code');
    twbkfrmt.p_tabledatalabel('ApplicationNo');
    twbkfrmt.p_tabledatalabel('Level');
    twbkfrmt.p_tabledatalabel('College');
    twbkfrmt.p_tabledatalabel('Degree');
    twbkfrmt.p_tabledatalabel('');
    twbkfrmt.p_tablerowclose;
    FOR idx IN lv_pending_tab_rec.first .. lv_pending_tab_rec.last
    LOOP
      -- ver C start
      -- display only if the application is ok to display
      -- check the logic under the function description.
      IF f_is_ok_to_diplay(p_pidm_in => lv_pending_tab_rec(idx).pidm,
                           p_term_code_in => lv_pending_tab_rec(idx).term_code,
                           p_levl_in => lv_pending_tab_rec(idx).levl_code,
                           p_citz_in => lv_pending_tab_rec(idx).citz_code,
                           p_admit_type_in => lv_pending_tab_rec(idx)
                                               .admit_code,
                           p_app_no_in => lv_pending_tab_rec(idx).app_no,
                           p_campus_code_in => lv_pending_tab_rec(idx)
                                                .camp_code) THEN
        lv_cur_term_code := lv_pending_tab_rec(idx).term_code;
        lv_cur_appln     := lv_pending_tab_rec(idx).app_no;
        IF f_is_new_app THEN
          p_get_appln_fee_info(lv_pending_tab_rec(idx));
          --p_init(lv_pending_tab_rec(idx));
          p_debug('upay site url is ' || gv_upay_site_url);
          p_debug('UPAY_SITE_ID is ' || gv_site_id);
          p_debug('AMT is ' || gv_fee_amt);
          htp.formopen(curl => gv_upay_site_url, cmethod => 'post',
                       cattributes => 'name="OK"');
          htp.formhidden(cname => 'UPAY_SITE_ID', cvalue => gv_site_id);
          htp.formhidden(cname => 'AMT', cvalue => gv_fee_amt);
          htp.formhidden(cname => 'EXT_TRANS_ID',
                         cvalue => lv_pending_tab_rec(idx)
                                    .term_code || lc_segment_seperator || lv_pending_tab_rec(idx).id ||
                                     lc_segment_seperator || lv_pending_tab_rec(idx)
                                    .app_no || lc_segment_seperator || lv_pending_tab_rec(idx)
                                    .levl_code || lc_segment_seperator || lv_pending_tab_rec(idx)
                                    .camp_code || lc_segment_seperator ||
                                     'USF');
        END IF;
      
        twbkfrmt.p_tablerowopen();
        twbkfrmt.p_tabledata(lv_pending_tab_rec(idx).term_code);
        twbkfrmt.p_tabledata(lv_pending_tab_rec(idx).app_no);
        twbkfrmt.p_tabledata(lv_pending_tab_rec(idx).levl);
        twbkfrmt.p_tabledata(lv_pending_tab_rec(idx).coll);
        twbkfrmt.p_tabledata(lv_pending_tab_rec(idx).deg);
        IF f_is_new_app THEN
          htp.print('<td>');
          htp.print('<input type="submit" value="Pay Now">');
          htp.print('</FORM>');
          htp.print('</td>');
        ELSE
          twbkfrmt.p_tabledata('');
        END IF;
        twbkfrmt.p_tablerowclose;
      
        lv_prev_term_code := lv_pending_tab_rec(idx).term_code;
        lv_prev_appln     := lv_pending_tab_rec(idx).app_no;
      END IF;
      -- ver C end
    END LOOP;
    twbkfrmt.p_tableclose;
  
    -- htp.print('</body>');
    -- htp.print('</html>');
  END;
  FUNCTION f_get_pidm(pv_uid_in VARCHAR2) RETURN spriden.spriden_pidm%TYPE IS
    lv_pidm spriden.spriden_pidm%TYPE;
  BEGIN
    SELECT spriden_pidm
      INTO lv_pidm
      FROM spriden
     WHERE spriden_id = pv_uid_in
       AND spriden_change_ind IS NULL;
    RETURN lv_pidm;
  END;
  PROCEDURE p_xtract_appln_info_from_pmnt IS
    l_line VARCHAR2(200);
  BEGIN
    l_line       := lc_segment_seperator || gv_ext_trans_id ||
                    lc_segment_seperator;
    gv_term_code := wsaklnutil.wf_elm_value_of_elm(p_elm_pos_in => 1,
                                                   p_seg_in => l_line,
                                                   p_elm_sep_in => lc_segment_seperator,
                                                   p_seg_sep_in => lc_segment_seperator);
    gv_pidm      := f_get_pidm(wsaklnutil.wf_elm_value_of_elm(p_elm_pos_in => 2,
                                                              p_seg_in => l_line,
                                                              p_elm_sep_in => lc_segment_seperator,
                                                              p_seg_sep_in => lc_segment_seperator));
    gv_appln_no  := wsaklnutil.wf_elm_value_of_elm(p_elm_pos_in => 3,
                                                   p_seg_in => l_line,
                                                   p_elm_sep_in => lc_segment_seperator,
                                                   p_seg_sep_in => lc_segment_seperator);
    gv_levl_code := wsaklnutil.wf_elm_value_of_elm(p_elm_pos_in => 4,
                                                   p_seg_in => l_line,
                                                   p_elm_sep_in => lc_segment_seperator,
                                                   p_seg_sep_in => lc_segment_seperator);
  END p_xtract_appln_info_from_pmnt;
  PROCEDURE p_disp_pending_apps IS
  BEGIN
    IF NOT twbkwbis.f_validuser(pidm) THEN
      htp.print('not valid');
    END IF;
    p_disp_pending_apps(pidm);
  END;
  PROCEDURE p_disp_pending_apps(p_pidm_in NUMBER) IS
  
  BEGIN
    -- check all required values from rule and then only proceed.
    -- p_chk_rqd_values( this needs to be added)
    gv_pidm := p_pidm_in;
    -- check for pending application fees
    -- (Note: this also builds lv_pending_tab_rec).
    twbkwbis.p_opendoc('wsak_touchnet.p_disp_pending_apps');
    IF f_has_pending_appfee THEN
      p_display_apps;
    ELSE
      -- display no pending message
      p_display_no_pending;
      lv_pending_tab_rec.delete;
      NULL;
    END IF;
    twbkwbis.p_closedoc(curr_release);
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('in error');
      lv_pending_tab_rec.delete;
  END p_disp_pending_apps;

  PROCEDURE p_load_credit_info IS
  BEGIN
  
    INSERT INTO swrvisa
      (swrvisa_posting_key
      ,swrvisa_tgp_trans_id
      ,swrvisa_pmt_status
      ,swrvisa_pmt_amt
      ,swrvisa_pmt_date
      ,swrvisa_name_on_acct
      ,swrvisa_acct_addr
      ,swrvisa_acct_city
      ,swrvisa_acct_state
      ,swrvisa_acct_zip
      ,swrvisa_card_type
      ,swrvisa_ext_trans_id
      ,swrvisa_upay_site_id
      ,swrvisa_sys_tracking_id
      ,swrvisa_bank_name
      ,swrvisa_bank_addr1
      ,swrvisa_bank_addr2
      ,swrvisa_bank_routing_num
      ,swrvisa_rec_pmt_type)
    VALUES
      (gv_posting_key
      ,gv_tpg_trans_id
      ,gv_pmt_status
      ,gv_pmt_amt
      ,gv_pmt_date
      ,gv_name_on_acct
      ,gv_acct_addr
      ,gv_acct_city
      ,gv_acct_state
      ,gv_acct_zip
      ,gv_card_type
      ,gv_ext_trans_id
      ,gv_upay_site_id
      ,gv_sys_tracking_id
      ,gv_bank_name
      ,gv_bank_addr1
      ,gv_bank_addr2
      ,gv_bank_routing_num
      ,gv_rec_pmt_type);
    COMMIT;
  END;
  FUNCTION f_is_facts_appln RETURN BOOLEAN IS
    --lv_return boolean;
  BEGIN
    RETURN(instr(gv_ext_trans_id, '~') = 0);
  
  END;
  FUNCTION f_get_payment_ind RETURN VARCHAR2 IS
    lv_return VARCHAR2(1) := NULL;
  BEGIN
    IF instr(lower(gv_card_type), 'visa') > 0 THEN
      lv_return := 'V';
    ELSIF instr(lower(gv_card_type), 'mast') > 0then lv_return := 'M' ;
     ELSIF instr(lower(gv_card_type), 'exp') > 0 THEN
      lv_return := 'E';
    ELSIF instr(lower(gv_card_type), 'dis') > 0 THEN
      lv_return := 'D';
      --ELSIF instr(lower(gv_card_type), 'ch') > 0 THEN
    ELSE
      lv_return := 'C';
    END IF;
    RETURN lv_return;
  END;
  PROCEDURE p_mark_facts_appln_as_paid IS
    lv_accept_ind VARCHAR2(1) := 'A';
    lv_conf_numb  VARCHAR2(100);
    lv_etbl_rec   swtetbl%ROWTYPE;
    lv_xapp_rec   swbxapp%ROWTYPE;
  BEGIN
    IF instr(lower(gv_card_type), 'visa') > 0 THEN
      lv_accept_ind := 'V';
    ELSIF instr(lower(gv_card_type), 'mast') > 0then lv_accept_ind := 'M' ;
     ELSIF instr(lower(gv_card_type), 'exp') > 0 THEN
      lv_accept_ind := 'E';
    ELSIF instr(lower(gv_card_type), 'dis') > 0 THEN
      lv_accept_ind := 'D';
      /* ELSIF instr(lower(gv_card_type), 'ch') > 0 THEN*/
    ELSE
      lv_accept_ind := 'C';
    END IF;
    lv_conf_numb := wsaklnutil.wf_elm_value_of_elm(p_elm_pos_in => 1,
                                                   
                                                   p_seg_in => gv_ext_trans_id,
                                                   p_elm_sep_in => ':',
                                                   p_seg_sep_in => ':');
    SELECT *
      INTO lv_etbl_rec
      FROM swtetbl a
     WHERE a.swtetbl_conf_numb = lv_conf_numb;
    SELECT *
      INTO lv_xapp_rec
      FROM swbxapp a
     WHERE a.swbxapp_conf_numb = lv_conf_numb;
    IF nvl(lv_etbl_rec.swtetbl_load_ind, 'E') IN ('E', 'X') OR
       lv_xapp_rec.swbxapp_levl_code = 'ND' THEN
      UPDATE swtetbl a
         SET a.swtetbl_credit_card_accept_ind = decode(a.swtetbl_grad_appl_ind,
                                                       'N', 'A', lv_accept_ind)
       WHERE a.swtetbl_conf_numb = lv_conf_numb;
    ELSE
      wsaketbl.p_upd_chklst_for_paid_appfee(p_pidm_in => lv_xapp_rec.swbxapp_pidm,
                                            p_term_code_in => lv_xapp_rec.swbxapp_appl_term,
                                            p_appl_no_in => lv_xapp_rec.swbxapp_appl_no,
                                            p_cc_type_ind_in => f_get_payment_ind,
                                            p_conf_in => gv_sys_tracking_id,
                                            p_level => lv_xapp_rec.swbxapp_levl_code);
    END IF;
  
  END;
  -- Version E Begin
  PROCEDURE load_credit_payment_info
  (
    name_array  IN owa.vc_arr
   ,value_array IN owa.vc_arr
  ) IS
    /*  PROCEDURE load_credit_payment_info
    (
      posting_key            VARCHAR2 DEFAULT NULL
     ,tpg_trans_id           VARCHAR2 DEFAULT NULL
     ,pmt_status             VARCHAR2 DEFAULT NULL
     ,pmt_amt                VARCHAR2 DEFAULT NULL
     ,pmt_date               VARCHAR2 DEFAULT NULL
     ,name_on_acct           VARCHAR2 DEFAULT NULL
     ,acct_addr              VARCHAR2 DEFAULT NULL
     ,acct_city              VARCHAR2 DEFAULT NULL
     ,acct_state             VARCHAR2 DEFAULT NULL
     ,acct_zip               VARCHAR2 DEFAULT NULL
     ,card_type              VARCHAR2 DEFAULT NULL
     ,ext_trans_id           VARCHAR2 DEFAULT NULL
     ,upay_site_id           VARCHAR2 DEFAULT NULL
     ,sys_tracking_id        VARCHAR2 DEFAULT NULL
     ,bank_name              VARCHAR2 DEFAULT NULL
     ,bank_addr1             VARCHAR2 DEFAULT NULL
     ,bank_addr2             VARCHAR2 DEFAULT NULL
     ,bank_routing_num       VARCHAR2 DEFAULT NULL
     ,recurring_payment_type VARCHAR2 DEFAULT NULL
    ) IS */
    -- Version E End
    lv_paid_ind VARCHAR2(1) := 'N';
    lv_success  BOOLEAN;
    lv_message  VARCHAR2(2000);
    lv_stage    VARCHAR2(200);
    FUNCTION f_is_successful_payment RETURN BOOLEAN IS
    BEGIN
      RETURN upper(gv_pmt_status) = upper('success');
    END;
  BEGIN
    -- Version E Begin
    FOR n IN 1 .. name_array.count
    LOOP
      CASE upper(name_array(n))
        WHEN 'POSTING_KEY' THEN
          gv_posting_key := value_array(n);
        WHEN 'TPG_TRANS_ID' THEN
          gv_tpg_trans_id := value_array(n);
        WHEN 'PMT_STATUS' THEN
          gv_pmt_status := value_array(n);
        WHEN 'PMT_AMT' THEN
          gv_pmt_amt := value_array(n);
        WHEN 'PMT_DATE' THEN
          gv_pmt_date := value_array(n);
        WHEN 'NAME_ON_ACCT' THEN
          gv_name_on_acct := value_array(n);
        WHEN 'ACCT_ADDR' THEN
          gv_acct_addr := value_array(n);
        WHEN 'ACCT_CITY' THEN
          gv_acct_city := value_array(n);
        WHEN 'ACCT_STATE' THEN
          gv_acct_state := value_array(n);
        WHEN 'ACCT_ZIP' THEN
          gv_acct_zip := value_array(n);
        WHEN 'CARD_TYPE' THEN
          gv_card_type := value_array(n);
        WHEN 'EXT_TRANS_ID' THEN
          gv_ext_trans_id := value_array(n);
        WHEN 'UPAY_SITE_ID' THEN
          gv_upay_site_id := value_array(n);
        WHEN 'SYS_TRACKING_ID' THEN
          gv_sys_tracking_id := value_array(n);
        WHEN 'BANK_NAME' THEN
          gv_bank_name := value_array(n);
        WHEN 'BANK_ADDR1' THEN
          gv_bank_addr1 := value_array(n);
        WHEN 'BANK_ADDR2' THEN
          gv_bank_addr2 := value_array(n);
        WHEN 'BANK_ROUTING' THEN
          gv_bank_routing_num := value_array(n);
        WHEN 'BANK_ROUTING_NUM' THEN
          gv_bank_routing_num := value_array(n);
        WHEN 'RECURRING_PAYMENT_TYPE' THEN
          gv_rec_pmt_type := value_array(n);
        ELSE
          NULL;
      END CASE;
    END LOOP;
    -- Version E End
    p_debug('in load_credit_payment_info');
    p_debug('ext_trans_id is ' || gv_ext_trans_id);
    -- IF ext_trans_id IS NOT NULL THEN
    -- Version E Begin
    /*    gv_posting_key      := posting_key;
    gv_tpg_trans_id     := tpg_trans_id;
    gv_pmt_status       := pmt_status;
    gv_pmt_amt          := pmt_amt;
    gv_pmt_date         := pmt_date;
    gv_name_on_acct     := name_on_acct;
    gv_acct_addr        := acct_addr;
    gv_acct_city        := acct_city;
    gv_acct_state       := acct_state;
    gv_acct_zip         := acct_zip;
    gv_card_type        := card_type;
    gv_ext_trans_id     := ext_trans_id;
    gv_upay_site_id     := upay_site_id;
    gv_sys_tracking_id  := sys_tracking_id;
    gv_bank_name        := bank_name;
    gv_bank_addr1       := bank_addr1;
    gv_bank_addr2       := bank_addr2;
    gv_bank_routing_num := bank_routing_num;
    gv_rec_pmt_type     := recurring_payment_type; */
    lv_stage := 'before loading credit card info into table.';
    p_validate_params;
    p_load_credit_info;
  
    --IF f_is_successful_payment THEN
    lv_stage := 'successful_payment.';
    -- application needs to reviewied
    IF f_is_facts_appln THEN
      lv_stage := 'facts application.';
      p_mark_facts_appln_as_paid;
    ELSE
      lv_stage := 'ssb application, before xtracting app info';
      -- this can not be ND application.
      p_xtract_appln_info_from_pmnt;
    
      lv_paid_ind := f_get_payment_ind;
      lv_stage    := 'calling upd chkllst appfee.';
      wsaketbl.p_upd_chklst_for_paid_appfee(p_pidm_in => gv_pidm,
                                            p_term_code_in => gv_term_code,
                                            p_appl_no_in => gv_appln_no,
                                            p_cc_type_ind_in => lv_paid_ind,
                                            p_conf_in => gv_sys_tracking_id,
                                            p_level => gv_levl_code);
      -- p_mark_appln_as_needs_to_rev;
      -- since we received payment, take it out from application check list
      --p_fulfil_appln_chk_list;
    END IF;
    /*ELSE
      wp_handle_error_db('TOUCHNET_PROCESS'
                        ,'wsak_touchnet.load_credit_payment_info'
                        ,'BUSINESS'
                        ,'Unable to update for Confirmation no, ' ||
                         gv_tpg_trans_id
                        ,lv_success
                        ,lv_message);
    END IF;*/
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      wp_handle_error_db('TOUCHNET_PROCESS',
                         'wsak_touchnet.load_credit_payment_info', 'ORACLE',
                         'at ' || lv_stage || ' and error is ' ||
                          substr(SQLERRM, 1, 200), lv_success, lv_message);
  END;
BEGIN
  SELECT substr(global_name, 1, 4) INTO gv_instance FROM global_name;

  gv_instance        := upper(gv_instance);
  gv_upay_site_url   := f_get_swrrule_val(gc_xref_qlfr_facts,
                                          'UPAY_SITE_' || gv_instance);
  gv_upay_ug_site_id := lower(f_get_swrrule_val(gc_xref_qlfr_facts,
                                                'UPAY_UG_SITE_ID'));
  gv_upay_gr_site_id := lower(f_get_swrrule_val(gc_xref_qlfr_facts,
                                                'UPAY_GR_SITE_ID'));

  gv_upay_nd_site_id := lower(f_get_swrrule_val(gc_xref_qlfr_facts,
                                                'UPAY_ND_SITE_ID'));

  gv_ug_app_fee_amt := f_get_swrrule_val(gc_xref_qlfr_facts,
                                         'UG_APP_FEE_AMT');
  gv_gr_app_fee_amt := f_get_swrrule_val(gc_xref_qlfr_facts,
                                         'GR_APP_FEE_AMT');

  gv_nd_app_fee_amt := f_get_swrrule_val(gc_xref_qlfr_facts,
                                         'ND_APP_FEE_AMT');

  gv_upay_stpt_gr_site_id := lower(f_get_swrrule_val(gc_xref_qlfr_facts,
                                                     'UPAY_STPT_GR_SITE_ID'));

  gv_upay_stpt_ug_site_id := lower(f_get_swrrule_val(gc_xref_qlfr_facts,
                                                     'UPAY_STPT_UG_SITE_ID'));

  gv_stpt_ug_app_fee_amt := f_get_swrrule_val(gc_xref_qlfr_facts,
                                              'STPT_UG_APP_FEE_AMT');
  gv_stpt_gr_app_fee_amt := f_get_swrrule_val(gc_xref_qlfr_facts,
                                              'STPT_GR_APP_FEE_AMT');

  gv_upay_sm_gr_site_id := lower(f_get_swrrule_val(gc_xref_qlfr_facts,
                                                   'UPAY_SM_GR_SITE_ID'));

  gv_upay_sm_ug_site_id := lower(f_get_swrrule_val(gc_xref_qlfr_facts,
                                                   'UPAY_SM_UG_SITE_ID'));

  gv_sm_ug_app_fee_amt := f_get_swrrule_val(gc_xref_qlfr_facts,
                                            'SM_UG_APP_FEE_AMT');
  gv_sm_gr_app_fee_amt := f_get_swrrule_val(gc_xref_qlfr_facts,
                                            'SM_GR_APP_FEE_AMT');
  -- 7.3F Start
  gv_upay_usfp_gr_site_id := lower(f_get_swrrule_val(gc_xref_qlfr_facts,
                                                     'UPAY_USFP_GR_SITE_ID'));

  gv_upay_usfp_ug_site_id := lower(f_get_swrrule_val(gc_xref_qlfr_facts,
                                                     'UPAY_USFP_UG_SITE_ID'));

  gv_usfp_ug_app_fee_amt := f_get_swrrule_val(gc_xref_qlfr_facts,
                                              'USFP_UG_APP_FEE_AMT');

  gv_usfp_gr_app_fee_amt := f_get_swrrule_val(gc_xref_qlfr_facts,
                                              'USFP_GR_APP_FEE_AMT');
  -- 7.3F End

EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Please check rules definitions. Some of rules are not defined.');
    htp.p('Please check rules definitions. Some of rules are not defined.');
    htp.p('Unable to initialize constants ..' || substr(SQLERRM, 1, 200));
  
END;
/
