CREATE OR REPLACE PACKAGE BANINST1.wsak_adm_appl IS
  gv_debug BOOLEAN := TRUE;
  TYPE gt_rules_tab IS TABLE OF VARCHAR2(200) INDEX BY VARCHAR2(200);
  ge_service_ticket    EXCEPTION;
  ge_unauthorized_user EXCEPTION;
  ge_others            EXCEPTION;
  ge_invalid_schema    EXCEPTION;
  ge_invalid_xapp_data EXCEPTION;
  ge_invalid_etbl_data EXCEPTION;
  ge_invalid_etst_data EXCEPTION;
  ge_invalid_fapc_data EXCEPTION;
  ge_etbl_select_error EXCEPTION;
  ge_nd_load_error     EXCEPTION;
  ge_invalid_conf_numb EXCEPTION;
  ge_invalid_dad_group EXCEPTION;
	GE_INVALID_APPID     exception;
  --****************************************************************************************************************************
  --
  --  University of South Florida
  --  Student Information System
  --  Program Unit Information
  --
  --  General Information
  --  -------------------
  --  Program Unit Name  : wsak_adm_appl
  --  Process Associated : Admissions
  --  Object Source File Location and Name : dbprocs\wsak_adm_appl.sql
  --  Business Logic : Package to handle web admission
  --   Package to handle web
  --  Documentation Links:
  --   O:\Documentation\OASIS\09-0045 Web Application for Admission
  --
  --
  --
  -- Audit Trail (in descending date order)
  -- --------------------------------------
  --  Version   Issue          Date          User         Reason For Change
  --  -------  ---------    -----------     --------     -----------------------
  --  #2
  --   #1
  --   A       O8-000495    02/16/2011      VBANGALo      Initial creation.
  --   B       OASBAN-2     05/08/2012      NABDELRA      Added procedures for processing docs downloaded for VisualZen
  --   C       OASBAN-89    01/16/2013      NABDELRA      Modifeid p_after_indexing proc ,
  --                                                      Added a parameter to fix bdms time difference problem
  --                                                      For #INC0052301

  --   D       OASBAN-106   04/22/13        VBANGALO      Added "VZCA post submission" functionality
  --   E       OASBAN-118   06/05/2013      VBANGALO      Added missing version C code.
  --   F       OASBAN-114   05/16/2013      VBANGALO      Changed code to accept from new webclients like bisk to submit
  --                                                      application in xml format.
  --   G       OASBAN-124   06/20/2013         HHNGO      Changed for BISK Application Documents as follow per #12-0177:
  --                                                      1) Renamed p_eligible_vzid to p_create_eligibleID_file to use
  --                                                         for Bisk or Into besides VZ; added a parm pv_docid_prefix to
  --                                                         accept the DocID Prefix value from Applications Manager passed in;
  --                                                         created an empty file when there's no data in swbxapp table.
  --                                                      2) Modified p_process_vz_doc to read the file received from BISK.
  --                                                      3) Added CURSOR c_appl_not_loaded in proc p_edit_vz_doc for
  --                                                         applications that are not yet loaded into Banner.
  --                                                      4) In p_create_bdms_index, added swrvdoc_conf_numb in CURSOR c_bdms_idx;
  --                                                         removed @ value on file type and used @@ only; included conf_numb and
  --                                                         file_name before the @@ when writing index into a file.
  --                                                      5) In p_after_indexing, removed parm pv_bdms_time_diff to replace with
  --                                                         swrvdoc_conf_numb (field15) and swrvdoc_file_name (field16) to match
  --                                                         the data which preventing documents loading multiple times; field15 and
  --                                                         field16 are newly created fields in otgmgr.ae_dt509 by BDMS Admistrator.
  --                                                      6) Renamed from VZ to APPLICATIONS for LOG REPORT and ERROR REPORT so 
  --                                                         these can be used for other applications, e.g. Bisk or Into besides VZ.
  --****************************************************************************************************************************

  /**
   This procedure allows broswr/http client program to get authenticated and redirects to p_submit_xml.
   Parameters: ticket
   Example: (In DVLP) https://oasisnp.it.usf.edu:8034/pls/vzusfappdvlp/!wsak_adm_appl.p_login?ticket=STXXXX
   For bisk in DVLP   https://oasisnp.it.usf.edu:8034/pls/biskappdvlp/!wsak_adm_appl.p_login?ticket=STXXXX
   For bisk in PPRD   https://oasisnp.it.usf.edu:8035/pls/biskapppprd/!wsak_adm_appl.p_login?ticket=STXXXX

  */
  PROCEDURE p_login(name_array IN owa.vc_arr

                   ,value_array IN owa.vc_arr);
  /**
     This procedure loads application submitted in XML into temporary holding area.
     Parameter: appln CLOB Application in XML format. (Application info should be in xml as par the schmea defined in registered schma
     whose URI is http://www.usf.edu/adm/APP.xsd. This is an URI not URL.)
  */
  PROCEDURE p_web_load_xml(appln CLOB);

  /**This procedure allows to submit xml application through browser. Opens up form with text area.
     Application should be copied into this text area in XML format. The xml should ahere to schma defined in
     URI, http://www.usf.edu/adm/APP.xsd, which is registerd as xml type in baninst1 schema.
      This procedure should not be called directly     through browser. You need to go to p_login page which, after autenitcating,
      will redirect to this page.
  */
  PROCEDURE p_submit_xml;


 /*This procedure create a file with all the ids that are eligible for VZ or BA download
   based on pv_docid_prefix passed in.*/
 PROCEDURE p_create_eligibleID_file
  (
    pv_dir         IN VARCHAR2
   ,pv_elig_file   IN VARCHAR2
   ,pv_docid_prefix IN VARCHAR2
  );

  /*This procedure reads  a file that contains the file names recieved from VZ and insert the records in swrvdoc,
  p_edit_doc is called from within this proc and is responsible for updating swrvdoc.*/
  PROCEDURE p_process_vz_doc
  (
    pv_file_name   IN VARCHAR2
   ,pv_err_file    IN VARCHAR2
   ,pv_dir         IN VARCHAR2
   ,pv_message_o   OUT VARCHAR2
  );

  /*This proc is responible of creating the bdms index file used by bdms appxtender*/
  PROCEDURE p_create_bdms_index
  (
    pv_dir      IN VARCHAR2
   ,pv_bdms_dir IN VARCHAR2
   ,pv_idx_id   IN VARCHAR2
  );

  FUNCTION f_get_campus(pv_camp_id VARCHAR2) RETURN VARCHAR2;
  PRAGMA RESTRICT_REFERENCES(f_get_campus, WNDS);

  /*This proc writes the number of documents being imaged in BDMS based on Lavel/campus/Doctype in a transaction log file.
  It then  deletes records from swrvdoc once they have been successfully indexed into BDMS or once they become obsolete
  It writes the document names in a file which will then be used to delete docs from folder in server*/
  PROCEDURE p_after_indexing
  (
    pv_dir  IN VARCHAR2
   ,pv_file IN VARCHAR2
   ,pv_log  IN VARCHAR2
   ,pv_days IN NUMBER)
  ;

  /**
    * This procedure checks payment status and generates xml response in http based confirmation number of student application.
    * parameters:
    * @pv_conf_numb  application confirmation number returned to applicant when application submitted.
  */
  PROCEDURE p_is_payment_exists(pv_conf_numb VARCHAR2);
  /**
    * This functions returns true if student already paid application fee or false if he did not paid applicaiton fee.
    * parameters:
    * @pv_conf_numb  application confirmation number returned to applicant when application submitted.
  */
  FUNCTION f_is_payment_made(pv_conf_numb VARCHAR2) RETURN BOOLEAN;

END wsak_adm_appl;
/
CREATE OR REPLACE PACKAGE BODY BANINST1.wsak_adm_appl IS
  gv_rules_array    gt_rules_tab;
  gv_cims_lgn_url   swrrule.swrrule_value%TYPE;
  gv_cims_val_url   swrrule.swrrule_value%TYPE;
  gv_xsl_bfile      BFILE;
  gv_xsl_xml        xmltype;
  gv_transform      xmltype;
  gv_xml            xmltype;
  gv_cononical_clob CLOB;
  gv_dom            xmldom.domdocument;
  gv_main_node      xmldom.domnode;
  gv_root_node      xmldom.domnode;
  gv_log_array      wsak_log.gt_log_array;
  gv_conf_numb      swtetbl.swtetbl_conf_numb%TYPE;
  gv_cookie_val     VARCHAR2(200);
  gv_file_name      VARCHAR2(200);
  gv_ssn            VARCHAR2(100);
  gv_docid          VARCHAR2(200);
  gv_error          VARCHAR2(2000);
  gv_doctype        VARCHAR2(100);
  gv_group          VARCHAR2(200) := 'FACTS_ADM_APPL';
  gv_appid_prefix   VARCHAR2(20) := 'VZ';

  PROCEDURE p_log(pv_message_i VARCHAR2);
  PROCEDURE p_proc_load_xml(pv_app_io IN CLOB);
	PROCEDURE p_set_app_group;

  /** this function gets DB instance name*/
  FUNCTION f_get_instance RETURN VARCHAR2 IS
    lv_return VARCHAR2(20);
  BEGIN
    SELECT substr(global_name, 1, 4) INTO lv_return FROM global_name;
    RETURN lv_return;
  END;

  /** This procedure writes information to log file.*/
  PROCEDURE p_log_to_file IS
  BEGIN
    -- If there is part of redirect, use cookie as file name.
    IF gv_cookie_val IS NULL THEN
      gv_file_name := 'ADMAPP_' || dbms_random.string('X', 5) || '.log';
    ELSE
      gv_file_name := 'ADMAPP_' || gv_cookie_val || '.log';
    END IF;
    -- write message to log file
    wsak_log.p_log_to_file(gv_log_array_io => gv_log_array,
                           file_name_i => gv_file_name);
    -- If there is track/conf number then include it in file name
    IF gv_conf_numb IS NOT NULL THEN

      wsak_log.p_rename_log_file(pv_new_file_name_i => 'ADMAPP_' ||
                                                       gv_conf_numb ||
                                                       '.log',
                                 pv_old_file_name_i => gv_file_name);
      gv_file_name := 'ADMAPP_' || gv_conf_numb || '.log';
    END IF;
  END;

  /** This procedure geneerates successful response in xml */
  PROCEDURE p_create_success_response IS
    lv_clob CLOB;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    p_log('');
    p_log('in WSAK_ADM_APPL.P_CREATE_SUCCESS_RESPONSE..');
    -- track application status
    INSERT INTO swbferr
      (swbferr_error_code
      ,swbferr_timestamp
      ,swbferr_function
      ,swbferr_docname
      ,swbferr.swbferr_ssn)
    VALUES
      ('00000'
      ,SYSDATE
      ,'ADMISSIONS'
      ,gv_docid
      ,gv_ssn);
    COMMIT;
    -- create successful response
    wsak_xml.p_create_main_node('1.0', 'Response', gv_dom, gv_root_node,
                                gv_main_node);
    wsak_xml.p_add_child(gv_dom, gv_main_node, 'status', 'success', NULL,
                         NULL);
    wsak_xml.p_add_child(gv_dom, gv_main_node, 'track', gv_conf_numb, NULL,
                         NULL);
    dbms_lob.createtemporary(lv_clob, TRUE);
    xmldom.writetoclob(gv_dom, lv_clob);
    xmldom.freedocument(gv_dom);
    owa_util.mime_header('text/xml', TRUE);
    htp.p(lv_clob);
  EXCEPTION
    WHEN OTHERS THEN
      htp.p('Error: ' || SQLERRM);
  END;

  /** This procedure creates error reponse in xml format
      Parameter: pv_exception_code_i Exception code defined in swrjexp table.
  */

  PROCEDURE p_create_error_response(pv_exception_code_i VARCHAR2) IS
    lv_clob              CLOB;
    lv_err_rec           swrjexp%ROWTYPE;
    lv_excep_not_defined BOOLEAN := FALSE;
    lv_err_code          swrjexp.swrjexp_error_code%TYPE;
    lv_err_message       swrjexp.swrjexp_error_desc%TYPE;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    p_log('');
    p_log('in WSAK_ADM_APPL.P_CRATE_ERROR_RESPONSE..');
    p_log('pv_exception_code_i is ' || pv_exception_code_i);
    -- get exception information from exception rule table.
    BEGIN
      SELECT *
        INTO lv_err_rec
        FROM swrjexp a
       WHERE a.swrjexp_exception = pv_exception_code_i;
      p_log('exception rule exists');
    EXCEPTION
      WHEN OTHERS THEN
        p_log('exception rule NOT exists');
        lv_excep_not_defined := TRUE;
    END;
    IF lv_excep_not_defined THEN
      -- if exception not defined, assign default values
      lv_err_code    := '99999';
      lv_err_message := 'Rules not defined for exception ' ||
                        pv_exception_code_i;
    ELSE
      lv_err_code    := lv_err_rec.swrjexp_error_code;
      lv_err_message := lv_err_rec.swrjexp_error_desc;
    END IF;
    -- log information to a file
    p_log_to_file;
    -- save transaction as unsuccessful.
    INSERT INTO swbferr
      (swbferr_error_code
      ,swbferr_timestamp
      ,swbferr_function
      ,swbferr_docname)
    VALUES
      (lv_err_code
      ,SYSDATE
      ,'ADMISSIONS'
      ,gv_file_name);
    -- create error response in xml format and send
    wsak_xml.p_create_main_node('1.0', 'Response', gv_dom, gv_root_node,
                                gv_main_node);
    wsak_xml.p_add_child(gv_dom, gv_main_node, 'status', 'failure', NULL,
                         NULL);
    wsak_xml.p_add_child(gv_dom, gv_main_node, 'error_code', lv_err_code,
                         NULL, NULL);
    wsak_xml.p_add_child(gv_dom, gv_main_node, 'error_message',
                         lv_err_message || '~' || gv_error, NULL, NULL);
    wsak_xml.p_add_child(gv_dom, gv_main_node, 'log_file', gv_file_name,
                         NULL, NULL);
    dbms_lob.createtemporary(lv_clob, TRUE);
    xmldom.writetoclob(gv_dom, lv_clob);
    xmldom.freedocument(gv_dom);
    owa_util.mime_header('text/xml', TRUE);
    htp.p(lv_clob);

    COMMIT;
    gv_log_array.delete;
  EXCEPTION
    WHEN OTHERS THEN
      htp.p('Error: ' || SQLERRM);
  END;

  PROCEDURE p_init IS
  BEGIN
    gv_xsl_bfile      := NULL;
    gv_xsl_xml        := NULL;
    gv_transform      := NULL;
    gv_cononical_clob := NULL;
  END;

  /** This procedure logs information to log array */
  PROCEDURE p_log(pv_message_i VARCHAR2) IS
  BEGIN
    IF NOT gv_log_array.exists(1) THEN
      gv_log_array := wsak_log.gt_log_array();
    END IF;
    gv_log_array.extend();
    gv_log_array(gv_log_array.last) := pv_message_i;
  END;

  /** this procedure gets Urls related to CAS from rules */
  PROCEDURE p_set_cims_lgn_val_urls IS
  BEGIN
    -- Make sure that urls are PROD urls
    IF f_get_instance = 'PROD' THEN
      gv_cims_lgn_url := wsak_cims.f_get_cims_url(pv_appln_i => gv_group,
                                                  pv_sdax_int_code_i => 'CIMS',
                                                  pv_sdax_ext_code_i => 'CIMS_LGN_PROD');
      gv_cims_val_url := wsak_cims.f_get_cims_url(pv_appln_i => gv_group,
                                                  pv_sdax_int_code_i => 'CIMS',
                                                  pv_sdax_ext_code_i => 'CIMS_VAL_PROD');
    ELSE
      gv_cims_lgn_url := wsak_cims.f_get_cims_url(pv_appln_i => gv_group,
                                                  pv_sdax_int_code_i => 'CIMS',
                                                  pv_sdax_ext_code_i => 'CIMS_LGN');
      gv_cims_val_url := wsak_cims.f_get_cims_url(pv_appln_i => gv_group,
                                                  pv_sdax_int_code_i => 'CIMS',
                                                  pv_sdax_ext_code_i => 'CIMS_VAL');
    END IF;

  END;
  /**
    This procedure sets rules infomration in array related to web application.
    This rule array is later used instead of selecting directly from table.
  */
  PROCEDURE p_get_rules_and_set_debug IS
  BEGIN
    p_log('');
    p_log('in WSAK_ADM_APPL.P_GET_RULES_AND_SET_DEBUG..');

    FOR x IN (SELECT a.gtvsdax_internal_code
                    ,a.gtvsdax_translation_code
                FROM gtvsdax a
               WHERE a.gtvsdax_internal_code_group = gv_group
                 AND gtvsdax_internal_code NOT IN ('CIMS'))
    LOOP
      p_log(x.gtvsdax_internal_code || ' := ' ||
            x.gtvsdax_translation_code);
      gv_rules_array(x.gtvsdax_internal_code) := x.gtvsdax_translation_code;
    END LOOP;

    IF gv_rules_array('DEBUG_FILE') = 'TRUE' THEN
      p_log('debug is true');
      gv_debug := TRUE;
    ELSE
      p_log('debug is false');
      gv_debug := FALSE;
    END IF;
  END;
  /**
   This procedure inserts xml (which is in canonical format) into table.
  */

  PROCEDURE p_xml_insert
  (
    xmldoc    IN CLOB
   ,tablename IN VARCHAR2
  ) IS
    insctx dbms_xmlsave.ctxtype;
    rows   NUMBER;
  BEGIN
    -- get the table context
    insctx := dbms_xmlsave.newcontext(tablename); -- get the context handle
    -- insert into table.
    rows := dbms_xmlsave.insertxml(insctx, xmldoc); -- this inserts the document
    -- need not check rows since we always insert one row.
    -- close context
    dbms_xmlsave.closecontext(insctx); -- this closes the handle
  END;
  /** This procedure transforms xml into cannoical format and then insert into
  table.
  Parameters: pv_xsl_file_name_i Name of the xls file that converts raw xml into
                                 canonical format.
              pv_table_name_i    Name of the table in which data need to be saved.
  */

  PROCEDURE p_table_insert
  (
    pv_xsl_file_name_i VARCHAR2
   ,pv_table_name_i    VARCHAR2
  ) IS

  BEGIN
    gv_xsl_bfile      := bfilename(directory => 'USF_LIB',
                                   filename => pv_xsl_file_name_i);
    gv_xsl_xml        := xmltype.createxml(gv_xsl_bfile, 0, NULL, 0, 0);
    gv_transform      := gv_xml.transform(gv_xsl_xml);
    gv_cononical_clob := gv_transform.getclobval();
    p_xml_insert(gv_cononical_clob, pv_table_name_i);
    p_init;

  END;

  PROCEDURE p_submit_xml AS
  BEGIN
    -- since vz unable to send cookie, do not send error response and do not log messages
    -- check if session is valid and diplay textarea where xml can be posted.
    --
    IF wsak_web_authorize.f_check_valid_session(gv_log_array, gv_cookie_val) THEN
      htp.p('<html><head></head><body>');
      htp.p('<h2> want to load xml? </h2>');
      htp.p('<form action ="wsak_adm_appl.p_web_load_xml" method = "post">');
      htp.p('<textarea  rows="20" cols="100" name ="appln"></textarea>');
      htp.p('<input type = "submit">');
      htp.p('</form>');
      htp.p('<h2> want to check payment? </h2>');
      htp.p('<form action ="wsak_adm_appl.p_is_payment_exists" method = "post">');
      htp.p('<input type="text" name="pv_conf_numb"> </input>');
      htp.p('<input type = "submit">');
      htp.p('</form>');

      htp.p('</body></html>');
    ELSE
      htp.p('in wsak_web_authorize.p_submit_xml .. null/invalid cookie');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      htp.p('in wsak_web_authorize.p_submit_xml .. null/invalid cookie');
  END;

  FUNCTION f_is_payment_made(pv_conf_numb VARCHAR2) RETURN BOOLEAN IS
    lv_etbl_rec    swtetbl%ROWTYPE;
    lv_xapp_rec    swbxapp%ROWTYPE;
    lv_paid        BOOLEAN;
    lv_sgbstdn_rec sgbstdn%ROWTYPE;
    lv_count       NUMBER;
  BEGIN
    -- validate confirmation number
    BEGIN
      SELECT *
        INTO lv_etbl_rec
        FROM swtetbl a
       WHERE a.swtetbl_conf_numb = pv_conf_numb;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE ge_invalid_conf_numb;
    END;
    -- if application is not loaded then check staging table for payment status
    IF nvl(lv_etbl_rec.swtetbl_load_ind, 'N') <> 'L' THEN
      IF nvl(lv_etbl_rec.swtetbl_credit_card_accept_ind, 'N') = 'N' THEN
        lv_paid := FALSE;
      ELSE
        lv_paid := TRUE;
      END IF;
    ELSE

      lv_xapp_rec := NULL;
      SELECT *
        INTO lv_xapp_rec
        FROM swbxapp a
       WHERE a.swbxapp_conf_numb = pv_conf_numb;
      -- if application is loaded and is non degree check sgbstdn for status.
      IF lv_etbl_rec.swtetbl_grad_appl_ind = 'N' THEN
        SELECT *
          INTO lv_sgbstdn_rec
          FROM sgbstdn a
         WHERE a.sgbstdn_pidm = lv_xapp_rec.swbxapp_pidm
           AND a.sgbstdn_term_code_eff = lv_xapp_rec.swbxapp_appl_term
           AND a.sgbstdn_levl_code = 'ND'
           AND a.sgbstdn_stst_code = 'AS';
        IF lv_sgbstdn_rec.sgbstdn_rate_code = 'AFNDP' AND
           lv_sgbstdn_rec.sgbstdn_activity_date IS NOT NULL THEN
          lv_paid := TRUE;
        ELSE
          lv_paid := FALSE;
        END IF;
      ELSE
        -- if application is loaded and is not non degree application, check checklist items
        lv_count := 0;
        SELECT COUNT(*)
          INTO lv_count
          FROM dual
         WHERE lv_xapp_rec.swbxapp_pidm IN
               (SELECT lv_xapp_rec.swbxapp_pidm
                  FROM sarchkl a
                 WHERE a.sarchkl_pidm = lv_xapp_rec.swbxapp_pidm
                   AND a.sarchkl_term_code_entry =
                       lv_xapp_rec.swbxapp_appl_term
                   AND a.sarchkl_appl_no = lv_xapp_rec.swbxapp_appl_no
                   AND a.sarchkl_receive_date IS NOT NULL
                   AND a.sarchkl_admr_code IN
                       (SELECT sx.gtvsdax_translation_code
                          FROM gtvsdax sx
                         WHERE sx.gtvsdax_internal_code_group =
                               'FEECHECKLIST'
                           AND sx.gtvsdax_internal_code = 'WAIVEDFEE'
                        UNION
                        SELECT 'FEE' FROM dual));
        lv_paid := lv_count > 0;

      END IF;

    END IF;
    RETURN lv_paid;
  END;

  PROCEDURE p_is_payment_exists(pv_conf_numb VARCHAR2) IS
    lv_clob        CLOB;
    lv_paid_status VARCHAR2(100);

  BEGIN
    p_log('');
    p_log('in WSAK_ADMN_APPLN.p_is_payment_exists..');
		p_set_app_group;    
    -- get rules into array
    p_get_rules_and_set_debug;
    -- load xml only if it is valid session
    IF wsak_web_authorize.f_check_valid_session(gv_log_array, gv_cookie_val) THEN
      IF f_is_payment_made(pv_conf_numb) THEN
        lv_paid_status := 'PAID';
      ELSE
        lv_paid_status := 'NOT PAID';
      END IF;

      wsak_xml.p_create_main_node('1.0', 'Response', gv_dom, gv_root_node,
                                  gv_main_node);
      wsak_xml.p_add_child(gv_dom, gv_main_node, 'status', 'success', NULL,
                           NULL);
      wsak_xml.p_add_child(gv_dom, gv_main_node, 'paid_status',
                           lv_paid_status, NULL, NULL);
      dbms_lob.createtemporary(lv_clob, TRUE);
      xmldom.writetoclob(gv_dom, lv_clob);
      xmldom.freedocument(gv_dom);
      owa_util.mime_header('text/xml', TRUE);
      htp.p(lv_clob);
    ELSE
      -- if not authorized user, send error response
      RAISE ge_unauthorized_user;
    END IF;
  EXCEPTION
    WHEN ge_unauthorized_user THEN
      ROLLBACK;
      p_create_error_response('GE_UNAUTHORIZED_USER');
    WHEN ge_invalid_conf_numb THEN
      ROLLBACK;
      p_create_error_response('GE_INVALID_CONF_NUMB');
    WHEN ge_invalid_schema THEN
      ROLLBACK;
      p_create_error_response('GE_INVALID_SCHEMA');
      gv_error := SQLERRM;
    WHEN OTHERS THEN
      ROLLBACK;
      p_log('in Others exception error is ' || SQLERRM);
      p_create_error_response('GE_OTHERS');
  END;
  PROCEDURE p_web_load_xml(appln CLOB) IS
  BEGIN
    p_log('');
    p_log('in WSAK_ADMN_APPLN.P_WEB_LOAD_XML..');
		 p_set_app_group;
    -- get rules into array
    p_get_rules_and_set_debug;
    -- load xml only if it is valid session
    IF wsak_web_authorize.f_check_valid_session(gv_log_array, gv_cookie_val) THEN
      p_proc_load_xml(appln); --, lv_clob);
    ELSE
      -- if not authorized user, send error response
      RAISE ge_unauthorized_user;
    END IF;
    -- No issues. So, send successful response
    p_create_success_response;
    -- log debug information based on rule
    IF gv_debug THEN
      p_log_to_file;
      gv_log_array.delete;
    END IF;
    -- log debug info and send error response process encounters
    -- issue.
  EXCEPTION
    WHEN ge_unauthorized_user THEN
      ROLLBACK;
      p_create_error_response('GE_UNAUTHORIZED_USER');
    WHEN ge_invalid_schema THEN
      ROLLBACK;
      p_create_error_response('GE_INVALID_SCHEMA');
      gv_error := SQLERRM;
    WHEN ge_invalid_xapp_data THEN
      ROLLBACK;
      p_create_error_response('GE_INVALID_XAPP_DATA');
    WHEN ge_invalid_etbl_data THEN
      ROLLBACK;
      p_create_error_response('GE_INVALID_ETBL_DATA');
    WHEN ge_invalid_etst_data THEN
      ROLLBACK;
      p_create_error_response('GE_INVALID_ETST_DATA');
    WHEN ge_invalid_fapc_data THEN
      ROLLBACK;
      p_create_error_response('GE_INVALID_FAPC_DATA');
    WHEN ge_nd_load_error THEN
      ROLLBACK;
      p_create_error_response('GE_ND_LOAD_ERROR');
    WHEN ge_etbl_select_error THEN
      ROLLBACK;
      p_create_error_response('GE_ETBL_SELECT_ERROR');
    WHEN OTHERS THEN
      ROLLBACK;
      p_log('in Others exception error is ' || SQLERRM);
      p_create_error_response('GE_OTHERS');

  END;
  PROCEDURE p_set_app_group IS
    lv_dad   VARCHAR2(200);

  BEGIN
		p_log('');
    p_log('in WSAK_ADMN_APPLN.p_set_app_group..');
    -- get DAD web client is using.
    lv_dad := wsak_web_authorize.f_get_dad;
		p_log(' dad is '||lv_dad);
    BEGIN
		SELECT 'FACTS_'||a.gtvsdax_internal_code
        INTO gv_group
        FROM gtvsdax a
            ,swrrule b
       WHERE a.gtvsdax_internal_code_group = 'FACTS_DAD_GROUP'
         AND b.swrrule_business_area = 'FACTS'
				 and b.swrrule_default_value =  a.gtvsdax_external_code
         AND b.swrrule_rule = a.gtvsdax_translation_code
		     AND lower(b.swrrule_value) = lower(lv_dad);
      /*SELECT 'FACTS_'||a.gtvsdax_internal_code
        INTO gv_group
        FROM gtvsdax a
            ,swrrule b
       WHERE a.gtvsdax_internal_code_group = 'FACTS_DAD_GROUP'
         AND b.swrrule_business_area = a.gtvsdax_external_code
         AND b.swrrule_rule = a.gtvsdax_translation_code
         AND lower(b.swrrule_value) = lower(lv_dad);*/
    EXCEPTION
      WHEN OTHERS THEN
				p_log(' in exception ge_invalid_dad_group '||lv_dad);
        RAISE ge_invalid_dad_group;

    END;
		begin
		SELECT a.gtvsdax_translation_code
        INTO gv_appid_prefix
        FROM gtvsdax a
       WHERE a.gtvsdax_internal_code_group = gv_group
			   AND a.gtvsdax_internal_code = 'APPID';
		exception when others then
			  p_log(' in exception ge_invalid_appid '||gv_group);
			  raise ge_invalid_appid;
		end;
	  END;

  PROCEDURE p_login
  (
    name_array  IN owa.vc_arr
   ,value_array IN owa.vc_arr
  ) IS
    lv_name_out    VARCHAR2(100) := NULL;
    lv_message_out VARCHAR2(200);
    le_user_not_authorized EXCEPTION;
  BEGIN
    p_log('');
    p_log('in WSAK_ADMN_APPLN.P_LOGIN..');
    p_set_app_group;
    -- set the rules
    p_get_rules_and_set_debug;
    -- set urls for cims
    p_set_cims_lgn_val_urls;
    p_log('before checking credentials..');
    -- if user has to be autheticated..
    IF gv_rules_array('ENABLE_ATH') = 'TRUE' THEN
      -- check if service ticket exits. If exits validate ST else redirect to CAS
      wsak_web_authorize.p_check_creditials(name_array, value_array,
                                            lv_name_out, gv_cims_lgn_url,
                                            gv_cims_val_url, gv_log_array,
                                            lv_message_out);
      p_log('');
      p_log('in WSAK_ADMN_APPLN.P_LOGIN..');
      -- if there is an ST is not valid, then raise exception (log and send error response)
      IF lv_message_out = 'ERROR' THEN
        p_log('messe_out is ERROR raising ge_service_ticket exception..');
        RAISE ge_service_ticket;
      END IF;
    ELSE
      -- no need to authenticate user
      p_log('User is not authenticated since enable is set to false');
      lv_name_out := gv_rules_array('AUTHID');
    END IF;
    p_log('after checking credentials, user logged in is ' || lv_name_out);
    p_log('autheticated user,  gv_rules_array(''LOGINID'') is ' ||
          gv_rules_array('LOGINID'));
    p_log('lv_message_out is ' || lv_message_out);
    -- If service ticket is not provided, client is redirected. If Service ticket is provided then..
    IF NOT lv_message_out = 'REDIRECTED' THEN
      -- check user is authorized to use this web service
      IF lv_name_out IS NOT NULL AND
         upper(gv_rules_array('LOGINID')) = upper(lv_name_out) THEN
        -- if authorized, set cookie and redirect to page where application info in xml can be submitted
        wsak_web_authorize.p_set_cookie_and_redirect(pv_app_group_id_i => gv_group,
                                                     pv_redirect_url_i => 'wsak_adm_appl.p_submit_xml',
                                                     pv_user_i => lv_name_out,
                                                     pv_cookie_o => gv_cookie_val,
                                                     gv_log_array_io => gv_log_array);
        p_log('');
        p_log('in WSAK_ADMN_APPLN.P_LOGIN..');

      ELSE
        -- if user requesting web service is not authorized, raise exception.
        p_log('Raising GE_UNAUTHORIZED_USER exception..');
        RAISE ge_unauthorized_user;
      END IF;
    END IF;
    -- if rules set to log then log debug info to a file.
    IF gv_debug THEN
      p_log_to_file;
      gv_log_array.delete;
    END IF;
    -- if error, then log info into file even when debug is false
    -- and send unsuccessful message back in xml format.
  EXCEPTION
    WHEN ge_service_ticket THEN
      p_create_error_response('GE_SERVICE_TICKET');
    WHEN ge_unauthorized_user THEN
      p_create_error_response('GE_UNAUTHORIZED_USER');
    WHEN ge_invalid_dad_group THEN
      p_create_error_response('GE_INVALID_DAD_GROUP');
		when ge_invalid_appid then
			 p_create_error_response('GE_INVALID_APPID');
    WHEN OTHERS THEN
      p_log('in Others exception error is ' || SQLERRM);
      p_create_error_response('GE_OTHERS');

  END;
  /**
     This procedure loads application data submitted in xml format into temporary area.
     (swtetbl, swtfapc, swtetst)
     Parameter: pv_app_io clob Application in XML format.
  */
  PROCEDURE p_proc_load_xml(pv_app_io IN CLOB) IS

    l_tst_code swtetst.swtetst_test_code%TYPE;

    lv_prev_inst VARCHAR2(200);

    lv_clob        CLOB;
    lv_etbl_rec    swtetbl%ROWTYPE;
    lv_dupapp      VARCHAR2(20);
    lv_err_ind     VARCHAR2(200);
    lv_clob_length NUMBER;
    lv_offset      NUMBER := 1;

  BEGIN
    p_log('');
    p_log('in WSAK_ADM_APPL.P_PROC_LOAD_XML ..');
    p_log('Incoming xml is ');
    IF gv_debug THEN
      lv_clob_length := dbms_lob.getlength(pv_app_io);

      IF lv_clob_length > 0 THEN
        LOOP

          p_log(REPLACE(dbms_lob.substr(pv_app_io, 200, lv_offset), chr(13)));
          lv_offset := lv_offset + 200;
          IF lv_offset > lv_clob_length THEN
            EXIT;
          END IF;
        END LOOP;
      END IF;
    END IF;

    --p_log(pv_app_io);

    -- add name space to incoming xml so that it can be validated against registered schema.
    lv_clob := '<APPLICATION xmlns="http://www.usf.edu/adm/APP.xsd">' ||
               pv_app_io || '</APPLICATION>';

    -- convert clob into xml type
    gv_xml := xmltype.createxml(lv_clob, 'http://www.usf.edu/adm/APP.xsd');

    -- validate against schema
    BEGIN
      gv_xml.schemavalidate();
    EXCEPTION
      WHEN OTHERS THEN
        -- if xml is not as per schema, log and send unsuccuessful back to user(in xml format)
        p_log('Schema validation error');
        p_log('Error is ' || SQLERRM);
        gv_error := SQLERRM;
        RAISE ge_invalid_schema;
    END;
    -- create xml type with original xml
    gv_xml := xmltype.createxml(pv_app_io);
    -- get conf number and set doc id
    gv_conf_numb := gv_xml.extract('ADMISSION_REQ/@Track').getstringval();
    p_log('conf number is ' || gv_conf_numb);
    gv_docid := REPLACE(wf_get_facts_app_name_db, 'TA', gv_appid_prefix);
    p_log('inserting xapp');
    p_log('doc id is ' || gv_docid);
    -- insert xml as clob into xapp
    BEGIN
      INSERT INTO swbxapp
        (swbxapp_document_id
        ,swbxapp_xml_application)
      VALUES
        (gv_docid
        ,pv_app_io);
    EXCEPTION
      WHEN OTHERS THEN
        p_log(SQLERRM);
        gv_error := SQLERRM;
        -- raise if xml could not be saved into xapp
        RAISE ge_invalid_xapp_data;
    END;
    p_log('after insert into xapp ');
    p_log('inserting etbl');
    -- insert app data into etbl using xsl
    BEGIN
      p_table_insert('swtetbl_ins.xsl', 'SWTETBL');
    EXCEPTION
      WHEN OTHERS THEN
        -- handle error if data could not be saved into etbl.
        p_log(SQLERRM);
        gv_error := SQLERRM;
        RAISE ge_invalid_etbl_data;
    END;
    p_log('after insert into etbl');
    -- load prev inst info if available.

    IF gv_xml.existsnode('ADMISSION_REQ/PREV_INST[position()=1]/INST_NAME/text()') = 1 THEN
      lv_prev_inst := gv_xml.extract('ADMISSION_REQ/PREV_INST[position()=1]/INST_NAME/text()')
                      .getstringval();
    END IF;
    IF lv_prev_inst IS NOT NULL THEN
      p_init;
      p_log('inserting fapc');
      BEGIN
        p_table_insert('swtfapc_ins.xsl', 'SWTFAPC');
      EXCEPTION
        WHEN OTHERS THEN
          -- if prev inst could not be saved, handle error.
          p_log(SQLERRM);
          gv_error := SQLERRM;
          RAISE ge_invalid_fapc_data;
      END;
      p_log('after insert into fapc');
    END IF;
    p_log('before updating etbl with doc id ' || gv_docid);
    UPDATE swtetbl a
       SET a.swtetbl_xml_document_name = gv_docid
          ,a.swtetbl_user              = USER
          ,a.swtetbl_source            = USER
     WHERE a.swtetbl_conf_numb = gv_conf_numb;
    p_log('after etbl update');
    -- test scores

    IF gv_xml.existsnode('//SSN/text()') = 1 THEN
      gv_ssn := gv_xml.extract('//SSN/text()').getstringval();
    END IF;
    p_log('SSN is ' || substr(gv_ssn, 1, 4) || 'XXXXX');
    IF gv_xml.existsnode('ADMISSION_REQ/ADM_TEST[position()=1]/TEST_TYPE_CD/text()') = 1 THEN
      l_tst_code := gv_xml.extract('ADMISSION_REQ/ADM_TEST[position()=1]/TEST_TYPE_CD/text()')
                    .getstringval();
    END IF;
    IF l_tst_code IS NOT NULL THEN
      p_init;
      p_log('inserting test scores');
      p_log('tst_code is ' || l_tst_code);
      BEGIN
        p_table_insert('swtetst_ins.xsl', 'SWTETST');
      EXCEPTION
        WHEN OTHERS THEN
          -- if xml is not as per schema, log and send unsuccuessful back to user(in xml format)
          p_log(SQLERRM);
          gv_error := SQLERRM;
          RAISE ge_invalid_etst_data;
      END;
      p_log('after test scores insert');
    END IF;

    p_log('before selecting etbl record based on docid ' || gv_docid);
    BEGIN
      SELECT *
        INTO lv_etbl_rec
        FROM swtetbl a
       WHERE a.swtetbl_xml_document_name = gv_docid;
    EXCEPTION
      WHEN OTHERS THEN
        -- if xml is not as per schema, log and send unsuccuessful back to user(in xml format)
        p_log('raising ge_etbl_select_error');
        gv_error := SQLERRM;
        RAISE ge_etbl_select_error;
    END;
    p_log('after etbl record fetched');
    p_log('checking if application is ND');
    IF lv_etbl_rec.swtetbl_grad_appl_ind = 'N' THEN
      p_log('application is ND. Loading application into Banner');
      BEGIN
        wsaketbl.wp_load_non_deg_appln_db(p_appl_id_in => gv_docid,
                                          p_err_out => lv_dupapp,
                                          p_err_ind => lv_err_ind);
      EXCEPTION
        WHEN OTHERS THEN
          -- if xml is not as per schema, log and send unsuccuessful back to user(in xml format)
          p_log(SQLERRM);
          gv_error := SQLERRM;
          RAISE ge_nd_load_error;
      END;
      -- If needed, check for dupapp lv_dupapp = 'DUPAPP' should be done here.
    END IF;

    p_log('before commit');
    COMMIT;

  END;

  /*This fumction retrieves the campus codes*/
  FUNCTION f_get_campus(pv_camp_id VARCHAR2) RETURN VARCHAR2 IS
    lv_campus   sorxref.sorxref_banner_value%TYPE := NULL;
    lc_ref_code sorxref.sorxref_xlbl_code%TYPE := 'STVCAMP';
    lc_ref_qlfr sorxref.sorxref_edi_qlfr%TYPE := 'FACTS';

  BEGIN
    IF pv_camp_id IN ('T', 'P', 'L', 'S') THEN
      RETURN pv_camp_id;
    END IF;
    SELECT a.sorxref_banner_value
      INTO lv_campus
      FROM sorxref a
     WHERE a.sorxref_xlbl_code = lc_ref_code
       AND a.sorxref_edi_qlfr = lc_ref_qlfr
       AND a.sorxref_edi_value = pv_camp_id;
    RETURN lv_campus;
  END f_get_campus;

  /*Processing vdocs  and creating error reports */
  PROCEDURE p_edit_vz_doc
  (
    pv_file_name IN VARCHAR2
   ,pv_dir       IN VARCHAR2
   ,pv_message   OUT VARCHAR2
  ) IS

    --Local Variables
    lv_valid_nt rule_nt := rule_nt();
    lv_vdoc_nt  string_nt := string_nt();
    lv_type_nt  string_nt := string_nt();
    lv_vpop_nt  string_nt := string_nt();
    lc_tab_name swrrule.swrrule_rule%TYPE := 'TABLENAME';
    lc_bus_area swrrule.swrrule_business_area%TYPE := 'VZBDMS';
    lv_campus   sorxref.sorxref_banner_value%TYPE;
    lv_err_ind  saturn.swrvdoc.swrvdoc_error_ind%TYPE := 'N';
    lv_term     VARCHAR2(25) := 'TERM';
    lv_bdms_ind VARCHAR2(35) := NULL;
    lv_meta_ind VARCHAR2(35) := NULL;
    lv_meta_val VARCHAR2(35) := NULL;
    lv_cursor   VARCHAR2(1000) := NULL;
    lv_bdms_tbl VARCHAR2(25) := NULL;
    lv_err_desc VARCHAR2(250) := NULL;
    lv_file     utl_file.file_type;
    lv_tab CONSTANT VARCHAR2(1) := chr(9);
    lc_ref_code sorxref.sorxref_xlbl_code%TYPE := 'STVCAMP';
    lc_ref_qlfr sorxref.sorxref_edi_qlfr%TYPE := 'FACTS';
    gv_err_desc swrvdoc.swrvdoc_error_desc%TYPE := NULL;
    gv_doctype  VARCHAR2(100);
 

    ----------------------CURSOR DEFINITIONS---------------------------------------
    /*This cursor loops through all the invalid vzids*/
    CURSOR c_invalid_vzids IS
      SELECT DISTINCT (v.swrvdoc_conf_numb) vzid
        FROM swrvdoc v
       WHERE v.swrvdoc_conf_numb NOT IN
             (SELECT s.swbxapp_conf_numb
                FROM swbxapp s
               WHERE s.swbxapp_conf_numb = v.swrvdoc_conf_numb);
               
  /*Version G.3 - This cursor loops through all the applications that are
    not yet loaded into Banner. This check is required since we'd image
    the documents for only successfully loaded applications into Banner. */
    CURSOR c_appl_not_loaded IS
      SELECT DISTINCT (v.swrvdoc_conf_numb) conf_numb
        FROM swrvdoc v, swbxapp s
       WHERE v.swrvdoc_conf_numb = s.swbxapp_conf_numb
         AND s.swbxapp_appl_no IS NULL;

    /* This cursor loops throught the selected population */
    CURSOR c_valid_term IS
      SELECT s.swbxapp_appl_term term
            ,s.swbxapp_conf_numb vzid
        FROM swbxapp s
            ,swrvdoc v
       WHERE s.swbxapp_conf_numb = v.swrvdoc_conf_numb
         AND v.swrvdoc_conf_numb IN
             (SELECT column_value FROM TABLE(lv_vpop_nt))
         AND v.swrvdoc_vz_doc_type = gv_doctype;

    /*This cursor loops through all the distinct valid rules*/
    CURSOR c_vdoc_rules IS
      SELECT DISTINCT (default_value) default_value
        FROM TABLE(lv_valid_nt);

    /* This cursor loads all the  valid rules that are IN SWRRULE */
    CURSOR c_valid_rules IS
      SELECT * FROM TABLE(lv_valid_nt);

    /* This cursor loads all the default values that are NOT in SWRRULE (like GR:T:RESUME_1) */
    CURSOR c_invalid_rules IS
      SELECT column_value dflt
        FROM TABLE(lv_vdoc_nt)
       WHERE column_value NOT IN
             (SELECT default_value FROM TABLE(lv_valid_nt));

    /* This cursor loads all the rules that are NOT in SWRRULE (like ADMREQ/DOCTYPE/ROUTINGSTATUS/BDMSAPP for a given default VAlue like GR:T:RESUME*/
    CURSOR c_invalid_type(p_dftl_val VARCHAR2) IS
      SELECT column_value rule
        FROM TABLE(lv_type_nt)
       WHERE column_value NOT IN
             (SELECT rule
                FROM TABLE(lv_valid_nt)
               WHERE default_value = p_dftl_val);

    /* This cursor loads all the OTGMGR table names that are IN SWRRULE */
    CURSOR c_table_rules(p_type VARCHAR2) IS
      SELECT s.swrrule_value
        FROM swrrule s
       WHERE s.swrrule_default_value = p_type
         AND s.swrrule_business_area = lc_bus_area
         AND s.swrrule_rule = lc_tab_name;

    --Cursor Variables
    invalid_rules_rec c_invalid_rules%ROWTYPE;
    valid_rules_rec   c_valid_rules%ROWTYPE;
    invalid_type_rec  c_invalid_type%ROWTYPE;
    vdoc_rules_rec    c_vdoc_rules%ROWTYPE;
    invalid_vzids_rec c_invalid_vzids%ROWTYPE;

    ----------------------LOCAL PROCEDURES---------------------------------------
    /*This local procedure creates the error report*/
    PROCEDURE p_error(p_val VARCHAR2) IS

      lv_err_val    VARCHAR2(250) := NULL;
      lv_err        VARCHAR2(250) := NULL;
      lv_filename   VARCHAR2(100) := NULL;
      lv_exists     BOOLEAN;
      lv_length     NUMBER;
      lv_block_size NUMBER;
      lv_cnt        NUMBER := 0;
      --This cursor collects error report data
      CURSOR c_err_report IS
        SELECT p.swbxapp_campus    campus
              ,p.swbxapp_levl_code lvl
              ,p.swbxapp_id        id
          FROM swbxapp p
              ,swrvdoc v
         WHERE p.swbxapp_conf_numb = v.swrvdoc_conf_numb
           AND v.swrvdoc_conf_numb IN
               (SELECT column_value FROM TABLE(lv_vpop_nt))
           AND v.swrvdoc_vz_doc_type = gv_doctype
         ORDER BY campus
                 ,lvl;

      err_report_rec c_err_report%ROWTYPE;
    BEGIN

      --lv_filename := pv_file_name|| '_' ||to_char(SYSDATE, 'ddmmyyyyhhmiss') ||'.txt';
      lv_filename := pv_file_name;
      BEGIN
        utl_file.fclose_all;
        utl_file.fgetattr(location => pv_dir, filename => pv_file_name,
                          fexists => lv_exists, file_length => lv_length,
                          block_size => lv_block_size);
      EXCEPTION
        WHEN OTHERS THEN
          lv_exists := FALSE;
      END;
      IF lv_exists THEN

        lv_file := utl_file.fopen(location => pv_dir,
                                  filename => lv_filename, open_mode => 'a');

      ELSE
        lv_file := utl_file.fopen(location => pv_dir,
                                  filename => lv_filename, open_mode => 'w');
        lv_err  := '==========APPLICATIONS BDMS ERROR REPORT==========================';
        utl_file.put_line(lv_file, lv_err);
        utl_file.new_line(lv_file);
        utl_file.put_line(lv_file, 'REPORT DATE:' || SYSDATE);
        utl_file.new_line(lv_file);
        lv_err := 'CAMPUS' || lv_tab || 'LEVEL' || lv_tab || 'U#' || lv_tab ||
                  lv_tab || 'ERROR TYPE';
        utl_file.put_line(lv_file, lv_err);
        lv_err := '=================================================================== ';
        utl_file.put_line(lv_file, lv_err);
      END IF;

      lv_err_val := p_val;
      SELECT COUNT(*) INTO lv_cnt FROM TABLE(lv_vpop_nt);
      IF lv_cnt = 0 THEN
        lv_err := '--' || lv_tab || '--' || lv_tab || '---------' || lv_tab ||
                  lv_err_val;
        utl_file.put_line(lv_file, lv_err);
        utl_file.new_line(lv_file);
      ELSE
        FOR err_report_rec IN c_err_report()
        LOOP
          lv_err := f_get_campus(err_report_rec.campus) || lv_tab ||
                    err_report_rec.lvl || lv_tab || err_report_rec.id ||
                    lv_tab || lv_err_val;
          utl_file.put_line(lv_file, lv_err);
          utl_file.new_line(lv_file);

        END LOOP;
      END IF;
      lv_err := '---------------------------------------------------------------';
      utl_file.put_line(lv_file, lv_err);
      utl_file.fclose(lv_file);
    END;

    /* This local procedure loads all of the possible default_rules into a nested table for later use (ADMREQ/DOCTYPE/ROUTINGSTATUS/BDMSAPP*/

    PROCEDURE lp_load_types(p_tbl_io IN OUT string_nt) IS
    BEGIN
      pv_message := 'In lp_load_types';
      SELECT DISTINCT (a.swrrule_rule) BULK COLLECT
        INTO p_tbl_io
        FROM swrrule a
       WHERE a.swrrule_business_area = lc_bus_area
         AND a.swrrule_rule != lc_tab_name;
    END lp_load_types;

    /* This local procedure loads the distinct default values in swrvdoc into a nested table for later use 'GR:T:RESUME' */
    PROCEDURE lp_load_vdoc_val(p_tbl_io IN OUT string_nt) IS
    BEGIN
      pv_message := 'In lp_load_vdoc_val';
      SELECT DISTINCT (p.swbxapp_levl_code || ':' ||
                      f_get_campus(p.swbxapp_campus) || ':' ||
                      v.swrvdoc_vz_doc_type) BULK COLLECT
        INTO p_tbl_io
        FROM swbxapp p
            ,swrvdoc v
       WHERE p.swbxapp_conf_numb = v.swrvdoc_conf_numb;
    END lp_load_vdoc_val;

    /* This local procedure loads all the valid rules ,i.e all the default values in swrvdoc and also has an entry in swrrule*/
    PROCEDURE lp_valid_rules(p_tbl_io IN OUT rule_nt) IS
    BEGIN
      pv_message := 'In lp_valid_rules';
      SELECT rule_object(s.swrrule_default_value, s.swrrule_rule,
                         s.swrrule_value) BULK COLLECT
        INTO p_tbl_io
        FROM swrrule s
       WHERE s.swrrule_business_area = lc_bus_area
         AND s.swrrule_rule IN (SELECT column_value FROM TABLE(lv_type_nt))
         AND s.swrrule_default_value IN
             (SELECT upper(column_value) FROM TABLE(lv_vdoc_nt))
       ORDER BY s.swrrule_default_value;
    END lp_valid_rules;

    /* This local procedure loads the vdoc population per default value in a nested table  */
    PROCEDURE lp_load_pop
    (
      p_dflt   IN VARCHAR2
     ,p_tbl_io IN OUT string_nt
    ) IS
      lv_level     VARCHAR2(25);
      lv_campus    VARCHAR2(5);
      lv_campus_id VARCHAR2(5);
    BEGIN
      pv_message   := 'In lp_load_pop: ' || p_dflt;
      gv_doctype   := substr(p_dflt, instr(p_dflt, ':', 1, 2) + 1,
                             length(p_dflt));
      lv_level     := substr(p_dflt, 1, instr(p_dflt, ':', 1, 1) - 1);
      lv_campus_id := substr(p_dflt, instr(p_dflt, ':', 1, 1) + 1, 1);

      SELECT a.sorxref_edi_value
        INTO lv_campus
        FROM sorxref a
       WHERE a.sorxref_xlbl_code = lc_ref_code
         AND a.sorxref_edi_qlfr = lc_ref_qlfr
         AND a.sorxref_banner_value = lv_campus_id;

      SELECT v.swrvdoc_conf_numb BULK COLLECT
        INTO p_tbl_io
        FROM swbxapp p
            ,swrvdoc v
       WHERE p.swbxapp_levl_code = lv_level
         AND p.swbxapp_campus = lv_campus
         AND v.swrvdoc_vz_doc_type = gv_doctype
         AND v.swrvdoc_conf_numb = p.swbxapp_conf_numb
       ORDER BY p.swbxapp_campus
               ,p.swbxapp_levl_code;
    END lp_load_pop;

    /*Procedureto check if bdms values retrieved actually exist in bdms tables otgmgr and then updates swrvdoc respectively     */
    PROCEDURE p_chk_meta_data
    (
      pv_meta_tbl  IN VARCHAR2
     ,pv_meta_val  IN VARCHAR2
     ,pv_meta_rule IN VARCHAR2
     ,pv_default   IN VARCHAR2
    ) IS

      lv_bdms_val otgmgr.ul509_12.item%TYPE;
      lv_bdms_app swrrule.swrrule_rule%TYPE := 'BDMSAPP';
      lv_bdms_col VARCHAR2(1);

    BEGIN
      pv_message := 'In p_chk_meta_data: ' || pv_meta_rule || ',' ||
                    pv_meta_val || ',' || pv_meta_tbl || pv_default;

      --check if it's a BDMSAPP value
      IF pv_meta_rule = lv_bdms_app THEN
        lv_cursor := ' SELECT appname FROM ' || pv_meta_tbl ||
                     ' WHERE appname = :1';
      ELSE
        lv_cursor := 'SELECT item FROM ' || pv_meta_tbl ||
                     ' WHERE item = :1';
      END IF;

      BEGIN
        EXECUTE IMMEDIATE (lv_cursor)
          INTO lv_bdms_val
          USING pv_meta_val;
        lv_err_ind  := 'N';
        lv_bdms_ind := 'swrvdoc_' || pv_meta_rule || '_ind';
        lv_meta_ind := 'swrvdoc_meta_' || pv_meta_rule || '_ind';
        lv_meta_val := 'swrvdoc_' || pv_meta_rule;

        IF pv_meta_rule = lv_term THEN
          lv_cursor := 'UPDATE swrvdoc s SET ' || lv_meta_ind || '=:1
                             ,s.swrvdoc_activity_date=sysdate
                             ,s.swrvdoc_error_ind=:2
                             ,s.swrvdoc_error_desc=NULL
                              WHERE s.swrvdoc_conf_numb IN  (SELECT column_value FROM  TABLE(:3))
                              AND s.swrvdoc_vz_doc_type =:4';

          EXECUTE IMMEDIATE (lv_cursor)
            USING lv_err_ind, lv_err_ind, lv_vpop_nt, gv_doctype;
        ELSE
          lv_cursor := 'UPDATE swrvdoc s SET ' || lv_bdms_ind || '=:1,' ||
                       lv_meta_ind || '=:2
                             ,' || lv_meta_val || '=:3
                             ,s.swrvdoc_activity_date=sysdate
                             ,s.swrvdoc_error_ind=:4
                             ,s.swrvdoc_error_desc=NULL
                              WHERE s.swrvdoc_conf_numb IN  (SELECT column_value FROM  TABLE(:5))
                              AND s.swrvdoc_vz_doc_type =:6';

          EXECUTE IMMEDIATE (lv_cursor)
            USING lv_err_ind, lv_err_ind, pv_meta_val, lv_err_ind, lv_vpop_nt, gv_doctype;
        END IF;
        COMMIT;

      EXCEPTION
        WHEN no_data_found THEN

          pv_message := 'In p_chk_meta_data Exception: ';
          IF pv_meta_val = 'NONE' THEN
            lv_err_ind := 'N';
          ELSE
            lv_err_desc := 'Invalid meta data for ' || pv_meta_rule ||
                           ': "' || pv_meta_val || '" not found for: ' ||
                           pv_default;
            gv_err_desc := gv_err_desc || '***' || lv_err_desc;
            p_error(lv_err_desc);
            lv_err_ind := 'Y';
          END IF;

          lv_bdms_col := 'N'; --indicates that the rule value exist
          lv_bdms_ind := 'swrvdoc_' || pv_meta_rule || '_ind';
          lv_meta_ind := 'swrvdoc_meta_' || pv_meta_rule || '_ind';
          lv_meta_val := 'swrvdoc_' || pv_meta_rule;

          IF pv_meta_rule = lv_term THEN

            lv_cursor := 'UPDATE swrvdoc s SET ' || lv_meta_ind || '=:1
                         ,s.swrvdoc_error_desc=:2
                         WHERE s.swrvdoc_conf_numb IN  (SELECT column_value FROM  TABLE(:3))
                         AND s.swrvdoc_vz_doc_type =:4';

            EXECUTE IMMEDIATE (lv_cursor)
              USING lv_err_ind, gv_err_desc, lv_vpop_nt, gv_doctype;
          ELSE
            lv_cursor := 'UPDATE swrvdoc s SET  ' || lv_bdms_ind || '=:1
                         ,' || lv_meta_ind || '=:2
                         ,' || lv_meta_val ||
                         '=NULL
                         ,s.swrvdoc_error_desc=:3
                         WHERE s.swrvdoc_conf_numb IN  (SELECT column_value FROM  TABLE(:4))
                         AND s.swrvdoc_vz_doc_type =:5';

            EXECUTE IMMEDIATE (lv_cursor)
              USING lv_bdms_col, lv_err_ind, gv_err_desc, lv_vpop_nt, gv_doctype;

          END IF;
          COMMIT;
          pv_message := 'In p_chk_meta_data:Records Updated ';
      END;
    END;
    ---------------------------------Begin proc ---------------------------------------------------------------------------
  BEGIN
    pv_message := 'In p_edit_vz_doc ';
    /*make sure that the nested tables are empty to start*/
    lv_type_nt.delete;
    lv_vdoc_nt.delete;
    lv_valid_nt.delete;
    lv_vpop_nt.delete;

    lp_load_types(lv_type_nt);
    lp_load_vdoc_val(lv_vdoc_nt);
    lp_valid_rules(lv_valid_nt);

    --Validate swrvdoc VZIDS
    FOR invalid_vzids_rec IN c_invalid_vzids
    LOOP
      lv_err_ind  := 'Y';
      lv_err_desc := invalid_vzids_rec.vzid ||
                     ' does not exist in SWBXAPP TABLE';

      UPDATE swrvdoc v
         SET v.swrvdoc_error_ind  = lv_err_ind
            ,v.swrvdoc_error_desc = lv_err_desc
       WHERE v.swrvdoc_conf_numb = invalid_vzids_rec.vzid;

      p_error(lv_err_desc);

    END LOOP;

    --Write all missing rules in log file
    FOR invalid_rules_rec IN c_invalid_rules
    LOOP
      pv_message := 'In p_edit_vz_doc :invalid_rules_rec' ||
                    invalid_rules_rec.dflt;
      BEGIN

        lv_vpop_nt.delete;
        lp_load_pop(invalid_rules_rec.dflt, lv_vpop_nt);

        lv_err_ind := 'Y';
        --if doctype was not passed in the file name then the values is defaulted to X
        IF gv_doctype = 'X' THEN
          lv_err_desc := 'Invalid VZ File Type: ' || invalid_rules_rec.dflt;
        ELSE
          lv_err_desc := 'Rule does not exist for VZ file type: ' ||
                         invalid_rules_rec.dflt;
        END IF;

        lv_cursor := '  UPDATE swrvdoc s SET
                            s.swrvdoc_bdmsapp_ind=:1
                           ,s.swrvdoc_doctype_ind=:2
                           ,s.swrvdoc_admreq_ind=:3
                           ,s.swrvdoc_routingstatus_ind=:4
                           ,s.swrvdoc_error_desc=:5
                           ,s.swrvdoc_activity_date=sysdate
                           WHERE s.swrvdoc_conf_numb IN (SELECT column_value FROM  TABLE(:6))
                           AND s.swrvdoc_vz_doc_type =:7';

        EXECUTE IMMEDIATE (lv_cursor)
          USING lv_err_ind, lv_err_ind, lv_err_ind, lv_err_ind, lv_err_desc, lv_vpop_nt, gv_doctype;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          pv_message := 'In p_edit_vz_doc :invalid_rules_rec :EXCEPTION ' ||
                        invalid_rules_rec.dflt;

      END;
      p_error(lv_err_desc);
    END LOOP;

    -- Checking for missings rule values for each valid rule
    -- and log in log file (like if we are missing doctype or ADMREQ from GR:T:RESUME)

    FOR vdoc_rules_rec IN c_vdoc_rules
    LOOP
      pv_message  := 'In p_edit_vz_doc : vdoc_rules_rec: ' ||
                     vdoc_rules_rec.default_value;
      gv_err_desc := NULL; --reset error desc for each iteration
      --Delete nested table for each iteration
      lv_vpop_nt.delete;
      lp_load_pop(vdoc_rules_rec.default_value, lv_vpop_nt);

      -- Validate Term
      OPEN c_table_rules(lv_term);
      FETCH c_table_rules
        INTO lv_bdms_tbl;
      CLOSE c_table_rules;
      pv_message := 'Checking Term ';

      FOR valid_term_rec IN c_valid_term
      LOOP
        p_chk_meta_data(lv_bdms_tbl, valid_term_rec.term, lv_term, lv_term);
      END LOOP;
      -- Validate Types
      FOR invalid_type_rec IN c_invalid_type(vdoc_rules_rec.default_value)
      LOOP
        BEGIN
          pv_message := 'In p_edit_vz_doc :invalid_type_rec';

          lv_err_desc := 'Invalid rule value: ' || invalid_type_rec.rule ||
                         ' For: ' || vdoc_rules_rec.default_value;
          lv_err_ind  := 'Y';
          gv_err_desc := gv_err_desc || '***' || lv_err_desc;
          lv_bdms_ind := 'swrvdoc_' || invalid_type_rec.rule || '_ind';
          lv_meta_val := 'swrvdoc_' || invalid_type_rec.rule;

          lv_cursor := 'UPDATE swrvdoc s SET
                                  ' || lv_bdms_ind || '=:1
                                 ,' || lv_meta_val ||
                       '= NULL
                                 ,s.swrvdoc_error_desc =:2
                                 ,s.swrvdoc_activity_date=sysdate
                                 WHERE s.swrvdoc_conf_numb IN (SELECT column_value FROM  TABLE(:3))
                                 AND s.swrvdoc_vz_doc_type =:4';

          EXECUTE IMMEDIATE (lv_cursor)
            USING lv_err_ind, gv_err_desc, lv_vpop_nt, gv_doctype;
          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            pv_message := 'In p_edit_vz_doc :invalid_type_rec :EXCEPTION';
        END;
        p_error(lv_err_desc);
      END LOOP;
    END LOOP;

    --Start Processing all the valid rules in swrvdoc
    FOR valid_rules_rec IN c_valid_rules
    LOOP
      pv_message := 'In p_edit_vz_doc :valid_rules_rec: ' ||
                    valid_rules_rec.default_value;
      --Delete nested table for each iteration
      lv_vpop_nt.delete;
      lp_load_pop(valid_rules_rec.default_value, lv_vpop_nt);

      --Validate META DATA
      OPEN c_table_rules(valid_rules_rec.rule);
      FETCH c_table_rules
        INTO lv_bdms_tbl;
      CLOSE c_table_rules;
      p_chk_meta_data(lv_bdms_tbl, valid_rules_rec.rule_value,
                      valid_rules_rec.rule, valid_rules_rec.default_value);

    END LOOP;
    
  /*Version G.3 - Update swrvdoc when there's a Null Application Number in 
    swbxapp at the end of p_edit_vz_doc so swrvdoc_error_ind won't reset
    to N and swrvdoc_error_desc won't be NULL when the next execution 
    of a record loops thru procedure p_chk_meta_data.*/
    FOR appl_not_loaded_rec IN c_appl_not_loaded
    LOOP
      lv_err_ind  := 'Y';
      lv_err_desc := appl_not_loaded_rec.conf_numb ||
                     ' appl not yet loaded into Banner';

      UPDATE swrvdoc v
         SET v.swrvdoc_error_ind  = lv_err_ind
            ,v.swrvdoc_error_desc = v.swrvdoc_error_desc||' '||lv_err_desc
       WHERE v.swrvdoc_conf_numb = appl_not_loaded_rec.conf_numb;

      p_error(lv_err_desc);

    END LOOP;    
    --

    --Update error indicators..
    UPDATE swrvdoc s
       SET s.swrvdoc_error_ind     = 'Y'
          ,s.swrvdoc_activity_date = SYSDATE
     WHERE (s.swrvdoc_bdmsapp_ind = 'Y' OR s.swrvdoc_doctype_ind = 'Y' OR
           s.swrvdoc_admreq_ind = 'Y' OR s.swrvdoc_routingstatus_ind = 'Y' OR
           s.swrvdoc_meta_term_ind = 'Y' OR
           s.swrvdoc_meta_bdmsapp_ind = 'Y' OR
           s.swrvdoc_meta_doctype_ind = 'Y' OR
           s.swrvdoc_meta_admreq_ind = 'Y' OR
           s.swrvdoc_meta_routingstatus_ind = 'Y');
    COMMIT;

    pv_message := 'Records Updated ';

    utl_file.fclose(lv_file);

  END;

  /*This procedure reads the success file recieved from VZ and saves the document names in SWRVDOC*/
  PROCEDURE p_process_vz_doc
  (
    pv_file_name   IN VARCHAR2
   ,pv_err_file    IN VARCHAR2
   ,pv_dir         IN VARCHAR2
   ,pv_message_o   OUT VARCHAR2
  ) IS

    lv_fname      swrvdoc.swrvdoc_file_name%TYPE;
    lv_vz_id      swrvdoc.swrvdoc_conf_numb%TYPE;
    lv_doctype    swrvdoc.swrvdoc_vz_doc_type%TYPE;
    lv_exists     BOOLEAN;
    lv_length     NUMBER;
    lv_block_size NUMBER;
    lv_line       VARCHAR2(4000);
    lv_file       utl_file.file_type;
    lv_last_line  VARCHAR2(250);
    lv_last_val   VARCHAR2(250);
    lv_success    VARCHAR2(250) := '0';
    lv_error      VARCHAR2(250);
    lv_cnt        NUMBER := 0;
    lv_records    NUMBER := 0;
    lv_docid_prefix     swrvdoc.swrvdoc_conf_numb%TYPE;

  BEGIN
    -- Check if file exist before processing
    BEGIN
      utl_file.fgetattr(location => pv_dir, filename => pv_file_name,
                        fexists => lv_exists, file_length => lv_length,
                        block_size => lv_block_size);

    EXCEPTION
      WHEN OTHERS THEN
        lv_exists := FALSE;
    END;
    --Once file is found then get values and insert into swrvdoc
    IF lv_exists THEN
      pv_message_o := 'File :' || pv_file_name || ' FOUND';
      lv_file      := utl_file.fopen(location => pv_dir,
                                     filename => pv_file_name,
                                     open_mode => 'r');
      LOOP
        BEGIN
          utl_file.get_line(lv_file, lv_line);
          
          IF lv_line IS NOT NULL THEN
            
          /*Version G.2 - Check for the document ID prefix of VZ or BA*/
            IF SUBSTR(lv_line, 1, 7) = 'SUCCESS' AND SUBSTR(lv_line, 32, 2) = 'VZ' THEN
                lv_docid_prefix := 'VZ';  
            ELSE
                lv_docid_prefix := SUBSTR(lv_line, 1, 2); --'BA'
            END IF;

            -- Get file statistics sent...

            pv_message_o := 'Checking if this is the last line in file.';
            lv_last_line := substr(lv_line, instr(lv_line, ' ', 1, 1) + 1,
                                   instr(lv_line, ' ', 1, 2) -
                                    instr(lv_line, ' ', 1, 1));
            lv_last_val  := substr(lv_line, instr(lv_line, '(', 1, 1) + 1,
                                   (instr(lv_line, ')', 1, 1) -
                                    instr(lv_line, '(', 1, 1)) - 1);                                    

            CASE lv_last_line
              WHEN 'SUCCESS' THEN
                lv_success := lv_last_val;
              WHEN 'ERROR' THEN
                lv_error := lv_last_val;
              ELSE
                pv_message_o := 'NOT END OF LINE';
            END CASE;
                        
         IF lv_docid_prefix = gv_appid_prefix THEN
            -- substring file entry to get filename, Vz-Id and Document Type
            lv_fname   := substr(lv_line, (instr(lv_line, '\VZ', 1, 1) + 1),
                                 (instr(lv_line, ' ', 1, 2) -
                                  instr(lv_line, '\VZ', 1, 1)));
            lv_vz_id   := substr(lv_fname, 1, instr(lv_fname, '_', 1, 1) - 1);
            lv_doctype := nvl(upper(substr(lv_fname,
                                           instr(lv_fname, '_', 1, 1) + 1,
                                           (instr(lv_fname, '_', 1, 2) -
                                            instr(lv_fname, '_', 1, 1)) - 1)),
                              'X');

         ELSE --If Not 'VZ' then 'BA'...
            /*Version G.2 - substring file entry to get filename, BA-Id and Document Type*/
            lv_fname   := lv_line;
            lv_vz_id   := substr(lv_fname, 1, instr(lv_fname, '_', 1, 1) - 1);
            lv_doctype := nvl(upper(substr(lv_fname,
                                           instr(lv_fname, '_', 1, 1) + 1,
                                           (instr(lv_fname, '_', 1, 2) -
                                            instr(lv_fname, '_', 1, 1)) - 1)),
                              'X');
                              
          END IF; 
           
            --insert values into swrvdoc
            IF lv_vz_id IS NOT NULL THEN
              SELECT COUNT(*)
                INTO lv_records
                FROM swrvdoc v
               WHERE v.swrvdoc_file_name = lv_fname;
              IF lv_records = 0 THEN
                BEGIN
                  INSERT INTO swrvdoc
                    (swrvdoc_file_name
                    ,swrvdoc_conf_numb
                    ,swrvdoc_vz_doc_type
                    ,swrvdoc_activity_date
                    ,swrvdoc_received_date)
                  VALUES
                    (lv_fname
                    ,lv_vz_id
                    ,lv_doctype
                    ,SYSDATE
                    ,SYSDATE);

                EXCEPTION
                  WHEN OTHERS THEN
                    pv_message_o := 'UNABLE TO INSERT  :' || lv_line;
                    EXIT;
                END;
                --Save number of records committed.
                lv_cnt := lv_cnt + 1;
              END IF; --IF lv_records =0 THEN
            END IF; -- IF lv_doctype IS NOT NULL THEN
          END IF; --IF lv_line IS NOT NULL THEN

        EXCEPTION
          WHEN no_data_found THEN
            pv_message_o := 'LINE :' || lv_line || '  NO DATA FOUND';
            EXIT;
        END;

      END LOOP;
      COMMIT;
      pv_message_o := 'Records Committed :(' || lv_cnt ||
                      '),,Records Recieved:(' || lv_success || ')';
    END IF;
    p_edit_vz_doc(pv_file_name => pv_err_file, pv_dir => pv_dir,
                  pv_message => pv_message_o);
  END p_process_vz_doc;

  FUNCTION f_create_file
  (
    pv_dir_i          VARCHAR2
   ,pv_process_name_i VARCHAR2
  ) RETURN utl_file.file_type IS
  BEGIN
    RETURN utl_file.fopen(location => pv_dir_i,
                          filename => pv_process_name_i || '_' ||
                                       to_char(SYSDATE, 'ddmmyyyyhhmiss') ||
                                       '.txt', open_mode => 'w');
  END;


/*This procedure is renamed from p_eligible_vzid to create eligible ID file
  based on the prefix of VZ or BA that passed in by Applications Manager job
  to distinguish if the process is running for VisualZen or Bisk.*/
 PROCEDURE p_create_eligibleid_file
  (
    pv_dir         IN VARCHAR2
   ,pv_elig_file   IN VARCHAR2
   ,pv_docid_prefix IN VARCHAR2
  ) IS

    lv_dir           VARCHAR2(25) := pv_dir;
    lv_file          utl_file.file_type;
    lv_file_name     VARCHAR2(30);
    lv_docid_prefix  VARCHAR2(25) := pv_docid_prefix||'%';
    lv_rec_exists    VARCHAR2(1) := 'N';


    CURSOR c_population IS
      SELECT s.swbxapp_conf_numb
        FROM swbxapp s
       WHERE s.swbxapp_doc_process_ind = 'P'         
         AND substr(s.swbxapp_document_id, 1, 2) LIKE lv_docid_prefix;


    c_pop_rec c_population%ROWTYPE;

  BEGIN

    lv_file_name := pv_elig_file;
    lv_file      := utl_file.fopen(location => lv_dir,
                                   filename => lv_file_name, open_mode => 'w');
                                      
    FOR c_pop_rec IN c_population
    LOOP

       lv_rec_exists := 'Y';
                                          
      BEGIN
        utl_file.put_line(lv_file, c_pop_rec.swbxapp_conf_numb);
      EXCEPTION
        WHEN no_data_found THEN
          EXIT;
      END;

    /*Update swbxapp based on conf_numb of BISK (BA%) or VZ%*/
    UPDATE swbxapp p
       SET p.swbxapp_doc_process_ind  = 'Y'
          ,p.swbxapp_doc_process_date = SYSDATE
     WHERE p.swbxapp_doc_process_ind = 'P';
    COMMIT;
         
    END LOOP;

 /* Version G.1 - This creates an empty IDs file for Applications Manager Sub-Flow 
    to be skipped FTP file to BISK when there is no data in swbxapp table. */
    IF NVL(lv_rec_exists, 'N') = 'N' THEN
     --Remove zero byte file
       utl_file.fremove(lv_dir, lv_file_name);
      
     --Create a blank file with different filename
       lv_file_name := 'NO_' || pv_elig_file;
       lv_file := utl_file.fopen(location => lv_dir,
                                 filename => lv_file_name, open_mode => 'w');                                            
    END IF;              
      
    utl_file.fclose(lv_file);

  END p_create_eligibleid_file;


  /*This procedure creates the bdms index file used in BDMS server*/
  PROCEDURE p_create_bdms_index
  (
    pv_dir      IN VARCHAR2
   ,pv_bdms_dir IN VARCHAR2
   ,pv_idx_id   IN VARCHAR2
  ) IS
    --Local variables
    lv_file     utl_file.file_type;
    lv_filename swrvdoc.swrvdoc_file_name%TYPE;
    lv_idx_val  VARCHAR2(1000);
    lv_idx_loc  VARCHAR2(100) := pv_bdms_dir;
    lv_level    swbxapp.swbxapp_levl_code%TYPE := NULL;
    lv_campus   swbxapp.swbxapp_campus%TYPE := NULL;
    lv_doctype  swrvdoc.swrvdoc_vz_doc_type%TYPE := NULL;
    lv_at       VARCHAR2(5);
    lv_cnt      NUMBER := 0;

    CURSOR c_rules_level IS
      SELECT DISTINCT (p.swbxapp_levl_code)
        FROM swbxapp p
            ,swrvdoc s
       WHERE s.swrvdoc_conf_numb = p.swbxapp_conf_numb
         AND s.swrvdoc_error_ind = 'N';

    CURSOR c_rules_campus IS
      SELECT DISTINCT (p.swbxapp_campus) campus
        FROM swbxapp p
            ,swrvdoc s
       WHERE s.swrvdoc_conf_numb = p.swbxapp_conf_numb
         AND s.swrvdoc_error_ind = 'N';

    CURSOR c_rules_doctype IS
      SELECT DISTINCT (s.swrvdoc_vz_doc_type)
        FROM swrvdoc s
       WHERE s.swrvdoc_error_ind = 'N';

    CURSOR c_bdms_idx IS
      SELECT p.swbxapp_id
            ,p.swbxapp_last_name
            ,p.swbxapp_appl_term
            ,p.swbxapp_appl_no
            ,s.swrvdoc_doctype
            ,s.swrvdoc_admreq
            ,s.swrvdoc_routingstatus
            ,s.swrvdoc_conf_numb --Added new field per Version G.4
            ,s.swrvdoc_file_name
        FROM swrvdoc s
            ,swbxapp p
       WHERE s.swrvdoc_conf_numb = p.swbxapp_conf_numb
         AND s.swrvdoc_error_ind = 'N'
         AND p.swbxapp_levl_code = lv_level
         AND p.swbxapp_campus = lv_campus
         AND s.swrvdoc_vz_doc_type = lv_doctype;

    c_bdms_idx_rec      c_bdms_idx%ROWTYPE;
    c_rules_level_rec   c_rules_level%ROWTYPE;
    c_rules_campus_rec  c_rules_campus%ROWTYPE;
    c_rules_doctype_rec c_rules_doctype%ROWTYPE;

  BEGIN

    FOR c_rules_level_rec IN c_rules_level
    LOOP
      --LEVEL
      lv_level := c_rules_level_rec.swbxapp_levl_code;

      FOR c_rules_campus_rec IN c_rules_campus
      LOOP
        --CAMPUS
        lv_campus := c_rules_campus_rec.campus;

        FOR c_rules_doctype_rec IN c_rules_doctype
        LOOP
          --DOCTYPE

          lv_doctype  := c_rules_doctype_rec.swrvdoc_vz_doc_type;
          lv_filename := lv_level || '_' || f_get_campus(lv_campus) || '_' ||
                         lv_doctype || '_' || pv_idx_id;

          lv_cnt := 0;
          FOR c_bdms_idx_rec IN c_bdms_idx
          LOOP
            --idx data
            lv_cnt := lv_cnt + 1;
            --Open file if this is the first record
            IF lv_cnt = 1 THEN
              lv_file := utl_file.fopen(location => pv_dir,
                                        filename => lv_filename || '.txt',
                                        open_mode => 'w');
            END IF;
            
           /* Version G.4 - Per requirement given by BDMS Administor to use 
             '@@' only and include conf_numb and file_name before the '@@'. 
             ',,' is for activity date (field13) in otgmgr.ae_dt509. */
            lv_at := '@@';

            lv_idx_val := c_bdms_idx_rec.swbxapp_id || ',' ||
                          c_bdms_idx_rec.swbxapp_last_name || ',' ||
                          c_bdms_idx_rec.swbxapp_appl_term || ',' ||
                          c_bdms_idx_rec.swbxapp_appl_no || ',' ||
                          c_bdms_idx_rec.swrvdoc_doctype || ',' ||
                          c_bdms_idx_rec.swrvdoc_admreq || ',' ||
                          c_bdms_idx_rec.swrvdoc_routingstatus || ',' ||
                          c_bdms_idx_rec.swrvdoc_conf_numb || ',' || 
                          c_bdms_idx_rec.swrvdoc_file_name || ',,' || 
                          lv_at || lv_idx_loc || c_bdms_idx_rec.swrvdoc_file_name;

            UPDATE swrvdoc s
               SET s.swrvdoc_success_ind  = 'Y'
                  ,s.swrvdoc_success_date = SYSDATE
             WHERE s.swrvdoc_file_name = c_bdms_idx_rec.swrvdoc_file_name
               AND s.swrvdoc_error_ind = 'N';

            utl_file.put_line(lv_file, lv_idx_val);

          END LOOP; --idx data;
          utl_file.fclose(lv_file);
        END LOOP; --DOCTYPE;
      END LOOP; --CAMPUS;
    END LOOP; --LEVEL
    COMMIT;

  END p_create_bdms_index;

  ------After Indexing
 Procedure p_after_indexing(pv_dir  IN VARCHAR2 ,
                            pv_file IN VARCHAR2,
                            pv_log  IN VARCHAR2,
                            pv_days IN NUMBER) IS

 -- Local variables
   lv_userid              VARCHAR2(10) := 'VZDOCS';
   lv_line                VARCHAR2(250);
   lv_dir                 VARCHAR2(25) := pv_dir;
   lv_file                utl_file.file_type;
   lv_cnt                 Number := 0;



  CURSOR c_get_uids Is
          SELECT v.swrvdoc_conf_numb vz_id,v.swrvdoc_file_name file_name
          FROM swrvdoc v,swbxapp p,otgmgr.ae_dt509 a, otgmgr.ae_audit t
   where t.eventid = 37
   and t.appid = 509
   and t.usrname = lv_userid   
   AND a.field15 = v.swrvdoc_conf_numb --Added join per Version G.5
   AND UPPER(TRIM(a.field16)) = UPPER(TRIM(v.swrvdoc_file_name)) --Added join per Version G.5      
   and a.field8 = p.swbxapp_appl_term
   and a.field9 = p.swbxapp_appl_no
   and upper(a.field3) = upper(v.swrvdoc_doctype)
   and upper(nvl(a.field10,'x')) = upper(nvl(v.swrvdoc_admreq,'x'))
   and upper(a.field12) = Upper(v.swrvdoc_routingstatus)
   and a.docid = t.docid
   and v.swrvdoc_success_ind='Y'
   and v.swrvdoc_conf_numb=p.swbxapp_conf_numb
   and a.field1 = p.swbxapp_id;

CURSOR c_trans_log Is
SELECT COUNT(*) records,p.swbxapp_levl_code,p.swbxapp_campus,v.swrvdoc_vz_doc_type  FROM
swrvdoc v,swbxapp p ,otgmgr.ae_dt509 a WHERE
a.field8 = p.swbxapp_appl_term       AND
a.field1 = p.swbxapp_id              AND
a.field9 = p.swbxapp_appl_no         AND
v.swrvdoc_success_ind='Y'            AND
v.swrvdoc_conf_numb=p.swbxapp_conf_numb  AND
upper(a.field3) = upper(v.swrvdoc_doctype)   AND
upper(nvl(a.field10,'x')) = upper(nvl(v.swrvdoc_admreq,'x'))   AND
upper(a.field12) = Upper(v.swrvdoc_routingstatus)   AND
a.field15 = v.swrvdoc_conf_numb AND --Added join per Version G.5
UPPER(TRIM(a.field16)) = UPPER(TRIM(v.swrvdoc_file_name)) --Added join per Version G.5
GROUP BY  p.swbxapp_levl_code,p.swbxapp_campus,v.swrvdoc_vz_doc_type ;

 CURSOR c_get_obsolete_doc IS
    SELECT v.swrvdoc_file_name file_name FROM swrvdoc v
    WHERE trunc(v.swrvdoc_received_date) <= trunc(sysdate-pv_days) ;


   get_uids_rec      c_get_uids%ROWTYPE;
   obsolete_doc_rec  c_get_obsolete_doc%ROWTYPE;
   trans_log_rec     c_trans_log%ROWTYPE;



     BEGIN
       lv_file:=utl_file.fopen(location => pv_dir,filename => pv_log, open_mode => 'w');
       lv_line :='==========APPLICATIONS BDMS TRANSACTION LOG REPORT==========================';
       utl_file.put_line(lv_file,lv_line);
       utl_file.new_line(lv_file);
       utl_file.put_line(lv_file,'REPORT DATE:'||sysdate);
       utl_file.new_line(lv_file);
       lv_line :=rpad('RECORDS IMAGED',24)||rpad('LEVEL',15)||rpad('CAMPUS',16)||'DOCUMENT TYPE';
       utl_file.put_line(lv_file,lv_line);
       lv_line :='=================================================================== ';
       utl_file.put_line(lv_file,lv_line);



        FOR trans_log_rec in c_trans_log
          LOOP
             lv_line :=  rpad(trans_log_rec.records,25)||
                         rpad(trans_log_rec.swbxapp_levl_code,17)||
                         rpad(f_get_campus(trans_log_rec.swbxapp_campus),18)||
                         trans_log_rec.swrvdoc_vz_doc_type;
              utl_file.put_line(lv_file,lv_line);
              lv_cnt  :=  lv_cnt + 1;
              END LOOP;
       -- If no records were imaged then the log file should show '0' records imaged
              IF lv_cnt = 0 THEN
              lv_line := rpad(lv_cnt,25)||rpad('--',17)||rpad('--',18)||'--';
              utl_file.put_line(lv_file,lv_line);
              utl_file.fclose(lv_file);
              ELSE
              utl_file.fclose(lv_file);
              END IF;



       lv_file:=utl_file.fopen(location => lv_dir,filename => pv_file, open_mode => 'w');
       --Clean up table if indexing is successfull
           FOR get_uids_rec in c_get_uids
              LOOP
              DELETE FROM swrvdoc v  WHERE
              v.swrvdoc_file_name=get_uids_rec.file_name ;
              utl_file.put_line(lv_file,get_uids_rec.file_name);
              END LOOP;

      --Clean up table if file is in table for more than pv_days days
      FOR obsolete_doc_rec in c_get_obsolete_doc
          LOOP
             DELETE FROM swrvdoc v  WHERE v.swrvdoc_file_name=obsolete_doc_rec.file_name ;
             utl_file.put_line(lv_file,obsolete_doc_rec.file_name);
          END LOOP;

          utl_file.fclose(lv_file);

    END;

END wsak_adm_appl;
/
