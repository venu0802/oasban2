CREATE OR REPLACE PACKAGE baninst1.wsakedi IS
  --
  --***********************************************************************
  --
  --  University of South Florida
  --  Student Information System
  --  Program Unit Information
  --
  --  General Information
  --  -------------------
  --  Program Unit Name  : wsakedi
  --  Process Associated : EDI
  --  Object Source File Location and Name : dbprocs\wsakedi.sql
  --  Business Logic :
  --   Explain business logic here.
  --  Documentation Links:
  --   This should be a URL link to the location of the Functional and
  --   Technical specificaions for the project to which the Program Unit
  --   is attatched.
  --
  --
  -- Audit Trail
  -- -----------
  --  Version  Issue      Date         User         Reason For Change
  --  -------  ---------  -----------  --------     -----------------------
  --     1     OASBAN-18  4/24/2012       MROBERTS  Modifications for Distance Learning Transient Student
  --                                                Project 11-00208
  --                                                Modified the following:
  --                                                1) wp_load_outbound_ack sub-procedure
  --                                                   wp_check_elements to add validation
  --                                                   for new 130 inbound types: S20 Cost of
  --                                                   Attendance transcripts. Moved all supporting code
  --                                                   for generating out 997 data in tables into the main
  --                                                   package so that they coudl be referenced by
  --                                                   wsakedi_transient nte validation procedures.
  --                                                2) wp_load_inbound_130 modified to load a new
  --                                                   note type for transient transcripts for the NTE(SES)
  --                                                   segment for inbound 130-S20, Cost of Attendance transcripts.
  --                                                3) Fixed prod issue, modified wp_gen_ack_files cursor transactions_c
  --                                                   to ORDER BY swteake_dcmt_seqno so that segments are printed in correct order.
  -------------------------------------------------------------------------
  --  Src   USF
  --  Ver   Ver  Package    Date         User       Reason For Change
  -- -----  ---  ---------  -----------  ------     -----------------------
  --  n/a   A   B5-002941  05-NOV-2002  VBANGALO   Initial Creation.
  --  n/a   B   B5-002941  08-NOV-2002  VBANGALO   Modified wp_load_inbound_130
  --  n/a   C   B5-002964  13-NOV-2002  VBANGALO   Modified wp_gen_ack_files
  --  n/a   D   B5-002968  15-NOV-2002  VBANGALO   Modified wp_load_inbound_130
  --  n/a   E   B5-003020  04-DEC-2002  VBANGALO   Modified wp_load_inbound_147
  --  n/a   F   B5-003033  10-DEC-2002  VBANGALO   Modified wp_generate_outbound_146
  --  n/a   G   B5-003003  11-DEC-2002  VBANGALO   Modifed wp_load_incoming_transactions
  --        H   B5-003037  13-DEC-2002  Mpella     Mofified wp_load_inbound_147
  --                                                and wp_generate_outbound_146
  --  n/a   I   B5-003127  04-MAR-2003  VBANGALO   Modified code to load IN1 segment
  --                                               vales correctly in wp_load_inbound_147.
  --  n/a   J   B5-003259  22-JUL-2003  VBANGALO   Modified wp_load_inbound_130.
  --  n/a   K   B5-003300  02-SEP-2003  VBANGALO   Modified wp_load_outbound_ack.
  --  n/a   L   B5-003304  05-SEP-2003  Arunion    Modified wp_load_inbound_130.
  --  n/a   M   B5-003482  04-DEC-2003  VBANGALO   Took out changes made by Arunion
  --                                               since that requiremnt is not required.
  --            B6-003581  02-FEV-2004  VBANGALO   Checked from B5003581 Package.
  --        N   06-003677  25-FEB-2004  VBANGALO   Modified wp_generate_outbound_146
  --        O   O6-003743  16-APR-2004  VBANGALO   Modified all directory filed length to 1000.
  --        P   O6-003783  18-JUN-2004  VBANGALO   Modified wp_generate_outbound_146
  --                                               and wp_generate_outbound_147
  --        Q   O6-003789  29-JUN-2004  VBANGALO   Modified wp_generate_outbound_146
  --        R   O6-003797  09-JUL-2004  VBANGALO   Modified wp_load_inbound_130
  --        S   O6-003809  26-JUL-2004  VBANGALO   Modified wp_generate_outbound_146
  --        T   UNF-001016 18-JUL-2005  DEEPAK     UNF Modification..HS Mods were also included.
  --        U   UNF-001019 25-JUL-2005  VBANGALO   Modified wp_load_inbound_130
  --        V              22-JUN-2006  RVOGETI    Brought over from FAU for 7 upgrade
  --                                               and also modified wp_verify_isa_seg
  --                                               to check for (00401, 00305, 00304)
  --        W   O7-000396  18-DEC-2006  WHURLEY    1) Modified wp_load_outbound_ack to accept new
  --                                               parameter for test_prod_ind so 997's can be
  --                                               generated with 'T' or 'P' in ISA segment
  --                                               2) Modified wp_load_incoming_transactions
  --                                               in the check on ISA(15) to make
  --                                               sure that if the prompt comes in
  --                                               as 'P' (PROD Default) that the
  --                                               ISA(15) is also P.  This ensures
  --                                               that TEST files are not loaded in PROD.
  --        X  O7-000841   20-MAR-2009  VBANGALO   Modified code to mark override degree in
  --                                               swrdegr_override_ind.
  --        Y  O7-000995   04-MAR-2010  VBANGALO   Fixed wp_load_inbound_130 to trunc over ride
  --                                               institution name to 30.N1(SES). Prod issue #4465
  --        Z  08-000339   05-APR-2010  RVOGETI    Replaced calls to the following functions
  --                                               a.wsaketbl.f_get_swrrule_val with wf_get_rule_value_db
  --                                               b.wsaketbl.f_get_xref_val_db with wf_get_xref_val_db
  --                                               c.wsaketbl.f_get_smtp_addr with wsakemal.f_get_smtp_addr
  --  1.01.01  08-000452   14-oct-2010  RVOGETI    Modified wp_load_inbound_130 to load EDI
  --                                               Immunization data, per project 10-0018
  --       AA  O8-000517   17-MAR-2011  VBANGALO   Modified wp_load_inbound_130 and truncated value before
  --                                               shrhdr4_enty_code of shrhdr4 table.
  --           O8-000677   02-02-2012   vbangalo   truncated shrcrsr_xcurr_code data to 20 since incoming data
  --                                               can be upto 80 characters. Also added proper exception value
  --                                               while loading immunization data.
  --  1.01.02  OASBAN-93   02/19/2013   DGRIFFIT   Modifications to support changes to swreelm max length to match TS130
  --                                               specification. Truncate the following:
  --							shrhdr4_enty_name2, shrhdr4_enty_name3, shrhdr4_contact_name
  --                                                    shriden_last_name, shriden_name_prefix, shriden_first_initial
  --                                                    shriden_middle_name_1, shriden_middle_name_2, shriden_middile_initial_1
  --                                                    shriden_middle_initial_2, shriden_name_sufix, shriden_former_name
  --                                                    shriden_combined_name, shriden_composite_name, shriden_agency_name
  --                                                    shrcsrs_crse_title
  --************************************************************************

  /* These objects support wp_load_outbound_ack and were moved here for the
  transient transcript project so that waskedi_transient could reference them.*/
  gc_data_segment_note CONSTANT CHAR(3) := 'AK3';
  gc_data_element_note CONSTANT CHAR(3) := 'AK4';

  FUNCTION wf_ak3_exists_db
  (
    p_dcmt_in   swtewls.swtewls_dcmt_seq%TYPE
   ,p_seg_id_in VARCHAR2
   ,p_pos_in    VARCHAR2
  ) RETURN BOOLEAN;

  PROCEDURE wp_build_ak3_seg_db
  (
    p_dcmt_in       swtewls.swtewls_dcmt_seq%TYPE
   ,p_seg_in        VARCHAR2
   ,p_pos_in        NUMBER
   ,p_error_code_in VARCHAR2
  );

  PROCEDURE wp_build_ak4_seg_db
  (
    p_dcmt_in       swtewls.swtewls_dcmt_seq%TYPE
   ,p_elm_seq_in    swtewle.swtewle_elm_seq%TYPE
   ,p_error_code_in VARCHAR2
   ,p_elm_val_in    swtewle.swtewle_elm_value%TYPE
  );

  FUNCTION wf_get_line_numb_db(p_dcmt_in swtewls.swtewls_dcmt_seq%TYPE)
    RETURN NUMBER;

  PROCEDURE wp_insert_swteaks_db
  (
    p_dcmt_in swteaks.swteaks_dcmt_seq%TYPE
   ,p_line_in swteaks.swteaks_line_num%TYPE
   ,p_seg_in  swteaks.swteaks_seg%TYPE
  );

  PROCEDURE wp_insert_swteake_db
  (
    p_dcmt_in      swteaks.swteaks_dcmt_seq%TYPE
   ,p_line_in      swteaks.swteaks_line_num%TYPE
   ,p_elm_seq_in   swteake.swteake_elm_seq%TYPE
   ,p_elm_value_in swteake.swteake_elm_value%TYPE
  );

  PROCEDURE wp_purge_tool_load_area
  --***********************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wsakedi.wp_purge_tool_load_area
    --  Process Associated : EDI
    --  Business Logic :
    --   This purges tool work load area and acknowledgment area.
    --  Documentation Links:
    --  G:\Documentation\Technical Specifications\EDI\
    --   Q202074 EDI Tool replacement\out997_technical_specifications.doc
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User       Reason For Change
    -- -----  ---  ---------  -----------  ------     -----------------------
    --  n/a    A   B5-002941  17-OCT-2002  VBANGALO   Initial Creation.
    --
    -- Parameter Information:
    --
    --************************************************************************
  ;

  PROCEDURE wp_load_incoming_transactions
  (
    p_dir_in      VARCHAR2
   ,p_file_in     VARCHAR2
   ,p_mail_add_in VARCHAR2
   ,p_tran_type   VARCHAR2 DEFAULT 'P'
   ,p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  )
  --***********************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wsakedi.wp_load_incoming_transactions
    --  Process Associated : EDI
    --  Business Logic :
    --   This procedure reads the EDI transactions sets in a file,
    --   splits them into single unit transaction and loads into
    --   temporary EDI workload area.
    --  Documentation Links:
    --  G:\Documentation\Technical Specifications\EDI\
    --   Q202074 EDI Tool replacement\out997_technical_specifications.doc
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User       Reason For Change
    -- -----  ---  ---------  -----------  ------     -----------------------
    --  n/a    A   B5-002941  17-OCT-2002  VBANGALO   Initial Creation.
    --  n/a    G   B5-003003  11-DEC-2002  VBANGALO   Modified call to wp_send_mail_db
    --                                                to include message out
    --                                                and success out parameters
    --  n/a    W   O7-000396  28-DEC-2006  WHURLEY    Modified check on ISA(15) to make
    --                                                sure that if the prompt comes in
    --                                                as 'P' (PROD Default) that the
    --                                                ISA(15) is also P.  This ensures
    --                                                that TEST files are not loaded in PROD.
    --
    -- Parameter Information:
    --  p_dir_in          in parameter  Directory in which inbound transaction
    --                                  file exists.
    --  p_file_in         in parameter  Name of EDI transaction file
    --  p_mail_add_in     in parameter  mail address to which error mail to
    --                                  be sent.
    --  p_success_out    out parameter  set to TRUE if process is success
    --                                  set to FALSE if process is failed.
    --  p_message_out    out parameter  message.
    --************************************************************************
  
  ;
  PROCEDURE wp_load_outbound_ack
  (
    p_test_or_prod_ind VARCHAR2
   ,p_message_out      OUT VARCHAR2
   ,p_success_out      OUT BOOLEAN
  )
  --***********************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wsakedi.wp_load_outbound_ack
    --  Process Associated : EDI
    --  Business Logic :
    --   This procedure reads incoming transaction from temporary
    --   work load area, checks for syntax and semantics of the
    --   incominng transactions, generates acknowledgments and
    --   loads into temporary acknowledgment tables(swteaks, swteake).
    --  Documentation Links:
    --  G:\Documentation\Technical Specifications\EDI\
    --   Q202074 EDI Tool replacement\out997_technical_specifications.doc
    --
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User       Reason For Change
    -- -----  ---  ---------  -----------  ------     -----------------------
    --  n/a   A   B5-002941  20-AUG-2002  VBANGALO   Initial Creation.
    --  n/a   K   B5-003300  02-SEP-2003  VBANGALO   Modified code to initialize
    --                                               previous segment and previous
    --                                               sequence variables.
    --  n/a   W   O7-000396  18-DEC-2006  WHURLEY    Added inbound parameter parameter for test_prod_ind
    --                                               so 997's can be generated with 'T' or 'P' in ISA segment
		--  n/a       OASBSAN-75 14-NOV-2012  VBANGALO   Fixed code to handle element 'E' rule to handle multiple conditions.
		--                                               This was required for IMM03 segment which requires to have value
		--                                               both IMM02, IMM04 elements. 
		-- 
    -- Parameter Information:
    -- ------------
    --  p_test_or_prod_ind in parameter   based on Appworx condition, will be 'P' if
    --                                    #test_or_prod is 'prod' and 'T' if test_or_prod
    --                                    is 'test'
    --  p_success_out      out parameter  set to TRUE if process is success
    --                                    set to FALSE if process is failed.
    --  p_message_out      out parameter  message.
    --************************************************************************
  ;

  PROCEDURE wp_gen_ack_files
  (
    p_dir_in      VARCHAR2
   ,p_message_out OUT VARCHAR2
   ,p_success_out OUT BOOLEAN
  )
  --***********************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wsakedi.wp_gen_ack_files
    --  Process Associated : EDI
    --  Business Logic :
    --   This procedure reads acknowledgments from acknowledgment tables
    --   (swteaks, swteake) and generates outbound997 for incoming
    --   transactions.
    --  Documentation Links:
    --  G:\Documentation\Technical Specifications\EDI\
    --   Q202074 EDI Tool replacement\out997_technical_specifications.doc
    --
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User       Reason For Change
    -- -----  ---  ---------  -----------  ------     -----------------------
    --  n/a   A   B5-002941  20-AUG-2002  VBANGALO   Initial Creation.
    --  n/a   C   B5-002964  13-NOV-2002  VBANGALO   Modified code so that
    --                                               AK1 segments are not grouped
    --                                               under same ST segment
    --
    -- Parameter Information:
    -- ------------
    --  p_dir_in          in parameter  Directory in which out997 to be
    --                                  generated.
    --  p_success_out    out parameter  set to TRUE if process is success
    --                                  set to FALSE if process is failed.
    --  p_message_out    out parameter  message.
    --************************************************************************
  ;

  PROCEDURE wp_load_inbound_130
  (
    p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  )
  --*****************************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wp_load_inbound_130
    --  Process Associated : EDI
    --  Business Logic :
    --   This procedure loads all inbound transcripts(TS130) into banner
    --   work load area. Process gets all documents that belong to
    --   inbound transcripts from EDI work load area(swtwls, swtwle)
    --   tables and verifies whther they are valied ones against
    --   EDI acknowledgment load area table(swteaks, swteake).
    --   If the transcripts are valied, then only this process loads
    --   transcrips into banner load area.
    --  Documentation Links:
    --  G:\Documentation\Technical Specifications\EDI\
    --   Q202074 EDI Tool replacement\inbound130 mapping.doc
    --
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User    Reason For Change
    -- -----  ---  ---------  -----------  ------  -----------------------
    --  n/a   A   B5-002941  20-AUG-2002  VBANGALO   Initial Creation.
    --  n/a   B   B5-002941  08-NOV-2002  VBANGALO   Modified code to update
    --                                               course number and tilte
    --                                               only when ther are null.
    --  n/a   D   B5-002968  15-NOV-2002  VBANGALO   Modified code to load
    --                                               only CLAST test components
    --                                               in test score tables.
    --  n/a   J   B5-003259  22-JUL-2003  VBANGALO   Modified code to load
    --                                               PCL segment as per new
    --                                               changes in swrspcl table.
    --                                               Also, when inserting zip code
    --                                               it is truncated to first 5
    --                                               digits.
    --  n/a   L   B5-003304  05-SEP-2003  Arunion    Modified so that N1 segment is
    --                                               read after CRS segment.
    --  n/a   M   B5-003482  04-DEC-2003  VBANGALO   Took out changes made by Arunion
    --                                               since that requiremnt is not required.
    --        R   O6-003797  09-JUL-2004  VBANGALO   Modified code to truncate override
    --                                               zip code to nine charecters.
    --        U   UNF-001019 25-JUL-2005  VBANGALO   shrcrsr_drop_date loading is commented out
    --                                               since it is not used in edi load process
    --                                               either in PS or HS.
    --        V   FAU-??     19-JAN-2006  VBANGALO   Modified code to include document(clob) in
    --                                               in shbhead.
    --
    -- Parameter Information:
    -- ------------
    --  p_success_out    out parameter  set to TRUE if process is success
    --                                  set to FALSE if process is failed.
    --  p_message_out    out parameter  message.
    --*****************************************************************************
  ;

  PROCEDURE wp_load_inbound_status
  (
    p_message_out OUT VARCHAR2
   ,p_success_out OUT BOOLEAN
  )
  --
    --***********************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wp_load_inbound_status
    --  Process Associated : EDI
    --  Business Logic :
    --   This procedure loads all inbound trnasactions' status
    --  into status table swtetss.
    --  Documentation Links:
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User       Reason For Change
    -- -----  ---  ---------  -----------  ------     -----------------------
    --  n/a   A   B5-002941  20-AUG-2002  VBANGALO   Initial Creation.
  
    -- Parameter Information:
    -- ------------
    --  p_success_out    out parameter  set to TRUE if process is success
    --                                  set to FALSE if process is failed.
    --  p_message_out    out parameter  message.
    --
    --************************************************************************
  ;
  PROCEDURE wp_send_error_mail
  (
    p_seg_in           VARCHAR2
   ,p_error_element_in VARCHAR2
   ,p_error_message_in VARCHAR2
   ,p_line_in          VARCHAR2
   ,p_sender_in        VARCHAR2
  );
  PROCEDURE wp_load_inbound_131
  (
    p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  );
  PROCEDURE wp_load_inbound_146
  (
    p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  );
  PROCEDURE wp_load_inbound_147
  (
    p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  );
  PROCEDURE wp_generate_outbound_146
  (
    p_dir_in      IN VARCHAR2
   ,p_type_in     IN VARCHAR2
   ,p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  );
  PROCEDURE wp_generate_outbound_147
  (
    p_dir_in      IN VARCHAR2
   ,p_type_in     IN VARCHAR2
   ,p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  );
  --venu's change incorporated on 08/31/06
  FUNCTION wf_build_edi_tran_clob(p_swtewls_dcmt_in swtewls.swtewls_dcmt_seq%TYPE)
    RETURN CLOB;

  l_host_inst_code     swrrule.swrrule_value%TYPE := wf_get_rule_value_db('EDI',
                                                                          'HOSTINST');
  l_host_edi_inst_code swrrule.swrrule_value%TYPE := wf_get_rule_value_db('INST INFO',
                                                                          'SBGI_CODE');
  l_host_addr_line1    swrrule.swrrule_value%TYPE := wf_get_rule_value_db('EDI',
                                                                          'ADDR1');
  l_host_addr_line2    swrrule.swrrule_value%TYPE := wf_get_rule_value_db('EDI',
                                                                          'ADDR2');
  l_host_city          swrrule.swrrule_value%TYPE := wf_get_rule_value_db('EDI',
                                                                          'CITY');
  l_host_state         swrrule.swrrule_value%TYPE := wf_get_rule_value_db('EDI',
                                                                          'STATE');
  l_host_zip           swrrule.swrrule_value%TYPE := wf_get_rule_value_db('EDI',
                                                                          'ZIP');
  l_host_inst_desc     stvsbgi.stvsbgi_desc%TYPE := wf_get_rule_value_db('EDI',
                                                                         'HOSTINSTNAME');
END wsakedi;
/
CREATE OR REPLACE PACKAGE BODY baninst1.wsakedi IS
  -- ver V start
  l_clob CLOB;
  FUNCTION wf_build_edi_tran_clob(p_swtewls_dcmt_in swtewls.swtewls_dcmt_seq%TYPE)
    RETURN CLOB IS
    l_seg  VARCHAR2(2000);
    l_clob CLOB;
    CURSOR swtewls_c IS
      SELECT *
        FROM swtewls a
       WHERE a.swtewls_dcmt_seq = p_swtewls_dcmt_in
       ORDER BY a.swtewls_line_num;
  
    CURSOR swtewle_c(c_swtewle_line_in swtewle.swtewle_line_num%TYPE) IS
      SELECT *
        FROM swtewle a
       WHERE a.swtewle_dcmt_seqno = p_swtewls_dcmt_in
         AND a.swtewle_line_num = c_swtewle_line_in
       ORDER BY a.swtewle_elm_seq;
  
  BEGIN
    l_clob := NULL;
    FOR swtewls_rec IN swtewls_c
    LOOP
      l_seg := NULL;
      l_seg := swtewls_rec.swtewls_seg;
      FOR swtewle_rec IN swtewle_c(swtewls_rec.swtewls_line_num)
      LOOP
        l_seg := l_seg || '|' || swtewle_rec.swtewle_elm_value;
      END LOOP;
      l_seg := rtrim(l_seg, '|') || '^' || chr(10);
      --dbms_output.put_line (l_seg);
      l_clob := l_clob || l_seg;
    END LOOP;
    RETURN l_clob;
  END;
  -- ven end

  PROCEDURE wp_send_error_mail
  (
    p_seg_in           VARCHAR2
   ,p_error_element_in VARCHAR2
   ,p_error_message_in VARCHAR2
   ,p_line_in          VARCHAR2
   ,p_sender_in        VARCHAR2
  ) IS
  
    /*
        This procedure generates error mail.
    
        Parameters:
            p_seg_in           in parameter Segment
            p_error_element_in in parameter Error element
            p_error_message_in in parameter Error message
            p_line_in          in parameter line in which error occured
            p_sender_in        in parameter sender email address
    
    */
  
    l_message     VARCHAR2(2000);
    l_mail_host   VARCHAR2(100);
    l_message_out VARCHAR2(2000);
    l_success_out BOOLEAN;
  BEGIN
    l_mail_host := wsakemal.f_get_smtp_addr('EDIGEN');
    --l_mail_host := substr(p_sender_in, instr(p_sender_in, '@', 1, 1) + 1);
    l_message := '                WARNING ' || chr(10) ||
                 '              -------------' || chr(10) || chr(10) ||
                 chr(10) || '    DATE                  :' ||
                 to_char(SYSDATE, 'DD-MON-YYYY') || chr(10) ||
                 '    TIME                  :' ||
                 to_char(SYSDATE, 'HH24:MI:SS') || chr(10) ||
                 '    ERROR SEGMENT         :' || p_seg_in || chr(10) ||
                 '    ERROR ELEMENT         :' || p_error_element_in ||
                 chr(10) || '    ERROR                 :' ||
                 p_error_message_in || chr(10) ||
                 '    ERROR SEGMENT COPY    :    ';
    wp_sendmail_db(p_sender_in, p_sender_in, l_mail_host, 'out997',
                   l_message || chr(10) || p_line_in, l_message_out,
                   l_success_out);
  END wp_send_error_mail;

  PROCEDURE wp_purge_tool_load_area IS
    num_of_rows NUMBER(3);
    CURSOR swtewls_c IS
      SELECT *
        FROM swtewls b
       ORDER BY b.swtewls_dcmt_seq
               ,b.swtewls_line_num;
    CURSOR swteaks_c IS
      SELECT *
        FROM swteaks e
       ORDER BY e.swteaks_dcmt_seq
               ,e.swteaks_line_num;
  
    --***********************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wsakedi.wp_purge_tool_load_area
    --  Process Associated : EDI
    --  Business Logic :
    --   This purges tool work load area and acknowledgment area.
    --  Documentation Links:
    --  G:\Documentation\Technical Specifications\EDI\
    --   Q202074 EDI Tool replacement\out997_technical_specifications.doc
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User       Reason For Change
    -- -----  ---  ---------  -----------  ------     -----------------------
    --  n/a    A   Bx-xxxxxx  17-OCT-2002  VBANGALO   Initial Creation.
    --  n/a    B   B5-003210  10-JUN-2003  VBANGALO   Modified delete statement
    --                                                so that rollback segment
    --                                                error will not occur.
    --
    -- Parameter Information:
    --
    --************************************************************************
  
  BEGIN
    num_of_rows := 0;
    FOR swtewls_rec IN swtewls_c
    LOOP
      DELETE FROM swtewle a
       WHERE a.swtewle_dcmt_seqno = swtewls_rec.swtewls_dcmt_seq
         AND a.swtewle_line_num = swtewls_rec.swtewls_line_num;
      DELETE FROM swtewls c
       WHERE c.swtewls_dcmt_seq = swtewls_rec.swtewls_dcmt_seq
         AND c.swtewls_line_num = swtewls_rec.swtewls_line_num;
      num_of_rows := num_of_rows + 1;
      IF num_of_rows >= 500 THEN
        num_of_rows := 0;
        COMMIT;
      END IF;
    END LOOP;
    COMMIT;
  
    num_of_rows := 0;
    FOR swteaks_rec IN swteaks_c
    LOOP
      DELETE FROM swteake g
       WHERE g.swteake_dcmt_seqno = swteaks_rec.swteaks_dcmt_seq
         AND g.swteake_line_num = swteaks_rec.swteaks_line_num;
      DELETE FROM swteaks h
       WHERE h.swteaks_dcmt_seq = swteaks_rec.swteaks_dcmt_seq
         AND h.swteaks_line_num = swteaks_rec.swteaks_line_num;
      num_of_rows := num_of_rows + 1;
      IF num_of_rows >= 500 THEN
        num_of_rows := 0;
        COMMIT;
      END IF;
    END LOOP;
    COMMIT;
  
  END wp_purge_tool_load_area;

  PROCEDURE wp_load_incoming_transactions
  (
    p_dir_in      VARCHAR2
   ,p_file_in     VARCHAR2
   ,p_mail_add_in VARCHAR2
   ,p_tran_type   VARCHAR2 DEFAULT 'P'
   ,p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  ) IS
  
    --***********************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wsakedi.wp_load_incoming_transactions
    --  Process Associated : EDI
    --  Business Logic :
    --   This procedure reads the EDI transactions sets in a file,
    --   splits them into single unit transaction and loads into
    --   temporary EDI workload area.
    --  Documentation Links:
    --  G:\Documentation\Technical Specifications\EDI\
    --   Q202074 EDI Tool replacement\out997_technical_specifications.doc
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User       Reason For Change
    -- -----  ---  ---------  -----------  ------     -----------------------
    --  n/a    A   B5-002941  17-OCT-2002  VBANGALO   Initial Creation.
    --  n/a    G   B5-003003  11-DEC-2002  VBANGALO   Modified call to wp_send_mail_db
    --                                                to include message out
    --                                                and success out parameters
    --  n/a    W   O7-000396  28-DEC-2006  WHURLEY    Modified check on ISA(15) to make
    --                                                sure that if the prompt comes in
    --                                                as 'P' (PROD Default) that the
    --                                                ISA(15) is also P.  This ensures
    --                                                that TEST files are not loaded in PROD.
    --
    -- Parameter Information:
    --  p_dir_in          in parameter  Directory in which inbound transaction
    --                                  file exists.
    --  p_file_in         in parameter  Name of EDI transaction file
    --  p_mail_add_in     in parameter  mail address to which error mail to
    --                                  be sent.
    --  p_success_out    out parameter  set to TRUE if process is success
    --                                  set to FALSE if process is failed.
    --  p_message_out    out parameter  message.
    --************************************************************************
  
    l_line_num              NUMBER := 0;
    l_fileid                utl_file.file_type;
    l_file_name             VARCHAR2(1000);
    l_dir_name              VARCHAR2(1000);
    l_eof                   BOOLEAN;
    l_line                  VARCHAR2(2000);
    l_isa_line              VARCHAR2(2000);
    l_gs_line               VARCHAR2(2000);
    l_success_out           BOOLEAN;
    l_message_out           VARCHAR2(2000);
    l_dcmt_seqno            NUMBER;
    l_elm_sep               CHAR(1);
    l_comp_sep              CHAR(1);
    l_seg_sep               CHAR(1);
    l_type                  CHAR(3);
    l_interchange_cntrl_nbr VARCHAR(10);
    l_segment               VARCHAR2(10);
    l_present_seg           VARCHAR2(10);
    l_previous_seg          VARCHAR2(10);
    l_grp_cntrl_nbr         VARCHAR2(50);
    c_interchange_cntrl_hdr_seg CONSTANT CHAR(3) := 'ISA';
    c_interchange_cntrl_trl_seg CONSTANT CHAR(3) := 'IEA';
    c_functional_gruop_hdr_seg  CONSTANT CHAR(2) := 'GS';
    c_functional_gruop_trl_seg  CONSTANT CHAR(2) := 'GE';
    c_interchange_trn_hdr_seg   CONSTANT CHAR(2) := 'ST';
    c_interchange_trn_trl_seg   CONSTANT CHAR(2) := 'SE';
    l_elment_table         wsaklnutil.varchar2_tabtype;
    l_test_boolean         BOOLEAN;
    l_seg_repeat           NUMBER := 1;
    l_skip_untill_next_isa BOOLEAN;
    l_skip_untill_next_gs  BOOLEAN;
    l_error                VARCHAR2(2000);
  
    PROCEDURE wp_send_error_mail
    (
      p_seg_in           VARCHAR2
     ,p_error_element_in VARCHAR2
     ,p_error_message_in VARCHAR2
     ,p_line_in          VARCHAR2
     ,p_sender_in        VARCHAR2
    ) IS
    
      /*
          This procedure generates error mail.
      
          Parameters:
              p_seg_in           in parameter Segment
              p_error_element_in in parameter Error element
              p_error_message_in in parameter Error message
              p_line_in          in parameter line in which error occured
              p_sender_in        in parameter sender email address
      
      */
    
      l_message   VARCHAR2(2000);
      l_mail_host VARCHAR2(100);
    BEGIN
      l_mail_host := wsakemal.f_get_smtp_addr('EDIGEN');
      --l_mail_host := substr(p_sender_in, instr(p_sender_in, '@', 1, 1) + 1);
      l_message := '                WARNING ' || chr(10) ||
                   '              -------------' || chr(10) || chr(10) ||
                   chr(10) || '    DATE                  :' ||
                   to_char(SYSDATE, 'DD-MON-YYYY') || chr(10) ||
                   '    TIME                  :' ||
                   to_char(SYSDATE, 'HH24:MI:SS') || chr(10) ||
                   '    ERROR SEGMENT         :' || p_seg_in || chr(10) ||
                   '    ERROR ELEMENT         :' || p_error_element_in ||
                   chr(10) || '    ERROR                 :' ||
                   p_error_message_in || chr(10) ||
                   '    ERROR SEGMENT COPY    :    ';
      wp_sendmail_db(p_sender_in, p_sender_in, l_mail_host, 'out997',
                     l_message || chr(10) || p_line_in, l_message_out,
                     l_success_out);
    END wp_send_error_mail;
  
    --> This procedure validates ISA elements.
    --> This procedure takes line in file that has ISA segment
    --> as one in parameter and one boolean out parameter that is
    --> set to true or false based on out come of the proeceure.
    --> If there is error in element valus of this segment
    --> it generates eamil and sets the sucess_out to FALSE.
    PROCEDURE wp_verify_isa_seg
    (
      p_line_in     VARCHAR2
     ,p_success_out OUT BOOLEAN
    ) IS
      l_message       VARCHAR2(2000);
      l_error_seg     VARCHAR2(5) := 'ISA';
      l_error_element VARCHAR2(3) := 0;
      l_success_out   BOOLEAN;
    
      /*FUNCTION wf_validate_trading_partner returns TRUE if
        the sender partner id is valid and returns FALSE if
        the sender partern id is invalid.
        Parameters:
        p_sen_qual_in         sender's qualifier code
        p_sender_id_in        sender's code
      */
      FUNCTION wf_valid_trading_partner
      (
        p_sen_qual_in  swtewle.swtewle_elm_value%TYPE
       ,p_sender_id_in swtewle.swtewle_elm_value%TYPE
      ) RETURN BOOLEAN IS
        l_exists    CHAR(1);
        l_cur_found BOOLEAN;
        l_result    BOOLEAN;
      
        CURSOR qualified_sender_c IS
          SELECT 'y'
            FROM swrenqc a
           WHERE a.swrenqc_qlfr_code = TRIM(p_sen_qual_in)
             AND a.swrenqc_inst_code = TRIM(p_sender_id_in);
      BEGIN
        l_result := FALSE;
        l_exists := 'n';
      
        IF qualified_sender_c%ISOPEN THEN
          CLOSE qualified_sender_c;
        END IF; /* qualified_sender_c%isopen */
      
        OPEN qualified_sender_c;
        FETCH qualified_sender_c
          INTO l_exists;
        l_result := qualified_sender_c%FOUND;
        CLOSE qualified_sender_c;
        RETURN l_result;
      END wf_valid_trading_partner;
    BEGIN
      --> load element values in plsql table
      p_success_out := TRUE;
      wsaklnutil.wp_load_elements_into_pltable(p_line_in, l_elm_sep,
                                               l_seg_sep, l_elment_table,
                                               l_success_out, l_message_out);
    
      --> validate all element values
      FOR tab_index IN 1 .. l_elment_table.count
      LOOP
        IF tab_index = 1 THEN
          IF length(l_elment_table(tab_index)) <> 2 THEN
            l_message       := 'Lenghth <> 2';
            l_error_element := '01';
            p_success_out   := FALSE;
            EXIT;
          END IF; /*LENGTH (l_elment_table (tab_index)) <> 2 */
        ELSIF tab_index = 2 THEN
          IF length(l_elment_table(tab_index)) <> 10 THEN
            l_message       := 'Lenghth <> 10';
            l_error_element := '02';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 10 */
        ELSIF tab_index = 3 THEN
          IF length(l_elment_table(tab_index)) <> 2 THEN
            l_message       := 'Lenghth <> 2';
            l_error_element := '03';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 2 */
        ELSIF tab_index = 4 THEN
          IF length(l_elment_table(tab_index)) <> 10 THEN
            l_message       := 'Lenghth <> 10';
            l_error_element := '04';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 10 */
        ELSIF tab_index = 5 THEN
          IF length(l_elment_table(tab_index)) <> 2 THEN
            l_message       := 'Lenghth <> 2';
            l_error_element := '05';
            p_success_out   := FALSE;
            EXIT;
          ELSIF l_elment_table(tab_index) NOT IN
                ('21', '22', '23', '24', '25', '35', '36', 'ZZ') THEN
            l_message       := 'Not Valid ID Qualifier';
            l_error_element := '05';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 2 */
        ELSIF tab_index = 6 THEN
          IF length(l_elment_table(tab_index)) <> 15 THEN
            l_message       := 'Lenghth <> 15';
            l_error_element := '06';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 15 */
        
          IF NOT
              wf_valid_trading_partner(l_elment_table(5), l_elment_table(6)) THEN
            l_message       := 'Not valid Partner';
            l_error_element := '06';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* NOT wf_valid_trading_partner (
                                                                           l_elment_table (5),
                                                                           l_elment_table (6)
                                                                          ) */
        ELSIF tab_index = 7 THEN
          IF length(l_elment_table(tab_index)) <> 2 THEN
            l_message       := 'Lenghth <> 2';
            l_error_element := '07';
            p_success_out   := FALSE;
            EXIT;
          ELSIF l_elment_table(tab_index) NOT IN
                ('21', '22', '23', '24', '25', '35', '36', 'ZZ') THEN
            l_message       := 'Not Valid ID Qualifier';
            l_error_element := '07';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 2 */
        ELSIF tab_index = 8 THEN
          IF length(l_elment_table(tab_index)) <> 15 THEN
            l_message       := 'Lenghth <> 15';
            l_error_element := '08';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 15 */
        ELSIF tab_index = 9 THEN
          IF length(l_elment_table(tab_index)) <> 6 THEN
            l_message       := 'Lenghth <> 6';
            l_error_element := '09';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 6 */
        ELSIF tab_index = 10 THEN
          IF length(l_elment_table(tab_index)) <> 4 THEN
            l_message       := 'Lenghth <> 4';
            l_error_element := '109';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 4 */
        ELSIF tab_index = 11 THEN
          IF length(l_elment_table(tab_index)) <> 1 THEN
            l_message       := 'Lenghth <> 1';
            l_error_element := '11';
            p_success_out   := FALSE;
            EXIT;
          ELSIF l_elment_table(tab_index) <> 'U' THEN
            l_message       := 'Not Valid Interchange Control Standard';
            l_error_element := '11';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 1 */
        ELSIF tab_index = 12 THEN
          IF length(l_elment_table(tab_index)) <> 5 THEN
            l_message       := 'Lenghth <> 5';
            l_error_element := '12';
            p_success_out   := FALSE;
            EXIT;
            --          ELSIF l_elment_table(tab_index) <> '00401' THEN
          ELSIF l_elment_table(tab_index) NOT IN
                ('00401', '00305', '00304') THEN
            l_message       := 'This Version Is Not Supported';
            l_error_element := '12';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 5 */
        ELSIF tab_index = 13 THEN
          IF length(l_elment_table(tab_index)) <> 9 THEN
            l_message       := 'Lenghth <> 9';
            l_error_element := '13';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 9 */
        ELSIF tab_index = 14 THEN
          IF length(l_elment_table(tab_index)) <> 1 THEN
            l_message       := 'Lenghth <> 1';
            l_error_element := '14';
            p_success_out   := FALSE;
            EXIT;
          ELSIF l_elment_table(tab_index) NOT IN ('0', '1') THEN
            l_message       := 'Not Valid Acknowledgement Request';
            l_error_element := '14';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* ENGTH (l_elment_table (tab_index)) <> 1 */
        ELSIF tab_index = 15 THEN
          IF length(l_elment_table(tab_index)) <> 1 THEN
            l_message       := 'Lenghth <> 1';
            l_error_element := '15';
            p_success_out   := FALSE;
            EXIT;
          ELSIF l_elment_table(tab_index) NOT IN ('T', 'P') THEN
            l_message       := 'Not Valid Test Indicator';
            l_error_element := '15';
            p_success_out   := FALSE;
            EXIT;
            -- Version W Start
            /*ELSIF (p_tran_type='T' and l_elment_table(tab_index)= 'P') THEN
              l_message       := 'Expecting Test Indicator as T';
              l_error_element := '15';
              p_success_out   := FALSE;
              EXIT;
            */
          ELSIF (p_tran_type = 'P' AND l_elment_table(tab_index) = 'T') THEN
            l_message       := 'Expecting Prod Indicator as P';
            l_error_element := '15';
            p_success_out   := FALSE;
            EXIT;
            -- Version W End
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 1 */
        
        ELSIF tab_index = 16 THEN
          IF length(l_elment_table(tab_index)) <> 1 THEN
            l_message       := 'Lenghth <> 1';
            l_error_element := '16';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 1 */
        END IF; /* tab_index = 1 */
      END LOOP; /* tab_index IN 1 .. l_elment_table.COUNT */
    
      --> if any of element is not valied one, then
      --> generate error mail.
      IF NOT p_success_out THEN
        wp_send_error_mail(l_error_seg, l_error_element, l_message,
                           p_line_in, p_mail_add_in);
      END IF; /* NOT p_success_out */
    END wp_verify_isa_seg;
  
    --> This procedure validates GS elements.
    --> This procedure takes line in file that has GS segment
    ---> as one in parameter and one boolean out parameter that is
    --> set to true or false based on out come of the proeceure.
    --> If there is error in element valus of this segment
    --> it generates eamil and sets the sucess_out to FALSE.
  
    PROCEDURE wp_verify_gs_seg
    (
      p_line_in     VARCHAR2
     ,l_success_out OUT BOOLEAN
    ) IS
      l_message       VARCHAR2(2000);
      l_error_seg     VARCHAR2(5) := 'GS';
      l_error_element VARCHAR2(3) := 0;
    BEGIN
      --> read element values into plsql table
      p_success_out := TRUE;
      wsaklnutil.wp_load_elements_into_pltable(p_line_in, l_elm_sep,
                                               l_seg_sep, l_elment_table,
                                               l_success_out, l_message_out);
    
      --> validate all elements
      FOR tab_index IN 1 .. l_elment_table.count
      LOOP
        IF tab_index = 1 THEN
          IF length(l_elment_table(tab_index)) <> 2 THEN
            l_message       := 'Lenghth <> 2';
            l_error_element := '01';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* LENGTH (l_elment_table (tab_index)) <> 2 */
        ELSIF tab_index = 2 THEN
          IF length(l_elment_table(tab_index)) NOT BETWEEN 2 AND 15 THEN
            l_message       := 'Lenghth is not in range';
            l_error_element := '02';
            p_success_out   := FALSE;
            EXIT;
          END IF;
          /* LENGTH (l_elment_table (tab_index)) NOT BETWEEN 2 AND 15 */
        ELSIF tab_index = 3 THEN
          IF length(l_elment_table(tab_index)) NOT BETWEEN 2 AND 15 THEN
            l_message       := 'Lenghth is not in range';
            l_error_element := '03';
            p_success_out   := FALSE;
            EXIT;
          END IF;
          /* LENGTH (l_elment_table (tab_index)) NOT BETWEEN 2 AND 15 */
        ELSIF tab_index = 4 THEN
          IF length(l_elment_table(tab_index)) <> 8 THEN
            l_message       := 'Lenghth <> 8';
            l_error_element := '04';
            p_success_out   := FALSE;
            EXIT;
          END IF;
          /* LENGTH (l_elment_table (tab_index)) NOT BETWEEN 2 AND 15 */
        ELSIF tab_index = 5 THEN
          IF length(l_elment_table(tab_index)) NOT BETWEEN 4 AND 8 THEN
            l_message       := 'Lenghth is not in range';
            l_error_element := '05';
            p_success_out   := FALSE;
            EXIT;
          END IF;
          /* LENGTH (l_elment_table (tab_index)) NOT BETWEEN 4 AND 8 */
        ELSIF tab_index = 6 THEN
          IF length(l_elment_table(tab_index)) NOT BETWEEN 1 AND 9 THEN
            l_message       := 'Lenghth is not in range';
            l_error_element := '06';
            p_success_out   := FALSE;
            EXIT;
          END IF;
          /* LENGTH (l_elment_table (tab_index)) NOT BETWEEN 1 AND 9 */
        ELSIF tab_index = 7 THEN
          IF length(l_elment_table(tab_index)) NOT BETWEEN 1 AND 2 THEN
            l_message       := 'Lenghth is not in range';
            l_error_element := '07';
            p_success_out   := FALSE;
            EXIT;
          ELSIF TRIM(l_elment_table(tab_index)) <> 'X' THEN
            l_message       := 'This version is not supported';
            l_error_element := '07';
            p_success_out   := FALSE;
            EXIT;
          END IF;
          /* LENGTH (l_elment_table (tab_index)) NOT BETWEEN 1 AND 9 */
        ELSIF tab_index = 8 THEN
          IF length(l_elment_table(tab_index)) NOT BETWEEN 1 AND 12 THEN
            l_message       := 'Lenghth is not in range';
            l_error_element := '08';
            p_success_out   := FALSE;
            EXIT;
          ELSIF TRIM(l_elment_table(tab_index)) <> '004010ED0040' THEN
            l_message       := 'This version is not supported';
            l_error_element := '08';
            p_success_out   := FALSE;
            EXIT;
          END IF; /* TRIM (l_elment_table (tab_index)) <> '004010ED0040' */
        END IF; /* IF tab_index = 1 */
      END LOOP; /*  tab_index IN 1 .. l_elment_table.COUNT */
    
      --> if any element is not valied, send error mail
      IF NOT p_success_out THEN
        wp_send_error_mail(l_error_seg, l_error_element, l_message,
                           p_line_in, p_mail_add_in);
      END IF; /* NOT p_success_out */
    END wp_verify_gs_seg;
  
    -->main of  wp_load_incoming_transactions starts here
  BEGIN
    --> check for directory and file parameters
    IF p_dir_in IS NOT NULL THEN
      l_dir_name := p_dir_in;
    END IF; /* p_dir_in IS NOT NULL */
  
    IF p_file_in IS NOT NULL THEN
      l_file_name := p_file_in;
    END IF; /* p_file_in IS NOT NULL */
  
    --> initiate previous segment and line number
    l_previous_seg := c_interchange_cntrl_trl_seg;
    l_line_num     := l_line_num + 1;
    --> open file and read a line
    l_fileid := utl_file.fopen(l_dir_name, l_file_name, 'R');
    wsakfileio.wp_read_next_line(l_fileid, l_eof, l_line, l_success_out,
                                 l_message_out);
  
    WHILE NOT l_eof
    LOOP
      BEGIN
        --> initialize variables if present segment is 'Inter change
        --> control segment'.
        IF substr(l_line, 1, 3) = c_interchange_cntrl_hdr_seg THEN
          l_skip_untill_next_isa := FALSE;
          l_isa_line             := l_line;
          l_line_num             := 1;
          l_elm_sep              := substr(l_line, 4, 1);
          l_comp_sep             := substr(l_line, 104, 1);
          l_seg_sep              := substr(l_line, 106, 1);
          l_segment              := substr(l_line, 1, 3);
          l_skip_untill_next_gs  := FALSE;
        ELSE
          --> capture segment value
          l_segment := substr(l_line, 1, (instr(l_line, l_elm_sep) - 1));
        END IF; /* SUBSTR (l_line, 1, 3) = c_interchange_cntrl_hdr_seg */
      
        l_present_seg := l_segment;
      
        --> calculate segment count
        IF l_present_seg = l_previous_seg THEN
          l_seg_repeat := l_seg_repeat + 1;
        ELSE
          l_seg_repeat := 1;
        END IF; /* l_present_seg = l_previous_seg */
      
        l_error := NULL;
      
        -->check and send error mail  if interchange control segment
        --> sequence is wong and skip untill next interchange control
        --> segment
      
        IF (l_previous_seg = c_interchange_cntrl_trl_seg AND
           l_present_seg <> c_interchange_cntrl_hdr_seg) OR
           (l_present_seg = c_interchange_cntrl_hdr_seg AND
           l_previous_seg <> c_interchange_cntrl_trl_seg) THEN
          wp_send_error_mail(c_interchange_cntrl_hdr_seg, '',
                             'Previous segment is not IEA', l_line,
                             p_mail_add_in);
          l_skip_untill_next_isa := TRUE;
        ELSIF (l_previous_seg = c_interchange_cntrl_trl_seg AND
              l_present_seg = c_interchange_cntrl_hdr_seg) OR
              (l_present_seg = c_interchange_cntrl_hdr_seg AND
              l_previous_seg = c_interchange_cntrl_trl_seg) THEN
          l_skip_untill_next_isa := FALSE;
        END IF; /* (    l_previous_seg = c_interchange_cntrl_trl_seg
                                          AND l_present_seg <> c_interchange_cntrl_hdr_seg
                                     )..*/
        --
        l_error := NULL;
      
        -->check and send error mail  if functional group trailer segment
        --> sequence is wong and skip untill next functional group
        --> trailer segment
      
        IF NOT l_skip_untill_next_gs AND
           ((l_previous_seg = c_functional_gruop_trl_seg AND
           l_present_seg NOT IN
           (c_functional_gruop_hdr_seg, c_interchange_cntrl_trl_seg)) OR
           (l_present_seg = c_functional_gruop_hdr_seg AND
           l_previous_seg NOT IN
           (c_functional_gruop_trl_seg, c_interchange_cntrl_hdr_seg)) OR
           (l_previous_seg = c_interchange_cntrl_hdr_seg AND
           l_present_seg <> c_functional_gruop_hdr_seg)) THEN
          wp_send_error_mail(c_functional_gruop_hdr_seg, '',
                             'Previous segment is not IEA', l_line,
                             p_mail_add_in);
          -- dbms_output.put_line('Error');
          l_skip_untill_next_gs := TRUE;
        ELSIF (l_previous_seg = c_interchange_cntrl_trl_seg AND
              l_present_seg = c_interchange_cntrl_hdr_seg) THEN
          l_skip_untill_next_gs := FALSE;
        END IF; /* NOT l_skip_untill_next_gs
                                     AND (   (    l_previous_seg = c_functional_gruop_trl_seg
                                     AND l_present_seg NOT IN
                                        (c_functional_gruop_hdr_seg,
                                         c_interchange_cntrl_trl_seg ..*/
      
        --> do element value check for interchange control headr
        --> segment. If there is error in any of the elements
        --> skip untill next interchange control headr segment
        --> and send error mail
      
        IF NOT l_skip_untill_next_isa AND
           l_present_seg = c_interchange_cntrl_hdr_seg THEN
          wp_verify_isa_seg(l_isa_line, l_success_out);
        
          IF NOT l_success_out THEN
            l_skip_untill_next_isa := TRUE;
          ELSE
            l_skip_untill_next_isa := FALSE;
          END IF; /*  NOT l_skip_untill_next_isa
                                                                                                                                                             AND l_present_seg = c_interchange_cntrl_hdr_seg */
        END IF; /*l_present_seg =   c_interchange_cntrl_hdr_seg*/
      
        --->
      
        IF NOT l_skip_untill_next_isa THEN
          --> do element value check for functional group headr
          --> segment. If there is error in any of the elements
          --> skip untill next functional group headr headr segment
          --> and send error mail
        
          IF NOT l_skip_untill_next_gs AND
             substr(l_line, 1, 2) = c_functional_gruop_hdr_seg THEN
            wp_verify_gs_seg(l_gs_line, l_success_out);
          
            IF NOT l_success_out THEN
              l_skip_untill_next_gs := TRUE;
            ELSE
              l_skip_untill_next_gs := FALSE;
            END IF; /* NOT l_success_out */
          
            l_gs_line  := l_line;
            l_line_num := 2;
          END IF; /* NOT l_skip_untill_next_gs
                                             AND SUBSTR (l_line, 1, 2) = c_functional_gruop_hdr_seg */
        
          IF NOT l_skip_untill_next_gs THEN
            --> if present segment is first inter change transaction
            --> header segment(ST), create new document sequence
            IF substr(l_line, 1, 2) = c_interchange_trn_hdr_seg AND
               l_seg_repeat = 1 THEN
              SELECT ws_document_seq.nextval INTO l_dcmt_seqno FROM dual;
              wsaklnutil.wp_load_elements_into_pltable(l_line, l_elm_sep,
                                                       l_seg_sep,
                                                       l_elment_table,
                                                       l_success_out,
                                                       l_message_out);
              --> get transaction type for ST01 element.
              l_type := l_elment_table(1);
              --> Assign line number
              l_line_num := 3; --> since ST is always third line
              --> after splitting transactions.
            
              --> if present segment is inter change transaction
              --> header segment(ST) , always insert ISA,GS segments
              --> before it.
            
              --> load work load area (swtewls, swtewle) with
              --> interchange control header segment
            
              --> load segment table(with ISA segment)
              INSERT INTO swtewls
                (swtewls_dcmt_seq
                ,swtewls_type
                ,swtewls_line_num
                ,swtewls_seg)
              VALUES
                (l_dcmt_seqno
                ,l_type
                ,1
                ,c_interchange_cntrl_hdr_seg);
            
              wsaklnutil.wp_load_elements_into_pltable(l_isa_line,
                                                       l_elm_sep, l_seg_sep,
                                                       l_elment_table,
                                                       l_success_out,
                                                       l_message_out);
              l_interchange_cntrl_nbr := l_elment_table(13);
            
              --> load element table(with ISA segment)
              FOR tab_index IN 1 .. l_elment_table.count
              LOOP
                INSERT INTO swtewle
                  (swtewle_dcmt_seqno
                  ,swtewle_line_num
                  ,swtewle_elm_seq
                  ,swtewle_elm_value)
                VALUES
                  (l_dcmt_seqno
                  ,1
                  ,tab_index
                  ,l_elment_table(tab_index));
              END LOOP;
            
              --> load work load area (swtewls, swtewle) with
              --> functional group header segment(GS)
            
              --> load segment table(with GS segment)
              INSERT INTO swtewls
                (swtewls_dcmt_seq
                ,swtewls_type
                ,swtewls_line_num
                ,swtewls_seg)
              VALUES
                (l_dcmt_seqno
                ,l_type
                ,2
                ,c_functional_gruop_hdr_seg);
            
              --> load element table(with GS segment)
              wsaklnutil.wp_load_elements_into_pltable(l_gs_line, l_elm_sep,
                                                       l_seg_sep,
                                                       l_elment_table,
                                                       l_success_out,
                                                       l_message_out);
              l_grp_cntrl_nbr := l_elment_table(6);
            
              FOR tab_index IN 1 .. l_elment_table.count
              LOOP
                INSERT INTO swtewle
                  (swtewle_dcmt_seqno
                  ,swtewle_line_num
                  ,swtewle_elm_seq
                  ,swtewle_elm_value)
                VALUES
                  (l_dcmt_seqno
                  ,2
                  ,tab_index
                  ,l_elment_table(tab_index));
              END LOOP;
            
              --> load work load area (swtewls, swtewle) with
              --> interchange transaction header segment(ST)
            
              --> load segment table(with ST segment)
              INSERT INTO swtewls
                (swtewls_dcmt_seq
                ,swtewls_type
                ,swtewls_line_num
                ,swtewls_seg)
              VALUES
                (l_dcmt_seqno
                ,l_type
                ,3
                ,c_interchange_trn_hdr_seg);
            
              --> load element table(with ST segment)
              wsaklnutil.wp_load_elements_into_pltable(l_line, l_elm_sep,
                                                       l_seg_sep,
                                                       l_elment_table,
                                                       l_success_out,
                                                       l_message_out);
            
              FOR tab_index IN 1 .. l_elment_table.count
              LOOP
                INSERT INTO swtewle
                  (swtewle_dcmt_seqno
                  ,swtewle_line_num
                  ,swtewle_elm_seq
                  ,swtewle_elm_value)
                VALUES
                  (l_dcmt_seqno
                  ,3
                  ,tab_index
                  ,l_elment_table(tab_index));
              END LOOP;
            END IF; /*  SUBSTR (l_line, 1, 2) = c_interchange_trn_hdr_seg
                                                                                                                                                                                     AND l_seg_repeat = 1 */
          
            --> if the present segment is IEA then
            --> update element values of populated IEA with
            --> actual IEA segment values
            IF l_segment = c_interchange_cntrl_trl_seg AND
               l_dcmt_seqno IS NOT NULL THEN
              wsaklnutil.wp_load_elements_into_pltable(l_line, l_elm_sep,
                                                       l_seg_sep,
                                                       l_elment_table,
                                                       l_success_out,
                                                       l_message_out);
            
              UPDATE swtewle a
                 SET a.swtewle_elm_value = l_elment_table(1)
               WHERE a.swtewle_dcmt_seqno = l_dcmt_seqno
                 AND a.swtewle_elm_seq = 1
                 AND a.swtewle_line_num IN
                     (SELECT swtewls_line_num
                        FROM swtewls b
                       WHERE b.swtewls_dcmt_seq = l_dcmt_seqno
                         AND b.swtewls_seg IN (c_interchange_cntrl_trl_seg));
            
              UPDATE swtewle a
                 SET a.swtewle_elm_value = l_elment_table(2)
               WHERE a.swtewle_dcmt_seqno = l_dcmt_seqno
                 AND a.swtewle_elm_seq = 2
                 AND a.swtewle_line_num IN
                     (SELECT swtewls_line_num
                        FROM swtewls b
                       WHERE b.swtewls_dcmt_seq = l_dcmt_seqno
                         AND b.swtewls_seg IN (c_interchange_cntrl_trl_seg));
              -- dbms_output.put_line('Need to update '||c_interchange_cntrl_trl_seg);
            END IF; /*     l_segment = c_interchange_cntrl_trl_seg
                                                         AND l_dcmt_seqno IS NOT NULL */
          
            --> if present segment is other than ISA, IEA, GS, GE
            --> or if they or one of them and are repeated..
            IF (l_segment NOT IN
               (c_interchange_cntrl_hdr_seg, c_functional_gruop_hdr_seg,
                 c_interchange_trn_hdr_seg, c_interchange_cntrl_trl_seg,
                 c_functional_gruop_trl_seg, c_interchange_trn_trl_seg)) OR
               (l_segment IN
               (c_interchange_cntrl_hdr_seg, c_functional_gruop_hdr_seg,
                 c_interchange_trn_hdr_seg, c_interchange_cntrl_trl_seg,
                 c_functional_gruop_trl_seg, c_interchange_trn_trl_seg) AND
               l_seg_repeat > 1) THEN
              --> ..and segment is SE ( since this segment is repeated)
              --> delete programtically added previous GE, IEA segment..
              IF l_segment = c_interchange_trn_trl_seg THEN
                DELETE FROM swtewle a
                 WHERE a.swtewle_dcmt_seqno = l_dcmt_seqno
                   AND a.swtewle_line_num IN
                       (SELECT swtewls_line_num
                          FROM swtewls b
                         WHERE b.swtewls_dcmt_seq = l_dcmt_seqno
                           AND b.swtewls_seg IN
                               (c_functional_gruop_trl_seg,
                                c_interchange_cntrl_trl_seg));
              
                DELETE FROM swtewls a
                 WHERE a.swtewls_dcmt_seq = l_dcmt_seqno
                   AND a.swtewls_seg IN
                       (c_functional_gruop_trl_seg,
                        c_interchange_cntrl_trl_seg);
              END IF; /* IF l_segment = c_interchange_trn_trl_seg
                                                             THEN */
            
              --> ..and inset present SE segment and element values
              INSERT INTO swtewls
                (swtewls_dcmt_seq
                ,swtewls_type
                ,swtewls_line_num
                ,swtewls_seg)
              VALUES
                (l_dcmt_seqno
                ,l_type
                ,l_line_num
                ,l_segment);
            
              wsaklnutil.wp_load_elements_into_pltable(l_line, l_elm_sep,
                                                       l_seg_sep,
                                                       l_elment_table,
                                                       l_success_out,
                                                       l_message_out);
            
              FOR tab_index IN 1 .. l_elment_table.count
              LOOP
                INSERT INTO swtewle
                  (swtewle_dcmt_seqno
                  ,swtewle_line_num
                  ,swtewle_elm_seq
                  ,swtewle_elm_value)
                VALUES
                  (l_dcmt_seqno
                  ,l_line_num
                  ,tab_index
                  ,l_elment_table(tab_index));
              END LOOP;
            
              --> insert GE, and IEA segments
              IF l_segment = c_interchange_trn_trl_seg THEN
                INSERT INTO swtewls
                  (swtewls_dcmt_seq
                  ,swtewls_type
                  ,swtewls_line_num
                  ,swtewls_seg)
                VALUES
                  (l_dcmt_seqno
                  ,l_type
                  ,l_line_num + 1
                  ,c_functional_gruop_trl_seg);
              
                INSERT INTO swtewle
                  (swtewle_dcmt_seqno
                  ,swtewle_line_num
                  ,swtewle_elm_seq
                  ,swtewle_elm_value)
                VALUES
                  (l_dcmt_seqno
                  ,l_line_num + 1
                  ,1
                  ,1);
              
                INSERT INTO swtewle
                  (swtewle_dcmt_seqno
                  ,swtewle_line_num
                  ,swtewle_elm_seq
                  ,swtewle_elm_value)
                VALUES
                  (l_dcmt_seqno
                  ,l_line_num + 1
                  ,2
                  ,l_grp_cntrl_nbr);
              
                INSERT INTO swtewls
                  (swtewls_dcmt_seq
                  ,swtewls_type
                  ,swtewls_line_num
                  ,swtewls_seg)
                VALUES
                  (l_dcmt_seqno
                  ,l_type
                  ,l_line_num + 2
                  ,c_interchange_cntrl_trl_seg);
              
                INSERT INTO swtewle
                  (swtewle_dcmt_seqno
                  ,swtewle_line_num
                  ,swtewle_elm_seq
                  ,swtewle_elm_value)
                VALUES
                  (l_dcmt_seqno
                  ,l_line_num + 2
                  ,1
                  ,'00001');
              
                INSERT INTO swtewle
                  (swtewle_dcmt_seqno
                  ,swtewle_line_num
                  ,swtewle_elm_seq
                  ,swtewle_elm_value)
                VALUES
                  (l_dcmt_seqno
                  ,l_line_num + 2
                  ,2
                  ,l_interchange_cntrl_nbr);
              END IF; /* l_segment = c_interchange_trn_trl_seg */
              --> if the present segment is first SE segment then
              --> delete and insert GE and IEA segments..
            ELSIF l_segment = c_interchange_trn_trl_seg THEN
              DELETE FROM swtewle a
               WHERE a.swtewle_dcmt_seqno = l_dcmt_seqno
                 AND a.swtewle_line_num IN
                     (SELECT swtewls_line_num
                        FROM swtewls b
                       WHERE b.swtewls_dcmt_seq = l_dcmt_seqno
                         AND b.swtewls_seg IN
                             (c_functional_gruop_trl_seg,
                              c_interchange_cntrl_trl_seg));
            
              DELETE FROM swtewls a
               WHERE a.swtewls_dcmt_seq = l_dcmt_seqno
                 AND a.swtewls_seg IN
                     (c_functional_gruop_trl_seg,
                      c_interchange_cntrl_trl_seg);
            
              --> insert SE segment..
              INSERT INTO swtewls
                (swtewls_dcmt_seq
                ,swtewls_type
                ,swtewls_line_num
                ,swtewls_seg)
              VALUES
                (l_dcmt_seqno
                ,l_type
                ,l_line_num
                ,l_segment);
            
              wsaklnutil.wp_load_elements_into_pltable(l_line, l_elm_sep,
                                                       l_seg_sep,
                                                       l_elment_table,
                                                       l_success_out,
                                                       l_message_out);
            
              --> ..insert SE elements
              FOR tab_index IN 1 .. l_elment_table.count
              LOOP
                INSERT INTO swtewle
                  (swtewle_dcmt_seqno
                  ,swtewle_line_num
                  ,swtewle_elm_seq
                  ,swtewle_elm_value)
                VALUES
                  (l_dcmt_seqno
                  ,l_line_num
                  ,tab_index
                  ,l_elment_table(tab_index));
              END LOOP;
            
              --> insert GE segment
              INSERT INTO swtewls
                (swtewls_dcmt_seq
                ,swtewls_type
                ,swtewls_line_num
                ,swtewls_seg)
              VALUES
                (l_dcmt_seqno
                ,l_type
                ,l_line_num + 1
                ,c_functional_gruop_trl_seg);
            
              --> insert GE elements
              INSERT INTO swtewle
                (swtewle_dcmt_seqno
                ,swtewle_line_num
                ,swtewle_elm_seq
                ,swtewle_elm_value)
              VALUES
                (l_dcmt_seqno
                ,l_line_num + 1
                ,1
                ,1);
            
              INSERT INTO swtewle
                (swtewle_dcmt_seqno
                ,swtewle_line_num
                ,swtewle_elm_seq
                ,swtewle_elm_value)
              VALUES
                (l_dcmt_seqno
                ,l_line_num + 1
                ,2
                ,l_grp_cntrl_nbr);
            
              --> insert IEA segment
              INSERT INTO swtewls
                (swtewls_dcmt_seq
                ,swtewls_type
                ,swtewls_line_num
                ,swtewls_seg)
              VALUES
                (l_dcmt_seqno
                ,l_type
                ,l_line_num + 2
                ,c_interchange_cntrl_trl_seg);
            
              --> insert IEA elements
              INSERT INTO swtewle
                (swtewle_dcmt_seqno
                ,swtewle_line_num
                ,swtewle_elm_seq
                ,swtewle_elm_value)
              VALUES
                (l_dcmt_seqno
                ,l_line_num + 2
                ,1
                ,'00001');
            
              INSERT INTO swtewle
                (swtewle_dcmt_seqno
                ,swtewle_line_num
                ,swtewle_elm_seq
                ,swtewle_elm_value)
              VALUES
                (l_dcmt_seqno
                ,l_line_num + 2
                ,2
                ,l_interchange_cntrl_nbr);
            END IF; /* (l_segment NOT IN (c_interchange_cntrl_hdr_seg,
                                                      c_functional_gruop_hdr_seg,
                                                      c_interchange_trn_hdr_seg,..*/
          
            -->if present segment is GE segment then
            --> insert the present segment
            --> and update previous GE element values
            --> with present GE element values
            IF l_segment = c_functional_gruop_trl_seg THEN
              wsaklnutil.wp_load_elements_into_pltable(l_line, l_elm_sep,
                                                       l_seg_sep,
                                                       l_elment_table,
                                                       l_success_out,
                                                       l_message_out);
            
              FOR tab_index IN 1 .. l_elment_table.count
              LOOP
              
                /*                        UPDATE swtewle a
                  SET swtewle_elm_value = l_elment_table (tab_index)
                WHERE a.swtewle_dcmt_seqno = l_dcmt_seqno
                  AND a.swtewle_elm_seq = tab_index
                  AND a.swtewle_line_num IN
                            (SELECT b.swtewls_line_num
                               FROM swtewls b
                              WHERE b.swtewls_dcmt_seq =
                                                        l_dcmt_seqno
                                AND b.swtewls_seg =
                                          c_functional_gruop_trl_seg);*/
                UPDATE swtewle a
                   SET swtewle_elm_value = l_elment_table(tab_index)
                 WHERE a.swtewle_dcmt_seqno IN
                       (SELECT DISTINCT (a.swtewle_dcmt_seqno) dcmt
                          FROM swtewle a
                         WHERE a.swtewle_line_num = 2
                           AND a.swtewle_elm_seq = 6
                           AND a.swtewle_elm_value IN
                               (SELECT b.swtewle_elm_value
                                  FROM swtewle b
                                 WHERE b.swtewle_dcmt_seqno = l_dcmt_seqno
                                   AND b.swtewle_line_num = 2
                                   AND b.swtewle_elm_seq = 6))
                   AND a.swtewle_elm_seq = tab_index
                   AND a.swtewle_line_num IN
                       (SELECT b.swtewls_line_num
                          FROM swtewls b
                         WHERE b.swtewls_dcmt_seq = a.swtewle_dcmt_seqno
                           AND b.swtewls_seg = c_functional_gruop_trl_seg);
              
                NULL;
              END LOOP;
            
              COMMIT;
            END IF; /* l_segment = c_functional_gruop_trl_seg */
          END IF; /* l_skip_untill_next_gs */
        END IF; /* not l_skip_untill_next_isa */
      
        wsakfileio.wp_read_next_line(l_fileid, l_eof, l_line, l_success_out,
                                     l_message_out);
        l_line_num     := l_line_num + 1;
        l_previous_seg := l_present_seg;
      END;
    
      COMMIT;
    END LOOP; /* NOT l_eof */
  
    COMMIT;
    utl_file.fclose(l_fileid);
  EXCEPTION
    WHEN utl_file.invalid_path THEN
      p_success_out := FALSE;
      p_message_out := ('invalid path');
    WHEN utl_file.invalid_mode THEN
      p_success_out := FALSE;
      p_message_out := ('invalid mode');
    WHEN utl_file.invalid_filehandle THEN
      p_success_out := FALSE;
      p_message_out := ('invalid filehandle');
    WHEN utl_file.invalid_operation THEN
      p_success_out := FALSE;
      p_message_out := ('invalid operation');
    WHEN utl_file.write_error THEN
      p_success_out := FALSE;
      p_message_out := ('write error');
    WHEN utl_file.internal_error THEN
      p_success_out := FALSE;
      p_message_out := ('internal error');
    WHEN OTHERS THEN
      p_success_out := FALSE;
      p_message_out := (substr(SQLERRM, 1, 200));
      utl_file.fclose(l_fileid);
  END wp_load_incoming_transactions;

  /* The following functions an dprocedures support wp_load_outbound_ack.
  They were moved here for the transient project so that wsakedi_transient
  could reference them.*/
  /*
    FUNCTION wf_ak3_exists returns if already ak3 segment exists.
  
    parameters:
    p_dcmt_in document sequence number
    p_seg_id_in segment
    p_pos_in segment position in
  */

  FUNCTION wf_ak3_exists_db
  (
    p_dcmt_in   swtewls.swtewls_dcmt_seq%TYPE
   ,p_seg_id_in VARCHAR2
   ,p_pos_in    VARCHAR2
  ) RETURN BOOLEAN IS
    l_result BOOLEAN;
  
    CURSOR ak3_seg_c IS
      SELECT 'x'
        FROM swteake a
            ,swteake b
            ,swteake c
       WHERE a.swteake_dcmt_seqno = b.swteake_dcmt_seqno
         AND a.swteake_line_num = b.swteake_line_num
         AND c.swteake_dcmt_seqno = a.swteake_dcmt_seqno
         AND c.swteake_line_num = a.swteake_line_num
         AND a.swteake_dcmt_seqno = p_dcmt_in
         AND (a.swteake_elm_seq = 1 AND a.swteake_elm_value = p_seg_id_in)
         AND (b.swteake_elm_seq = 2 AND b.swteake_elm_value = p_pos_in)
         AND (c.swteake_elm_value <> '7' AND c.swteake_elm_seq = 4)
         AND a.swteake_line_num IN
             (SELECT c.swteaks_line_num
                FROM swteaks c
               WHERE c.swteaks_dcmt_seq = p_dcmt_in
                 AND c.swteaks_seg = gc_data_segment_note);
  BEGIN
    l_result := FALSE;
  
    FOR ak3_seg_rec IN ak3_seg_c
    LOOP
      l_result := ak3_seg_c%FOUND;
    END LOOP;
  
    RETURN l_result;
  END wf_ak3_exists_db;

  /*
    PROCEDURE wp_build_ak3_seg builds segment level acknowledgement.
  
    parameters:
    p_dcmt_in document sequence number
    p_seg_id_in segment
    p_pos_in segment position in
    p_error_code_in error coede as per ASC x12 nomenculture
  */
  PROCEDURE wp_build_ak3_seg_db
  (
    p_dcmt_in       swtewls.swtewls_dcmt_seq%TYPE
   ,p_seg_in        VARCHAR2
   ,p_pos_in        NUMBER
   ,p_error_code_in VARCHAR2
  ) IS
    l_current_line NUMBER;
  BEGIN
    l_current_line := wf_get_line_numb_db(p_dcmt_in);
    wp_insert_swteaks_db(p_dcmt_in, l_current_line, gc_data_segment_note);
    wp_insert_swteake_db(p_dcmt_in, l_current_line, 1, p_seg_in);
    wp_insert_swteake_db(p_dcmt_in, l_current_line, 2, to_char(p_pos_in));
    wp_insert_swteake_db(p_dcmt_in, l_current_line, 3, '');
    wp_insert_swteake_db(p_dcmt_in, l_current_line, 4, p_error_code_in);
  END wp_build_ak3_seg_db;

  /*
    PROCEDURE wp_build_ak4_seg_db builds element level acknowledgement.
  
    parameters:
    p_dcmt_in document sequence number
    p_seg_id_in segment
    p_pos_in segment position in
    p_error_code_in error coede as per ASC x12 nomenculture
  */

  PROCEDURE wp_build_ak4_seg_db
  (
    p_dcmt_in       swtewls.swtewls_dcmt_seq%TYPE
   ,p_elm_seq_in    swtewle.swtewle_elm_seq%TYPE
   ,p_error_code_in VARCHAR2
   ,p_elm_val_in    swtewle.swtewle_elm_value%TYPE
  ) IS
    l_current_line NUMBER;
  
  BEGIN
    l_current_line := wf_get_line_numb_db(p_dcmt_in);
    wp_insert_swteaks_db(p_dcmt_in, l_current_line, gc_data_element_note);
    wp_insert_swteake_db(p_dcmt_in, l_current_line, 1,
                         to_char(p_elm_seq_in));
    wp_insert_swteake_db(p_dcmt_in, l_current_line, 2, NULL);
    wp_insert_swteake_db(p_dcmt_in, l_current_line, 3, p_error_code_in);
    wp_insert_swteake_db(p_dcmt_in, l_current_line, 4, p_elm_val_in);
    NULL;
  END wp_build_ak4_seg_db;

  /*
    FUNCTION wf_get_line_numb_db gets next line number to write ack. segment.
    parameters:
    p_dcmt_in document sequence number
  */

  FUNCTION wf_get_line_numb_db(p_dcmt_in swtewls.swtewls_dcmt_seq%TYPE)
    RETURN NUMBER IS
    l_result NUMBER;
  
    CURSOR line_numb_c IS
      SELECT MAX(swteaks.swteaks_line_num) + 1 line_number
        FROM swteaks
       WHERE swteaks.swteaks_dcmt_seq = p_dcmt_in;
  BEGIN
    FOR line_numb_rec IN line_numb_c
    LOOP
      l_result := line_numb_rec.line_number;
    END LOOP; /*line_numb_c*/
  
    RETURN l_result;
  END wf_get_line_numb_db;

  /*
    Proceudre wp_insert_swteaks_db inserts outbound ack. segment table(swteaks).
    parameters:
    p_dcmt_in  Document sequence number
    p_line_in  line number
    p_seg_in_Segment to be loaded
  */

  PROCEDURE wp_insert_swteaks_db
  (
    p_dcmt_in swteaks.swteaks_dcmt_seq%TYPE
   ,p_line_in swteaks.swteaks_line_num%TYPE
   ,p_seg_in  swteaks.swteaks_seg%TYPE
  ) IS
  BEGIN
    INSERT INTO swteaks
      (swteaks_dcmt_seq
      ,swteaks_line_num
      ,swteaks_seg)
    VALUES
      (p_dcmt_in
      ,p_line_in
      ,p_seg_in);
  END wp_insert_swteaks_db;

  /*
    Proceudre wp_insert_swteake_db inserts outbound ack. element table(swteake).
    parameters:
    p_dcmt_in  Document sequence number
    p_line_in  line number
    p_seg_in_Segment to be loaded
  */

  PROCEDURE wp_insert_swteake_db
  (
    p_dcmt_in      swteaks.swteaks_dcmt_seq%TYPE
   ,p_line_in      swteaks.swteaks_line_num%TYPE
   ,p_elm_seq_in   swteake.swteake_elm_seq%TYPE
   ,p_elm_value_in swteake.swteake_elm_value%TYPE
  ) IS
  BEGIN
    INSERT INTO swteake
      (swteake_dcmt_seqno
      ,swteake_line_num
      ,swteake_elm_seq
      ,swteake_elm_value)
    VALUES
      (p_dcmt_in
      ,p_line_in
      ,p_elm_seq_in
      ,p_elm_value_in);
  END wp_insert_swteake_db;

  PROCEDURE wp_load_outbound_ack
  (
    p_test_or_prod_ind VARCHAR2
   ,p_message_out      OUT VARCHAR2
   ,p_success_out      OUT BOOLEAN
  ) IS
  
    --***********************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wsakedi.wp_load_outbound_ack
    --  Process Associated : EDI
    --  Business Logic :
    --   This procedure reads incoming transaction from temporary
    --   work load area, checks for syntax and semantics of the
    --   incominng transactions, generates acknowledgments and
    --   loads into temporary acknowledgment tables(swteaks, swteake).
    --  Documentation Links:
    --  G:\Documentation\Technical Specifications\EDI\
    --   Q202074 EDI Tool replacement\out997_technical_specifications.doc
    --
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User       Reason For Change
    -- -----  ---  ---------  -----------  ------     -----------------------
    --  n/a   A   B5-002941  20-AUG-2002  VBANGALO   Initial Creation.
    --  n/a   K   B5-003300  02-SEP-2003  VBANGALO   Modified code to initialize
    --                                               previous segment and previous
    --                                               sequence variables.
    --  n/a   W   O7-000396  18-DEC-2006  WHURLEY    Added inbound parameter parameter for test_prod_ind
    --                                               so 997's can be generated with 'T' or 'P' in ISA segment
    -- Parameter Information:
    -- ------------
    --  p_test_or_prod_ind in parameter   based on Appworx condition, will be 'P' if
    --                                    #test_or_prod is 'prod' and 'T' if test_or_prod
    --                                    is 'test'
    --  p_success_out      out parameter  set to TRUE if process is success
    --                                    set to FALSE if process is failed.
    --  p_message_out      out parameter  message.
    --************************************************************************
    --
    le_exception1 EXCEPTION; --business exception raised when requirement1 is not met
  
    --local variables:
    l_state             VARCHAR2(2000);
    l_message_out       VARCHAR2(2000);
    l_success_out       BOOLEAN;
    l_present_seg       VARCHAR2(10);
    l_present_loop_seg  VARCHAR2(10);
    l_previous_loop_seg VARCHAR2(10);
    l_previous_seg      VARCHAR2(10);
    l_present_seq       VARCHAR2(10);
    l_previous_loop     VARCHAR2(10);
    l_type              VARCHAR2(10);
    l_new_seq           swreseq.swreseq_loop%TYPE;
    l_cur_found         BOOLEAN;
    l_segment_count     NUMBER(5);
    l_loop_count        NUMBER(5);
    l_accepted          BOOLEAN;
    l_repeats           NUMBER;
    c_interchange_cntrl_hdr_seg  CONSTANT CHAR(3) := 'ISA';
    c_interchange_cntrl_trl_seg  CONSTANT CHAR(3) := 'IEA';
    c_functional_gruop_hdr_seg   CONSTANT CHAR(2) := 'GS';
    c_functional_gruop_trl_seg   CONSTANT CHAR(2) := 'GE';
    c_interchange_trn_hdr_seg    CONSTANT CHAR(2) := 'ST';
    c_interchange_trn_trl_seg    CONSTANT CHAR(2) := 'SE';
    c_fnl_group_response_header  CONSTANT CHAR(3) := 'AK1';
    c_tr_set_response_header     CONSTANT CHAR(3) := 'AK2';
    c_tr_set_response_trailer    CONSTANT CHAR(3) := 'AK5';
    c_fnl_group_response_trailer CONSTANT CHAR(3) := 'AK9';
  
    CURSOR swtewls_dcmt_seq_c IS
      SELECT DISTINCT swtewls_dcmt_seq dcmt_seq
        FROM swtewls
       ORDER BY swtewls_dcmt_seq;
  
    --This cursor selects incoming transaction sets
    CURSOR segment_sequence_c(c_dcmt_in swtewls.swtewls_dcmt_seq%TYPE) IS
      SELECT swtewls_dcmt_seq
            ,swtewls_type
            ,swtewls_line_num
            ,swtewls_seg
        FROM swtewls a
       WHERE a.swtewls_dcmt_seq = c_dcmt_in
       ORDER BY a.swtewls_dcmt_seq
               ,a.swtewls_line_num;
  
    CURSOR present_sequence_c
    (
      c_set_id_in    swreseq.swreseq_trans_set_id%TYPE
     ,c_pres_seg_in  swreseq.swreseq_current_segment%TYPE
     ,c_prev_loop_in swreseq.swreseq_loop%TYPE
     ,c_prev_seg_in  swreseq.swreseq_previous_segment%TYPE
    ) IS
      SELECT a.swreseq_new_loop
        FROM swreseq a
       WHERE (a.swreseq_ansi_version IS NULL OR
             a.swreseq_ansi_version = '004010ED0040')
         AND (a.swreseq_trans_set_id IS NULL OR
             a.swreseq_trans_set_id = c_set_id_in)
         AND a.swreseq_current_segment = c_pres_seg_in
         AND a.swreseq_loop = c_prev_loop_in
         AND a.swreseq_previous_segment = c_prev_seg_in;
  
    /*
      FUNCTION wf_element_value gets element value from work load area.
    
      parameters:
      p_dcmt_seq_in document sequence number
      p_line_in  line number
      p_elm_seq_in elemnet sequnece number
    */
    --> function to get element value
    FUNCTION wf_element_value
    (
      p_dcmt_seq_in swtewle.swtewle_dcmt_seqno%TYPE
     ,p_line_in     swtewle.swtewle_line_num%TYPE
     ,p_elm_seq_in  swtewle.swtewle_elm_seq%TYPE
    ) RETURN swtewle.swtewle_elm_value%TYPE IS
      l_result swtewle.swtewle_elm_value%TYPE := NULL;
    
      CURSOR element_value_c IS
        SELECT swtewle_elm_value
          FROM swtewle a
         WHERE a.swtewle_dcmt_seqno = p_dcmt_seq_in
           AND a.swtewle_line_num = p_line_in
           AND a.swtewle_elm_seq = p_elm_seq_in;
    BEGIN
      FOR element_value_rec IN element_value_c
      LOOP
        l_result := element_value_rec.swtewle_elm_value;
      END LOOP;
    
      RETURN l_result;
    END wf_element_value;
  
    /*
      PROCEDURE wp_check_id_elem_value checks vale of element if element type
      is ID. This is done aginst element value rule table(swreelv).
    
      parameters:
      p_ansi_code_in    element value
      p_trans_type_in   transaction type
      p_loop_in         the loop present segment belongs to.
      p_elm_nbr_in      element number(ANSCI value of element)
      p_seg_id_in       segment to which present element belongs.
      p_elm_seq_in      element position
      p_dcmt_seq_in     document sequence
      p_line_in         line number of segment
    */
  
    PROCEDURE wp_check_id_elem_value
    (
      p_ansi_code_in  swtewle.swtewle_elm_value%TYPE
     ,p_trans_type_in swreseq.swreseq_trans_set_id%TYPE
     ,p_loop_in       swreseq.swreseq_loop%TYPE
     ,p_elm_nbr_in    swreelm.swreelm_ansi_elm_nbr%TYPE
     ,p_seg_id_in     swreelm.swreelm_seg_id%TYPE
     ,p_elm_seq_in    swreelm.swreelm_seg_elem%TYPE
     ,p_dcmt_seq_in   NUMBER
     ,p_line_in       VARCHAR2
    ) IS
      l_elm_exists BOOLEAN;
    
      CURSOR element_value_c IS
        SELECT 'x'
          FROM swreelv a
         WHERE (a.swreelv_ansi_version IS NULL OR
               a.swreelv_ansi_version = '004010ED0040')
           AND a.swreelv_ansi_code = p_ansi_code_in
           AND (a.swreelv_trans_set_id IS NULL OR
               a.swreelv_trans_set_id = p_trans_type_in)
           AND (a.swreelv_ansi_loop IS NULL OR
               a.swreelv_ansi_loop = p_loop_in)
           AND a.swreelv_ansi_elem_nbr = p_elm_nbr_in
           AND (a.swreelv_ansi_seg_id IS NULL OR
               a.swreelv_ansi_seg_id = p_seg_id_in)
           AND (a.swreelv_ansi_ref_desig IS NULL OR
               a.swreelv_ansi_ref_desig = p_elm_seq_in);
    
      CURSOR element_c IS
        SELECT 'x'
          FROM swreelv a
         WHERE (a.swreelv_ansi_version IS NULL OR
               a.swreelv_ansi_version = '004010ED0040')
           AND (a.swreelv_trans_set_id IS NULL OR
               a.swreelv_trans_set_id = p_trans_type_in)
           AND (a.swreelv_ansi_loop IS NULL OR
               a.swreelv_ansi_loop = p_loop_in)
           AND a.swreelv_ansi_elem_nbr = p_elm_nbr_in
           AND (a.swreelv_ansi_seg_id IS NULL OR
               a.swreelv_ansi_seg_id = p_seg_id_in)
           AND (a.swreelv_ansi_ref_desig IS NULL OR
               a.swreelv_ansi_ref_desig = p_elm_seq_in);
    BEGIN
      l_elm_exists := FALSE;
    
      --> if element check exits for the element..
    
      FOR element_rec IN element_c
      LOOP
        l_elm_exists := element_c%FOUND;
      END LOOP;
    
      --> ..validate the element value.
      IF l_elm_exists THEN
        l_elm_exists := FALSE;
      
        FOR element_value_rec IN element_value_c
        LOOP
          l_elm_exists := element_value_c%FOUND;
        END LOOP;
      
        --> if element value is not valid, then generate segment
        --> level ack. if it does not exists already..
        IF NOT l_elm_exists THEN
        
          IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_id_in, p_line_in) THEN
            wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_id_in, p_line_in, '8');
          END IF;
          /*  NOT wf_ak3_exists (p_dcmt_seq_in, p_seg_id_in, p_line_in) */
        
          --> .. and generate element level ack.
          l_accepted := FALSE;
          wp_build_ak4_seg_db(p_dcmt_seq_in, p_elm_seq_in, '7',
                              p_ansi_code_in);
          --dbms_output.put_line(p_seg_id_in||p_elm_seq_in||' : Id type not in range');
        END IF; /*NOT l_elm_exists*/
      END IF; /* l_elm_exists */
    END wp_check_id_elem_value;
  
    /*
      FUNCTION wf_get_prev_elm_nbr returns previous element number with
      respect to present elemnt
    
      parameters:
      p_seg_in          segment to which present element belongs.
      p_elm_in          element position
    
    */
    FUNCTION wf_get_prev_elm_nbr
    (
      p_seg_in swreelm.swreelm_seg_id%TYPE
     ,p_elm_in NUMBER
    ) RETURN VARCHAR2 IS
      l_result swreelm.swreelm_ansi_elm_nbr%TYPE;
    
      CURSOR prev_elm_nbr_c IS
        SELECT swreelm_ansi_elm_nbr
          FROM swreelm a
         WHERE (a.swreelm_version IS NULL OR
               a.swreelm_version = '004010ED0040')
           AND a.swreelm_seg_id = p_seg_in
           AND a.swreelm_seg_elem = p_elm_in;
    BEGIN
      l_result := 0;
    
      IF prev_elm_nbr_c%ISOPEN THEN
        CLOSE prev_elm_nbr_c;
      END IF; /* prev_elm_nbr_c%isopen */
    
      OPEN prev_elm_nbr_c;
      FETCH prev_elm_nbr_c
        INTO l_result;
      CLOSE prev_elm_nbr_c;
      RETURN l_result;
    END wf_get_prev_elm_nbr;
  
    /*
      PROCEDURE wp_check_elements does element position check,element
       condition check and element value check. If any of this is invalid,
       this procedure generates outbound ack(997) and sets the success_out
       to FALSE.
    
      parameters:
      p_dcmt_seq_in     document sequence number to whcih present element
                        belongs.
      p_line_in         Position of present segment
      p_seg_in          Present segment
      p_loop_in         loop to which present segment belongs
      l_success_out     out parameter. It will be set to
                        TRUE if element is valid
                        FALSE if element is invalid
    
    
    */
    PROCEDURE wp_check_elements
    (
      p_dcmt_seq_in swtewls.swtewls_dcmt_seq%TYPE
     ,p_line_in     swtewls.swtewls_line_num%TYPE
     ,p_seg_in      swtewls.swtewls_seg%TYPE
     ,p_loop_in     swreseq.swreseq_loop%TYPE
     ,l_success_out OUT BOOLEAN
    ) IS
      l_type_req        swreelm.swreelm_req_ansi%TYPE;
      l_elm_seq         swreelm.swreelm_seg_elem%TYPE;
      l_valid_elm_check BOOLEAN;
      l_date            DATE;
      l_prev_elm_val    swtewle.swtewle_elm_value%TYPE;
    
      CURSOR inbound_elements_c IS
        SELECT swtewle_dcmt_seqno
              ,swtewle_line_num
              ,swtewle_elm_seq
              ,swtewle_elm_value
          FROM swtewle a
         WHERE a.swtewle_dcmt_seqno = p_dcmt_seq_in
           AND a.swtewle_line_num = p_line_in
         ORDER BY a.swtewle_elm_seq;
    
      CURSOR element_rule_c(c_elm_in swreelm.swreelm_seg_elem%TYPE) IS
        SELECT swreelm_seg_id
              ,swreelm_seg_elem
              ,swreelm_ansi_elm_nbr
              ,swreelm_req_ansi
              ,swreelm_req_130p
              ,swreelm_req_130s
              ,swreelm_req_131
              ,swreelm_req_146
              ,swreelm_req_147
              ,swreelm_req_997
              ,swreelm_elem_type
              ,swreelm_min_len
              ,swreelm_max_len
              ,swreelm_cond_column
          FROM swreelm a
         WHERE (a.swreelm_version IS NULL OR
               a.swreelm_version = '004010ED0040')
           AND a.swreelm_seg_id = p_seg_in
           AND a.swreelm_seg_elem = c_elm_in
         ORDER BY a.swreelm_seg_elem;
    
      CURSOR element_count_c IS
        SELECT allowed_elm_count
              ,trn_elm_count
          FROM (SELECT COUNT(*) allowed_elm_count
                  FROM swreelm a
                 WHERE (a.swreelm_version = '004010ED0040' OR
                       a.swreelm_version IS NULL)
                   AND a.swreelm_seg_id = p_seg_in) a
              ,(SELECT COUNT(*) trn_elm_count
                  FROM swtewle a
                 WHERE a.swtewle_dcmt_seqno = p_dcmt_seq_in
                   AND a.swtewle_line_num = p_line_in) b;
    
      l_swtewle_erp_rec swtewle%ROWTYPE;
      l_valid_ind_out   VARCHAR2(1);
    BEGIN
      --Handle validation of NTE segment for transient student 130 transcripts of type S20
      l_swtewle_erp_rec := wsakedi_transient.wf_erp_type_rec_db(p_dcmt_seq_in);
      IF l_type = '130' AND l_swtewle_erp_rec.swtewle_elm_value = 'S20' THEN
        IF p_seg_in = 'NTE' THEN
          wsakedi_transient.wp_validate_s20_nte_db(p_dcmt_seq_in, p_line_in,
                                                   l_valid_ind_out);
          IF l_valid_ind_out = 'N' THEN
            l_accepted := FALSE;
          END IF;
        
        END IF;
      ELSE
        -- execute all remaining validation for all other inbound types and 130s that aren't transient
      
        -->for each elements of the segment..
        FOR inbound_elements_rec IN inbound_elements_c
        LOOP
          l_valid_elm_check := TRUE;
        
          IF length(inbound_elements_rec.swtewle_elm_seq) = 1 THEN
            l_elm_seq := '0' ||
                         to_char(inbound_elements_rec.swtewle_elm_seq);
          ELSE
            l_elm_seq := to_char(inbound_elements_rec.swtewle_elm_seq);
          END IF; /* LENGTH (inbound_elements_rec.swtewle_elm_seq) = 1 */
        
          --> ..get element rule
          FOR element_rule_rec IN element_rule_c(l_elm_seq)
          LOOP
            IF l_type = '146' THEN
              l_type_req := element_rule_rec.swreelm_req_146;
            ELSIF l_type = '147' THEN
              l_type_req := element_rule_rec.swreelm_req_147;
            ELSIF l_type = '130' THEN
              l_type_req := element_rule_rec.swreelm_req_130p;
            ELSIF l_type = '131' THEN
              l_type_req := element_rule_rec.swreelm_req_131;
            END IF; /* l_type = '146' */
          
            -->handle l_type_req first and handle req_ansi next.
            --> if type of element is not IGNORE..
            IF nvl(l_type_req, 'q') <> 'I' THEN
              --> if the element is PCL06 then check it is in CCYY format.
              IF p_seg_in = 'PCL' AND l_elm_seq = '06' AND
                 inbound_elements_rec.swtewle_elm_value IS NOT NULL THEN
                BEGIN
                  l_date := NULL;
                  l_date := to_date(inbound_elements_rec.swtewle_elm_value,
                                    'YYYY');
                
                EXCEPTION
                  WHEN OTHERS THEN
                    --> if date format is not valid, then
                    --> generate outbound ack(997)
                    l_accepted := FALSE;
                  
                    IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                            to_char(p_line_in - 2)) THEN
                      wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                          to_char(p_line_in - 2), '8');
                    END IF; /* NOT wf_ak3_exists (
                                                                                   p_dcmt_seq_in,
                                                                                   p_seg_in,
                                                                                   TO_CHAR (p_line_in - 2)
                                                                                   ) */
                  
                    wp_build_ak4_seg_db(p_dcmt_seq_in,
                                        inbound_elements_rec.swtewle_elm_seq,
                                        '8',
                                        inbound_elements_rec.swtewle_elm_value);
                    l_valid_elm_check := FALSE;
                    --          dbms_output.put_line('date format is wrong');
                
                END;
              
              END IF; --> p_seg_in = 'PCL' and l_elm_seq = '06'
            
              --> if previous element value is 1251 and present
              --> element value is 1250, then check present date
              --> format as per the value in previous element value
              IF element_rule_rec.swreelm_ansi_elm_nbr = '1251' AND
                 TRIM(wf_get_prev_elm_nbr(p_seg_in, l_elm_seq - 1)) =
                 '1250' THEN
                l_prev_elm_val := wf_element_value(p_dcmt_seq_in, p_line_in,
                                                   l_elm_seq - 1);
              
                BEGIN
                  l_date := NULL;
                
                  IF TRIM(l_prev_elm_val) = 'D8' THEN
                    l_date := to_date(inbound_elements_rec.swtewle_elm_value,
                                      'YYYYMMDD');
                  ELSIF TRIM(l_prev_elm_val) = 'CM' THEN
                    l_date := to_date(inbound_elements_rec.swtewle_elm_value,
                                      'YYYYMM');
                  ELSIF TRIM(l_prev_elm_val) = 'CY' THEN
                    l_date := to_date(inbound_elements_rec.swtewle_elm_value,
                                      'YYYY');
                  ELSIF TRIM(l_prev_elm_val) = 'DB' THEN
                    l_date := to_date(inbound_elements_rec.swtewle_elm_value,
                                      'MMDDYYYY');
                  ELSIF TRIM(l_prev_elm_val) = 'MD' THEN
                    l_date := to_date(inbound_elements_rec.swtewle_elm_value,
                                      'MMDD');
                  END IF; /* TRIM (l_prev_elm_val) = 'D8' */
                
                  l_date := NULL;
                EXCEPTION
                  WHEN OTHERS THEN
                    --> if date format is not valid, then
                    --> generate outbound ack(997)
                    l_accepted := FALSE;
                  
                    IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                            to_char(p_line_in - 2)) THEN
                      wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                          to_char(p_line_in - 2), '8');
                    END IF; /* NOT wf_ak3_exists (
                                                                                   p_dcmt_seq_in,
                                                                                   p_seg_in,
                                                                                   TO_CHAR (p_line_in - 2)
                                                                                    ) */
                  
                    wp_build_ak4_seg_db(p_dcmt_seq_in,
                                        inbound_elements_rec.swtewle_elm_seq,
                                        '8',
                                        inbound_elements_rec.swtewle_elm_value);
                    l_valid_elm_check := FALSE;
                    --          dbms_output.put_line('date format is wrong');
                END;
                --    dbms_output.put_line(p_seg_in||l_elm_seq||'  need tp be checked for date '||l_prev_elm_val);
              END IF; /*  element_rule_rec.swreelm_ansi_elm_nbr = '1251'
                                                            AND TRIM (
                                                            wf_get_prev_elm_nbr (p_seg_in, l_elm_seq - 1)
                                                            ) = '1250' */
            
              --> checking for element count
            
              FOR element_count_rec IN element_count_c
              LOOP
                --> if segment has number of elements grater than allowed element count
                --> then generate out997.
                IF element_count_rec.trn_elm_count >
                   element_count_rec.allowed_elm_count THEN
                  l_accepted := FALSE;
                
                  IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                          to_char(p_line_in - 2)) THEN
                    wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                        to_char(p_line_in - 2), '8');
                  END IF; /* NOT wf_ak3_exists (
                                                                            p_dcmt_seq_in,
                                                                            p_seg_in,
                                                                            TO_CHAR (p_line_in - 2)
                                                                            ) */
                
                  /*  wp_build_ak4_seg_db (
                     p_dcmt_seq_in,
                     to_char(element_count_rec.trn_elm_count + 1),
                     '3',
                     ''
                  );*/
                  l_valid_elm_check := FALSE;
                  --dbms_output.put_line
                  --(to_char(element_count_rec.allowed_elm_count)||' '|| to_char(element_count_rec.trn_elm_count));
                END IF;
                /* element_count_rec.trn_elm_count > element_count_rec.allowed_elm_count */
              END LOOP;
            
              --> checking for type specific reqirements
              IF nvl(l_type_req, 'q') = 'M' AND
                 inbound_elements_rec.swtewle_elm_value IS NULL THEN
                /*DBMS_OUTPUT.put_line (
                      p_seg_in
                   || inbound_elements_rec.swtewle_elm_seq
                   || ' : mandatory elm is missing'
                );*/
                l_accepted := FALSE;
              
                IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                        to_char(p_line_in - 2)) THEN
                  wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                      to_char(p_line_in - 2), '8');
                END IF; /* NOT wf_ak3_exists (
                                                                    p_dcmt_seq_in,
                                                                   p_seg_in,
                                                                   TO_CHAR (p_line_in - 2)
                                                                   ) */
              
                wp_build_ak4_seg_db(p_dcmt_seq_in,
                                    inbound_elements_rec.swtewle_elm_seq,
                                    '1',
                                    inbound_elements_rec.swtewle_elm_value);
                l_valid_elm_check := FALSE;
              END IF; /*   NVL (l_type_req, 'q') = 'M'
                                                             AND inbound_elements_rec.swtewle_elm_value IS NULL */
            
              --> check for conditional requirement
              IF l_valid_elm_check AND nvl(l_type_req, 'q') = 'C' AND
                 (wf_element_value(p_dcmt_seq_in, p_line_in,
                                   to_number(element_rule_rec.swreelm_cond_column)) IS NULL AND
                 inbound_elements_rec.swtewle_elm_value IS NOT NULL) THEN
                /*
                DBMS_OUTPUT.put_line (
                      p_seg_in
                   || inbound_elements_rec.swtewle_elm_seq
                   || ' conditional(C) elem value is null'
                );*/
                l_valid_elm_check := FALSE;
                l_accepted        := FALSE;
              
                --> if conditional element does not exist
                --> generate outbound 997
              
                IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                        to_char(p_line_in - 2)) THEN
                  wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                      to_char(p_line_in - 2), '8');
                END IF; /* NOT wf_ak3_exists (
                                                                   p_dcmt_seq_in,
                                                                   p_seg_in,
                                                                   TO_CHAR (p_line_in - 2)
                                                                   ) */
              
                wp_build_ak4_seg_db(p_dcmt_seq_in,
                                    inbound_elements_rec.swtewle_elm_seq,
                                    '2',
                                    inbound_elements_rec.swtewle_elm_value);
              END IF; /* l_valid_elm_check
                                                           AND NVL (l_type_req, 'q') = 'C'
                                                           AND (   wf_element_value (
                                                           p_dcmt_seq_in,
                                                           p_line_in,..*/
            
              --> check for referential element check ('X')
            
              IF l_valid_elm_check AND nvl(l_type_req, 'q') = 'X' AND
                 (wf_element_value(p_dcmt_seq_in, p_line_in,
                                   to_number(element_rule_rec.swreelm_cond_column)) IS NULL AND
                 inbound_elements_rec.swtewle_elm_value IS NULL) THEN
                --> if referential condion does not satisfy
                --> generate error.
                /*DBMS_OUTPUT.put_line (
                      p_seg_in
                   || inbound_elements_rec.swtewle_elm_seq
                   || ' conditional(X) elem value is null'
                );*/
                l_valid_elm_check := FALSE;
                l_accepted        := FALSE;
              
                IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                        to_char(p_line_in - 2)) THEN
                  wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                      to_char(p_line_in - 2), '8');
                END IF; /* NOT wf_ak3_exists (
                                                                   p_dcmt_seq_in,
                                                                   p_seg_in,
                                                                   TO_CHAR (p_line_in - 2)
                                                                   ) */
              
                wp_build_ak4_seg_db(p_dcmt_seq_in,
                                    inbound_elements_rec.swtewle_elm_seq,
                                    '2',
                                    inbound_elements_rec.swtewle_elm_value);
              END IF; /*       l_valid_elm_check
                                                                 AND NVL (l_type_req, 'q') = 'X'
                                                                 AND (    wf_element_value (
                                                                 p_dcmt_seq_in, */
            
              --> check for 'eiether of' element condition(ie
              --> any one of elements should be present).
            
              IF l_valid_elm_check AND nvl(l_type_req, 'q') = 'E' THEN
              
                FOR i IN 1 .. wsaklnutil.wf_elements_count_in_segment('ab,' ||
                                                                      element_rule_rec.swreelm_cond_column || ',',
                                                                      ',',
                                                                      ',')
                LOOP
                  IF (wf_element_value(p_dcmt_seq_in, p_line_in,
                                       wsaklnutil.wf_elm_value_of_elm(i,
                                                                       'ab,' ||
                                                                        element_rule_rec.swreelm_cond_column || ',',
                                                                       ',', ',')) IS NULL AND
                     inbound_elements_rec.swtewle_elm_value IS NOT NULL) THEN
                  
                    --> if 'either of condition does not satisfied,
                    --> then generate outbound ack.(997)
                    l_valid_elm_check := FALSE;
                    l_accepted        := FALSE;
                  
                    IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                            to_char(p_line_in - 2)) THEN
                      wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                          to_char(p_line_in - 2), '8');
                    END IF; /* NOT wf_ak3_exists (
                                                                           p_dcmt_seq_in,
                                                                           p_seg_in,
                                                                           TO_CHAR (p_line_in - 2)
                                                                           ) */
                  
                    wp_build_ak4_seg_db(p_dcmt_seq_in,
                                        inbound_elements_rec.swtewle_elm_seq,
                                        '2',
                                        inbound_elements_rec.swtewle_elm_value);
                  END IF;
                END LOOP;
              END IF;
            
              -->checking for ansi spefic requirements.
              --> check for mandatory element
              IF l_valid_elm_check AND
                 nvl(element_rule_rec.swreelm_req_ansi, 'q') = 'M' AND
                 inbound_elements_rec.swtewle_elm_value IS NULL THEN
                /*DBMS_OUTPUT.put_line (
                      p_seg_in
                   || inbound_elements_rec.swtewle_elm_seq
                   || ' : mandatory elm is missing'
                );*/
                l_valid_elm_check := FALSE;
                l_accepted        := FALSE;
              
                --> if mandatory check is not satisfied,
                --> generate outbound ack.(997)
                IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                        to_char(p_line_in - 2)) THEN
                  wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                      to_char(p_line_in - 2), '8');
                END IF; /* NOT wf_ak3_exists (
                                                                    p_dcmt_seq_in,
                                                                    p_seg_in,
                                                                    TO_CHAR (p_line_in - 2)
                                                                   ) */
              
                wp_build_ak4_seg_db(p_dcmt_seq_in,
                                    inbound_elements_rec.swtewle_elm_seq,
                                    '1',
                                    inbound_elements_rec.swtewle_elm_value);
              END IF; /*      l_valid_elm_check
                                                                AND NVL (element_rule_rec.swreelm_req_ansi, 'q') = 'M'
                                                                AND inbound_elements_rec.swtewle_elm_value IS NULL */
            
              --> check for element value range..
              IF l_valid_elm_check AND length(inbound_elements_rec.swtewle_elm_value) NOT BETWEEN
                 element_rule_rec.swreelm_min_len AND
                 element_rule_rec.swreelm_max_len THEN
                /*DBMS_OUTPUT.put_line (
                      p_seg_in
                   || inbound_elements_rec.swtewle_elm_seq
                   || ' :not bet min and max'
                );*/
                l_valid_elm_check := FALSE;
                l_accepted        := FALSE;
              
                --> if element value range is not valid,
                --> generate outbound ack.(997)
              
                IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                        to_char(p_line_in - 2)) THEN
                  wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                      to_char(p_line_in - 2), '8');
                END IF; /* NOT wf_ak3_exists (
                                                                   p_dcmt_seq_in,
                                                                   p_seg_in,
                                                                   TO_CHAR (p_line_in - 2)
                                                                   ) */
              
                IF length(inbound_elements_rec.swtewle_elm_value) <
                   element_rule_rec.swreelm_min_len THEN
                  wp_build_ak4_seg_db(p_dcmt_seq_in,
                                      inbound_elements_rec.swtewle_elm_seq,
                                      '4',
                                      inbound_elements_rec.swtewle_elm_value);
                ELSIF length(inbound_elements_rec.swtewle_elm_value) >
                      element_rule_rec.swreelm_max_len THEN
                  wp_build_ak4_seg_db(p_dcmt_seq_in,
                                      inbound_elements_rec.swtewle_elm_seq,
                                      '5',
                                      inbound_elements_rec.swtewle_elm_value);
                END IF;
                /* LENGTH (inbound_elements_rec.swtewle_elm_value) <
                element_rule_rec.swreelm_min_len */
              END IF; /*      l_valid_elm_check
                                                                AND LENGTH (inbound_elements_rec.swtewle_elm_value) NOT
                                                                BETWEEN element_rule_rec.swreelm_min_len
                                                                AND element_rule_rec.swreelm_max_len*/
            
              --> check for element exclusive condition.
              IF l_valid_elm_check AND
                 nvl(element_rule_rec.swreelm_req_ansi, 'q') = 'X' AND
                 (wf_element_value(p_dcmt_seq_in, p_line_in,
                                   to_number(element_rule_rec.swreelm_cond_column)) IS NULL AND
                 inbound_elements_rec.swtewle_elm_value IS NULL) THEN
                /*DBMS_OUTPUT.put_line (
                      p_seg_in
                   || inbound_elements_rec.swtewle_elm_seq
                   || ' conditional(x) elem value is null'
                );*/
                l_valid_elm_check := FALSE;
                l_accepted        := FALSE;
              
                --> if 'exclusive condition' NOT ment, then
                --> generate outbound ack. (997).
              
                IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                        to_char(p_line_in - 2)) THEN
                  wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                      to_char(p_line_in - 2), '8');
                END IF; /* NOT wf_ak3_exists (
                                                                   p_dcmt_seq_in,
                                                                   p_seg_in,
                                                                   TO_CHAR (p_line_in - 2)
                                                                   ) */
              
                wp_build_ak4_seg_db(p_dcmt_seq_in,
                                    inbound_elements_rec.swtewle_elm_seq,
                                    '2',
                                    inbound_elements_rec.swtewle_elm_value);
              END IF; /* l_valid_elm_check
                                                           AND NVL (element_rule_rec.swreelm_req_ansi, 'q') = 'X'
                                                           AND (    wf_element_value (
                                                           p_dcmt_seq_in,
                                                           p_line_in,
                                                           TO_NUMBER (element_rule_rec.swreelm_cond_column)
                                                           ) IS NULL
                                                           AND inbound_elements_rec.swtewle_elm_value IS NULL
                                                           ) */
            
              --> check for 'eiether of' element condition(ie
              --> any one of elements should be present).
             IF l_valid_elm_check AND
                 nvl(element_rule_rec.swreelm_req_ansi, 'q') = 'E' THEN
                FOR i IN 1 .. wsaklnutil.wf_elements_count_in_segment('ab,' ||
                                                                      element_rule_rec.swreelm_cond_column || ',',
                                                                      ',',
                                                                      ',')
                LOOP
                  IF (wf_element_value(p_dcmt_seq_in, p_line_in,
                                      wsaklnutil.wf_elm_value_of_elm(i,
                                                                      'ab,' ||
                                                                       element_rule_rec.swreelm_cond_column || ',',
                                                                      ',', ',')) IS NULL 
                 AND
                 inbound_elements_rec.swtewle_elm_value IS NOT NULL)	 THEN
                    l_valid_elm_check := FALSE;
                    l_accepted        := FALSE;
                  
                    --> if either of element condition is not satisfied
                    --> geneate outbound 997
                  
                    IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                            to_char(p_line_in - 2)) THEN
                      wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                          to_char(p_line_in - 2), '8');
                    END IF; /* NOT wf_ak3_exists (
                                                                               p_dcmt_seq_in,
                                                                               p_seg_in,
                                                                               TO_CHAR (p_line_in - 2)
                                                                               ) */
                  
                    wp_build_ak4_seg_db(p_dcmt_seq_in,
                                        inbound_elements_rec.swtewle_elm_seq,
                                        '2',
                                        inbound_elements_rec.swtewle_elm_value);
                  END IF;
                END LOOP;
              END IF;
            
              --> check for conditional requirement
              IF l_valid_elm_check AND
                 nvl(element_rule_rec.swreelm_req_ansi, 'q') = 'C' AND
                 (wf_element_value(p_dcmt_seq_in, p_line_in,
                                   to_number(element_rule_rec.swreelm_cond_column)) IS NULL AND
                 inbound_elements_rec.swtewle_elm_value IS NOT NULL) THEN
                /*DBMS_OUTPUT.put_line (
                      p_seg_in
                   || inbound_elements_rec.swtewle_elm_seq
                   || ' conditional(C) elem value is null'
                );*/
                l_valid_elm_check := FALSE;
                l_accepted        := FALSE;
              
                --> if conditional req is not met, generate
                --> outbound 997
                IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                        to_char(p_line_in - 2)) THEN
                  wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                      to_char(p_line_in - 2), '8');
                END IF; /* NOT wf_ak3_exists (
                                                                   p_dcmt_seq_in,
                                                                   p_seg_in,
                                                                   TO_CHAR (p_line_in - 2)
                                                                   ) */
              
                wp_build_ak4_seg_db(p_dcmt_seq_in,
                                    inbound_elements_rec.swtewle_elm_seq,
                                    '2',
                                    inbound_elements_rec.swtewle_elm_value);
              END IF;
            END IF; /*l_type_req <> 'I'*/
          
            --> if element check is not tobe ignored
            --> and if the element type is ID then
            --> check for element value against element value
            --> rule table.
            IF nvl(l_type_req, 'q') <> 'I' AND l_valid_elm_check AND
               inbound_elements_rec.swtewle_elm_value IS NOT NULL THEN
              IF element_rule_rec.swreelm_elem_type = 'ID' THEN
                wp_check_id_elem_value(inbound_elements_rec.swtewle_elm_value,
                                       l_type, p_loop_in,
                                       element_rule_rec.swreelm_ansi_elm_nbr,
                                       element_rule_rec.swreelm_seg_id,
                                       element_rule_rec.swreelm_seg_elem,
                                       p_dcmt_seq_in,
                                       to_char(inbound_elements_rec.swtewle_line_num - 2));
                --wp_build_ak3_seg(p_dcmt_in, p_seg_in, to_char(p_line_in-2),'8');
                --wp_build_ak4_seg_db(p_dcmt_seq_in, inbound_elements_rec.swtewle_elm_seq, '1',inbound_elements_rec.swtewle_elm_value);
              
                --> if element type is of date type, then for date format
              ELSIF element_rule_rec.swreelm_elem_type IN ('DT', 'D8') THEN
                BEGIN
                  l_date := to_date(inbound_elements_rec.swtewle_elm_value,
                                    'YYYYMMDD');
                EXCEPTION
                  WHEN OTHERS THEN
                    --> if the date format is incorrect,
                    --> then generate outbound997
                    --dbms_output.put_line(element_rule_rec.swreelm_seg_id||element_rule_rec.swreelm_seg_elem||' : date format is wrong');
                    l_accepted := FALSE;
                  
                    IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                            to_char(p_line_in - 2)) THEN
                      wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                          to_char(p_line_in - 2), '8');
                    END IF; /* NOT wf_ak3_exists (
                                                                                   p_dcmt_seq_in,
                                                                                   p_seg_in,
                                                                                   TO_CHAR (p_line_in - 2)
                                                                                   ) */
                  
                    wp_build_ak4_seg_db(p_dcmt_seq_in,
                                        inbound_elements_rec.swtewle_elm_seq,
                                        '8',
                                        inbound_elements_rec.swtewle_elm_value);
                END;
                --> if the element type is of time type, check for
                --> time format.
              ELSIF element_rule_rec.swreelm_elem_type = 'TM' THEN
                BEGIN
                  IF length(inbound_elements_rec.swtewle_elm_value) = 4 THEN
                    l_date := to_date(inbound_elements_rec.swtewle_elm_value,
                                      'HH24MI');
                  ELSIF length(inbound_elements_rec.swtewle_elm_value) IN
                        (7, 8) THEN
                    l_date := to_date(substr(inbound_elements_rec.swtewle_elm_value,
                                             1, 6), 'HH24MISS');
                  ELSIF length(inbound_elements_rec.swtewle_elm_value) = 6 THEN
                    l_date := to_date(inbound_elements_rec.swtewle_elm_value,
                                      'HH24MISS');
                  END IF;
                  /* LENGTH (inbound_elements_rec.swtewle_elm_value) =
                  4 */
                EXCEPTION
                  WHEN OTHERS THEN
                    --> if time format is wrong, generate
                    --> outbound 997
                    --dbms_output.put_line(element_rule_rec.swreelm_seg_id||element_rule_rec.swreelm_seg_elem||' : time format is wrong');
                    l_accepted := FALSE;
                  
                    IF NOT wf_ak3_exists_db(p_dcmt_seq_in, p_seg_in,
                                            to_char(p_line_in - 2)) THEN
                      wp_build_ak3_seg_db(p_dcmt_seq_in, p_seg_in,
                                          to_char(p_line_in - 2), '8');
                    END IF; /* NOT wf_ak3_exists (
                                                                                   p_dcmt_seq_in,
                                                                                   p_seg_in,
                                                                                   TO_CHAR (p_line_in - 2)
                                                                                   ) */
                  
                    wp_build_ak4_seg_db(p_dcmt_seq_in,
                                        inbound_elements_rec.swtewle_elm_seq,
                                        '9',
                                        inbound_elements_rec.swtewle_elm_value);
                END;
              END IF; /*element_rule_rec.swreelm_elem_type = 'ID'*/
            END IF; /* NOT l_valid_elm_check */
          END LOOP; --element_rule_c
        --dbms_output.put_line(p_seg_in||inbound_elements_rec.swtewle_elm_seq||' :'||inbound_elements_rec.swtewle_elm_value);
        
        END LOOP; --inbound_elements_c
      END IF; --IF l_type = '130' AND l_swtewle_rec.swtewle_elm_value = 'S20' THEN
    END wp_check_elements;
  
    /*
      PROCEDURE wp_load_ack_isa_gs_st  builds isa, gs, st for outbound997
    
    
      parameters:
      p_dcmt_in         document sequence number to whcih present element
                        belongs.
    
    
    */
  
    PROCEDURE wp_load_ack_isa_gs_st(p_dcmt_in swtewls.swtewls_dcmt_seq%TYPE) IS
      l_recv_qulfr_code   VARCHAR2(10);
      l_recv_inst_code    VARCHAR2(50);
      l_recv_gs_inst_code VARCHAR2(50);
      l_gs_fnl_id_code    VARCHAR2(2);
      l_gs_grp_cntrl_numb VARCHAR2(10);
      l_ts_id_code        VARCHAR2(3);
      l_ts_cnt_nbr        VARCHAR2(10);
      --USF Version W start
      l_t_or_p VARCHAR2(1) := 'P';
      --USF Version W end
    
      CURSOR swtewle_elm_value_c
      (
        c_line_in   swteaks.swteaks_line_num%TYPE
       ,c_elmseq_in swtewle.swtewle_elm_seq%TYPE
      ) IS
        SELECT swtewle_elm_value
          FROM swtewle a
         WHERE a.swtewle_dcmt_seqno = p_dcmt_in
           AND a.swtewle_line_num = c_line_in
           AND a.swtewle_elm_seq = c_elmseq_in;
    BEGIN
      DELETE FROM swteake WHERE swteake.swteake_dcmt_seqno = p_dcmt_in;
    
      DELETE FROM swteaks WHERE swteaks.swteaks_dcmt_seq = p_dcmt_in;
    
      -->
      FOR swtewle_elm_value_rec IN swtewle_elm_value_c(1, 5)
      LOOP
        l_recv_qulfr_code := swtewle_elm_value_rec.swtewle_elm_value;
      END LOOP; /*swtewle_elm_value_c*/
    
      FOR swtewle_elm_value_rec IN swtewle_elm_value_c(1, 6)
      LOOP
        l_recv_inst_code := swtewle_elm_value_rec.swtewle_elm_value;
      END LOOP; /*swtewle_elm_value_c*/
    
      --USF Version W start
      IF p_test_or_prod_ind IS NOT NULL THEN
        l_t_or_p := p_test_or_prod_ind;
      END IF; -- p_test_or_prod_ind IS NOT NULL
      --USF Version W end
    
      wp_insert_swteaks_db(p_dcmt_in, 1, c_interchange_cntrl_hdr_seg);
      wp_insert_swteake_db(p_dcmt_in, 1, 1, '00');
      wp_insert_swteake_db(p_dcmt_in, 1, 2, '          ');
      wp_insert_swteake_db(p_dcmt_in, 1, 3, '00');
      wp_insert_swteake_db(p_dcmt_in, 1, 4, '          ');
      wp_insert_swteake_db(p_dcmt_in, 1, 5, '22');
      wp_insert_swteake_db(p_dcmt_in, 1, 6, l_host_inst_code || '         ');
      wp_insert_swteake_db(p_dcmt_in, 1, 7, l_recv_qulfr_code);
      wp_insert_swteake_db(p_dcmt_in, 1, 8, l_recv_inst_code);
      wp_insert_swteake_db(p_dcmt_in, 1, 9, to_char(SYSDATE, 'YYMMDD'));
      wp_insert_swteake_db(p_dcmt_in, 1, 10, to_char(SYSDATE, 'HH24MI'));
      wp_insert_swteake_db(p_dcmt_in, 1, 11, 'U');
      wp_insert_swteake_db(p_dcmt_in, 1, 12, '00401');
      wp_insert_swteake_db(p_dcmt_in, 1, 13, lpad(p_dcmt_in, 9, '0'));
      wp_insert_swteake_db(p_dcmt_in, 1, 14, '0');
      --USF Version W start
      -- wp_insert_swteake_db(p_dcmt_in, 1, 15, 'P');
      wp_insert_swteake_db(p_dcmt_in, 1, 15, l_t_or_p);
      --USF Version W end
      wp_insert_swteake_db(p_dcmt_in, 1, 16, '~');
    
      FOR swtewle_elm_value_rec IN swtewle_elm_value_c(2, 2)
      LOOP
        l_recv_gs_inst_code := swtewle_elm_value_rec.swtewle_elm_value;
      END LOOP; /*swtewle_elm_value_c*/
    
      wp_insert_swteaks_db(p_dcmt_in, 2, c_functional_gruop_hdr_seg);
      wp_insert_swteake_db(p_dcmt_in, 2, 1, 'FA');
      wp_insert_swteake_db(p_dcmt_in, 2, 2, l_host_inst_code);
      wp_insert_swteake_db(p_dcmt_in, 2, 3, l_recv_gs_inst_code);
      wp_insert_swteake_db(p_dcmt_in, 2, 4, to_char(SYSDATE, 'YYYYMMDD'));
      wp_insert_swteake_db(p_dcmt_in, 2, 5, to_char(SYSDATE, 'HH24MISS'));
      wp_insert_swteake_db(p_dcmt_in, 2, 6, lpad(p_dcmt_in, 9, '0'));
      wp_insert_swteake_db(p_dcmt_in, 2, 7, 'X');
      wp_insert_swteake_db(p_dcmt_in, 2, 8, '004010ED0040');
      wp_insert_swteaks_db(p_dcmt_in, 3, c_interchange_trn_hdr_seg);
      wp_insert_swteake_db(p_dcmt_in, 3, 1, '997');
      wp_insert_swteake_db(p_dcmt_in, 3, 2, p_dcmt_in);
    
      FOR swtewle_elm_value_rec IN swtewle_elm_value_c(2, 1)
      LOOP
        l_gs_fnl_id_code := swtewle_elm_value_rec.swtewle_elm_value;
      END LOOP; /*swtewle_elm_value_c*/
    
      FOR swtewle_elm_value_rec IN swtewle_elm_value_c(2, 6)
      LOOP
        l_gs_grp_cntrl_numb := swtewle_elm_value_rec.swtewle_elm_value;
      END LOOP; /*swtewle_elm_value_c*/
    
      wp_insert_swteaks_db(p_dcmt_in, 4, c_fnl_group_response_header);
      wp_insert_swteake_db(p_dcmt_in, 4, 1, l_gs_fnl_id_code);
      wp_insert_swteake_db(p_dcmt_in, 4, 2, l_gs_grp_cntrl_numb);
    
      FOR swtewle_elm_value_rec IN swtewle_elm_value_c(3, 1)
      LOOP
        l_ts_id_code := swtewle_elm_value_rec.swtewle_elm_value;
      END LOOP; /*swtewle_elm_value_c*/
    
      FOR swtewle_elm_value_rec IN swtewle_elm_value_c(3, 2)
      LOOP
        l_ts_cnt_nbr := swtewle_elm_value_rec.swtewle_elm_value;
      END LOOP; /*swtewle_elm_value_c*/
    
      wp_insert_swteaks_db(p_dcmt_in, 5, c_tr_set_response_header);
      wp_insert_swteake_db(p_dcmt_in, 5, 1, l_ts_id_code);
      wp_insert_swteake_db(p_dcmt_in, 5, 2, l_ts_cnt_nbr);
    END wp_load_ack_isa_gs_st;
  
    /*
      PROCEDURE PROCEDURE wp_generate_ak5  generates transaction set response
      trailer segment for outbound 997.
      This also generates AK9, SE, GE, IEA segments for outbound 997
    
    
      parameters:
      p_dcmt_in         document sequence number to whcih present element
                        belongs.
      p_ack_code_in     acknowledgement code
                        'A' accepted
                        'R' rejected
    
    
    */
  
    PROCEDURE wp_generate_ak5
    (
      p_dcmt_in     swtewls.swtewls_dcmt_seq%TYPE
     ,p_ack_code_in VARCHAR2
    ) IS
      l_current_line NUMBER;
    BEGIN
      l_current_line := wf_get_line_numb_db(p_dcmt_in);
      wp_insert_swteaks_db(p_dcmt_in, l_current_line,
                           c_tr_set_response_trailer);
      wp_insert_swteake_db(p_dcmt_in, l_current_line, 1, p_ack_code_in);
      l_current_line := wf_get_line_numb_db(p_dcmt_in);
      wp_insert_swteaks_db(p_dcmt_in, l_current_line,
                           c_fnl_group_response_trailer);
      wp_insert_swteake_db(p_dcmt_in, l_current_line, 1, p_ack_code_in);
      wp_insert_swteake_db(p_dcmt_in, l_current_line, 2, '1');
      wp_insert_swteake_db(p_dcmt_in, l_current_line, 3, '1');
    
      IF p_ack_code_in = 'A' THEN
        wp_insert_swteake_db(p_dcmt_in, l_current_line, 4, '1');
      ELSE
        /*p_ack_code_in = 'A'*/
        wp_insert_swteake_db(p_dcmt_in, l_current_line, 4, '0');
      END IF; /* p_ack_code_in = 'A' */
    
      l_current_line := wf_get_line_numb_db(p_dcmt_in);
      wp_insert_swteaks_db(p_dcmt_in, l_current_line,
                           c_interchange_trn_trl_seg);
      wp_insert_swteake_db(p_dcmt_in, l_current_line, 1,
                           to_char(l_current_line - 2));
      wp_insert_swteake_db(p_dcmt_in, l_current_line, 2, to_char(p_dcmt_in));
      l_current_line := wf_get_line_numb_db(p_dcmt_in);
      wp_insert_swteaks_db(p_dcmt_in, l_current_line,
                           c_functional_gruop_trl_seg);
      wp_insert_swteake_db(p_dcmt_in, l_current_line, 1, '1');
      wp_insert_swteake_db(p_dcmt_in, l_current_line, 2, to_char(p_dcmt_in));
      l_current_line := wf_get_line_numb_db(p_dcmt_in);
      wp_insert_swteaks_db(p_dcmt_in, l_current_line,
                           c_interchange_cntrl_trl_seg);
      wp_insert_swteake_db(p_dcmt_in, l_current_line, 1, '1');
      wp_insert_swteake_db(p_dcmt_in, l_current_line, 2,
                           lpad(to_char(p_dcmt_in), 9, '0'));
    END wp_generate_ak5;
  
    FUNCTION wf_allowd_loop_rpt
    (
      p_type_in     swrelrp.swrelrp_type%TYPE
     ,p_loop_seg_in swrelrp.swrelrp_segment%TYPE
    ) RETURN NUMBER IS
      l_result    NUMBER;
      l_cur_found BOOLEAN;
    
      CURSOR swrelrp_loop_repeat_c IS
        SELECT t.swrelrp_loop_repeat
          FROM swrelrp t
         WHERE t.swrelrp_type = p_type_in
           AND t.swrelrp_segment = p_loop_seg_in;
    BEGIN
      l_result := 0;
    
      IF swrelrp_loop_repeat_c%ISOPEN THEN
        CLOSE swrelrp_loop_repeat_c;
      END IF; /* swrelrp_loop_repeat_c%ISOPEN */
    
      OPEN swrelrp_loop_repeat_c;
      FETCH swrelrp_loop_repeat_c
        INTO l_result;
      l_cur_found := swrelrp_loop_repeat_c%FOUND;
      CLOSE swrelrp_loop_repeat_c;
    
      IF NOT l_cur_found THEN
        l_result := NULL;
      END IF; /* NOT l_cur_found */
    
      RETURN l_result;
    END wf_allowd_loop_rpt;
  
    FUNCTION wf_is_loop_seg
    (
      p_type_in swrelrp.swrelrp_type%TYPE
     ,p_seg_in  swrelrp.swrelrp_segment%TYPE
    ) RETURN BOOLEAN IS
      l_result    BOOLEAN;
      l_char      CHAR(1);
      l_cur_found BOOLEAN;
    
      CURSOR swrelrp_segment_c IS
        SELECT 'x'
          FROM swrelrp a
         WHERE a.swrelrp_type = p_type_in
           AND a.swrelrp_segment = p_seg_in;
    BEGIN
      IF swrelrp_segment_c%ISOPEN THEN
        CLOSE swrelrp_segment_c;
      END IF; /* swrelrp_segment_c%ISOPEN */
    
      OPEN swrelrp_segment_c;
      FETCH swrelrp_segment_c
        INTO l_char;
      l_result := swrelrp_segment_c%FOUND;
      CLOSE swrelrp_segment_c;
      RETURN l_result;
    END wf_is_loop_seg;
  
    /*
      FUNCTION wf_allowd_seg_rpt  returns checks aginst element rule
      table and returns valid no of segment repeats for
      the present segment
    
      parameters:
      p_type_in         Transaction type
      p_lp_seg_in       Segment loop to which present
                        segment belongs.
      p_seg_in          present segment
    
    
    */
  
    FUNCTION wf_allowd_seg_rpt
    (
      p_type_in   swresrp.swresrp_type%TYPE
     ,p_lp_seg_in swresrp.swresrp_loop_segment%TYPE
     ,p_seg_in    swresrp.swresrp_segment%TYPE
    ) RETURN NUMBER IS
      l_result NUMBER;
    
      CURSOR swresrp_loop_repeat_c IS
        SELECT swresrp_loop_repeat
          FROM swresrp
         WHERE swresrp_type = p_type_in
           AND swresrp_loop_segment = p_lp_seg_in
           AND swresrp_segment = p_seg_in;
    BEGIN
      IF swresrp_loop_repeat_c%ISOPEN THEN
        CLOSE swresrp_loop_repeat_c;
      END IF; /* swresrp_loop_repeat_c%ISOPEN */
    
      OPEN swresrp_loop_repeat_c;
      FETCH swresrp_loop_repeat_c
        INTO l_result;
      l_cur_found := swresrp_loop_repeat_c%FOUND;
      CLOSE swresrp_loop_repeat_c;
    
      IF NOT l_cur_found THEN
        l_result := NULL;
      END IF; /* NOT l_cur_found */
    
      RETURN l_result;
    END wf_allowd_seg_rpt;
  
    /*
      PROCEDURE wp_chk_st_se  checks transaction set header
      and transaction set trailer of present transaction.
      If no of lines present transaction is incorrect
      or if transaction set control number is not mathed
      this procedure generates outbound 997.
    
      parameters:
      p_dcmt_in         Present document sequence number
      p_line_in         Present segment line number
      p_accepted_out    out parameter that specifies
                        valied
                        if valied it is set to TRUE
                        if invalid it is set to FALSE
    
    
    */
  
    PROCEDURE wp_chk_st_se
    (
      p_dcmt_in      swtewls.swtewls_dcmt_seq%TYPE
     ,p_line_in      NUMBER
     ,p_accepted_out OUT BOOLEAN
    ) IS
      CURSOR st_ref_c IS
        SELECT st_ref
              ,se_ref
          FROM (SELECT a.swtewle_elm_value  st_ref
                      ,a.swtewle_dcmt_seqno dcmt
                  FROM swtewle a
                 WHERE a.swtewle_dcmt_seqno = p_dcmt_in
                   AND a.swtewle_line_num = 3
                   AND a.swtewle_elm_seq = 2) d
              ,(SELECT a.swtewle_elm_value  se_ref
                      ,a.swtewle_dcmt_seqno dcmt
                  FROM swtewle a
                 WHERE a.swtewle_dcmt_seqno = p_dcmt_in
                   AND a.swtewle_line_num =
                       (SELECT MAX(b.swtewls_line_num)
                          FROM swtewls b
                         WHERE b.swtewls_dcmt_seq = a.swtewle_dcmt_seqno
                           AND b.swtewls_seg = c_interchange_trn_trl_seg)
                   AND a.swtewle_elm_seq = 2) e
         WHERE d.dcmt = e.dcmt;
    
      CURSOR tran_couunt_c IS
        SELECT act_count
              ,se_count
          FROM (SELECT (COUNT(*) - 4) act_count
                      ,MAX(a.swtewls_dcmt_seq) dcmt
                  FROM swtewls a
                 WHERE a.swtewls_dcmt_seq = p_dcmt_in) e
              ,(SELECT a.swtewle_elm_value  se_count
                      ,a.swtewle_dcmt_seqno dcmt
                  FROM swtewle a
                 WHERE a.swtewle_dcmt_seqno = p_dcmt_in
                   AND a.swtewle_line_num =
                       (SELECT MAX(b.swtewls_line_num)
                          FROM swtewls b
                         WHERE b.swtewls_dcmt_seq = a.swtewle_dcmt_seqno
                           AND b.swtewls_seg = c_interchange_trn_trl_seg)
                   AND a.swtewle_elm_seq = 1) f
         WHERE e.dcmt = f.dcmt;
    BEGIN
      p_accepted_out := TRUE;
    
      FOR st_ref_rec IN st_ref_c
      LOOP
        -- dbms_output.put_line(st_ref_rec.st_ref ||' '||st_ref_rec.se_ref);
        IF st_ref_rec.st_ref <> st_ref_rec.se_ref THEN
          IF NOT wf_ak3_exists_db(p_dcmt_in, c_interchange_trn_trl_seg,
                                  to_char(p_line_in)) THEN
            wp_build_ak3_seg_db(p_dcmt_in, c_interchange_trn_trl_seg,
                                to_char(p_line_in), '8');
          END IF; /* NOT wf_ak3_exists (
                                             p_dcmt_in,
                                             c_interchange_trn_trl_seg,
                                             TO_CHAR (p_line_in)
                                             ) */
        
          wp_build_ak4_seg_db(p_dcmt_in, 2, '3', st_ref_rec.st_ref);
          p_accepted_out := FALSE;
        END IF; /* st_ref_rec.st_ref <> st_ref_rec.se_ref */
      END LOOP;
    
      IF p_accepted_out THEN
        FOR tran_couunt_rec IN tran_couunt_c
        LOOP
          IF tran_couunt_rec.act_count <>
             to_number(TRIM(tran_couunt_rec.se_count)) THEN
            IF NOT wf_ak3_exists_db(p_dcmt_in, c_interchange_trn_trl_seg,
                                    to_char(p_line_in)) THEN
              wp_build_ak3_seg_db(p_dcmt_in, c_interchange_trn_trl_seg,
                                  to_char(p_line_in), '8');
            END IF; /* NOT wf_ak3_exists (
                                                     p_dcmt_in,
                                                     c_interchange_trn_trl_seg,
                                                     TO_CHAR (p_line_in)
                                                     ) */
          
            wp_build_ak4_seg_db(p_dcmt_in, 1, '4', tran_couunt_rec.se_count);
            p_accepted_out := FALSE;
          END IF; /* tran_couunt_rec.act_count <>
                                                                                                                                                                 TO_NUMBER (TRIM (tran_couunt_rec.se_count)) */
        --dbms_output.put_line(tran_couunt_rec.act_count ||' '||tran_couunt_rec.se_count);
        END LOOP;
      END IF; /* p_accepted_out */
    END wp_chk_st_se;
  
    /*
      PROCEDURE wp_chk_gs_ge  checks segment group header
      and segment group trailer of present transaction.
      If no of trasacton set in  present group is incorrect
      or if group control number is not matched,
      this procedure generates outbound 997.
    
      parameters:
      p_dcmt_in         Present document sequence number
      p_line_in         Present segment line number
      p_accepted_out    out parameter that specifies
                        valied
                        if valied it is set to TRUE
                        if invalid it is set to FALSE
    
    
    */
  
    PROCEDURE wp_chk_gs_ge
    (
      p_dcmt_in      swtewls.swtewls_dcmt_seq%TYPE
     ,p_line_in      NUMBER
     ,p_accepted_out OUT BOOLEAN
    ) IS
      CURSOR gs_ref_c IS
        SELECT gs_ref
              ,ge_ref
          FROM (SELECT a.swtewle_elm_value  gs_ref
                      ,a.swtewle_dcmt_seqno dcmt
                  FROM swtewle a
                 WHERE a.swtewle_dcmt_seqno = p_dcmt_in
                   AND a.swtewle_line_num = 2
                   AND a.swtewle_elm_seq = 6) d
              ,(SELECT a.swtewle_elm_value  ge_ref
                      ,a.swtewle_dcmt_seqno dcmt
                  FROM swtewle a
                 WHERE a.swtewle_dcmt_seqno = p_dcmt_in
                   AND a.swtewle_line_num =
                       (SELECT MAX(b.swtewls_line_num)
                          FROM swtewls b
                         WHERE b.swtewls_dcmt_seq = a.swtewle_dcmt_seqno
                           AND b.swtewls_seg = c_functional_gruop_trl_seg)
                   AND a.swtewle_elm_seq = 2) e
         WHERE d.dcmt = e.dcmt;
    
      CURSOR tran_count_c IS
        SELECT *
          FROM (SELECT COUNT(DISTINCT a.swtewle_dcmt_seqno) act_count
                  FROM swtewle a
                 WHERE a.swtewle_line_num = 2
                   AND a.swtewle_elm_seq = 6
                   AND a.swtewle_elm_value IN
                       (SELECT b.swtewle_elm_value
                          FROM swtewle b
                         WHERE b.swtewle_dcmt_seqno = p_dcmt_in
                           AND b.swtewle_line_num = 2
                           AND b.swtewle_elm_seq = 6)) e
              ,(SELECT a.swtewle_elm_value ge_count
                  FROM swtewle a
                 WHERE a.swtewle_dcmt_seqno = p_dcmt_in
                   AND a.swtewle_elm_seq = 1
                   AND a.swtewle_line_num =
                       (SELECT b.swtewls_line_num
                          FROM swtewls b
                         WHERE b.swtewls_dcmt_seq = a.swtewle_dcmt_seqno
                           AND b.swtewls_seg = c_functional_gruop_trl_seg)) f;
    
      PROCEDURE wp_delete_from_load_area IS
        l_count NUMBER := 0;
      
        CURSOR delete_dcmt_c IS
          SELECT DISTINCT (a.swtewle_dcmt_seqno) dcmt
            FROM swtewle a
           WHERE a.swtewle_line_num = 2
             AND a.swtewle_elm_seq = 6 --2
             AND a.swtewle_elm_value IN
                 (SELECT b.swtewle_elm_value
                    FROM swtewle b
                   WHERE b.swtewle_dcmt_seqno = p_dcmt_in
                     AND b.swtewle_line_num = 2
                     AND b.swtewle_elm_seq = 6); --2
      
        CURSOR gs_grp_seqno_c IS
          SELECT b.swtewle_elm_value no_included
            FROM swtewle b
           WHERE b.swtewle_dcmt_seqno = p_dcmt_in
             AND b.swtewle_line_num =
                 (SELECT c.swtewls_line_num
                    FROM swtewls c
                   WHERE c.swtewls_dcmt_seq = b.swtewle_dcmt_seqno
                     AND c.swtewls_seg = c_functional_gruop_trl_seg)
             AND b.swtewle_elm_seq = 1;
      BEGIN
        FOR gs_grp_seqno_rec IN gs_grp_seqno_c
        LOOP
          UPDATE swteake a
             SET a.swteake_elm_value = gs_grp_seqno_rec.no_included
           WHERE a.swteake_elm_seq = 2
             AND a.swteake_dcmt_seqno = p_dcmt_in
             AND a.swteake_line_num =
                 (SELECT b.swteaks_line_num
                    FROM swteaks b
                   WHERE b.swteaks_dcmt_seq = a.swteake_dcmt_seqno
                     AND b.swteaks_seg = c_fnl_group_response_trailer);
        END LOOP;
      
        FOR delete_dcmt_rec IN delete_dcmt_c
        LOOP
          l_count := l_count + 1;
        
          DELETE FROM swtewle
           WHERE swtewle_dcmt_seqno = delete_dcmt_rec.dcmt;
        
          DELETE FROM swtewls
           WHERE swtewls_dcmt_seq = delete_dcmt_rec.dcmt;
        END LOOP; --delete_dcmt_c
      
        UPDATE swteake a
           SET a.swteake_elm_value = to_char(l_count)
         WHERE a.swteake_elm_seq IN (3)
           AND a.swteake_dcmt_seqno = p_dcmt_in
           AND a.swteake_line_num =
               (SELECT b.swteaks_line_num
                  FROM swteaks b
                 WHERE b.swteaks_dcmt_seq = a.swteake_dcmt_seqno
                   AND b.swteaks_seg = c_fnl_group_response_trailer);
      END wp_delete_from_load_area;
    
      PROCEDURE wp_delete_from_ack_area IS
      BEGIN
        DELETE FROM swteake a
         WHERE a.swteake_dcmt_seqno = p_dcmt_in
           AND a.swteake_line_num IN
               (SELECT b.swteaks_line_num
                  FROM swteaks b
                 WHERE b.swteaks_dcmt_seq = a.swteake_dcmt_seqno
                   AND b.swteaks_seg IN
                       (c_tr_set_response_header, gc_data_segment_note,
                        gc_data_element_note, c_tr_set_response_trailer));
      
        DELETE FROM swteaks b
         WHERE b.swteaks_dcmt_seq = p_dcmt_in
           AND b.swteaks_seg IN
               (c_tr_set_response_header, gc_data_segment_note,
                gc_data_element_note, c_tr_set_response_trailer);
      END wp_delete_from_ack_area;
    BEGIN
      FOR gs_ref_rec IN gs_ref_c
      LOOP
        IF gs_ref_rec.gs_ref <> gs_ref_rec.ge_ref THEN
          wp_delete_from_load_area;
          wp_delete_from_ack_area;
          /*DBMS_OUTPUT.put_line (
                'need to skip  '
             || gs_ref_rec.gs_ref
             || ' '
             || gs_ref_rec.ge_ref
          ); */
        END IF; --gs_ref_rec.gs_ref <> gs_ref_rec.ge_ref
      END LOOP;
    
      --dbms_output.put_line('hay this is GE');
      FOR tran_count_rec IN tran_count_c
      LOOP
        IF wf_is_numeric_db(tran_count_rec.ge_count) THEN
          NULL;
          -- DBMS_OUTPUT.put_line (tran_count_rec.ge_count || 'is numeric');
        ELSE
          wp_delete_from_load_area;
          wp_delete_from_ack_area;
        END IF; /* wf_is_numeric_db (tran_count_rec.ge_count) */
      
        IF (tran_count_rec.act_count <> tran_count_rec.ge_count) THEN
          wp_delete_from_load_area;
          wp_delete_from_ack_area;
          /*
          DBMS_OUTPUT.put_line (
                'need to skip beacuse count does not match'
             || TO_CHAR (tran_count_rec.act_count)
             || ' '
             || tran_count_rec.ge_count
          );
          */
        END IF; --tran_count_rec.act_count <>  tran_count_rec.ge_count
      END LOOP; --tran_count_c
    END wp_chk_gs_ge;
  
    -->main procedure for wp_load_outbound_ack starts here
  BEGIN
    l_state := 'before initializing variables at begin';
    --initialize variables
    l_previous_seg      := c_interchange_cntrl_trl_seg;
    l_previous_loop     := c_interchange_cntrl_trl_seg;
    l_present_loop_seg  := c_interchange_cntrl_trl_seg;
    l_previous_loop_seg := c_interchange_cntrl_trl_seg;
    --> for each transaction in workload area(i.e distinct
    --> document sequence from swtwls)..
    l_state := 'before opening cursor swtewls_dcmt_seq_c';
  
    FOR swtewls_dcmt_seq_rec IN swtewls_dcmt_seq_c
    LOOP
      l_accepted := TRUE;
      --> ..for each segment in the transaction..
      l_state := 'before opening cursor segment_sequence_c';
    
      FOR segment_sequence_rec IN segment_sequence_c(swtewls_dcmt_seq_rec.dcmt_seq)
      LOOP
        --> assign type of transaction. (Since GE, and IEA are
        --> populated programatically for each transaction,
        --> they will not have type)
        l_state := 'before assigning transaction type';
      
        IF segment_sequence_rec.swtewls_seg IN
           (c_functional_gruop_trl_seg, c_interchange_cntrl_trl_seg) THEN
          l_type := NULL;
        ELSE
          l_type := segment_sequence_rec.swtewls_type;
        END IF; /* segment_sequence_rec.swtewls_seg IN
                                                                                                                   (c_functional_gruop_trl_seg, c_interchange_cntrl_trl_seg) */
      
        --> get present segment
        l_present_seg := segment_sequence_rec.swtewls_seg;
        l_state       := 'before incrementing segment count';
      
        --> count segment repeats
        IF l_previous_seg = l_present_seg THEN
          l_segment_count := l_segment_count + 1;
        ELSE
          l_segment_count := 1;
        END IF; /* l_previous_seg = l_present_seg */
      
        --> if header and trailer segments' segment repeat is more than one,
        --> create 997(All these segments' segment repeat should not be more than 1).
        l_state := 'before building out997 for heder, trailer seg repeat error';
      
        IF l_present_seg IN
           (c_interchange_cntrl_hdr_seg, c_functional_gruop_hdr_seg,
            c_interchange_trn_hdr_seg, c_interchange_trn_trl_seg,
            c_functional_gruop_trl_seg, c_interchange_cntrl_trl_seg,
            c_interchange_trn_trl_seg) AND l_segment_count > 1 THEN
          wp_build_ak3_seg_db(segment_sequence_rec.swtewls_dcmt_seq,
                              l_present_seg,
                              segment_sequence_rec.swtewls_line_num - 2, '5');
          l_accepted := FALSE;
        END IF; /* l_present_seg IN (c_interchange_cntrl_hdr_seg,
                                     c_functional_gruop_hdr_seg,
                                     c_interchange_trn_hdr_seg,
                                     c_interchange_trn_trl_seg,
                                     c_functional_gruop_trl_seg,
                                     c_interchange_cntrl_trl_seg,
                                     c_interchange_trn_trl_seg
                                     ) */
      
        --> if the present segment is transaction header,
        --> then build acknowledgement(997) interchange header, group header,
        --> and transactional header
        l_state := 'before building out997 isa, gs, st segments';
      
        IF l_accepted THEN
          IF l_present_seg = c_interchange_trn_hdr_seg THEN
            wp_load_ack_isa_gs_st(segment_sequence_rec.swtewls_dcmt_seq);
          END IF; /*l_present_seg = C_interchange_trn_hdr_seg*/
        END IF; /* l_accepted */
      
        --> if the present segment is transaction trailer,
        --> check for no of lines included in transaction,
        --> and check for transaction control number match
      
        IF l_accepted THEN
          IF l_present_seg = c_interchange_trn_trl_seg THEN
            l_state := 'before calling wp_chk_st_se';
            wp_chk_st_se(segment_sequence_rec.swtewls_dcmt_seq,
                         segment_sequence_rec.swtewls_line_num - 2,
                         l_accepted);
          END IF; /*l_present_seg = C_interchange_trn_hdr_seg*/
        END IF; /* l_accepted */
      
        --> if the present segment is transaction trailer,
        --> check for no of lines included in transaction,
        --> and check for transaction control number match
      
        IF l_present_seg = c_functional_gruop_trl_seg THEN
          l_state := 'before calling wp_chk_gs_ge';
          wp_chk_gs_ge(segment_sequence_rec.swtewls_dcmt_seq,
                       segment_sequence_rec.swtewls_line_num - 2, l_accepted);
        END IF; /*l_present_seg = C_interchange_trn_hdr_seg*/
      
        --> find the parent loop segment to which present segment belongs
        IF present_sequence_c%ISOPEN THEN
          CLOSE present_sequence_c;
        END IF; /* present_sequence_c%ISOPEN */
      
        l_state := 'before getting present loop';
        OPEN present_sequence_c(l_type, l_present_seg, l_previous_loop,
                                l_previous_seg);
        FETCH present_sequence_c
          INTO l_new_seq;
        l_cur_found := present_sequence_c%FOUND;
        CLOSE present_sequence_c;
        l_state := 'before calculating present loop count';
      
        --> calculate loop count
        IF l_new_seq NOT IN
           (c_interchange_cntrl_hdr_seg, c_functional_gruop_hdr_seg,
            c_interchange_trn_hdr_seg, c_interchange_trn_trl_seg,
            c_functional_gruop_trl_seg, c_interchange_cntrl_trl_seg) AND
           REPLACE(REPLACE(l_new_seq, 'SMD', 'SUM'), 'SMH', 'SUM') =
           l_present_seg AND l_accepted THEN
          l_present_loop_seg := l_new_seq;
        
          IF l_present_loop_seg = l_previous_loop_seg THEN
            l_loop_count := l_loop_count + 1;
          ELSE
            l_loop_count := 1;
          END IF; /* l_present_loop_seg = l_previous_loop_seg */
        
          l_previous_loop_seg := l_present_loop_seg;
        END IF; /* l_new_seq NOT IN (c_interchange_cntrl_hdr_seg,
                                     c_functional_gruop_hdr_seg,
                                     c_interchange_trn_hdr_seg,
                                     c_interchange_trn_trl_seg,
                                     c_functional_gruop_trl_seg,
                                     c_interchange_cntrl_trl_seg
                                     )... */
      
        --> if the parent loop is not exits, generate ack.(997) with
        --> with rejected status
      
        l_state := 'before generating outbound997 for sequence error';
      
        IF NOT l_cur_found THEN
          /*DBMS_OUTPUT.put_line (
                'At line '
             || TO_CHAR (segment_sequence_rec.swtewls_line_num - 2)
             || '( '
             || TO_CHAR (segment_sequence_rec.swtewls_line_num)
             || ')'
             || l_present_seg
             || ' seg pos is wrong'
          );*/
          l_accepted := FALSE;
          /* Since AFTER SE we build ak9, we need not look for IEA, AND GE*/
          IF l_present_seg NOT IN ('IEA', 'GE') THEN
          
            wp_build_ak3_seg_db(segment_sequence_rec.swtewls_dcmt_seq,
                                l_present_seg,
                                segment_sequence_rec.swtewls_line_num - 2,
                                '7');
          END IF;
        ELSE
          --> if the seg pos is correct and is not loop segment
          --> check for allowed segment repeats.
          --> if the present segment repeat is more than the allowed
          --> segment repeate, generate ack.(997) with rejected status
          IF l_present_seg NOT IN
             (c_interchange_cntrl_hdr_seg, c_functional_gruop_hdr_seg,
              c_functional_gruop_trl_seg, c_interchange_trn_trl_seg,
              c_interchange_cntrl_trl_seg) THEN
            l_state := 'before generating outbound997 for seg repeat error';
          
            IF NOT wf_is_loop_seg(l_type, segment_sequence_rec.swtewls_seg) THEN
              NULL;
              l_repeats := wf_allowd_seg_rpt(l_type, l_new_seq,
                                             segment_sequence_rec.swtewls_seg);
            
              IF l_repeats IS NOT NULL AND l_segment_count > l_repeats THEN
                l_accepted := FALSE;
                wp_build_ak3_seg_db(segment_sequence_rec.swtewls_dcmt_seq,
                                    l_present_seg,
                                    segment_sequence_rec.swtewls_line_num - 2,
                                    '5');
              END IF; /* l_repeats IS NOT NULL
                                                             AND l_segment_count > l_repeats */
            END IF; /* NOT wf_is_loop_seg (
                                                      l_type,
                                                      segment_sequence_rec.swtewls_seg
                                                      ) */
          
            l_state := 'before generating outbound997 for element chk error';
          
            --> check elements and error out if the element value is wrong
            IF l_accepted THEN
              wp_check_elements(segment_sequence_rec.swtewls_dcmt_seq,
                                segment_sequence_rec.swtewls_line_num,
                                segment_sequence_rec.swtewls_seg, l_new_seq,
                                l_success_out);
            END IF; /* l_accepted */
          END IF; /* l_present_seg NOT IN (c_interchange_cntrl_hdr_seg,
                                             c_functional_gruop_hdr_seg,
                                             c_functional_gruop_trl_seg,
                                             c_interchange_trn_trl_seg,
                                             c_interchange_cntrl_trl_seg
                                             ) */
        END IF; /* NOT l_cur_found */
      
        --> if the element is transaction trailer, generate ak5, ak9, ge, iea segmens
        --> of ack.(997)
        l_state := 'before generating ak5, ak9, ge, iea segments for outbound997';
      
        IF l_present_seg = c_interchange_trn_trl_seg THEN
          DELETE FROM swteake a
           WHERE a.swteake_dcmt_seqno =
                 segment_sequence_rec.swtewls_dcmt_seq
             AND a.swteake_line_num IN
                 (SELECT b.swteaks_line_num
                    FROM swteaks b
                   WHERE b.swteaks_dcmt_seq =
                         segment_sequence_rec.swtewls_dcmt_seq
                     AND b.swteaks_seg IN
                         (c_tr_set_response_trailer,
                          c_fnl_group_response_trailer,
                          c_interchange_trn_trl_seg,
                          c_functional_gruop_trl_seg,
                          c_interchange_cntrl_trl_seg));
        
          DELETE FROM swteaks b
           WHERE b.swteaks_dcmt_seq = segment_sequence_rec.swtewls_dcmt_seq
             AND b.swteaks_seg IN
                 (c_tr_set_response_trailer, c_fnl_group_response_trailer,
                  c_interchange_trn_trl_seg, c_functional_gruop_trl_seg,
                  c_interchange_cntrl_trl_seg);
        
          IF NOT l_accepted THEN
            wp_generate_ak5(segment_sequence_rec.swtewls_dcmt_seq, 'R');
          ELSE
            /* NOT l_accepted  */
            wp_generate_ak5(segment_sequence_rec.swtewls_dcmt_seq, 'A');
          END IF; /* NOT l_accepted */
        END IF; /* l_present_seg = C_interchange_trn_trl_seg */
      
        /* IF      l_previous_loop = l_new_seq
             AND l_previous_loop = l_present_seg
         THEN
            l_loop_count := l_loop_count + 1;
        ELSE
            l_loop_count := 0;
         END IF;*/
      
        l_previous_loop := l_new_seq;
        l_previous_seg  := l_present_seg;
        IF NOT l_cur_found AND l_present_seg = ('SE') THEN
          l_previous_loop := 'SE';
          l_previous_seg  := 'SE';
        ELSIF l_cur_found AND l_present_seg = ('GE') THEN
          l_previous_loop := 'GE';
          l_previous_seg  := 'GE';
        ELSIF l_cur_found AND l_present_seg = ('IEA') THEN
          l_previous_loop := 'IEA';
          l_previous_seg  := 'IEA';
        END IF;
      END LOOP; --segment_sequence_c
    
      COMMIT;
    
    END LOOP; /*swtewls_dcmt_seq_c*/
  
    COMMIT;
    --
    NULL;
    p_success_out := TRUE;
    p_message_out := l_state;
    -- much more code
  EXCEPTION
    WHEN le_exception1 THEN
      --handele business exception here.
      wp_handle_error_db('EDI', 'wp_load_outbound_ack', 'BUSINESS',
                         'le_exception1 encountered at state ' || l_state,
                         l_success_out, l_message_out);
      p_success_out := FALSE;
      p_message_out := l_state;
    WHEN OTHERS THEN
      -- handle oracle errors here.
      wp_handle_error_db('EDI', 'wp_load_outbound_ack', 'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_state,
                         l_success_out, l_message_out);
      p_success_out := FALSE;
      p_message_out := l_state;
  END wp_load_outbound_ack;

  --

  --
  PROCEDURE wp_gen_ack_files
  (
    p_dir_in      VARCHAR2
   ,p_message_out OUT VARCHAR2
   ,p_success_out OUT BOOLEAN
  ) IS
  
    --***********************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wsakedi.wp_gen_ack_files
    --  Process Associated : EDI
    --  Business Logic :
    --   This procedure reads acknowledgments from acknowledgment tables
    --   (swteaks, swteake) and generates outbound997 for incoming
    --   transactions.
    --  Documentation Links:
    --  G:\Documentation\Technical Specifications\EDI\
    --   Q202074 EDI Tool replacement\out997_technical_specifications.doc
    --
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User       Reason For Change
    -- -----  ---  ---------  -----------  ------     -----------------------
    --  n/a   A   B5-002941  20-AUG-2002  VBANGALO   Initial Creation.
    --  n/a   C   B5-002964  13-NOV-2002  VBANGALO   Modified code so that
    --                                               AK1 segments are not grouped
    --                                               under same ST segment
    --
    -- Parameter Information:
    -- ------------
    --  p_dir_in          in parameter  Directory in which out997 to be
    --                                  generated.
    --  p_success_out    out parameter  set to TRUE if process is success
    --                                  set to FALSE if process is failed.
    --  p_message_out    out parameter  message.
    --************************************************************************
  
    l_segment         VARCHAR2(2000);
    l_min_dcmt        swteaks.swteaks_dcmt_seq%TYPE;
    l_max_dcmt        swteaks.swteaks_dcmt_seq%TYPE;
    l_grp_frst_dcmt   swteaks.swteaks_dcmt_seq%TYPE;
    l_grp_last_dcmt   swteaks.swteaks_dcmt_seq%TYPE;
    l_print_segemt    BOOLEAN;
    l_line_count      NUMBER;
    l_isa_seq         NUMBER;
    l_gs_seq          NUMBER;
    l_ts_seq          NUMBER;
    l_grp_cntrl_numb  swteake.swteake_elm_value%TYPE;
    l_ack_code_out    swteake.swteake_elm_value%TYPE;
    l_recvd_trans_out swteake.swteake_elm_value%TYPE;
    l_sent_trans_out  swteake.swteake_elm_value%TYPE;
    l_acc_trans_out   swteake.swteake_elm_value%TYPE;
    l_file_name       VARCHAR2(100);
    l_file_id         utl_file.file_type;
    l_message_out     VARCHAR2(2000);
    l_success_out     BOOLEAN;
    l_state           VARCHAR2(2000);
    l_sbgi_code       swteake.swteake_elm_value%TYPE;
    le_exception1 EXCEPTION;
    c_interchange_cntrl_hdr_seg  CONSTANT CHAR(3) := 'ISA';
    c_interchange_cntrl_trl_seg  CONSTANT CHAR(3) := 'IEA';
    c_functional_gruop_hdr_seg   CONSTANT CHAR(2) := 'GS';
    c_functional_gruop_trl_seg   CONSTANT CHAR(2) := 'GE';
    c_interchange_trn_hdr_seg    CONSTANT CHAR(2) := 'ST';
    c_interchange_trn_trl_seg    CONSTANT CHAR(2) := 'SE';
    c_fnl_group_response_header  CONSTANT CHAR(3) := 'AK1';
    c_tr_set_response_header     CONSTANT CHAR(3) := 'AK2';
    c_data_segment_note          CONSTANT CHAR(3) := 'AK3';
    c_data_element_note          CONSTANT CHAR(3) := 'AK4';
    c_tr_set_response_trailer    CONSTANT CHAR(3) := 'AK5';
    c_fnl_group_response_trailer CONSTANT CHAR(3) := 'AK9';
  
    CURSOR grp_cntrl_numb_c IS
      SELECT DISTINCT a.swteake_elm_value grp_cntrl_numb
        FROM swteake a
       WHERE a.swteake_line_num = 4
         AND a.swteake_elm_seq = 2;
  
    CURSOR sbgi_code_c(c_grp_cntrl_num_in swteake.swteake_elm_value%TYPE) IS
      SELECT DISTINCT a.swteake_elm_value sbgi_code
        FROM swteake a
       WHERE a.swteake_line_num = 1
         AND a.swteake_elm_seq = 8
         AND EXISTS
       (SELECT 'x'
                FROM swteake b
               WHERE b.swteake_dcmt_seqno = a.swteake_dcmt_seqno
                 AND b.swteake_line_num = 4
                 AND b.swteake_elm_seq = 2
                 AND b.swteake_elm_value = c_grp_cntrl_num_in
              --'023120180'
              );
    /*SELECT DISTINCT a.swteake_elm_value sbgi_code
     FROM swteake a
    WHERE a.swteake_line_num = 1
      AND a.swteake_elm_seq = 8;*/
  
    CURSOR transactions_c(c_grp_cntrl_in swteake.swteake_elm_value%TYPE) IS
      SELECT DISTINCT swteake_dcmt_seqno dcmt
        FROM swteake b
       WHERE b.swteake_dcmt_seqno IN
             (SELECT DISTINCT a.swteake_dcmt_seqno dcmt
                FROM swteake a
               WHERE a.swteake_line_num = 4
                 AND a.swteake_elm_seq = 2
                 AND a.swteake_elm_value = c_grp_cntrl_in
              --'023120632'
              )
         AND b.swteake_elm_seq = 1
         AND (b.swteake_elm_value = 'R' OR
             (b.swteake_elm_value = 'A' AND EXISTS
              (SELECT c.swtewle_elm_value
                  FROM swtewle c
                 WHERE c.swtewle_dcmt_seqno = b.swteake_dcmt_seqno
                   AND c.swtewle_line_num = 1
                   AND c.swtewle_elm_seq = 14
                   AND c.swtewle_elm_value = 1)))
       ORDER BY swteake_dcmt_seqno;
  
    CURSOR first_last_dcmt_c(c_grp_cntrl_in swteake.swteake_elm_value%TYPE) IS
    
      SELECT MIN(b.swteake_dcmt_seqno) first_dcmt
            ,MAX(b.swteake_dcmt_seqno) last_dcmt
        FROM swteake b
       WHERE b.swteake_dcmt_seqno IN
             (SELECT DISTINCT a.swteake_dcmt_seqno dcmt
                FROM swteake a
               WHERE a.swteake_line_num = 4
                 AND a.swteake_elm_seq = 2
                 AND a.swteake_elm_value = c_grp_cntrl_in
              --'023120632'
              )
         AND b.swteake_elm_seq = 1
         AND (b.swteake_elm_value = 'R' OR
             (b.swteake_elm_value = 'A' AND EXISTS
              (SELECT c.swtewle_elm_value
                  FROM swtewle c
                 WHERE c.swtewle_dcmt_seqno = b.swteake_dcmt_seqno
                   AND c.swtewle_line_num = 1
                   AND c.swtewle_elm_seq = 14
                   AND c.swtewle_elm_value = 1)));
    /*
    SELECT MIN (b.swteake_dcmt_seqno) first_dcmt,
           MAX (b.swteake_dcmt_seqno) last_dcmt
      FROM swteake b
     WHERE b.swteake_dcmt_seqno IN
                 (SELECT DISTINCT a.swteake_dcmt_seqno dcmt
                             FROM swteake a
                            WHERE a.swteake_line_num = 1
                              AND a.swteake_elm_seq = 8
                              AND a.swteake_elm_value = c_sbgi_code_in)
       AND b.swteake_elm_seq = 1
       AND (   b.swteake_elm_value = 'R'
            OR (    b.swteake_elm_value = 'A'
                AND EXISTS ( SELECT c.swtewle_elm_value
                               FROM swtewle c
                              WHERE c.swtewle_dcmt_seqno =
                                                    b.swteake_dcmt_seqno
                                AND c.swtewle_line_num = 1
                                AND c.swtewle_elm_seq = 14
                                AND c.swtewle_elm_value = 1)
               )
           );*/
  
    CURSOR last_dcmt_c(c_sbgi_code_in swteake.swteake_elm_value%TYPE) IS
      SELECT MAX(a.swteake_dcmt_seqno) first_dcmt
        FROM swteake a
       WHERE a.swteake_line_num = 1
         AND a.swteake_elm_seq = 8
         AND a.swteake_elm_value = c_sbgi_code_in;
  
    CURSOR swteaks_1_c(c_dcmt_in swteaks.swteaks_dcmt_seq%TYPE) IS
      SELECT swteaks_dcmt_seq
            ,swteaks_line_num
            ,swteaks_seg
        FROM swteaks
       WHERE swteaks_dcmt_seq = c_dcmt_in
       ORDER BY swteaks_dcmt_seq
               ,swteaks_line_num;
  
    CURSOR swteake_1_c
    (
      c_dcmt_in swteaks.swteaks_dcmt_seq%TYPE
     ,c_line_in swteaks.swteaks_line_num%TYPE
    ) IS
      SELECT swteake_elm_seq
            ,swteake_elm_value
            ,swteake_dcmt_seqno
            ,swteake_line_num
        FROM swteake
       WHERE swteake_dcmt_seqno = c_dcmt_in
         AND swteake_line_num = c_line_in
       ORDER BY swteake_elm_seq;
  
    CURSOR swteaks_c IS
      SELECT swteaks_dcmt_seq
            ,swteaks_line_num
            ,swteaks_seg
        FROM swteaks
       ORDER BY swteaks_dcmt_seq
               ,swteaks_line_num;
  
    CURSOR group_swteaks_c IS
      SELECT swteaks_dcmt_seq
            ,swteaks_line_num
            ,swteaks_seg
        FROM swteaks a
       WHERE NOT EXISTS (SELECT 'x'
                FROM swteaks b
               WHERE b.swteaks_dcmt_seq = a.swteaks_dcmt_seq
                 AND b.swteaks_seg = 'AK5')
       ORDER BY swteaks_dcmt_seq
               ,swteaks_line_num;
  
    CURSOR swteake_c
    (
      c_dcmt_in swteaks.swteaks_dcmt_seq%TYPE
     ,c_line_in swteaks.swteaks_line_num%TYPE
    ) IS
      SELECT swteake_elm_seq
            ,swteake_elm_value
            ,swteake_dcmt_seqno
            ,swteake_line_num
        FROM swteake
       WHERE swteake_dcmt_seqno = c_dcmt_in
         AND swteake_line_num = c_line_in
       ORDER BY swteake_elm_seq;
  
    CURSOR group_c(c_sbgi_in swteake.swteake_elm_value%TYPE) IS
      SELECT DISTINCT a.swteake_elm_value grp_code
        FROM swteake a
       WHERE a.swteake_line_num = 4
         AND a.swteake_elm_seq = 2
         AND a.swteake_dcmt_seqno IN
             (SELECT DISTINCT a.swteake_dcmt_seqno dcmt
                FROM swteake a
               WHERE a.swteake_line_num = 1
                 AND a.swteake_elm_seq = 8
                 AND a.swteake_elm_value = c_sbgi_in);
  
    CURSOR grp_first_last_c
    (
      c_sbgi_in  swteake.swteake_elm_value%TYPE
     ,c_group_in swteake.swteake_elm_value%TYPE
    ) IS
      SELECT MIN(a.swteake_dcmt_seqno) first_dcmt
            ,MAX(a.swteake_dcmt_seqno) last_dcmt
        FROM swteake a
       WHERE a.swteake_line_num = 4
         AND a.swteake_elm_seq = 2
         AND a.swteake_elm_value = c_group_in
         AND a.swteake_dcmt_seqno IN
             (SELECT DISTINCT a.swteake_dcmt_seqno dcmt
                FROM swteake a
               WHERE a.swteake_line_num = 1
                 AND a.swteake_elm_seq = 8
                 AND a.swteake_elm_value = c_sbgi_in)
         AND EXISTS
       (SELECT DISTINCT swteake_dcmt_seqno dcmt
                FROM swteake d
               WHERE d.swteake_dcmt_seqno = a.swteake_dcmt_seqno
                 AND d.swteake_elm_seq = 1
                 AND (d.swteake_elm_value = 'R' OR
                     (d.swteake_elm_value = 'A' AND EXISTS
                      (SELECT c.swtewle_elm_value
                          FROM swtewle c
                         WHERE c.swtewle_dcmt_seqno = d.swteake_dcmt_seqno
                           AND c.swtewle_line_num = 1
                           AND c.swtewle_elm_seq = 14
                           AND c.swtewle_elm_value = 1))));
  
    CURSOR group_ack_c IS
      SELECT swteaks_dcmt_seq
            ,swteaks_line_num
            ,swteaks_seg
        FROM swteaks
       ORDER BY swteaks_dcmt_seq
               ,swteaks_line_num;
  
    FUNCTION wf_get_inst_code(p_dcmt_in swteake.swteake_dcmt_seqno%TYPE)
      RETURN swteake.swteake_elm_value%TYPE IS
      l_result swteake.swteake_elm_value%TYPE := NULL;
    
      /* This procedure returns inst code from isa segment
         for the present transaction.
         Parameters :
                     p_dcmt_in present transaction document sequnce no.
      */
      CURSOR inst_code_c IS
        SELECT a.swteake_elm_value inst_code
          FROM swteake a
         WHERE a.swteake_dcmt_seqno = p_dcmt_in
           AND a.swteake_line_num = 1
           AND a.swteake_elm_seq = 8;
    BEGIN
      FOR inst_code_rec IN inst_code_c
      LOOP
        l_result := inst_code_rec.inst_code;
      END LOOP;
    
      RETURN l_result;
    END wf_get_inst_code;
  
    PROCEDURE wp_get_group_information
    (
      p_sbgi_in         swteake.swteake_elm_value%TYPE
     ,p_group_in        swteake.swteake_elm_value%TYPE
     ,p_ack_code_out    OUT swteake.swteake_elm_value%TYPE
     ,p_recvd_trans_out OUT swteake.swteake_elm_value%TYPE
     ,p_sent_trans_out  OUT swteake.swteake_elm_value%TYPE
     ,p_acc_trans_out   OUT swteake.swteake_elm_value%TYPE
    ) IS
      /*
        This procedure gets information pertaining to current group,
        such as no of transactions that are received, no of transactions
        that are sent, no of transactions that are accepted and ack code.
      
        parameters:
        p_sbgi_in  Inst code, present transaction belongs to
        p_group_in group, present transaction belongs to
        p_ack_cod_out Acknowledgement code
                      A- ALL accepted in this group
                      R- All Rejected in this group
                      P- Some of them accepted and some of them rejected
        p_recvd_trans_out out paramenter, returns no of transactions received
                              for the group
        p_sent_trans_out  out parameter, returns no of transactions processed
        p_acc_trans_out   out parameter, returns no of transactions accepted
      
      
      */
      l_count     NUMBER;
      l_acc_count NUMBER;
      l_rej_count NUMBER;
    
      --> this cursor selects no of transactions under group control number
      CURSOR tran_for_group_c
      (
        c_sbgi_in  swteake.swteake_elm_value%TYPE
       ,c_group_in swteake.swteake_elm_value%TYPE
      ) IS
        SELECT DISTINCT a.swteake_dcmt_seqno dcmt
          FROM swteake a
         WHERE a.swteake_line_num = 4
           AND a.swteake_elm_seq = 2
           AND a.swteake_elm_value = c_group_in
           AND a.swteake_dcmt_seqno IN
               (SELECT DISTINCT a.swteake_dcmt_seqno dcmt
                  FROM swteake a
                 WHERE a.swteake_line_num = 1
                   AND a.swteake_elm_seq = 8
                   AND a.swteake_elm_value = c_sbgi_in);
    
      --> this cursor selects transaction status,  i.e accepted or rejected
      CURSOR aknowledge_c(c_dcmt_in swteake.swteake_dcmt_seqno%TYPE) IS
        SELECT a.swteake_elm_value elm_value
          FROM swteake a
         WHERE a.swteake_dcmt_seqno = c_dcmt_in
           AND a.swteake_line_num =
               (SELECT b.swteaks_line_num
                  FROM swteaks b
                 WHERE b.swteaks_dcmt_seq = a.swteake_dcmt_seqno
                   AND b.swteaks_seg = c_tr_set_response_trailer);
    BEGIN
      l_count     := 0;
      l_acc_count := 0;
      l_rej_count := 0;
    
      --> for each transaction in a group
      FOR tran_for_group_rec IN tran_for_group_c(p_sbgi_in, p_group_in)
      LOOP
        l_count := l_count + 1;
      
        --> get transaction status
        FOR aknowledge_rec IN aknowledge_c(tran_for_group_rec.dcmt)
        LOOP
          --> count no of tranasactions accepted or rejected
          IF aknowledge_rec.elm_value = 'A' THEN
            l_acc_count := l_acc_count + 1;
          ELSE
            l_rej_count := l_rej_count + 1;
          END IF; /* aknowledge_rec.elm_value = 'A' */
        END LOOP; --aknowledge_c
      END LOOP; --tran_for_group_c
    
      --> set aknowledgement status code
      IF l_count = l_acc_count THEN
        p_ack_code_out := 'A';
      ELSIF l_count = l_rej_count THEN
        p_ack_code_out := 'R';
      ELSE
        p_ack_code_out := 'P';
      END IF; /* l_count = l_acc_count */
    
      --> set no of transactions received, sent, accepted.
      p_recvd_trans_out := to_char(l_count);
      p_sent_trans_out  := to_char(l_count);
      p_acc_trans_out   := to_char(l_acc_count);
      --dbms_output.put_line(to_char(l_count)||' '|| to_char(l_count)||' '|| to_char(l_acc_count));
    END wp_get_group_information;
  
    /*
      This fallowing function returns presence of acknowledgement segment
      for the present transaction.
    
      parameters:
      p_dcmt_in  document sequnce no of the present transaction
    */
    FUNCTION wf_ak5_exists(p_dcmt_in swteaks.swteaks_dcmt_seq%TYPE)
      RETURN BOOLEAN IS
      l_cur_found BOOLEAN;
      l_result    BOOLEAN;
      l_exists    CHAR(1);
    
      CURSOR ak5_exits_c IS
        SELECT 'x'
          FROM swteaks b
         WHERE b.swteaks_dcmt_seq = p_dcmt_in
           AND b.swteaks_seg = c_tr_set_response_trailer;
    BEGIN
      l_result := FALSE;
    
      IF ak5_exits_c%ISOPEN THEN
        CLOSE ak5_exits_c;
      END IF; /* ak5_exits_c%ISOPEN */
    
      OPEN ak5_exits_c;
      FETCH ak5_exits_c
        INTO l_exists;
      l_result := ak5_exits_c%FOUND;
      CLOSE ak5_exits_c;
      RETURN l_result;
    END wf_ak5_exists;
  
    FUNCTION wf_get_ak1_seg(p_dcmt_in swteake.swteake_dcmt_seqno%TYPE)
      RETURN VARCHAR2 IS
      /*
       This function returns ak1 segment for the present
       transaction
       parametrs:
                  p_dcmt_in present document sequence number
      */
      l_result VARCHAR2(100);
    
      CURSOR ak1_seg_c IS
        SELECT a.swteake_elm_value element
          FROM swteake a
         WHERE a.swteake_dcmt_seqno = p_dcmt_in
           AND a.swteake_line_num = 4;
    BEGIN
      FOR ak1_seg_rec IN ak1_seg_c
      LOOP
        l_result := l_result || '|' || ak1_seg_rec.element;
      END LOOP;
    
      RETURN 'AK1' || l_result;
    END wf_get_ak1_seg;
  
    --> Main procedure for  wp_gen_ack_files
  BEGIN
    l_grp_cntrl_numb := NULL;
    l_file_name      := 'O997_' || to_char(SYSDATE, 'YYYYMMDDHH24MISS') ||
                        '.EDI';
    l_state          := 'before opening file';
    wsakfileio.wp_open_file(p_dir_in, l_file_name, 'W', l_file_id,
                            l_success_out, l_message_out);
  
    FOR swteaks_rec IN swteaks_c
    LOOP
      l_segment := swteaks_rec.swteaks_seg || '|';
    
      FOR swteake_rec IN swteake_c(swteaks_rec.swteaks_dcmt_seq,
                                   swteaks_rec.swteaks_line_num)
      LOOP
        l_segment := l_segment || swteake_rec.swteake_elm_value || '|';
      END LOOP;
      -- DBMS_OUTPUT.put_line (RTRIM (l_segment, '|') || '^');
    END LOOP;
  
    -- DBMS_OUTPUT.put_line ('---------------------------------');
  
    --> for each inst code..
    l_state := 'before opening sbgi_c cursor';
    FOR grp_cntrl_numb_rec IN grp_cntrl_numb_c
    LOOP
      FOR sbgi_code_rec IN sbgi_code_c(grp_cntrl_numb_rec.grp_cntrl_numb)
      LOOP
        IF first_last_dcmt_c%ISOPEN THEN
          CLOSE first_last_dcmt_c;
        END IF; /* first_last_dcmt_c%ISOPEN */
      
        -->.., find first and last documents
        OPEN first_last_dcmt_c(grp_cntrl_numb_rec.grp_cntrl_numb);
        FETCH first_last_dcmt_c
          INTO l_min_dcmt
              ,l_max_dcmt;
        CLOSE first_last_dcmt_c;
        --dbms_output.put_line(to_char(l_min_dcmt)||' '||to_char(l_max_dcmt));
        --> for each transaction(i.e document sequence) in a institute..
        l_state := 'Before opening transactions_c cursor';
      
        FOR transactions_rec IN transactions_c(grp_cntrl_numb_rec.grp_cntrl_numb)
        LOOP
          --> intialize variables.
          l_ack_code_out    := NULL;
          l_recvd_trans_out := NULL;
          l_sent_trans_out  := NULL;
          l_acc_trans_out   := NULL;
          --> .. get segment from acknowledgement table
          l_state := ' before opening swteaks_1_c cursor';
        
          FOR swteaks_1_rec IN swteaks_1_c(transactions_rec.dcmt)
          LOOP
            l_print_segemt := FALSE;
          
            --> if the segments belong to ISA, GS, ST AND are
            -- present transaction is first transaction under the instite..
            IF (swteaks_1_rec.swteaks_seg IN
               (c_interchange_cntrl_hdr_seg, c_functional_gruop_hdr_seg,
                 c_interchange_trn_hdr_seg) AND
               swteaks_1_rec.swteaks_dcmt_seq = l_min_dcmt)
              --> or if they are NOT belong to ISA, GS,ST,SE,GE,IEA
               OR
               swteaks_1_rec.swteaks_seg NOT IN
               (c_interchange_cntrl_hdr_seg, c_functional_gruop_hdr_seg,
                c_interchange_trn_hdr_seg, c_interchange_trn_trl_seg,
                c_functional_gruop_trl_seg, c_interchange_cntrl_trl_seg)
              --> or if they belong to SE, GE, IEA and are LAST transaction
              --> under the institute..
               OR (swteaks_1_rec.swteaks_seg IN
               (c_interchange_trn_trl_seg, c_functional_gruop_trl_seg,
                    c_interchange_cntrl_trl_seg) AND
               swteaks_1_rec.swteaks_dcmt_seq = l_max_dcmt) THEN
              --> select that segment value..
              l_segment := swteaks_1_rec.swteaks_seg || '|';
            
              --> ..get corresponding element values.
              FOR swteake_1_rec IN swteake_1_c(swteaks_1_rec.swteaks_dcmt_seq,
                                               swteaks_1_rec.swteaks_line_num)
              LOOP
                --> if the element is AK102 then get group information
                IF swteake_1_rec.swteake_line_num = 4 AND
                   swteake_1_rec.swteake_elm_seq = 2 THEN
                  l_grp_cntrl_numb := NULL;
                  l_grp_cntrl_numb := swteake_1_rec.swteake_elm_value;
                  --dbms_output.put_line(l_grp_cntrl_numb);
                  --dbms_output.put_line(sbgi_code_rec.sbgi_code||' '||l_grp_cntrl_numb);
                  l_state := 'before getting group information';
                  wp_get_group_information(sbgi_code_rec.sbgi_code,
                                           l_grp_cntrl_numb, l_ack_code_out,
                                           l_recvd_trans_out,
                                           l_sent_trans_out, l_acc_trans_out);
                
                  --> get first and last document that belongs
                  --> to the group
                  IF grp_first_last_c%ISOPEN THEN
                    CLOSE grp_first_last_c;
                  END IF; /* grp_first_last_c%ISOPEN */
                
                  OPEN grp_first_last_c(sbgi_code_rec.sbgi_code,
                                        swteake_1_rec.swteake_elm_value);
                  FETCH grp_first_last_c
                    INTO l_grp_frst_dcmt
                        ,l_grp_last_dcmt;
                  CLOSE grp_first_last_c;
                  --dbms_output.put_line(to_char(l_grp_frst_dcmt));
                END IF; /*  swteake_1_rec.swteake_line_num = 4
                                                                       AND swteake_1_rec.swteake_elm_seq = 2 */
              
                --> if the element is AK102
                --> and trasaction is first in the group..
                IF (swteake_1_rec.swteake_line_num = 4 AND
                   swteake_1_rec.swteake_elm_seq = 2 AND
                   swteaks_1_rec.swteaks_dcmt_seq = l_grp_frst_dcmt)
                  --> ..or if segment belongs to AK9 and is last transaction
                  --> in that group
                   OR (swteaks_1_rec.swteaks_seg =
                   c_fnl_group_response_trailer AND
                   swteaks_1_rec.swteaks_dcmt_seq = l_grp_last_dcmt)
                  --> or if segmet does not bleong to AK9 or AK1
                   OR (swteake_1_rec.swteake_line_num <> 4 AND
                   swteaks_1_rec.swteaks_seg <>
                   c_fnl_group_response_trailer) THEN
                  --> print the segment
                  l_print_segemt := TRUE;
                
                  IF substr(l_segment, 1, 3) = 'AK1' THEN
                    l_line_count := l_line_count;
                  END IF; /* SUBSTR (l_segment, 1, 3) = 'AK1' */
                
                  --> track line numbers
                  IF swteaks_1_rec.swteaks_seg = c_interchange_trn_hdr_seg AND
                     swteake_1_rec.swteake_elm_seq = 1 THEN
                    l_line_count := 1;
                  ELSIF swteaks_1_rec.swteaks_seg <>
                        c_interchange_trn_hdr_seg AND
                        swteake_1_rec.swteake_elm_seq = 1 THEN
                    l_line_count := l_line_count + 1;
                  END IF;
                  /* swteaks_1_rec.swteaks_seg =
                  c_interchange_trn_hdr_seg */
                
                  --> if the element is SE01 print line count
                  IF swteaks_1_rec.swteaks_seg = c_interchange_trn_trl_seg AND
                     swteake_1_rec.swteake_elm_seq = 1 THEN
                    l_segment := l_segment || to_char(l_line_count + 1) || '|';
                    --> if element is ISA13, then assign new envelop control number
                  ELSIF (swteaks_1_rec.swteaks_seg =
                        c_interchange_cntrl_hdr_seg AND
                        swteake_1_rec.swteake_elm_seq = 13) THEN
                    l_state := 'before creating isa sequence';
                    SELECT ws_isasegment_seq.nextval
                      INTO l_isa_seq
                      FROM dual;
                    l_segment := l_segment ||
                                 lpad(to_char(l_isa_seq), 9, '0') || '|';
                    --> if element is GS06, assign new group control number
                  ELSIF (swteaks_1_rec.swteaks_seg =
                        c_functional_gruop_hdr_seg AND
                        swteake_1_rec.swteake_elm_seq = 6) THEN
                    l_state := ' before creating group sequence';
                    SELECT ws_groupsegment_seq.nextval
                      INTO l_gs_seq
                      FROM dual;
                    l_segment := l_segment || to_char(l_gs_seq) || '|';
                    --> if the element is GE02 then assign the group control number
                  ELSIF (swteaks_1_rec.swteaks_seg =
                        c_functional_gruop_trl_seg AND
                        swteake_1_rec.swteake_elm_seq = 2) THEN
                    l_segment := l_segment || to_char(l_gs_seq) || '|';
                    --> if the element is ST02 then assign new transaction control number
                  ELSIF (swteaks_1_rec.swteaks_seg =
                        c_interchange_trn_hdr_seg AND
                        swteake_1_rec.swteake_elm_seq = 2) THEN
                    l_state := ' before creating transaction seq';
                    SELECT ws_transaction_seq.nextval
                      INTO l_ts_seq
                      FROM dual;
                    l_segment := l_segment || to_char(l_ts_seq) || '|';
                    --> if element is SE02 assign the transaction control number
                  ELSIF (swteaks_1_rec.swteaks_seg =
                        c_interchange_trn_trl_seg AND
                        swteake_1_rec.swteake_elm_seq = 2) THEN
                    l_segment := l_segment || to_char(l_ts_seq) || '|';
                    --> if element is IEA02 then assign envelop control number
                  ELSIF (swteaks_1_rec.swteaks_seg =
                        c_interchange_cntrl_trl_seg AND
                        swteake_1_rec.swteake_elm_seq = 2) THEN
                    l_segment := l_segment ||
                                 lpad(to_char(l_isa_seq), 9, '0') || '|';
                    --> if element is AK901 and ak5 exists assign ack code
                  ELSIF (swteaks_1_rec.swteaks_seg =
                        c_fnl_group_response_trailer AND
                        swteake_1_rec.swteake_elm_seq = 1) AND
                        wf_ak5_exists(swteaks_1_rec.swteaks_dcmt_seq) THEN
                    --dbms_output.put_line('in AK9-01');
                    l_segment := l_segment || l_ack_code_out || '|';
                    --> if element is AK902 and ak5 exists assign received trasaction
                    --> numbers
                  ELSIF (swteaks_1_rec.swteaks_seg =
                        c_fnl_group_response_trailer AND
                        swteake_1_rec.swteake_elm_seq = 2) AND
                        wf_ak5_exists(swteaks_1_rec.swteaks_dcmt_seq) THEN
                    l_segment := l_segment || l_recvd_trans_out || '|';
                    --> if element is AK903 and ak5 exists, assign processd transactions
                  ELSIF (swteaks_1_rec.swteaks_seg =
                        c_fnl_group_response_trailer AND
                        swteake_1_rec.swteake_elm_seq = 3) AND
                        wf_ak5_exists(swteaks_1_rec.swteaks_dcmt_seq) THEN
                    l_segment := l_segment || l_sent_trans_out || '|';
                    --> if element is AK904 and ak5 exists assign accepted transactions
                  ELSIF (swteaks_1_rec.swteaks_seg =
                        c_fnl_group_response_trailer AND
                        swteake_1_rec.swteake_elm_seq = 4) AND
                        wf_ak5_exists(swteaks_1_rec.swteaks_dcmt_seq) THEN
                    l_segment := l_segment || l_acc_trans_out || '|';
                  ELSIF (swteake_1_rec.swteake_line_num = 4) THEN
                    l_segment := wf_get_ak1_seg(swteake_1_rec.swteake_dcmt_seqno);
                  ELSE
                    --> print segment
                    l_segment := l_segment ||
                                 swteake_1_rec.swteake_elm_value || '|';
                  END IF; /* swteaks_1_rec.swteaks_seg =
                                                                             c_interchange_trn_trl_seg
                                                                             AND swteake_1_rec.swteake_elm_seq = 1 */
                END IF; /* IF    (    swteake_1_rec.swteake_line_num = 4
                                                                                AND swteake_1_rec.swteake_elm_seq = 2
                                                                                AND swteaks_1_rec.swteaks_dcmt_seq = .. */
              END LOOP; /*swteake_c*/
            
              IF l_print_segemt THEN
                wsakfileio.wp_write_next_line(l_file_id,
                                              rtrim(l_segment, '|') || '^',
                                              l_success_out, l_message_out);
                --DBMS_OUTPUT.put_line (RTRIM (l_segment, '|') || '^');
              END IF; /* l_print_segemt */
            END IF; /* IF    (    swteaks_1_rec.swteaks_seg IN
                                                                (c_interchange_cntrl_hdr_seg,
                                                                c_functional_gruop_hdr_seg,
                                                                c_interchange_trn_hdr_seg
                                                                )
                                                                AND swteaks_1_rec.swteaks_dcmt_seq = l_min_dcmt
                                                                ) .. */
          END LOOP;
        END LOOP; /* transactions_c */
      END LOOP; /* sbgi_code_c */
    END LOOP; --grp_cntrl_numb_c;
  
    --> since group level ack is not getting populated, it is seperated
    l_state := ' before consturcting gs level acknowledgement';
  
    FOR group_swteaks_rec IN group_swteaks_c
    LOOP
      l_segment := group_swteaks_rec.swteaks_seg || '|';
    
      FOR swteake_rec IN swteake_c(group_swteaks_rec.swteaks_dcmt_seq,
                                   group_swteaks_rec.swteaks_line_num)
      LOOP
        IF swteake_rec.swteake_line_num = 4 AND
           swteake_rec.swteake_elm_seq = 2 THEN
          l_grp_cntrl_numb := NULL;
          l_grp_cntrl_numb := swteake_rec.swteake_elm_value;
          l_sbgi_code      := wf_get_inst_code(swteake_rec.swteake_dcmt_seqno);
          --dbms_output.put_line(l_grp_cntrl_numb);
          --dbms_output.put_line(sbgi_code_rec.sbgi_code||' '||l_grp_cntrl_numb);
          wp_get_group_information(l_sbgi_code, l_grp_cntrl_numb,
                                   l_ack_code_out, l_recvd_trans_out,
                                   l_sent_trans_out, l_acc_trans_out);
          --dbms_output.put_line(l_grp_cntrl_numb);
        END IF; /* swteake_rec.swteake_line_num = 4
                                      AND swteake_rec.swteake_elm_seq = 2 */
      
        --> if present element is ak902 then  put actual no of recv transaction
        IF (group_swteaks_rec.swteaks_seg = c_fnl_group_response_trailer AND
           swteake_rec.swteake_elm_seq = 2) AND
           NOT wf_ak5_exists(group_swteaks_rec.swteaks_dcmt_seq) THEN
          l_segment := l_segment || l_recvd_trans_out || '|';
          --> if present element is ak903 then  put actual no of transactions processed
        ELSIF (group_swteaks_rec.swteaks_seg = c_fnl_group_response_trailer AND
              swteake_rec.swteake_elm_seq = 3) AND
              NOT wf_ak5_exists(group_swteaks_rec.swteaks_dcmt_seq) THEN
          l_segment := l_segment || l_sent_trans_out || '|';
          --> if present element is ak901 then  put status as rejected
        ELSIF (group_swteaks_rec.swteaks_seg = c_fnl_group_response_trailer AND
              swteake_rec.swteake_elm_seq = 1) AND
              NOT wf_ak5_exists(group_swteaks_rec.swteaks_dcmt_seq) THEN
          l_segment := l_segment || 'R' || '|';
          --> if present element is ak904 then  put 0 since all transactions are rejected
          --> in this group
        ELSIF (group_swteaks_rec.swteaks_seg = c_fnl_group_response_trailer AND
              swteake_rec.swteake_elm_seq = 4) AND
              NOT wf_ak5_exists(group_swteaks_rec.swteaks_dcmt_seq) THEN
          l_segment := l_segment || '0' || '|';
          --> if present element is SE01 then  put actual no lines in transaction
        ELSIF (group_swteaks_rec.swteaks_seg = c_interchange_trn_trl_seg AND
              swteake_rec.swteake_elm_seq = 1) AND
              NOT wf_ak5_exists(group_swteaks_rec.swteaks_dcmt_seq) THEN
          l_segment := l_segment ||
                       to_char(to_number(swteake_rec.swteake_elm_value) - 2) || '|';
          --> if the element is ST02 then assign new transaction control number
        ELSIF (group_swteaks_rec.swteaks_seg = c_interchange_trn_hdr_seg AND
              swteake_rec.swteake_elm_seq = 2) THEN
          SELECT ws_transaction_seq.nextval INTO l_ts_seq FROM dual;
          l_segment := l_segment || to_char(l_ts_seq) || '|';
        ELSIF (group_swteaks_rec.swteaks_seg = c_interchange_trn_trl_seg AND
              swteake_rec.swteake_elm_seq = 2) THEN
          l_segment := l_segment || to_char(l_ts_seq) || '|';
        ELSE
          l_segment := l_segment || swteake_rec.swteake_elm_value || '|';
        END IF; /* (    group_swteaks_rec.swteaks_seg =
                                          c_fnl_group_response_trailer
                                          AND swteake_rec.swteake_elm_seq = 2
                                          )
                                          AND NOT wf_ak5_exists (group_swteaks_rec.swteaks_dcmt_seq) */
      END LOOP;
    
      wsakfileio.wp_write_next_line(l_file_id, rtrim(l_segment, '|') || '^',
                                    l_success_out, l_message_out);
      --DBMS_OUTPUT.put_line (RTRIM (l_segment, '|') || '^');
    END LOOP;
  
    wsakfileio.wp_close_file(l_file_id, l_success_out, l_message_out);
    wp_populate_inbound_997_db(p_dir_in, l_file_name, 'OUT', l_success_out,
                               l_message_out);
    p_message_out := l_state;
    p_success_out := TRUE;
  EXCEPTION
    WHEN le_exception1 THEN
      --handele business exception here.
      wp_handle_error_db('EDI', 'wp_gen_ack_files', 'BUSINESS',
                         'le_exception1 encountered at state ' || l_state,
                         l_success_out, l_message_out);
      p_success_out := FALSE;
      p_message_out := l_state;
    WHEN OTHERS THEN
      -- handle oracle errors here.
      wp_handle_error_db('EDI', 'wp_gen_ack_files', 'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_state,
                         l_success_out, l_message_out);
      p_success_out := FALSE;
      p_message_out := l_state;
  END wp_gen_ack_files;

  PROCEDURE wp_load_inbound_131
  (
    p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  ) IS
  
    --
    --*****************************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wp_load_inbound_131
    --  Process Associated : EDI
    --  Business Logic :
    --   Generating outbond files using PL/SQL Procedures
    --
    -- This procedure loads inbound - 131 Transaction set, acknowledgment for
    -- transacript sent by USF.
    -- Reads data from 997's Workflow table SWTEAKS,SWTEAKE,SWTEWLS and SWTEWLE
    -- for all accepted 131's by validating AK5 segment value, and loads
    -- corresponding elements into EDI load area tables SHBHEAD, SHRHDR4, SWRQTY0
    -- SHRSUMA and SHRIDEN tables.
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User    Reason For Change
    -- -----  ---  ---------  -----------  ------  -----------------------
    -- 1.0.1   A   B5-002917  16-OCT-2002  JBritto Loads Inbound 131 Transactions
    --         V   FAU-??     19-JAN-2006  VBANGALO Modified code to include
    --                                              document(clob) in shbhead.
    -- Parameter Information:
    -- ------------
    --  Not Applicable.
    --****************************************************************************
  
    -- Declaration of variables
  
    l_name_qual               swtewle.swtewle_elm_value%TYPE;
    l_stage                   VARCHAR2(256);
    l_success                 BOOLEAN;
    l_message                 VARCHAR2(256);
    l_ref_qual                VARCHAR2(10);
    l_dcmt_seqno              swteaks.swteaks_dcmt_seq%TYPE;
    l_line_no                 swtewls.swtewls_line_num%TYPE;
    l_current_dcmt_no         shbhead.shbhead_dcmt_seqno%TYPE;
    l_shbhead_id_date_key     shbhead.shbhead_id_date_key%TYPE;
    l_shbhead_id_tporg        shbhead.shbhead_id_tporg%TYPE;
    l_shbhead_id_edi_key      shbhead.shbhead_id_edi_key%TYPE;
    l_shbhead_xset_code       shbhead.shbhead_xset_code%TYPE;
    l_shbhead_ackkey_t        shbhead.shbhead_ackkey_t%TYPE;
    l_shbhead_send_date       shbhead.shbhead_send_date%TYPE;
    l_shbhead_send_time       shbhead.shbhead_send_time%TYPE;
    l_shbhead_stim_code       shbhead.shbhead_stim_code%TYPE;
    l_shbhead_sid_ssnum       shbhead.shbhead_sid_ssnum%TYPE;
    l_shbhead_sid_agency_num  shbhead.shbhead_sid_agency_num%TYPE;
    l_shbhead_sid_agency_desc shbhead.shbhead_sid_agency_desc%TYPE;
    l_shrhdr4_enty_code       shrhdr4.shrhdr4_enty_code%TYPE;
    l_shrhdr4_enty_name_1     shrhdr4.shrhdr4_enty_name_1%TYPE;
    l_shrhdr4_inql_code       shrhdr4.shrhdr4_inql_code%TYPE;
    l_shrhdr4_inst_code       shrhdr4.shrhdr4_inst_code%TYPE;
    l_swrqty0_qty_qual        swrqty0.swrqty0_quantity_qualifier%TYPE;
    l_swrqty0_qty             swrqty0.swrqty0_quantity%TYPE;
    l_shrsuma_ctyp_code       shrsuma.shrsuma_ctyp_code%TYPE;
    l_shrsuma_slvl_code       shrsuma.shrsuma_slvl_code%TYPE;
    l_shrsuma_gpa_hours       shrsuma.shrsuma_gpa_hours%TYPE;
    l_shrsuma_hours_attempted shrsuma.shrsuma_hours_attempted%TYPE;
    l_shrsuma_hours_earned    shrsuma.shrsuma_hours_earned%TYPE;
    l_shrsuma_gpa_low         shrsuma.shrsuma_gpa_low%TYPE;
    l_shrsuma_gpa_high        shrsuma.shrsuma_gpa_high%TYPE;
    l_shrsuma_gpa             shrsuma.shrsuma_gpa%TYPE;
    l_shrsuma_gpa_excess_ind  shrsuma.shrsuma_gpa_excess_ind%TYPE;
    l_shrsuma_class_rank      shrsuma.shrsuma_class_rank%TYPE;
    l_shrsuma_class_size      shrsuma.shrsuma_class_size%TYPE;
    l_shrsuma_rdql_code       shrsuma.shrsuma_rdql_code%TYPE;
    l_shrsuma_rank_date       shrsuma.shrsuma_rank_date%TYPE;
    l_shrsuma_gpa_seqno       shrsuma.shrsuma_gpa_seqno%TYPE;
    --l_shrsuma_seqno              shrsuma.shrsuma_seqno%TYPE;
    l_shriden_agency_name      shriden.shriden_agency_name%TYPE;
    l_shriden_last_name        shriden.shriden_last_name%TYPE;
    l_shriden_name_prefix      shriden.shriden_name_prefix%TYPE;
    l_shriden_first_name       shriden.shriden_first_name%TYPE;
    l_shriden_first_initial    shriden.shriden_first_initial%TYPE;
    l_shriden_middle_name_1    shriden.shriden_middle_name_1%TYPE;
    l_shriden_middle_name_2    shriden.shriden_middle_name_2%TYPE;
    l_shriden_middle_initial_1 shriden.shriden_middle_initial_1%TYPE;
    l_shriden_middle_initial_2 shriden.shriden_middle_initial_2%TYPE;
    l_shriden_name_suffix      shriden.shriden_name_suffix%TYPE;
    l_shriden_former_name      shriden.shriden_former_name%TYPE;
    l_shriden_combined_name    shriden.shriden_combined_name%TYPE;
    l_shriden_composite_name   shriden.shriden_composite_name%TYPE;
  
    -- Declaration of Cursors
    -- This is the main cursor which will fetch all inbound 131 transactions and load them into
    -- EDI load area tables.
  
    CURSOR in_131_dcmt_seq_c IS
      SELECT DISTINCT swtewls_dcmt_seq
        FROM swteaks a
            ,swteake b
            ,swtewls c
       WHERE a.swteaks_seg = 'AK5'
         AND b.swteake_elm_seq = 1
         AND b.swteake_elm_value = 'A'
         AND a.swteaks_line_num = b.swteake_line_num
         AND c.swtewls_dcmt_seq = a.swteaks_dcmt_seq
         AND a.swteaks_dcmt_seq = b.swteake_dcmt_seqno
         AND c.swtewls_type = '131'
       ORDER BY swtewls_dcmt_seq;
  
    CURSOR in_131_seg_c(p_dcmt_seqno IN NUMBER) IS
      SELECT swtewls_line_num
            ,swtewls_seg
        FROM swtewls
       WHERE swtewls_dcmt_seq = p_dcmt_seqno
       ORDER BY swtewls_line_num;
  
    -- Fetch all the elements of all 131 transaction by passing
    -- dcmt_seqno and the segment identification number of
    -- in_131_c cursor.
  
    CURSOR in_131_elem_c
    (
      p_dcmt_seqno IN NUMBER
     ,p_line_no    IN NUMBER
    ) IS
      SELECT swtewle_dcmt_seqno
            ,swtewle_line_num
            ,swtewle_elm_seq
            ,swtewle_elm_value
        FROM swtewle a
       WHERE a.swtewle_dcmt_seqno = p_dcmt_seqno
         AND a.swtewle_line_num = p_line_no
       ORDER BY swtewle_dcmt_seqno
               ,swtewle_line_num
               ,swtewle_elm_seq;
  
    -- Cursor to get current document sequence number from shbhead
    -- for current row to update other columns of the same row.
  
    CURSOR shbhead_dcmt_c(p_id_edi_key IN shbhead.shbhead_id_edi_key%TYPE) IS
      SELECT shbhead_dcmt_seqno
        FROM shbhead
       WHERE shbhead_id_edi_key = p_id_edi_key;
  
    -- Main procedure starts here.
  BEGIN
    -- Open the first cursor which will have all the valid transactions.
    FOR in_131_dcmt_seq_rec IN in_131_dcmt_seq_c
    LOOP
      BEGIN
        l_dcmt_seqno := in_131_dcmt_seq_rec.swtewls_dcmt_seq;
      
        FOR in_131_seg_rec IN in_131_seg_c(l_dcmt_seqno)
        LOOP
          BEGIN
            -- Begin to either commit the transaction or rollback.
            -- Initilize the Sequence number for GPA for SHRSUMA Table.
            l_shrsuma_gpa_seqno := 0;
            --l_shrsuma_seqno := 0;
          
            -- Now increament the seq no by 1 for each SUM segment.
            IF in_131_seg_rec.swtewls_seg = 'SUM' THEN
              l_shrsuma_gpa_seqno := l_shrsuma_gpa_seqno + 1;
              --l_shrsuma_seqno := l_shrsuma_seqno + 1;
            END IF; -- End of In_131_seg_rec.swtewls_seg
          
            -- Assigns value for local variables to populate in_131_elem_c cursor.
          
            l_line_no := in_131_seg_rec.swtewls_line_num;
            l_stage   := ' Assigning values to the variables from table SWTEWLE';
          
            IF in_131_elem_c%ISOPEN THEN
              CLOSE in_131_elem_c;
            END IF; -- End of in_131_elem_c%ISOPEN
          
            -- Now we open the Inner cursor In_131_elem_c.
            FOR in_131_elem_rec IN in_131_elem_c(l_dcmt_seqno, l_line_no)
            LOOP
              --Loop through each record of this cursor and subsequently assign the values to
              --different local variables and then load these values into EDI Load Area tables.
            
              -- Get the Institution code from where the acknowledgment has come.
              -- ST Segment
              IF in_131_seg_rec.swtewls_seg = 'GS' AND
                 in_131_elem_rec.swtewle_elm_seq = 2 THEN
                l_shbhead_id_tporg := in_131_elem_rec.swtewle_elm_value;
              END IF; -- In_131_seg_rec.swtewls = 'GS' AND  in_131_elem_rec.swtewle_elm_seq = 2
            
              l_shbhead_id_date_key := to_number(to_char(SYSDATE, 'YYMMDD'));
            
              IF in_131_seg_rec.swtewls_seg = 'ST' AND
                 in_131_elem_rec.swtewle_elm_seq = 2 THEN
                l_shbhead_id_edi_key := in_131_elem_rec.swtewle_elm_value;
              END IF; -- In_131_seg_rec.swtewls = 'ST' THEN in_131_elem_rec.swtewle_elm_seq = 2;
            
              -- BGN Segment
              IF in_131_seg_rec.swtewls_seg = 'BGN' THEN
                IF in_131_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shbhead_xset_code := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shbhead_ackkey_t := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 3 THEN
                  l_shbhead_send_date := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shbhead_send_time := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 5 THEN
                  l_shbhead_stim_code := in_131_elem_rec.swtewle_elm_value;
                END IF; -- End of in_131_elem_rec.swtewle_elm_seq = 1
              END IF; -- In_131_seg_rec.swtewls_seg = 'BGN'
            
              -- N1 Segment
              IF in_131_seg_rec.swtewls_seg = 'N1' THEN
                IF in_131_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shrhdr4_enty_code := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shrhdr4_enty_name_1 := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 3 THEN
                  l_shrhdr4_inql_code := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shrhdr4_inst_code := in_131_elem_rec.swtewle_elm_value;
                END IF; -- In_131_seg_rec.swtewls_seg = 'N1'
              END IF; -- In_131_seg_rec.swtewls_seg = 'N1'
            
              -- REF Segment
              IF in_131_seg_rec.swtewls_seg = 'REF' THEN
                IF in_131_elem_rec.swtewle_elm_seq = 1 THEN
                  l_ref_qual := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 2 THEN
                  IF l_ref_qual = 'SY' THEN
                    l_shbhead_sid_ssnum := in_131_elem_rec.swtewle_elm_value;
                  ELSIF l_ref_qual = '48' THEN
                    l_shbhead_sid_agency_num := in_131_elem_rec.swtewle_elm_value;
                  END IF; -- l_ref_qual = 'SY'
                ELSIF in_131_elem_rec.swtewle_elm_seq = 3 AND
                      l_ref_qual = '48' THEN
                  l_shbhead_sid_agency_desc := in_131_elem_rec.swtewle_elm_value;
                END IF; -- in_131_elem_rec.swtewle_elm_seq = 1
              END IF; -- In_131_seg_rec.swtewls_seg = 'REF'
            
              -- QTY Segment
              IF in_131_seg_rec.swtewls_seg = 'QTY' THEN
                IF in_131_elem_rec.swtewle_elm_seq = 1 THEN
                  l_swrqty0_qty_qual := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 2 THEN
                  l_swrqty0_qty := in_131_elem_rec.swtewle_elm_value;
                END IF; -- in_131_elem_rec.swtewle_elm_seq = 1
              END IF; -- In_131_seg_rec.swtewls_seg = 'QTY'
            
              -- SUM Segment.
              IF in_131_seg_rec.swtewls_seg = 'SUM' THEN
                IF in_131_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shrsuma_ctyp_code := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shrsuma_slvl_code := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 3 THEN
                  NULL;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shrsuma_gpa_hours := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 5 THEN
                  l_shrsuma_hours_attempted := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 6 THEN
                  l_shrsuma_hours_earned := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 7 THEN
                  l_shrsuma_gpa_low := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 8 THEN
                  l_shrsuma_gpa_high := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 9 THEN
                  l_shrsuma_gpa := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 10 THEN
                  l_shrsuma_gpa_excess_ind := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 11 THEN
                  l_shrsuma_class_rank := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 12 THEN
                  l_shrsuma_class_size := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 13 THEN
                  l_shrsuma_rdql_code := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 14 THEN
                  l_shrsuma_rank_date := in_131_elem_rec.swtewle_elm_value;
                END IF; -- in_131_elem_rec.swtewle_elm_seq = 1
              END IF; -- In_131_seg_rec.swtewls_seg = 'SUM'
            
              -- IN2 Segment
            
              IF in_131_seg_rec.swtewls_seg = 'IN2' THEN
                IF in_131_elem_rec.swtewle_elm_seq = 1 THEN
                  l_name_qual := in_131_elem_rec.swtewle_elm_value;
                ELSIF in_131_elem_rec.swtewle_elm_seq = 2 THEN
                  IF l_name_qual = '14' THEN
                    l_shriden_agency_name := substr(in_131_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '05' THEN
                    l_shriden_last_name := substr(in_131_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '01' THEN
                    l_shriden_name_prefix := substr(in_131_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '02' THEN
                    l_shriden_first_name := in_131_elem_rec.swtewle_elm_value;
                  ELSIF l_name_qual = '06' THEN
                    l_shriden_first_initial := substr(in_131_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '03' THEN
                    l_shriden_middle_name_1 := substr(in_131_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '04' THEN
                    l_shriden_middle_name_2 := substr(in_131_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '07' THEN
                    l_shriden_middle_initial_1 := substr(in_131_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '08' THEN
                    l_shriden_middle_initial_2 := substr(in_131_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '09' THEN
                    l_shriden_name_suffix := substr(in_131_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '15' THEN
                    l_shriden_former_name := substr(in_131_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '12' THEN
                    l_shriden_combined_name := substr(in_131_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '16' THEN
                    l_shriden_composite_name := substr(in_131_elem_rec.swtewle_elm_value,1,35);
                  END IF; -- l_name_qual = '14'
                END IF; --  in_131_elem_rec.swtewle_elm_seq = 1
              END IF; -- In_131_seg_rec.swtewls_seg = 'IN2'
            END LOOP; -- End of Loop for Cursor in_131_elem_c
          
            IF in_131_seg_rec.swtewls_seg = 'BGN' THEN
              l_stage := ' Loading into SHBHEAD for a BGN Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- ver V start. FAU mods brought to USF/UNF on 08/31/2006 by Deepak
              l_clob := NULL;
              l_clob := wf_build_edi_tran_clob(l_dcmt_seqno);
              -- ver V end
            
              INSERT INTO shbhead
                (shbhead_id_date_key
                ,shbhead_id_doc_key
                ,shbhead_id_edi_key
                ,shbhead_id_tporg
                ,shbhead_activity_date
                ,shbhead_xset_code
                ,shbhead_ackkey_t
                ,shbhead_send_date
                ,shbhead_send_time
                ,shbhead_stim_code)
              VALUES
                (l_shbhead_id_date_key
                ,'131'
                ,l_shbhead_id_edi_key
                ,l_shbhead_id_tporg
                ,SYSDATE
                ,l_shbhead_xset_code
                ,l_shbhead_ackkey_t
                ,l_shbhead_send_date
                ,l_shbhead_send_time
                ,l_shbhead_stim_code);
            
              -- ver v start. FAU Mods
              INSERT INTO swtdcmt
                (swtdcmt_dcmt_seqno
                ,swtdcmt_document)
              VALUES
                (wshkedi.dcmt_seqno
                ,l_clob);
              -- ver v end
            
            ELSIF in_131_seg_rec.swtewls_seg = 'N1' THEN
              l_stage := ' Loading into SHRHDR4 for a N1 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- N1 Segment Load
              INSERT INTO shrhdr4
                (shrhdr4_activity_date
                ,shrhdr4_enty_code
                ,shrhdr4_enty_name_1
                ,shrhdr4_inql_code
                ,shrhdr4_inst_code
                ,shrhdr4_domestic_addr_ind)
              VALUES
                (SYSDATE
                ,l_shrhdr4_enty_code
                ,l_shrhdr4_enty_name_1
                ,l_shrhdr4_inql_code
                ,l_shrhdr4_inst_code
                ,'N');
            ELSIF in_131_seg_rec.swtewls_seg = 'REF' THEN
              IF shbhead_dcmt_c%ISOPEN THEN
                CLOSE shbhead_dcmt_c;
              END IF; --shbhead_dcmt_c%ISOPEN
            
              OPEN shbhead_dcmt_c(l_shbhead_id_edi_key);
              FETCH shbhead_dcmt_c
                INTO l_current_dcmt_no;
              CLOSE shbhead_dcmt_c;
              l_stage := ' Loading into SHBHEAD for a REF Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- REF Segment Update
              UPDATE shbhead
                 SET shbhead_sid_ssnum       = l_shbhead_sid_ssnum
                    ,shbhead_sid_agency_num  = l_shbhead_sid_agency_num
                    ,shbhead_sid_agency_desc = l_shbhead_sid_agency_desc
               WHERE shbhead_dcmt_seqno = l_current_dcmt_no;
            ELSIF in_131_seg_rec.swtewls_seg = 'QTY' THEN
              l_stage := ' Loading into SWRQTY0 for a QTY Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- QTY Segment Load
              INSERT INTO swrqty0
                (swrqty0_quantity_qualifier
                ,swrqty0_quantity)
              VALUES
                (l_swrqty0_qty_qual
                ,l_swrqty0_qty);
            ELSIF in_131_seg_rec.swtewls_seg = 'SUM' THEN
              l_stage := ' Loading into SHRSUMA for a SUM Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- SUM Segment Load
            
              INSERT INTO shrsuma
                (shrsuma_gpa_seqno
                ,shrsuma_activity_date
                ,shrsuma_ctyp_code
                ,shrsuma_slvl_code
                ,shrsuma_gpa_hours
                ,shrsuma_hours_attempted
                ,shrsuma_hours_earned
                ,shrsuma_gpa_low
                ,shrsuma_gpa_high
                ,shrsuma_gpa
                ,shrsuma_gpa_excess_ind
                ,shrsuma_class_rank
                ,shrsuma_class_size
                ,shrsuma_rdql_code
                ,shrsuma_rank_date)
              -- SJM,shrsuma_seqno)
              VALUES
                (l_shrsuma_gpa_seqno
                ,SYSDATE
                ,l_shrsuma_ctyp_code
                ,l_shrsuma_slvl_code
                ,l_shrsuma_gpa_hours
                ,l_shrsuma_hours_attempted
                ,l_shrsuma_hours_earned
                ,l_shrsuma_gpa_low
                ,l_shrsuma_gpa_high
                ,l_shrsuma_gpa
                ,l_shrsuma_gpa_excess_ind
                ,l_shrsuma_class_rank
                ,l_shrsuma_class_size
                ,l_shrsuma_rdql_code
                ,l_shrsuma_rank_date);
              --SJM,l_shrsuma_seqno);
            ELSIF in_131_seg_rec.swtewls_seg = 'IN2' THEN
              l_stage := ' Loading into SHRIDEN for a IN2 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- IN2 Segment Load
              INSERT INTO shriden
                (shriden_activity_date
                ,shriden_agency_name
                ,shriden_last_name
                ,shriden_name_prefix
                ,shriden_first_name
                ,shriden_first_initial
                ,shriden_middle_name_1
                ,shriden_middle_name_2
                ,shriden_middle_initial_1
                ,shriden_middle_initial_2
                ,shriden_name_suffix
                ,shriden_former_name
                ,shriden_combined_name
                ,shriden_composite_name
                ,shriden_domestic_addr_ind)
              VALUES
                (SYSDATE
                ,l_shriden_agency_name
                ,l_shriden_last_name
                ,l_shriden_name_prefix
                ,l_shriden_first_name
                ,l_shriden_first_initial
                ,l_shriden_middle_name_1
                ,l_shriden_middle_name_2
                ,l_shriden_middle_initial_1
                ,l_shriden_middle_initial_2
                ,l_shriden_name_suffix
                ,l_shriden_former_name
                ,l_shriden_combined_name
                ,l_shriden_composite_name
                ,'N');
            END IF; --In_131_seg_rec.swtewls_seg = 'BGN'
          END; -- End of the begin
        END LOOP; -- Close the Loop for cursor In_131_seg_c.
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          wp_handle_error_db('Assigning the variables and loading the data',
                             'wp_load_inbound_131', 'ORACLE',
                             'Encountered ' || to_char(SQLCODE) || ' : ' ||
                              substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                             l_success, l_message);
          p_success_out := FALSE;
          p_message_out := l_stage;
      END;
    END LOOP; -- In_131_dcmt_seq_c
  
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      wp_handle_error_db('Start of the processing', 'wp_load_inbound_131',
                         'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
  END wp_load_inbound_131;

  PROCEDURE wp_load_inbound_146
  (
    p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  ) IS
  
    --
    --*****************************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wp_load_inbound_146
    --  Process Associated : EDI
    --  Business Logic :
    --  Load inbond 146 files using PL/SQL Procedures
    --  This procedure loads inbound - 146 Transaction set, acknowledgment for
    --  transacript sent by USF.
    --  Reads data from 997's Workflow table SWTEAKS,SWTEAKE,SWTEWLS and SWTEWLE
    --  for all accepted 146's by validating AK5 segment value, and loads
    --  corresponding elements into EDI load area tables SHBHEAD, SHRHDR4, SWRACAD
    --  SWRNOTE and SHRIDEN tables.
  
    -- And the following is how a In-146 transaction will look like.
    /*
    ISA`00`          `00`          `22`001519         `22`001537         `021001`0716`U`00401`022740435`1`P`~^
    GS`RY`001519`001537`20021001`071654`022740436`X`004010ED0040^
    ST`146`E00018433^
    BGN`00`E00018433`20020930`07165305`ES^
    ERP`PS``R2^
    REF`SY`480080574^
    DMG`D8`19810908`F``H````21^
    N1`AT``73`001537^
    N1`AS``73`001519^
    PER`RG`NESLER , TIM`TE`S/650-5152^
    IN1`1`04`S2^
    IN2`05`PENA^
    IN2`02`KARENMARIE^
    SE`12`E00018433^
    GE`1`022740436^
    IEA`00001`022740435^
    */
    --
    --
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User      Reason For Change
    -- -----  ---  ---------  -----------  ------    -----------------------
    -- 1.0.1   A   B5-002917  14-OCT-2002  HSHEKHAR  Loads Inbound 146 Transactions
    --         V   FAU-??     19-JAN-2006  VBANGALO Modified code to include
    --                                              document(clob) in shbhead.
    -- Parameter Information:
    -- ------------
    --  P_success_out and P_message_out - The two out variables for error handling.
    --****************************************************************************
  
    -- Declaration of variables
    l_line_no                  swtewls.swtewls_line_num%TYPE;
    l_name_qual                swtewle.swtewle_elm_value%TYPE;
    l_current_dcmt_seqno       shbhead.shbhead_dcmt_seqno%TYPE;
    l_sst_seqno                swracad.swracad_sst_seqno%TYPE;
    l_note_seqno               swrnote.swrnote_seqno%TYPE;
    l_stage                    VARCHAR2(256);
    l_success                  BOOLEAN;
    l_message                  VARCHAR2(256);
    l_identifier_flag_n1       VARCHAR2(1) := '';
    l_identifier_flag_in1      VARCHAR2(1) := '';
    l_name_qlfr_ref            VARCHAR2(3) := '';
    l_dcmt_seqno               shbhead.shbhead_dcmt_seqno%TYPE;
    l_shbhead_id_tporg         shbhead.shbhead_id_tporg%TYPE;
    l_shbhead_id_date_key      shbhead.shbhead_id_date_key%TYPE;
    l_shbhead_id_edi_key       shbhead.shbhead_id_edi_key%TYPE;
    l_shbhead_xset_code        shbhead.shbhead_xset_code%TYPE;
    l_shbhead_ackkey_t         shbhead.shbhead_ackkey_t%TYPE;
    l_shbhead_send_date        shbhead.shbhead_send_date%TYPE;
    l_shbhead_send_time        shbhead.shbhead_send_time%TYPE;
    l_shbhead_stim_code        shbhead.shbhead_stim_code%TYPE;
    l_shbhead_xprp_code        shbhead.shbhead_xprp_code%TYPE;
    l_shbhead_xrsn_code        shbhead.shbhead_xrsn_code%TYPE;
    l_shbhead_sid_ssnum        shbhead.shbhead_sid_ssnum%TYPE;
    l_shbhead_sid_agency_num   shbhead.shbhead_sid_agency_num%TYPE;
    l_shbhead_sid_agency_desc  shbhead.shbhead_sid_agency_desc%TYPE;
    l_shbhead_dob_qual         shbhead.shbhead_dob_qual%TYPE;
    l_shbhead_dob_date         shbhead.shbhead_dob_date_code%TYPE;
    l_shbhead_gender           shbhead.shbhead_gender%TYPE;
    l_shbhead_marital          shbhead.shbhead_marital%TYPE;
    l_shbhead_ethnic           shbhead.shbhead_ethnic%TYPE;
    l_shbhead_citizen          shbhead.shbhead_citizen%TYPE;
    l_shbhead_home_cntry       shbhead.shbhead_home_cntry%TYPE;
    l_swracad_grad_type        swracad.swracad_grad_type%TYPE;
    l_swracad_grad_date_qual   swracad.swracad_grad_date_qual%TYPE;
    l_swracad_grad_date        swracad.swracad_grad_date%TYPE;
    l_swrnote_comment          swrnote.swrnote_comment%TYPE;
    l_shrhdr4_enty_code        shrhdr4.shrhdr4_enty_code%TYPE;
    l_shrhdr4_enty_name_1      shrhdr4.shrhdr4_enty_name_1%TYPE;
    l_shrhdr4_inql_code        shrhdr4.shrhdr4_inql_code%TYPE;
    l_shrhdr4_inst_code        shrhdr4.shrhdr4_inst_code%TYPE;
    l_shrhdr4_enty_name_2      shrhdr4.shrhdr4_enty_name_2%TYPE;
    l_shrhdr4_enty_name_3      shrhdr4.shrhdr4_enty_name_3%TYPE;
    l_shrhdr4_street_line_1    shrhdr4.shrhdr4_street_line1%TYPE;
    l_shrhdr4_street_line_2    shrhdr4.shrhdr4_street_line2%TYPE;
    l_shrhdr4_city             shrhdr4.shrhdr4_city%TYPE;
    l_shrhdr4_stat_code        shrhdr4.shrhdr4_stat_code%TYPE;
    l_shrhdr4_zip              shrhdr4.shrhdr4_zip%TYPE;
    l_shrhdr4_natn_code        shrhdr4.shrhdr4_natn_code%TYPE;
    l_shrhdr4_ctfn_code        shrhdr4.shrhdr4_ctfn_code%TYPE;
    l_shrhdr4_contact_name     shrhdr4.shrhdr4_contact_name%TYPE;
    l_shrhdr4_coql_code        shrhdr4.shrhdr4_coql_code%TYPE;
    l_shrhdr4_comm_no          shrhdr4.shrhdr4_comm_no%TYPE;
    l_shriden_idql_code        shriden.shriden_idql_code%TYPE;
    l_shriden_idnm_code        shriden.shriden_idnm_code%TYPE;
    l_shriden_enid_code        shriden.shriden_enid_code%TYPE;
    l_shriden_rnql_code        shriden.shriden_rnql_code%TYPE;
    l_shriden_ref_numb         shriden.shriden_ref_numb%TYPE;
    l_shriden_rltn_code        shriden.shriden_rltn_code%TYPE;
    l_shriden_name_prefix      shriden.shriden_name_prefix%TYPE;
    l_shriden_first_name       shriden.shriden_first_name%TYPE;
    l_shriden_middle_name_1    shriden.shriden_middle_name_1%TYPE;
    l_shriden_middle_name_2    shriden.shriden_middle_name_2%TYPE;
    l_shriden_last_name        shriden.shriden_last_name%TYPE;
    l_shriden_first_initial    shriden.shriden_first_initial%TYPE;
    l_shriden_middle_initial_1 shriden.shriden_middle_initial_1%TYPE;
    l_shriden_middle_initial_2 shriden.shriden_middle_initial_2%TYPE;
    l_shriden_name_suffix      shriden.shriden_name_suffix%TYPE;
    l_shriden_combined_name    shriden.shriden_combined_name%TYPE;
    l_shriden_agency_name      shriden.shriden_agency_name%TYPE;
    l_shriden_former_name      shriden.shriden_former_name%TYPE;
    l_shriden_composite_name   shriden.shriden_composite_name%TYPE;
    l_shriden_street_line_1    shriden.shriden_street_line1%TYPE;
    l_shriden_street_line_2    shriden.shriden_street_line1%TYPE;
    l_shriden_city             shriden.shriden_city%TYPE;
    l_shriden_stat_code        shriden.shriden_stat_code%TYPE;
    l_shriden_zip              shriden.shriden_zip%TYPE;
    l_shriden_natn_code        shriden.shriden_natn_code%TYPE;
  
    -- Declaration of Cursors
    -- This is the main cursor which will fetch all inbound 146 transactions and load them into
    -- EDI load area tables.
  
    CURSOR in_146_dcmt_seq_c IS
      SELECT DISTINCT swtewls_dcmt_seq
        FROM swteaks a
            ,swteake b
            ,swtewls c
       WHERE a.swteaks_seg = 'AK5'
         AND b.swteake_elm_seq = 1
         AND b.swteake_elm_value = 'A'
         AND a.swteaks_line_num = b.swteake_line_num
         AND c.swtewls_dcmt_seq = a.swteaks_dcmt_seq
         AND a.swteaks_dcmt_seq = b.swteake_dcmt_seqno
         AND c.swtewls_type = '146'
       ORDER BY swtewls_dcmt_seq;
  
    CURSOR in_146_seg_c(p_dcmt_seqno IN NUMBER) IS
      SELECT swtewls_line_num
            ,swtewls_seg
        FROM swtewls
       WHERE swtewls_dcmt_seq = p_dcmt_seqno
       ORDER BY swtewls_line_num;
  
    -- Fetch all the elements of all 146 transaction by passing
    -- dcmt_seqno and the segment identification number of
    -- in_146_c cursor.
  
    CURSOR in_146_elem_c
    (
      p_dcmt_seqno IN NUMBER
     ,p_line_no    IN NUMBER
    ) IS
      SELECT swtewle_dcmt_seqno
            ,swtewle_line_num
            ,swtewle_elm_seq
            ,swtewle_elm_value
        FROM swtewle a
       WHERE a.swtewle_dcmt_seqno = p_dcmt_seqno
         AND a.swtewle_line_num = p_line_no
       ORDER BY swtewle_dcmt_seqno
               ,swtewle_line_num
               ,swtewle_elm_seq;
  
    -- Cursor to get current document sequence number from shbhead
    -- for current row to update other columns of the same row.
  
    CURSOR csr_shbhead_dcmt_seqno_c(p_id_edi_key IN shbhead.shbhead_id_edi_key%TYPE) IS
      SELECT shbhead_dcmt_seqno
        FROM shbhead
       WHERE shbhead_id_edi_key = p_id_edi_key;
  BEGIN
    -- Open the first cursor which will have all the valid transactions.
    -- Opening the first Cursor
    FOR in_146_dcmt_seq_rec IN in_146_dcmt_seq_c
    LOOP
      BEGIN
        l_dcmt_seqno := in_146_dcmt_seq_rec.swtewls_dcmt_seq;
        l_stage      := 'Opening the Segment values cursor';
      
        FOR in_146_seg_rec IN in_146_seg_c(l_dcmt_seqno)
        LOOP
          BEGIN
            -- This begin will be used to either commit a transaction or rollback the transaction.
            -- Initialize the seq no for swracad and swrnote as 0.
            l_sst_seqno  := 0;
            l_note_seqno := 0;
          
            -- Re-Initialize all the variables
          
            -- Now increament the seq no by 1 for each transaction.
          
            IF in_146_seg_rec.swtewls_seg = 'SST' THEN
              l_sst_seqno := l_sst_seqno + 1;
            END IF; -- End of In_146_rec.swtewls_seg = 'SST'
          
            IF in_146_seg_rec.swtewls_seg = 'NTE' THEN
              l_note_seqno := l_note_seqno + 1;
            END IF; -- End of In_146_seg_rec.swtewls_seg = 'NTE'
          
            -- Assign the line no to the procedure variables.
          
            l_line_no := in_146_seg_rec.swtewls_line_num;
            --Close the cursor In_146_Elem_c if it is open.
          
            l_stage := ' Assigning values to the variables from table SWTEWLE';
          
            IF in_146_elem_c%ISOPEN THEN
              CLOSE in_146_elem_c;
            END IF;
          
            -- Now we open the Inner cursor In_146_elem_c.
            FOR in_146_elem_rec IN in_146_elem_c(l_dcmt_seqno, l_line_no)
            LOOP
              --Now we will go through each record of this cursor and subsequently assign the values to
              -- different variables and then load those values to EDI Load Area tables.
            
              -- Get the Institution code from where the acknowledgment has come.
            
              --GS and ST Segment.
              IF in_146_seg_rec.swtewls_seg = 'GS' AND
                 in_146_elem_rec.swtewle_elm_seq = 2 THEN
                l_shbhead_id_tporg := in_146_elem_rec.swtewle_elm_value;
              END IF; -- End of In_146_seg_rec.swtewls_seg = 'GS'..
            
              -- Generate the date in the following format.
            
              l_shbhead_id_date_key := to_number(to_char(SYSDATE, 'YYMMDD'));
            
              -- Get the EDI document key
              IF in_146_seg_rec.swtewls_seg = 'ST' AND
                 in_146_elem_rec.swtewle_elm_seq = 2 THEN
                l_shbhead_id_edi_key := in_146_elem_rec.swtewle_elm_value;
              END IF; -- End of In_146_seg_rec.swtewls_seg = 'ST'..
            
              -- BGN segment
              IF in_146_seg_rec.swtewls_seg = 'BGN' THEN
                IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shbhead_xset_code := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shbhead_ackkey_t := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 3 THEN
                  l_shbhead_send_date := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shbhead_send_time := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 5 THEN
                  l_shbhead_stim_code := in_146_elem_rec.swtewle_elm_value;
                END IF;
              END IF; -- End of In_146_seg_rec.swtewls_seg='BGN'
            
              -- ERP Segment
              IF in_146_seg_rec.swtewls_seg = 'ERP' THEN
              
                IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shbhead_xprp_code := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 3 THEN
                  --IF in_146_elem_rec.swtewle_elm_value NOT IN ('R6','R7')THEN
                  l_shbhead_xrsn_code := in_146_elem_rec.swtewle_elm_value;
                  -- END IF;
                  -- set up xrsn for identifying incoming 146 transient types
                ELSIF in_146_elem_rec.swtewle_elm_seq = 4 THEN
                
                  IF in_146_elem_rec.swtewle_elm_value IN ('R6', 'R7') THEN
                    l_shbhead_xrsn_code := in_146_elem_rec.swtewle_elm_value;
                  END IF;
                END IF;
              END IF; -- End of In_146_seg_rec.swtewls_seg = 'ERP'
            
              ---REF Segment
              IF in_146_seg_rec.swtewls_seg = 'REF' THEN
                IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                  l_name_qlfr_ref := in_146_elem_rec.swtewle_elm_value;
                END IF; -- End Of In_146_elem_rec.swtewle_elm_seq=1
              
                IF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                  IF l_name_qlfr_ref = 'SY' THEN
                    l_shbhead_sid_ssnum := in_146_elem_rec.swtewle_elm_value;
                  ELSIF l_name_qlfr_ref = '48' THEN
                    l_shbhead_sid_agency_num := in_146_elem_rec.swtewle_elm_value;
                  END IF; -- End of l_name_qlfr_ref = 'SY'
                ELSIF in_146_elem_rec.swtewle_elm_seq = 3 AND
                      l_name_qlfr_ref = '48' THEN
                  l_shbhead_sid_agency_desc := in_146_elem_rec.swtewle_elm_value;
                END IF; -- End of In_146_elem_rec.swtewle_elm_seq=2
              END IF; -- End Of In_146_seg_rec.swtewls_seg = 'REF'
            
              --DMG Segment
              IF in_146_seg_rec.swtewls_seg = 'DMG' THEN
                IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shbhead_dob_qual := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shbhead_dob_date := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 3 THEN
                  l_shbhead_gender := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shbhead_marital := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 5 THEN
                  l_shbhead_ethnic := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 6 THEN
                  l_shbhead_citizen := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 7 THEN
                  l_shbhead_home_cntry := in_146_elem_rec.swtewle_elm_value;
                END IF;
              END IF; -- End Of In_146_seg_rec.swtewls_seg = 'DMG'
            
              --SST Segment
              IF in_146_seg_rec.swtewls_seg = 'SST' THEN
                IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                  l_swracad_grad_type := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                  l_swracad_grad_date_qual := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 3 THEN
                  l_swracad_grad_date := in_146_elem_rec.swtewle_elm_value;
                END IF;
              END IF; -- End of In_146_seg_rec.swtewls_seg = 'SST'
            
              --NTE Segment
              IF in_146_seg_rec.swtewls_seg = 'NTE' THEN
                IF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                  l_swrnote_comment := in_146_elem_rec.swtewle_elm_value;
                END IF;
              END IF; -- End of In_146_seg_rec.swtewls_seg = 'NTE'
            
              --N1 Segment
              IF in_146_seg_rec.swtewls_seg = 'N1' THEN
                IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shrhdr4_enty_code := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shrhdr4_enty_name_1 := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 3 THEN
                  l_shrhdr4_inql_code := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shrhdr4_inst_code := in_146_elem_rec.swtewle_elm_value;
                END IF;
              
                l_identifier_flag_n1 := 'T';
              END IF; -- End Of In_146_seg_rec.swtewls_seg = 'N1'
            
              -- N2 Segment
              IF in_146_seg_rec.swtewls_seg = 'N2' THEN
                IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shrhdr4_enty_name_2 := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                ELSIF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shrhdr4_enty_name_3 := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                END IF;
              END IF; -- End Of In_146_seg_rec.swtewls_seg = 'N2'
            
              -- N3 Segment
              IF in_146_seg_rec.swtewls_seg = 'N3' THEN
                IF l_identifier_flag_n1 = 'T' THEN
                  IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                    l_shrhdr4_street_line_1 := in_146_elem_rec.swtewle_elm_value;
                  ELSIF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                    l_shrhdr4_street_line_2 := in_146_elem_rec.swtewle_elm_value;
                  END IF;
                END IF;
              END IF; -- End Of In_146_seg_rec.swtewls_seg = 'N3'
            
              -- N4 Segment
              IF in_146_seg_rec.swtewls_seg = 'N4' THEN
                IF l_identifier_flag_n1 = 'T' THEN
                  IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                    l_shrhdr4_city := in_146_elem_rec.swtewle_elm_value;
                  ELSIF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                    l_shrhdr4_stat_code := in_146_elem_rec.swtewle_elm_value;
                  ELSIF in_146_elem_rec.swtewle_elm_seq = 3 THEN
                    l_shrhdr4_zip := in_146_elem_rec.swtewle_elm_value;
                  ELSIF in_146_elem_rec.swtewle_elm_seq = 4 THEN
                    l_shrhdr4_natn_code := in_146_elem_rec.swtewle_elm_value;
                  END IF;
                END IF;
              END IF; -- End of In_146_seg_rec.swtewls_seg = 'N4'
            
              -- PER Segment
              IF in_146_seg_rec.swtewls_seg = 'PER' THEN
                IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shrhdr4_ctfn_code := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shrhdr4_contact_name := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                ELSIF in_146_elem_rec.swtewle_elm_seq = 3 THEN
                  l_shrhdr4_coql_code := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shrhdr4_comm_no := in_146_elem_rec.swtewle_elm_value;
                END IF;
              END IF; -- End Of In_146_seg_rec.swtewls_seg = 'PER'
            
              --IN1 Segment
              IF in_146_seg_rec.swtewls_seg = 'IN1' THEN
                IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shriden_idql_code := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shriden_idnm_code := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 3 THEN
                  l_shriden_enid_code := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shriden_rnql_code := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 5 THEN
                  l_shriden_ref_numb := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 6 THEN
                  l_shriden_rltn_code := in_146_elem_rec.swtewle_elm_value;
                END IF;
              
                l_identifier_flag_in1 := 'T';
              END IF; -- End of In_146_seg_rec.swtewls_seg = 'IN1'
            
              -- IN2 Segment
              IF in_146_seg_rec.swtewls_seg = 'IN2' THEN
                IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                  l_name_qual := in_146_elem_rec.swtewle_elm_value;
                ELSIF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                  IF l_name_qual = '01' THEN
                    l_shriden_name_prefix := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '02' THEN
                    l_shriden_first_name := in_146_elem_rec.swtewle_elm_value;
                  ELSIF l_name_qual = '03' THEN
                    l_shriden_middle_name_1 := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '04' THEN
                    l_shriden_middle_name_2 := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '05' THEN
                    l_shriden_last_name := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '06' THEN
                    l_shriden_first_initial := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '07' THEN
                    l_shriden_middle_initial_1 := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '08' THEN
                    l_shriden_middle_initial_2 := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '09' THEN
                    l_shriden_name_suffix := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '12' THEN
                    l_shriden_combined_name := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '14' THEN
                    l_shriden_agency_name := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '15' THEN
                    l_shriden_former_name := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '16' THEN
                    l_shriden_composite_name := substr(in_146_elem_rec.swtewle_elm_value,1,35);
                  END IF; -- End of l_name_qual = '01'
                END IF; -- End of In_146_elem_rec.swtewle_elm_seq = 1
              END IF; -- End of In_146_seg_rec.swtewls_seg = 'IN2'
            
              -- N3 Segment
              IF in_146_seg_rec.swtewls_seg = 'N3' THEN
                IF l_identifier_flag_in1 = 'T' THEN
                  IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                    l_shriden_street_line_1 := in_146_elem_rec.swtewle_elm_value;
                  ELSIF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                    l_shriden_street_line_2 := in_146_elem_rec.swtewle_elm_value;
                  END IF; -- End Of In_146_elem_rec.swtewle_elm_seq = 1
                END IF; --End Of l_identifier_flag_in1 = 'T'
              END IF; -- End Of In_146_seg_rec.swtewls_seg = 'N3'
            
              -- N4 Segment
              IF in_146_seg_rec.swtewls_seg = 'N4' THEN
                IF l_identifier_flag_in1 = 'T' THEN
                  IF in_146_elem_rec.swtewle_elm_seq = 1 THEN
                    l_shriden_city := in_146_elem_rec.swtewle_elm_value;
                  ELSIF in_146_elem_rec.swtewle_elm_seq = 2 THEN
                    l_shriden_stat_code := in_146_elem_rec.swtewle_elm_value;
                  ELSIF in_146_elem_rec.swtewle_elm_seq = 3 THEN
                    l_shriden_zip := substr(in_146_elem_rec.swtewle_elm_value,
                                            1, 5);
                  ELSIF in_146_elem_rec.swtewle_elm_seq = 4 THEN
                    l_shriden_natn_code := in_146_elem_rec.swtewle_elm_value;
                  END IF; --End of In_146_elem_rec.swtewle_elm_seq = 1
                END IF; -- End of l_identifier_flag_in1 = 'T'
              END IF; -- End Of In_146_seg_rec.swtewls_seg = 'N4'
            END LOOP; -- Close the Loop for cursor csr_146_elm_c .
          
            -- Start of Inserting data into EDI Load Area tables. ARP picks up data from these tables
            -- and loads them into Banner Tables.
            --If the current segment is BGN then insert into SHBHEAD.
            --The document seq no is internally generated.
          
            -- Open the shbhead_dcmt_seqno_c to get the current document seqno .
          
            IF csr_shbhead_dcmt_seqno_c%ISOPEN THEN
              CLOSE csr_shbhead_dcmt_seqno_c;
            END IF; -- End of Csr_shbhead_dcmt_seqno_c%ISOPEN
          
            OPEN csr_shbhead_dcmt_seqno_c(l_shbhead_id_edi_key);
            FETCH csr_shbhead_dcmt_seqno_c
              INTO l_current_dcmt_seqno;
          
            IF csr_shbhead_dcmt_seqno_c%NOTFOUND THEN
              l_current_dcmt_seqno := NULL;
            END IF; -- End of Csr_shbhead_dcmt_seqno_c%NOTFOUND
          
            CLOSE csr_shbhead_dcmt_seqno_c; -- Close the cursor csr_shbhead_dcmt_seqno_c
          
            -- Load the data into EDI Load Area tables
          
            IF in_146_seg_rec.swtewls_seg = 'BGN' THEN
            
              -- ver V start
              l_clob := NULL;
              l_clob := wf_build_edi_tran_clob(l_dcmt_seqno);
              -- ver V end
            
              l_stage := ' Loading into SHBHEAD for a BGN Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              INSERT INTO shbhead
                (shbhead_id_date_key
                ,shbhead_id_doc_key
                ,shbhead_id_edi_key
                ,shbhead_id_tporg
                ,shbhead_activity_date
                ,shbhead_xset_code
                ,shbhead_ackkey_t
                ,shbhead_send_date
                ,shbhead_send_time
                ,shbhead_stim_code)
              VALUES
                (l_shbhead_id_date_key
                ,'146'
                ,l_shbhead_id_edi_key
                ,l_shbhead_id_tporg
                ,SYSDATE
                ,l_shbhead_xset_code
                ,l_shbhead_ackkey_t
                ,l_shbhead_send_date
                ,l_shbhead_send_time
                ,l_shbhead_stim_code);
            
              -- ver v start
              INSERT INTO saturn.swtdcmt
                (swtdcmt_dcmt_seqno
                ,swtdcmt_document)
              VALUES
                (wshkedi.dcmt_seqno
                ,l_clob);
              -- ver v end
            
              --Update shbhead for the ERP segment. The dcmt seqno has already been generated.
            ELSIF in_146_seg_rec.swtewls_seg = 'ERP' THEN
              l_stage := ' Updating SHBHEAD for a ERP Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              UPDATE shbhead
                 SET shbhead_xprp_code = l_shbhead_xprp_code
                    ,shbhead_xrsn_code = l_shbhead_xrsn_code
               WHERE shbhead_dcmt_seqno = l_current_dcmt_seqno;
              --Update shbhead_sid_ssnum for the REF segment.
            ELSIF in_146_seg_rec.swtewls_seg = 'REF' THEN
              l_stage := ' Updating SHBHEAD for a REF Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              UPDATE shbhead
                 SET shbhead_sid_ssnum       = l_shbhead_sid_ssnum
                    ,shbhead_sid_agency_num  = l_shbhead_sid_agency_num
                    ,shbhead_sid_agency_desc = l_shbhead_sid_agency_desc
               WHERE shbhead_dcmt_seqno = l_current_dcmt_seqno;
            
              --Update shbhead for the DMG segment.
            ELSIF in_146_seg_rec.swtewls_seg = 'DMG' THEN
              l_stage := ' Updating SHBHEAD for a DMG Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              UPDATE shbhead
                 SET shbhead_dob_qual      = l_shbhead_dob_qual
                    ,shbhead_dob_date_code = l_shbhead_dob_date
                    ,shbhead_gender        = l_shbhead_gender
                    ,shbhead_marital       = l_shbhead_marital
                    ,shbhead_ethnic        = l_shbhead_ethnic
                    ,shbhead_citizen       = l_shbhead_citizen
                    ,shbhead_home_cntry    = l_shbhead_home_cntry
               WHERE shbhead_dcmt_seqno = l_current_dcmt_seqno;
            
              -- Create record in SWRACAD for SST segment.
            ELSIF in_146_seg_rec.swtewls_seg = 'SST' THEN
              l_stage := ' Loading into SWRACAD for SST Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              INSERT INTO swracad
                (swracad_sst_seqno
                ,swracad_grad_type
                ,swracad_grad_date_qual
                ,swracad_grad_date)
              VALUES
                (l_sst_seqno
                ,l_swracad_grad_type
                ,l_swracad_grad_date_qual
                ,l_swracad_grad_date);
            
              -- Create the comments in SWRNOTE for NTE segment.
            
            ELSIF in_146_seg_rec.swtewls_seg = 'NTE' THEN
              l_stage := ' Loading into SWRNOTE for NTE Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              INSERT INTO swrnote
                (swrnote_seqno
                ,swrnote_comment)
              VALUES
                (l_note_seqno
                ,l_swrnote_comment);
            
              -- Load the data in SHRHDR4 for N1 segment.
            ELSIF in_146_seg_rec.swtewls_seg = 'N1' THEN
              l_stage := ' Loading into SHRHDR4 for N1 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              INSERT INTO shrhdr4
                (shrhdr4_activity_date
                ,shrhdr4_enty_code
                ,shrhdr4_enty_name_1
                ,shrhdr4_inql_code
                ,shrhdr4_inst_code
                ,shrhdr4_domestic_addr_ind)
              VALUES
                (SYSDATE
                ,l_shrhdr4_enty_code
                ,l_shrhdr4_enty_name_1
                ,l_shrhdr4_inql_code
                ,l_shrhdr4_inst_code
                ,'N');
            
              -- Update the SHRHDR4 for N2 segment.
            ELSIF in_146_seg_rec.swtewls_seg = 'N2' THEN
              l_stage := ' Updating SHRHDR4 for N2 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              UPDATE shrhdr4
                 SET shrhdr4_enty_name_2 = l_shrhdr4_enty_name_2
                    ,shrhdr4_enty_name_3 = l_shrhdr4_enty_name_3
               WHERE shrhdr4_dcmt_seqno = l_current_dcmt_seqno;
            
              -- Update the SHRHDR4 for N3 segment.
            ELSIF (in_146_seg_rec.swtewls_seg = 'N3' AND
                  l_identifier_flag_n1 = 'T') THEN
              l_stage := ' Updating SHRHDR4 for N3 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              UPDATE shrhdr4
                 SET shrhdr4_street_line1 = l_shrhdr4_street_line_1
                    ,shrhdr4_street_line2 = l_shrhdr4_street_line_2
               WHERE shrhdr4_dcmt_seqno = l_current_dcmt_seqno;
            
              -- Update the SHRHDR4 for N4 segment.
            ELSIF (in_146_seg_rec.swtewls_seg = 'N4' AND
                  l_identifier_flag_n1 = 'T') THEN
              l_stage := ' Updating SHRHDR4 for N4 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              UPDATE shrhdr4
                 SET shrhdr4_city      = l_shrhdr4_city
                    ,shrhdr4_stat_code = l_shrhdr4_stat_code
                    ,shrhdr4_zip       = l_shrhdr4_zip
                    ,shrhdr4_natn_code = l_shrhdr4_natn_code
               WHERE shrhdr4_dcmt_seqno = l_current_dcmt_seqno;
            
              -- Update the SHRHDR4 for PER segment.
            ELSIF in_146_seg_rec.swtewls_seg = 'PER' THEN
              l_stage := ' Updating SHRHDR4 for PER Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              UPDATE shrhdr4
                 SET shrhdr4_ctfn_code    = l_shrhdr4_ctfn_code
                    ,shrhdr4_contact_name = l_shrhdr4_contact_name
                    ,shrhdr4_coql_code    = l_shrhdr4_coql_code
                    ,shrhdr4_comm_no      = l_shrhdr4_comm_no
               WHERE shrhdr4_dcmt_seqno = l_current_dcmt_seqno
                 AND shrhdr4_enty_code IN ('AS', 'KS');
            
              -- Load the data in SHRIDEN for IN1 segment.
            ELSIF (in_146_seg_rec.swtewls_seg = 'IN1' AND
                  l_shriden_idnm_code = '04') THEN
              l_stage := ' Loading into SHRIDEN for IN1 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              INSERT INTO shriden
                (shriden_activity_date
                ,shriden_idql_code
                ,shriden_idnm_code
                ,shriden_enid_code
                ,shriden_rnql_code
                ,shriden_ref_numb
                ,shriden_rltn_code
                ,shriden_domestic_addr_ind)
              VALUES
                (SYSDATE
                ,l_shriden_idql_code
                ,l_shriden_idnm_code
                ,l_shriden_enid_code
                ,l_shriden_rnql_code
                ,l_shriden_ref_numb
                ,l_shriden_rltn_code
                ,'N');
            
              -- Update the SHRIDEN for IN2 segment.
            ELSIF in_146_seg_rec.swtewls_seg = 'IN2' THEN
              l_stage := ' Updating SHRIDEN for IN2 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              UPDATE shriden
                 SET shriden_agency_name      = l_shriden_agency_name
                    ,shriden_composite_name   = l_shriden_composite_name
                    ,shriden_combined_name    = l_shriden_combined_name
                    ,shriden_former_name      = l_shriden_former_name
                    ,shriden_name_suffix      = l_shriden_name_suffix
                    ,shriden_middle_initial_1 = l_shriden_middle_initial_1
                    ,shriden_middle_initial_2 = l_shriden_middle_initial_2
                    ,shriden_middle_name_1    = l_shriden_middle_name_1
                    ,shriden_middle_name_2    = l_shriden_middle_name_2
                    ,shriden_first_initial    = l_shriden_first_initial
                    ,shriden_first_name       = l_shriden_first_name
                    ,shriden_name_prefix      = l_shriden_name_prefix
                    ,shriden_last_name        = l_shriden_last_name
               WHERE shriden_dcmt_seqno = l_current_dcmt_seqno;
            
              --Update the SHRIDEN for N3 segment.
            ELSIF (in_146_seg_rec.swtewls_seg = 'N3' AND
                  l_identifier_flag_in1 = 'T') THEN
              l_stage := ' Updating SHRIDEN for N3 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              UPDATE shriden
                 SET shriden_street_line1 = l_shriden_street_line_1
                    ,shriden_street_line2 = l_shriden_street_line_2
               WHERE shriden_dcmt_seqno = l_current_dcmt_seqno;
            
              -- Update the SHRIDEN for N4 segment.
            ELSIF (in_146_seg_rec.swtewls_seg = 'N4' AND
                  l_identifier_flag_in1 = 'T') THEN
              l_stage := ' Updating SHRIDEN for N4 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              UPDATE shriden
                 SET shriden_city      = l_shriden_city
                    ,shriden_stat_code = l_shriden_stat_code
                    ,shriden_zip       = substr(l_shriden_zip, 1, 5)
                    ,shriden_natn_code = l_shriden_natn_code
               WHERE shriden_dcmt_seqno = l_current_dcmt_seqno;
            END IF; --End of In_146_seg_rec.swtewls_seg = 'BGN'
          END; -- End of the begin
        END LOOP; -- Close the Loop for cursor In_146_seg_c.
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          wp_handle_error_db('Assigning the variables and loading the data',
                             'wp_load_inbound_146', 'ORACLE',
                             'Encountered ' || to_char(SQLCODE) || ' : ' ||
                              substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                             l_success, l_message);
          p_success_out := FALSE;
          p_message_out := l_stage;
      END;
    END LOOP; -- In_146_dcmt_seq_c
  
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      wp_handle_error_db('Start of the processing', 'wp_load_inbound_146',
                         'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
  END wp_load_inbound_146;

  PROCEDURE wp_load_inbound_147
  (
    p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  ) IS
  
    --
    --*****************************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wp_load_inbound_147
    --  Process Associated : EDI
    --  Business Logic :
    --   Load inbond 147 files using PL/SQL Procedures
    -- This procedure loads inbound - 147 Transaction set, acknowledgment for
    -- transacript sent by USF.
    -- Reads data from 997's Workflow table SWTEAKS,SWTEAKE,SWTEWLS and SWTEWLE
    -- for all accepted 147's by validating AK5 segment value, and loads
    -- corresponding elements into EDI load area tables SHBHEAD, SHRHDR4, SWRAAA0
    -- SWRNOTE and SHRIDEN tables.
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User      Reason For Change
    -- -----  ---  ---------  -----------  ------    -----------------------
    -- 1.0.1   A    B5-002917  16-OCT-2002  Jbritto  Loads Inbound 147 Transactions
    --  n/a    E    B5-003020  04-DEC-2002  VBANGALO Modified code to load first
    --                                               five degits of zip code into
    --                                               shrhdr4_zip.
    --                                               Included dcmt seqno in exception
    --                                               handling.
    --  n/a    I    B5-003127  04-MAR-2003  VBANGALO Modified code to load IN1 segment
    --                                               vales correctly.
    --         V   FAU-??     19-JAN-2006  VBANGALO Modified code to include
    --                                              document(clob) in shbhead.
    -- Parameter Information:
    -- ------------
    --  Not Applicable.
    --****************************************************************************
  
    -- Declaration of variables
  
    l_line_no                    swtewls.swtewls_line_num%TYPE;
    l_name_qual                  swtewle.swtewle_elm_value%TYPE;
    l_current_dcmt_seqno         shbhead.shbhead_dcmt_seqno%TYPE;
    l_sst_seqno                  swracad.swracad_sst_seqno%TYPE;
    l_note_seqno                 swrnote.swrnote_seqno%TYPE;
    l_stage                      VARCHAR2(256);
    l_success                    BOOLEAN;
    l_message                    VARCHAR2(256);
    l_ref_qual                   VARCHAR2(10);
    l_dcmt_seqno                 shbhead.shbhead_dcmt_seqno%TYPE;
    l_shbhead_id_tporg           shbhead.shbhead_id_tporg%TYPE;
    l_shbhead_id_date_key        shbhead.shbhead_id_date_key%TYPE;
    l_shbhead_id_edi_key         shbhead.shbhead_id_edi_key%TYPE;
    l_shbhead_xset_code          shbhead.shbhead_xset_code%TYPE;
    l_shbhead_ackkey_t           shbhead.shbhead_ackkey_t%TYPE;
    l_shbhead_send_date          shbhead.shbhead_send_date%TYPE;
    l_shbhead_send_time          shbhead.shbhead_send_time%TYPE;
    l_shbhead_stim_code          shbhead.shbhead_stim_code%TYPE;
    l_shbhead_sid_ssnum          shbhead.shbhead_sid_ssnum%TYPE;
    l_shbhead_sid_agency_num     shbhead.shbhead_sid_agency_num%TYPE;
    l_shbhead_sid_agency_desc    shbhead.shbhead_sid_agency_desc%TYPE;
    l_swraaa0_yes_no_cond_resp   swraaa0.swraaa0_yes_no_cond_resp%TYPE;
    l_swraaa0_agency_qual_code   swraaa0.swraaa0_agency_qual_code%TYPE;
    l_swraaa0_reject_reason_code swraaa0.swraaa0_reject_reason_code%TYPE;
    l_swraaa0_f_up_action_code   swraaa0.swraaa0_follow_up_action_code%TYPE;
    l_swrnote_comment            swvedi_swrnote_head.swrnote_comment%TYPE;
    l_swrnote_note_type          swvedi_swrnote_head.swrnote_note_type%TYPE;
    c_swrnote_child_loop  CONSTANT NUMBER(1) := 1;
    c_swrnote_parent_loop CONSTANT NUMBER(1) := 1;
    l_shrhdr4_enty_code        shrhdr4.shrhdr4_enty_code%TYPE;
    l_shrhdr4_enty_name_1      shrhdr4.shrhdr4_enty_name_1%TYPE;
    l_shrhdr4_inql_code        shrhdr4.shrhdr4_inql_code%TYPE;
    l_shrhdr4_inst_code        shrhdr4.shrhdr4_inst_code%TYPE;
    l_shrhdr4_enty_name_2      shrhdr4.shrhdr4_enty_name_2%TYPE;
    l_shrhdr4_enty_name_3      shrhdr4.shrhdr4_enty_name_3%TYPE;
    l_shrhdr4_street_line_1    shrhdr4.shrhdr4_street_line1%TYPE;
    l_shrhdr4_street_line_2    shrhdr4.shrhdr4_street_line2%TYPE;
    l_shrhdr4_city             shrhdr4.shrhdr4_city%TYPE;
    l_shrhdr4_stat_code        shrhdr4.shrhdr4_stat_code%TYPE;
    l_shrhdr4_zip              shrhdr4.shrhdr4_zip%TYPE;
    l_shrhdr4_natn_code        shrhdr4.shrhdr4_natn_code%TYPE;
    l_shrhdr4_ctfn_code        shrhdr4.shrhdr4_ctfn_code%TYPE;
    l_shrhdr4_contact_name     shrhdr4.shrhdr4_contact_name%TYPE;
    l_shrhdr4_coql_code        shrhdr4.shrhdr4_coql_code%TYPE;
    l_shrhdr4_comm_no          shrhdr4.shrhdr4_comm_no%TYPE;
    l_shriden_idql_code        shriden.shriden_idql_code%TYPE;
    l_shriden_idnm_code        shriden.shriden_idnm_code%TYPE;
    l_shriden_enid_code        shriden.shriden_enid_code%TYPE;
    l_shriden_rnql_code        shriden.shriden_rnql_code%TYPE;
    l_shriden_ref_numb         shriden.shriden_ref_numb%TYPE;
    l_shriden_rltn_code        shriden.shriden_rltn_code%TYPE;
    l_shriden_name_prefix      shriden.shriden_name_prefix%TYPE;
    l_shriden_first_name       shriden.shriden_first_name%TYPE;
    l_shriden_middle_name_1    shriden.shriden_middle_name_1%TYPE;
    l_shriden_middle_name_2    shriden.shriden_middle_name_2%TYPE;
    l_shriden_last_name        shriden.shriden_last_name%TYPE;
    l_shriden_first_initial    shriden.shriden_first_initial%TYPE;
    l_shriden_middle_initial_1 shriden.shriden_middle_initial_1%TYPE;
    l_shriden_middle_initial_2 shriden.shriden_middle_initial_2%TYPE;
    l_shriden_name_suffix      shriden.shriden_name_suffix%TYPE;
    l_shriden_combined_name    shriden.shriden_combined_name%TYPE;
    l_shriden_agency_name      shriden.shriden_agency_name%TYPE;
    l_shriden_former_name      shriden.shriden_former_name%TYPE;
    l_shriden_composite_name   shriden.shriden_composite_name%TYPE;
    l_shriden_street_line_1    shriden.shriden_street_line1%TYPE;
    l_shriden_street_line_2    shriden.shriden_street_line1%TYPE;
    l_shriden_city             shriden.shriden_city%TYPE;
    l_shriden_stat_code        shriden.shriden_stat_code%TYPE;
    l_shriden_zip              shriden.shriden_zip%TYPE;
    l_shriden_natn_code        shriden.shriden_natn_code%TYPE;
  
    -- Declaration of Cursors
    -- This is the main cursor which will fetch all inbound 147 transactions and load them into
    -- EDI load area tables.
  
    CURSOR in_147_dcmt_seq_c IS
      SELECT DISTINCT swtewls_dcmt_seq
        FROM swteaks a
            ,swteake b
            ,swtewls c
       WHERE a.swteaks_seg = 'AK5'
         AND b.swteake_elm_seq = 1
         AND b.swteake_elm_value = 'A'
         AND a.swteaks_line_num = b.swteake_line_num
         AND c.swtewls_dcmt_seq = a.swteaks_dcmt_seq
         AND a.swteaks_dcmt_seq = b.swteake_dcmt_seqno
         AND c.swtewls_type = '147'
       ORDER BY swtewls_dcmt_seq;
  
    CURSOR in_147_seg_c(p_dcmt_seqno IN NUMBER) IS
      SELECT swtewls_line_num
            ,swtewls_seg
        FROM swtewls
       WHERE swtewls_dcmt_seq = p_dcmt_seqno
       ORDER BY swtewls_line_num;
  
    -- Fetch all the elements of all 147 transaction by passing
    -- dcmt_seqno and the segment identification number of
    -- In_147_c cursor.
  
    CURSOR in_147_elem_c
    (
      p_dcmt_seqno IN NUMBER
     ,p_line_no    IN NUMBER
    ) IS
      SELECT swtewle_dcmt_seqno
            ,swtewle_line_num
            ,swtewle_elm_seq
            ,swtewle_elm_value
        FROM swtewle a
       WHERE a.swtewle_dcmt_seqno = p_dcmt_seqno
         AND a.swtewle_line_num = p_line_no
       ORDER BY swtewle_dcmt_seqno
               ,swtewle_line_num
               ,swtewle_elm_seq;
  
    -- Cursor to get current document sequence number from shbhead
    -- for current row to update other columns of the same row.
  
    CURSOR csr_shbhead_dcmt_seqno_c(p_id_edi_key IN shbhead.shbhead_id_edi_key%TYPE) IS
      SELECT shbhead_dcmt_seqno
        FROM shbhead
       WHERE shbhead_id_edi_key = p_id_edi_key;
  BEGIN
    FOR in_147_dcmt_seq_rec IN in_147_dcmt_seq_c
    LOOP
      BEGIN
        l_dcmt_seqno := in_147_dcmt_seq_rec.swtewls_dcmt_seq;
      
        -- Open the first cursor which will have all the valid transactions.
        FOR in_147_seg_rec IN in_147_seg_c(l_dcmt_seqno)
        LOOP
          BEGIN
            -- Begin  to commit or rollback the transaction.
            -- Initialize the seq no for swracad and swrnote as 0.
            l_sst_seqno  := 0;
            l_note_seqno := 0;
          
            -- Now increament the seq no by 1 for each transaction.
          
            IF in_147_seg_rec.swtewls_seg = 'SST' THEN
              l_sst_seqno := l_sst_seqno + 1;
            END IF; -- End of In_147_seg_rec.swtewls_seg = 'SST'
          
            IF in_147_seg_rec.swtewls_seg = 'NTE' THEN
              l_note_seqno := l_note_seqno + 1;
            END IF; -- End of In_147_seg_rec.swtewls_seg = 'NTE'
          
            -- Assign the document seq no and line no to the procedure variables.
          
            l_line_no := in_147_seg_rec.swtewls_line_num;
            --Close the cursor In_147_elem_c if it is open.
          
            l_stage := ' Assigning values to the variables from table SWTEWLE';
          
            IF in_147_elem_c%ISOPEN THEN
              CLOSE in_147_elem_c;
            END IF;
          
            -- Now we open the Inner cursor In_147_elem_c.
            FOR in_147_elem_rec IN in_147_elem_c(l_dcmt_seqno, l_line_no)
            LOOP
              --Now we will go through each record of this cursor and subsequently assign the values to
              -- different variables and then load those values to EDI Load Area tables.
            
              -- Get the Institution code from where the acknowledgment has come.
            
              --GS and ST Segment.
              IF in_147_seg_rec.swtewls_seg = 'GS' AND
                 in_147_elem_rec.swtewle_elm_seq = 2 THEN
                l_shbhead_id_tporg := in_147_elem_rec.swtewle_elm_value;
              END IF; -- End of In_147_seg_rec.swtewls_seg = 'GS'..
            
              -- Generate the date in the following format.
            
              l_shbhead_id_date_key := to_number(to_char(SYSDATE, 'YYMMDD'));
            
              -- Get the EDI document key
              IF in_147_seg_rec.swtewls_seg = 'ST' AND
                 in_147_elem_rec.swtewle_elm_seq = 2 THEN
                l_shbhead_id_edi_key := in_147_elem_rec.swtewle_elm_value;
              END IF; -- End of In_147_seg_rec.swtewls_seg = 'ST'..
            
              -- BGN segment
              IF in_147_seg_rec.swtewls_seg = 'BGN' THEN
                IF in_147_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shbhead_xset_code := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shbhead_ackkey_t := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 3 THEN
                  l_shbhead_send_date := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shbhead_send_time := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 5 THEN
                  l_shbhead_stim_code := in_147_elem_rec.swtewle_elm_value;
                END IF;
              END IF; -- End of In_147_seg_rec.swtewls_seg='BGN'
            
              --- AAA Segment.
            
              IF in_147_seg_rec.swtewls_seg = 'AAA' THEN
                IF in_147_elem_rec.swtewle_elm_seq = 1 THEN
                  l_swraaa0_yes_no_cond_resp := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 2 THEN
                  l_swraaa0_agency_qual_code := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 3 THEN
                  l_swraaa0_reject_reason_code := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 4 THEN
                  l_swraaa0_f_up_action_code := in_147_elem_rec.swtewle_elm_value;
                END IF;
              END IF; -- End of In_147_seg_rec.swtewls_seg='AAA'
            
              ---REF Segment
            
              IF in_147_seg_rec.swtewls_seg = 'REF' THEN
                IF in_147_elem_rec.swtewle_elm_seq = 1 THEN
                  l_ref_qual := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 2 THEN
                  IF l_ref_qual = 'SY' THEN
                    l_shbhead_sid_ssnum := in_147_elem_rec.swtewle_elm_value;
                  ELSIF l_ref_qual = '48' THEN
                    l_shbhead_sid_agency_num := in_147_elem_rec.swtewle_elm_value;
                  END IF; -- l_ref_qual = 'SY'
                ELSIF in_147_elem_rec.swtewle_elm_seq = 3 AND
                      l_ref_qual = '48' THEN
                  l_shbhead_sid_agency_desc := in_147_elem_rec.swtewle_elm_value;
                END IF; -- in_147_elem_rec.swtewle_elm_seq = 1
              END IF; -- In_147_seg_rec.swtewls_seg = 'REF'
            
              --- PWK Segment : Not used.
            
              --NTE Segment
              IF in_147_seg_rec.swtewls_seg = 'NTE' THEN
                IF in_147_elem_rec.swtewle_elm_seq = 1 THEN
                  l_swrnote_note_type := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 2 THEN
                  l_swrnote_comment := in_147_elem_rec.swtewle_elm_value;
                END IF; -- End of In_147_elem_rec .swtewle_elm_seq = 1
              END IF; -- End of In_147_seg_rec.swtewls_seg = 'NTE'
            
              --N1 Segment
              IF in_147_seg_rec.swtewls_seg = 'N1' THEN
                IF in_147_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shrhdr4_enty_code := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shrhdr4_enty_name_1 := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 3 THEN
                  l_shrhdr4_inql_code := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shrhdr4_inst_code := in_147_elem_rec.swtewle_elm_value;
                END IF;
              END IF; -- End Of In_147_seg_rec.swtewls_seg = 'N1'
            
              -- N2 Segment
              IF in_147_seg_rec.swtewls_seg = 'N2' THEN
                IF in_147_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shrhdr4_enty_name_2 := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                ELSIF in_147_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shrhdr4_enty_name_3 := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                END IF;
              END IF; -- End Of In_147_seg_rec.swtewls_seg = 'N2'
            
              -- N3 Segment
              IF in_147_seg_rec.swtewls_seg = 'N3' THEN
                IF in_147_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shrhdr4_street_line_1 := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shrhdr4_street_line_2 := in_147_elem_rec.swtewle_elm_value;
                END IF; -- End of In_147_elem_rec.swtewle_elm_seq =1
              END IF; -- End Of In_147_seg_rec.swtewls_seg = 'N3'
            
              -- N4 Segment
              IF in_147_seg_rec.swtewls_seg = 'N4' THEN
                IF in_147_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shrhdr4_city := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shrhdr4_stat_code := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 3 THEN
                  l_shrhdr4_zip := substr(in_147_elem_rec.swtewle_elm_value,
                                          1, 5);
                ELSIF in_147_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shrhdr4_natn_code := in_147_elem_rec.swtewle_elm_value;
                END IF; -- End of In_147_elem_rec .swtewle_elm_seq =1
              END IF; -- End of In_147_seg_rec.swtewls_seg = 'N4'
            
              -- PER Segment
              IF in_147_seg_rec.swtewls_seg = 'PER' THEN
                IF in_147_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shrhdr4_ctfn_code := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shrhdr4_contact_name := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                ELSIF in_147_elem_rec.swtewle_elm_seq = 3 THEN
                  l_shrhdr4_coql_code := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shrhdr4_comm_no := in_147_elem_rec.swtewle_elm_value;
                END IF; --In_147_elem_rec.swtewle_elm_seq = 1
              END IF; -- End Of In_147_seg_rec.swtewls_seg = 'PER'
            
              --IN1 Segment
              IF in_147_seg_rec.swtewls_seg = 'IN1' THEN
                IF in_147_elem_rec.swtewle_elm_seq = 1 THEN
                  l_shriden_idql_code := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 2 THEN
                  l_shriden_idnm_code := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 3 THEN
                  l_shriden_enid_code := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 4 THEN
                  l_shriden_rnql_code := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 5 THEN
                  l_shriden_ref_numb := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 6 THEN
                  l_shriden_rltn_code := in_147_elem_rec.swtewle_elm_value;
                END IF; --End of In_147_elem_rec.swtewle_elm_seq = 1
              END IF; -- End of In_147_seg_rec.swtewls_seg = 'IN1'
            
              -- IN2 Segment
              IF in_147_seg_rec.swtewls_seg = 'IN2' THEN
                IF in_147_elem_rec.swtewle_elm_seq = 1 THEN
                  l_name_qual := in_147_elem_rec.swtewle_elm_value;
                ELSIF in_147_elem_rec.swtewle_elm_seq = 2 THEN
                  IF l_name_qual = '01' THEN
                    l_shriden_name_prefix := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '02' THEN
                    l_shriden_first_name := in_147_elem_rec.swtewle_elm_value;
                  ELSIF l_name_qual = '03' THEN
                    l_shriden_middle_name_1 := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '04' THEN
                    l_shriden_middle_name_2 := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '05' THEN
                    l_shriden_last_name := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '06' THEN
                    l_shriden_first_initial := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '07' THEN
                    l_shriden_middle_initial_1 := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '08' THEN
                    l_shriden_middle_initial_2 := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '09' THEN
                    l_shriden_name_suffix := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '12' THEN
                    l_shriden_combined_name := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '14' THEN
                    l_shriden_agency_name := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '15' THEN
                    l_shriden_former_name := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                  ELSIF l_name_qual = '16' THEN
                    l_shriden_composite_name := substr(in_147_elem_rec.swtewle_elm_value,1,35);
                  END IF; -- End of l_name_qual = '01'
                END IF; -- End of In_147_elem_rec .swtewle_elm_seq = 1
              END IF; -- End of In_147_seg_rec.swtewls_seg = 'IN2'
            END LOOP; -- Close the loop for Cursor In_147_elem_c
          
            -- Start of Inserting data into EDI Load Area tables. ARP picks up data from these tables
            -- and loads them into Banner Tables.
            --If the current segment is BGN then insert into SHBHEAD.
            --The document seq no is internally generated.
          
            -- Open the shbhead_dcmt_seqno_c to get the current document seqno .
          
            IF csr_shbhead_dcmt_seqno_c%ISOPEN THEN
              CLOSE csr_shbhead_dcmt_seqno_c;
            END IF;
          
            OPEN csr_shbhead_dcmt_seqno_c(l_shbhead_id_edi_key);
            FETCH csr_shbhead_dcmt_seqno_c
              INTO l_current_dcmt_seqno;
          
            IF csr_shbhead_dcmt_seqno_c%NOTFOUND THEN
              l_current_dcmt_seqno := NULL;
            END IF;
          
            CLOSE csr_shbhead_dcmt_seqno_c;
          
            IF in_147_seg_rec.swtewls_seg = 'BGN' THEN
              -- ver V start. FAU mods brought to USF/UNF code on 08/31/06
              l_clob := NULL;
              l_clob := wf_build_edi_tran_clob(l_dcmt_seqno);
              -- ver V end
            
              l_stage := ' Loading into SHBHEAD for a BGN Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- BGN Segment Load
              INSERT INTO shbhead
                (shbhead_id_date_key
                ,shbhead_id_doc_key
                ,shbhead_id_edi_key
                ,shbhead_id_tporg
                ,shbhead_activity_date
                ,shbhead_xset_code
                ,shbhead_ackkey_t
                ,shbhead_send_date
                ,shbhead_send_time
                ,shbhead_stim_code)
              VALUES
                (l_shbhead_id_date_key
                ,'147'
                ,l_shbhead_id_edi_key
                ,l_shbhead_id_tporg
                ,SYSDATE
                ,l_shbhead_xset_code
                ,l_shbhead_ackkey_t
                ,l_shbhead_send_date
                ,l_shbhead_send_time
                ,l_shbhead_stim_code);
            
              -- ver v start
              INSERT INTO saturn.swtdcmt
                (swtdcmt_dcmt_seqno
                ,swtdcmt_document)
              VALUES
                (wshkedi.dcmt_seqno
                ,l_clob);
              -- ver v end
            
              -- Inserting data for AAA segment here.
            
            ELSIF in_147_seg_rec.swtewls_seg = 'AAA' THEN
              l_stage := ' Loading into SWRAAA0 for AAA Segment ' ||
                         l_shbhead_id_edi_key;
            
              INSERT INTO swraaa0
                (swraaa0_yes_no_cond_resp
                ,swraaa0_agency_qual_code
                ,swraaa0_reject_reason_code
                ,swraaa0_follow_up_action_code)
              VALUES
                (l_swraaa0_yes_no_cond_resp
                ,l_swraaa0_agency_qual_code
                ,l_swraaa0_reject_reason_code
                ,l_swraaa0_f_up_action_code);
              --Update shbhead_sid_ssnum for the REF segment.
            ELSIF in_147_seg_rec.swtewls_seg = 'REF' THEN
              l_stage := ' Updating SHBHEAD for a REF Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- Update for REF Segment
              UPDATE shbhead
                 SET shbhead_sid_ssnum       = l_shbhead_sid_ssnum
                    ,shbhead_sid_agency_num  = l_shbhead_sid_agency_num
                    ,shbhead_sid_agency_desc = l_shbhead_sid_agency_desc
               WHERE shbhead_dcmt_seqno = l_current_dcmt_seqno;
              -- Create the comments in SWRNOTE for NTE segment.
            
            ELSIF in_147_seg_rec.swtewls_seg = 'NTE' THEN
              l_stage := ' Loading into SWRNOTE for NTE Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- Load for NTE Segment
              INSERT INTO swvedi_swrnote_head
                (swrnote_seqno
                ,swrnote_parent_loop
                ,swrnote_child_loop
                ,swrnote_note_type
                ,swrnote_comment)
              VALUES
                (l_note_seqno
                ,c_swrnote_parent_loop
                ,c_swrnote_child_loop
                ,l_swrnote_note_type
                ,l_swrnote_comment);
              -- Load the data in SHRHDR4 for N1 segment.
            ELSIF in_147_seg_rec.swtewls_seg = 'N1' THEN
              l_stage := ' Loading into SHRHDR4 for N1 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- Load for N1 Segment
              INSERT INTO shrhdr4
                (shrhdr4_activity_date
                ,shrhdr4_enty_code
                ,shrhdr4_enty_name_1
                ,shrhdr4_inql_code
                ,shrhdr4_inst_code
                ,shrhdr4_domestic_addr_ind)
              VALUES
                (SYSDATE
                ,l_shrhdr4_enty_code
                ,l_shrhdr4_enty_name_1
                ,l_shrhdr4_inql_code
                ,l_shrhdr4_inst_code
                ,'N');
              -- Update the SHRHDR4 for N2 segment.
            ELSIF in_147_seg_rec.swtewls_seg = 'N2' THEN
              l_stage := ' Updating SHRHDR4 for N2 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- Update for N2 Segment
              UPDATE shrhdr4
                 SET shrhdr4_enty_name_2 = l_shrhdr4_enty_name_2
                    ,shrhdr4_enty_name_3 = l_shrhdr4_enty_name_3
               WHERE shrhdr4_dcmt_seqno = l_current_dcmt_seqno;
              -- Update the SHRHDR4 for N3 segment.
            ELSIF (in_147_seg_rec.swtewls_seg = 'N3') THEN
              l_stage := ' Updating SHRHDR4 for N3 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- Update for N3 Segment
              UPDATE shrhdr4
                 SET shrhdr4_street_line1 = l_shrhdr4_street_line_1
                    ,shrhdr4_street_line2 = l_shrhdr4_street_line_2
               WHERE shrhdr4_dcmt_seqno = l_current_dcmt_seqno;
            ELSIF (in_147_seg_rec.swtewls_seg = 'N4') THEN
              l_stage := ' Updating SHRHDR4 for N4 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- Update for N4 Segment
              UPDATE shrhdr4
                 SET shrhdr4_city      = l_shrhdr4_city
                    ,shrhdr4_stat_code = l_shrhdr4_stat_code
                    ,shrhdr4_zip       = l_shrhdr4_zip
                    ,shrhdr4_natn_code = l_shrhdr4_natn_code
               WHERE shrhdr4_dcmt_seqno = l_current_dcmt_seqno;
            ELSIF in_147_seg_rec.swtewls_seg = 'PER' THEN
              l_stage := ' Updating SHRHDR4 for PER Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- Update for PER Segment
              UPDATE shrhdr4
                 SET shrhdr4_ctfn_code    = l_shrhdr4_ctfn_code
                    ,shrhdr4_contact_name = l_shrhdr4_contact_name
                    ,shrhdr4_coql_code    = l_shrhdr4_coql_code
                    ,shrhdr4_comm_no      = l_shrhdr4_comm_no
               WHERE shrhdr4_dcmt_seqno = l_current_dcmt_seqno;
              -- VER I BEGIN
              /*
              ELSIF in_147_seg_rec.swtewls_seg = 'IN1'
              THEN
                 l_stage :=
                          ' Loading into SHRIDEN for IN1 Segment for ID edi key '
                       || l_shbhead_id_edi_key;
              
                 -- Load for IN1 Segment
                 INSERT INTO shriden
                             (shriden_activity_date, shriden_idql_code,
                              shriden_idnm_code, shriden_enid_code,
                              shriden_rnql_code, shriden_ref_numb,
                              shriden_rltn_code)
                      VALUES (SYSDATE, l_shriden_idql_code,
                              l_shriden_idnm_code, l_shriden_enid_code,
                              l_shriden_rnql_code, l_shriden_ref_numb,
                              l_shriden_rltn_code);
              ELSIF in_147_seg_rec.swtewls_seg = 'IN2'
              THEN
                 l_stage :=
                          ' Updating SHRIDEN for IN2 Segment for ID edi key '
                       || l_shbhead_id_edi_key;
              
                 -- Load for IN2 Segment
                 UPDATE shriden
                    SET shriden_agency_name = l_shriden_agency_name,
                        shriden_composite_name = l_shriden_composite_name,
                        shriden_combined_name = l_shriden_combined_name,
                        shriden_former_name = l_shriden_former_name,
                        shriden_name_suffix = l_shriden_name_suffix,
                        shriden_middle_initial_1 =
                                               l_shriden_middle_initial_1,
                        shriden_middle_initial_2 =
                                               l_shriden_middle_initial_2,
                        shriden_middle_name_1 = l_shriden_middle_name_1,
                        shriden_middle_name_2 = l_shriden_middle_name_2,
                        shriden_first_initial = l_shriden_first_initial,
                        shriden_first_name = l_shriden_first_name,
                        shriden_name_prefix = l_shriden_name_prefix,
                        shriden_last_name = l_shriden_last_name
                  WHERE shriden_dcmt_seqno = l_current_dcmt_seqno;
                  */
            ELSIF in_147_seg_rec.swtewls_seg = 'SE' THEN
              l_stage := ' Loading into SHRIDEN for IN1 Segment for ID edi key ' ||
                         l_shbhead_id_edi_key;
            
              -- Load for IN1 Segment
              INSERT INTO shriden
                (shriden_activity_date
                ,shriden_idql_code
                ,shriden_idnm_code
                ,shriden_enid_code
                ,shriden_rnql_code
                ,shriden_ref_numb
                ,shriden_rltn_code
                ,shriden_agency_name
                ,shriden_composite_name
                ,shriden_combined_name
                ,shriden_former_name
                ,shriden_name_suffix
                ,shriden_middle_initial_1
                ,shriden_middle_initial_2
                ,shriden_middle_name_1
                ,shriden_middle_name_2
                ,shriden_first_initial
                ,shriden_first_name
                ,shriden_name_prefix
                ,shriden_last_name
                ,shriden_domestic_addr_ind)
              VALUES
                (SYSDATE
                ,l_shriden_idql_code
                ,l_shriden_idnm_code
                ,l_shriden_enid_code
                ,l_shriden_rnql_code
                ,l_shriden_ref_numb
                ,l_shriden_rltn_code
                ,l_shriden_agency_name
                ,l_shriden_composite_name
                ,l_shriden_combined_name
                ,l_shriden_former_name
                ,l_shriden_name_suffix
                ,l_shriden_middle_initial_1
                ,l_shriden_middle_initial_2
                ,l_shriden_middle_name_1
                ,l_shriden_middle_name_2
                ,l_shriden_first_initial
                ,l_shriden_first_name
                ,l_shriden_name_prefix
                ,l_shriden_last_name
                ,'N');
              -- VER I END
            
            END IF; --End of In_147_seg_rec.swtewls_seg = 'BGN'
          END; -- End of the begin
        END LOOP; -- Close the Loop for cursor In_147_seg_c.
        -- VER I BEGIN
        p_success_out := TRUE;
        p_message_out := l_stage;
        -- VER I END
      
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          wp_handle_error_db('Assigning the variables and loading the data',
                             'wp_load_inbound_147', 'ORACLE',
                             'For dcmt seq ' || to_char(l_dcmt_seqno) ||
                              ' Encountered ' || to_char(SQLCODE) || ' : ' ||
                              substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                             l_success, l_message);
          p_success_out := FALSE;
          p_message_out := l_stage;
      END;
    END LOOP; -- In_147_dcmt_seq_c
  
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      wp_handle_error_db('Start of the processing', 'wp_load_inbound_147',
                         'ORACLE',
                         'For dcmt seq ' || to_char(l_dcmt_seqno) ||
                          ' Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
  END wp_load_inbound_147;

  PROCEDURE wp_generate_outbound_147
  (
    p_dir_in      IN VARCHAR2
   ,p_type_in     IN VARCHAR2
   ,p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  ) IS
  
    --
    --*****************************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wp_generate_outbound_147_db
    --  Process Associated : EDI
    --  Business Logic :
    --   Generating outbond files using PL/SQL Procedures
    --
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User      Reason For Change
    -- -----  ---  ---------  -----------  ------    -----------------------
    -- 1.0.1   A   B-         17-OCT-2002  JBritto   Generating outbound 147
    --                                                EDI ANSI files.
    --         H   B5-003037  13-DEC-2002  mpella    Added update of occurence_date,
    --                                                when sent_indicator is updated.
    --         P   O6-003783  18-JUN-2004  VBANGALO  Removed precission on number
    --                                               variables.
    -- Parameter Information:
    -- ------------
    -- p_dir_in Specify the folder to create outbound files using UTL_FILE package
    -- p_type_in Specifies the file is Test file or Production file.
    --****************************************************************************
  
    l_stage           VARCHAR2(256);
    l_success         BOOLEAN;
    l_message         VARCHAR2(256);
    l_type            CHAR(1) := 'T';
    l_error           VARCHAR2(500);
    l_sqlerrm         VARCHAR2(500);
    l_strbffr         VARCHAR2(2000); -- Holding current segment
    l_fileid          utl_file.file_type;
    l_dir_name        VARCHAR2(1000);
    c_dir_name        VARCHAR2(1000) := '/spool/temp/edi';
    l_file_name       VARCHAR2(100) := 'Out_test_147.txt';
    l_v_college       swvedi_out_147.recv_inst_code%TYPE;
    l_tran_set_number NUMBER;
    l_file_open       BOOLEAN; -- Flag to open OS file
    l_mandatory_check BOOLEAN; -- Flag to check all the mandatory elements.
    --ver P starts
    l_file_name_seq    NUMBER := 0;
    l_file_count       NUMBER := 0;
    l_group_count      NUMBER := 0;
    l_col_count        NUMBER := 0;
    l_count            NUMBER := 0;
    l_line_count       NUMBER := 0;
    l_isa_seq          NUMBER := 0;
    l_ge_seq           NUMBER := 0;
    l_isasegment_seq   NUMBER := 0;
    l_groupsegment_seq NUMBER := 0;
    -- ver P ends
    l_enve_code     swredit.swredit_enve_code%TYPE;
    l_env_qlfr_code swredit.swredit_env_qulfr_code%TYPE;
  
    le_mandatory_exception EXCEPTION;
  
    -- Cursor to populate all distinct instituition.
    -- To generate ISA,GS - Envelop segments for out 147.
  
    CURSOR college_c IS
      SELECT DISTINCT recv_inst_code inst_code
        FROM swvedi_out_147
       WHERE sent_indicator = 'N';
  
    -- Cursor to populate all the segments other than envelop segments.
  
    CURSOR out_147_c(l_v_college swvedi_out_147.recv_inst_code%TYPE) IS
      SELECT *
        FROM swvedi_out_147
       WHERE recv_inst_code = l_v_college
       ORDER BY recv_inst_code;
  
    -- Populate elments of Envelop segments -- ISA and GS
  
    CURSOR swredit_enve_c
    (
      c_tset_code_in swredit.swredit_tset_code%TYPE
     ,c_sbgi_in      swredit.swredit_sbgi_code%TYPE
    ) IS
      SELECT a.swredit_enve_code
            ,a.swredit_env_qulfr_code
        FROM swredit a
       WHERE a.swredit_tset_code = c_tset_code_in
         AND a.swredit_sbgi_code = c_sbgi_in;
    -- Main Procedure Starts Here.
  
  BEGIN
    l_file_open := FALSE;
  
    -- Assigning Directory Name and Type as T or P
  
    IF p_dir_in IS NOT NULL THEN
      l_dir_name := p_dir_in;
    ELSE
      l_dir_name := c_dir_name;
    END IF; -- p_dir_in IS NOT NULL
  
    IF p_type_in IS NOT NULL THEN
      l_type := p_type_in;
    END IF; -- p_type_in IS NOT NULL
  
    -- Generating Unique file name for every Institution
    -- Using ws_out147_file_seq.
  
    SELECT ws_out147_file_seq.nextval INTO l_file_name_seq FROM dual;
    l_file_name := 'O147_' || to_char(SYSDATE, 'MMDD') || l_file_name_seq ||
                   '.EDI';
    l_v_college := NULL;
  
    -- Opening main cursor for all institution to send outbound 147
  
    FOR college_rec IN college_c
    LOOP
      l_group_count := 0;
      l_col_count   := 0;
      l_count       := 0;
      l_v_college   := college_rec.inst_code;
    
      -- Opening element level cursor for all the components of outbound 147
    
      FOR out_147_rec IN out_147_c(l_v_college)
      LOOP
        -- Mandatory Segment and Element Check. If mandatory segment and element
        -- are present for the first institution then OS file will be created
        -- and transaction will be written into it. On subsequent iteration file
        -- will not be created if already created transaction also will be skipped
        -- or written into it based on mandatory segment and element check.
      
        l_stage := 'Checking for Mandatory element for outbound 147';
      
        IF out_147_rec.trans_numb IS NULL OR out_147_rec.ref_numb IS NULL OR
           out_147_rec.validity IS NULL OR (out_147_rec.sid_agency_num IS NULL AND
           out_147_rec.sid_ssnum IS NULL) THEN
          l_stage := 'Mandatory Elements are missing ';
          RAISE le_mandatory_exception;
        ELSE
          l_file_open       := TRUE;
          l_mandatory_check := TRUE;
        END IF; -- out_147_rec.trans_numb IS NULL OR out_147_rec.ref_numb  IS NULL OR ....
      
        l_stage := 'Opening the file for outbound 147';
      
        IF l_mandatory_check THEN
          IF NOT utl_file.is_open(l_fileid) AND l_file_open THEN
            l_fileid := utl_file.fopen(l_dir_name, l_file_name, 'W');
          ELSE
            l_file_open := FALSE;
          END IF; -- l_Mandatory_Check
        
          l_count       := 0;
          l_group_count := l_group_count + 1;
          l_col_count   := l_col_count + 1;
        
          -- To assign unique group number
        
          IF l_group_count = 1 THEN
            SELECT ws_isasegment_seq.nextval
              INTO l_isasegment_seq
              FROM dual;
            SELECT ws_groupsegment_seq.nextval
              INTO l_groupsegment_seq
              FROM dual;
          
            IF swredit_enve_c%ISOPEN THEN
              CLOSE swredit_enve_c;
            END IF; -- swredit_enve_c%ISOPEN
          
            OPEN swredit_enve_c('147', college_rec.inst_code);
            FETCH swredit_enve_c
              INTO l_enve_code
                  ,l_env_qlfr_code;
          
            IF swredit_enve_c%NOTFOUND THEN
              NULL;
              l_enve_code     := 'FIRNX25';
              l_env_qlfr_code := 'ZZ';
            END IF; -- swredit_enve_c%NOTFOUND
          
            CLOSE swredit_enve_c;
            l_stage   := 'Creating ISA Segment for outbound 147';
            l_strbffr := 'ISA|00|          |00|          |22|' ||
                         l_host_inst_code || '         |' ||
                         l_env_qlfr_code || '|' ||
                         rpad(l_enve_code, 15, ' ') || '|' ||
                         to_char(SYSDATE, 'YYMMDD') || '|' ||
                         to_char(SYSDATE, 'HH24MI') || '|' || 'U|00401|' ||
                         lpad(l_isasegment_seq, 9, '0') || '|' || '0|' ||
                         l_type || '|~' || '^';
            utl_file.put_line(l_fileid, l_strbffr);
            l_stage   := 'Creating GS Segment for outbound 147';
            l_strbffr := 'GS|RZ|' || l_host_inst_code || '|' || l_enve_code /*college_rec.inst_code*/
                         || '|' || to_char(SYSDATE, 'YYYYMMDD') || '|' ||
                         to_char(SYSDATE, 'HH24MISS') || '|' ||
                         lpad(l_groupsegment_seq, 9, '0') || '|' ||
                         'X|004010ED0040^';
            utl_file.put_line(l_fileid, l_strbffr);
          END IF; -- l_group_count = 1
        
          -- ST Segment
          l_stage           := 'Creating ST Segment for outbound 147';
          l_tran_set_number := out_147_rec.trans_numb;
          l_count           := l_count + 1;
          l_strbffr         := 'ST|' || '147' || '|' ||
                               out_147_rec.trans_numb || '^';
          utl_file.put_line(l_fileid, l_strbffr);
          -- BGN Segment
          l_stage   := 'Creating BGN Segment for outbound 147';
          l_count   := l_count + 1;
          l_strbffr := 'BGN|06|' || out_147_rec.ref_numb || '|' ||
                       to_char(SYSDATE, 'YYYYMMDD') || '|' ||
                       to_char(SYSDATE, 'hh24mi') || '|' || 'ET^';
          utl_file.put_line(l_fileid, l_strbffr);
          -- AAA Segment
          l_stage := 'Creating AAA Segment for outbound 147';
          l_count := l_count + 1;
        
          IF out_147_rec.follow_up_action IS NULL THEN
            l_strbffr := 'AAA|' || out_147_rec.validity || '||' ||
                         out_147_rec.reject_reason || '^';
          ELSE
            l_strbffr := 'AAA|' || out_147_rec.validity || '||' ||
                         out_147_rec.reject_reason || '|' ||
                         out_147_rec.follow_up_action || '^';
          END IF; -- out_147_rec.follow_up_action IS NULL
        
          utl_file.put_line(l_fileid, l_strbffr);
          --- REF Segment
        
          l_stage := 'Creating REF Segment for outbound 147';
          l_count := l_count + 1;
        
          IF out_147_rec.sid_ssnum IS NULL THEN
            l_strbffr := 'REF|' || '48|' || out_147_rec.sid_agency_num || '^';
          ELSE
            l_strbffr := 'REF|' || 'SY|' || out_147_rec.sid_ssnum || '^';
          END IF; -- out_147_rec.sid_ssnum IS NULL
        
          utl_file.put_line(l_fileid, l_strbffr);
          l_stage := 'Creating N1 and N4 Segment for outbound 147';
          --- N1 and N4 Segment for Sender
          l_count := l_count + 2;
        
          utl_file.put_line(l_fileid,
                            'N1|AS|' || l_host_inst_desc || '|73|' ||
                             l_host_inst_code || '^'); --Introduced variable instead of hardcoded institution description
        
          IF l_host_addr_line1 IS NOT NULL THEN
            utl_file.put_line(l_fileid,
                              'N3|' || l_host_addr_line1 || '|' ||
                               l_host_addr_line2 || '^'); --Introduced variable instead of hardcoded institution description
            l_count := l_count + 1;
          END IF;
        
          utl_file.put_line(l_fileid,
                            'N4|' || l_host_city || '|' || l_host_state || '|' ||
                             l_host_zip || '|US^'); --Introduced variable instead of hardcoded institution description
          --- N1 and N4 Segment for Reciever
          l_count   := l_count + 1;
          l_strbffr := 'N1|' || out_147_rec.recv_enty_code || '|' ||
                       out_147_rec.recv_enty_name || '|' ||
                       out_147_rec.recv_inql_code || '|' ||
                      /*out_147_rec.recv_inst_code*/
                       wf_get_xref_val_db('STVSBGIC',
                                          out_147_rec.recv_inql_code, NULL,
                                          out_147_rec.recv_inst_code) || '^'; -- Modified for UNF to get institution code FICE.
          utl_file.put_line(l_fileid, l_strbffr);
          l_count   := l_count + 1;
          l_strbffr := 'N4|' || out_147_rec.recv_city || '|' ||
                       out_147_rec.recv_stat_code || '|' ||
                       out_147_rec.recv_zip || '|' ||
                       out_147_rec.recv_natn_code || '^';
          utl_file.put_line(l_fileid, l_strbffr);
          --- IN1 Segment
        
          l_stage   := 'Creating IN1 Segment for outbound 147';
          l_count   := l_count + 1;
          l_strbffr := 'IN1|' || out_147_rec.idql_code || '|' ||
                       out_147_rec.idnm_code || '^';
          utl_file.put_line(l_fileid, l_strbffr);
          -- IN2 Segment. Can be upto 5 individual segment as per the our out view.
        
          l_stage := 'Creating IN2 Segment for outbound 147';
        
          IF out_147_rec.name_prefix IS NOT NULL THEN
            l_count   := l_count + 1;
            l_strbffr := 'IN2|01|' || out_147_rec.name_prefix || '^';
            utl_file.put_line(l_fileid, l_strbffr);
          END IF; --out_147_rec.name_prefix IS NOT NULL
        
          IF out_147_rec.first_name IS NOT NULL THEN
            l_count   := l_count + 1;
            l_strbffr := 'IN2|02|' || out_147_rec.first_name || '^';
            utl_file.put_line(l_fileid, l_strbffr);
          END IF; -- out_147_rec.first_name IS NOT NULL
        
          IF out_147_rec.middle_name IS NOT NULL THEN
            l_count   := l_count + 1;
            l_strbffr := 'IN2|03|' || out_147_rec.middle_name || '^';
            utl_file.put_line(l_fileid, l_strbffr);
          END IF; -- out_147_rec.middle_name IS NOT NULL
        
          IF out_147_rec.last_name IS NOT NULL THEN
            l_count   := l_count + 1;
            l_strbffr := 'IN2|05|' || out_147_rec.last_name || '^';
            utl_file.put_line(l_fileid, l_strbffr);
          END IF; -- out_147_rec.last_name IS NOT NULL
        
          IF out_147_rec.name_suffix IS NOT NULL THEN
            l_count   := l_count + 1;
            l_strbffr := 'IN2|09|' || out_147_rec.name_suffix || '^';
            utl_file.put_line(l_fileid, l_strbffr);
          END IF; -- out_147_rec.name_suffix IS NOT NULL
        
          -- SE Segment
        
          l_stage   := 'Creating SE Segment for outbound 147';
          l_count   := l_count + 1;
          l_strbffr := 'SE|' || to_char(l_count) || '|' ||
                       out_147_rec.trans_numb || '^';
          utl_file.put_line(l_fileid, l_strbffr);
        
          -- Updating  SENT_INDICATOR variable to Y for generated out 147 transaction.
          -- Mpella 12/17/2002 - commented out the following update, and changed to
          --  update the swbotrs table instead, after adding an update to the both the
          --  occurence_date and activity_date fields.
          /*               UPDATE swvedi_out_147
                            SET sent_indicator = 'Y',
                                occurence_date = SYSDATE
                          WHERE trans_numb = out_147_rec.trans_numb;
          */
          UPDATE swrotrs
             SET swrotrs_successful_ind = 'Y'
                ,swrotrs_occurence_date = SYSDATE
                ,swrotrs_activity_date  = SYSDATE
           WHERE swrotrs_trans_numb = out_147_rec.trans_numb
             AND swrotrs_step_code IN ('TRANS SENT', 'END');
          COMMIT;
          p_success_out := TRUE;
        END IF; -- l_mandatory_Check
      END LOOP; -- out_147_rec.
    
      IF l_group_count > 0 THEN
        l_strbffr := 'GE|' || l_group_count || '|' ||
                     lpad(l_groupsegment_seq, 9, '0');
        l_strbffr := rtrim(l_strbffr, '|') || '^';
        utl_file.put_line(l_fileid, l_strbffr);
        l_strbffr := 'IEA|1|' || lpad(l_isasegment_seq, 9, '0');
        l_strbffr := rtrim(l_strbffr, '|') || '^';
        utl_file.put_line(l_fileid, l_strbffr);
      END IF;
    END LOOP; -- END OF college_c
  
    utl_file.fclose(l_fileid);
    COMMIT;
  EXCEPTION
    WHEN le_mandatory_exception THEN
      wp_handle_error_db('Mandatory element Check - outbound 147',
                         'wp_generate_outbound_147_db', 'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
    WHEN utl_file.invalid_path THEN
      wp_handle_error_db('Updating SHRIDEN- N3',
                         'wp_generate_outbound_147_db', 'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN utl_file.invalid_mode THEN
      wp_handle_error_db('Invalid File opening Mode',
                         'wp_generate_outbound_147_db', 'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN utl_file.invalid_filehandle THEN
      wp_handle_error_db('Invalid File Handle',
                         'wp_generate_outbound_147_db', 'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN utl_file.invalid_operation THEN
      wp_handle_error_db('Invalid Operation', 'wp_generate_outbound_147_db',
                         'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN utl_file.write_error THEN
      wp_handle_error_db('Write Error', 'wp_generate_outbound_147_db',
                         'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN utl_file.internal_error THEN
      wp_handle_error_db('Internal Error', 'wp_generate_outbound_147_db',
                         'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN OTHERS THEN
      wp_handle_error_db('Error in generating outbound 147',
                         'wp_generate_outbound_147_db', 'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
  END; -- wp_generate_outbound_147

  PROCEDURE wp_generate_outbound_146
  (
    p_dir_in      IN VARCHAR2
   ,p_type_in     IN VARCHAR2
   ,p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  ) IS
  
    --
    --*****************************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wp_generate_outbound_146_db
    --  Process Associated : EDI
    --  Business Logic :
    --   Generating outbond files using PL/SQL Procedures
    --
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User    Reason For Change
    -- -----  ---  ---------  -----------  ------  -----------------------
    -- 1.0.1   A   B5-002889  20-SEP-2002  JBritto  Generating outbound 146
    --                                              EDI ANSI files.
    -- 1.0.2   A   B5-002964  11-NOV-2002  HSHEKHAR Modified the string generation logic for SST segment.
    --  n/a    F   B5-003033  10-DEC-2002  VBANGALO Modified code to generate
    --                                              out 146 for SSN's that do have
    --                                              date of birth. For others
    --                                              error table record is generated.
    --         H   B5-003037  13-DEC-2002  mpella   Added update of occurence_date,
    --                                               when sent_indicator is updated.
    --         M   06-003677  25-FEB-2004  VBANGALO Initialized variable out_xref_rec.
    --                        23-MAR-2004  VBANGALO Modified code to test for ansii standars
    --                                              before it is built.
    --         P   O6-003783  18-JUN-2004  VBANGALO  Removed precission on number
    --                                               variables.
    --         Q   O6-003789  29-JUN-2004  VBANGALO  Modified code to set GE, IEA properly
    --         S   O6-003809  26-JUL-2004  VBANGALO  Modified code to include qualifier code
    --                                               for N1 segment to include 75.
    -- Parameter Information:
    -- ------------
    -- p_dir_in Specify the folder to create outbound files using UTL_FILE package
    -- p_type_in Specifies the file is Test file or Production file.
    --****************************************************************************
    l_stage           VARCHAR2(256);
    l_success         BOOLEAN;
    l_message         VARCHAR2(256);
    l_type            CHAR(1) := 'T';
    l_error           VARCHAR2(500);
    l_sqlerrm         VARCHAR2(500);
    l_strbffr         VARCHAR2(2000); -- Holding current segment
    l_fileid          utl_file.file_type;
    l_dir_name        VARCHAR2(100);
    c_dir_name        VARCHAR2(1000) := '/spool/temp/edi';
    l_file_name       VARCHAR2(1000) := 'Out_test_146.txt';
    l_v_college       swvedi_146_open.recv_sgbi_code%TYPE;
    l_v_trans_numb    swvedi_146_open.trans_numb%TYPE;
    l_stvsbgi_code    stvsbgi.stvsbgi_code%TYPE;
    l_file_open       BOOLEAN; -- Flag to open OS file
    l_mandatory_check BOOLEAN; -- Flag to check all the mandatory elements.
    out_146_rec       swvedi_out_146%ROWTYPE;
    out_xref_rec      swvedi_146_xref%ROWTYPE;
    l_qlfr_code       VARCHAR2(2);
    l_erp_tran_type   VARCHAR2(2);
    -- ver P starts
    l_tran_set_number  NUMBER;
    l_file_name_seq    NUMBER := 0;
    l_file_count       NUMBER := 0;
    l_group_count      NUMBER := 0;
    l_col_count        NUMBER := 0;
    l_count            NUMBER := 0;
    l_line_count       NUMBER := 0;
    l_isa_seq          NUMBER := 0;
    l_ge_seq           NUMBER := 0;
    l_isasegment_seq   NUMBER := 0;
    l_groupsegment_seq NUMBER := 0;
    -- ver P ends
    l_enve_code     swredit.swredit_enve_code%TYPE;
    l_env_qlfr_code swredit.swredit_env_qulfr_code%TYPE;
  
    le_mandatory_exception EXCEPTION;
    l_dcmt_seqno             swbotrn.swbotrn_dcmt_seqno%TYPE;
    l_valied_no_transactions NUMBER(5) := 0;
    l_valied_transaction     BOOLEAN := TRUE;
  
    -- Cursor to populate all instituition.
    -- Cursor to populate all distinct instituition.
    -- To generate ISA,GS - Envelop segments for out 146.
  
    CURSOR college_c IS
      SELECT DISTINCT recv_sgbi_code inst_code
        FROM swvedi_146_open a
       WHERE a.sent_indicator = 'N'
         AND EXISTS
       (SELECT 'x'
                FROM swvedi_out_146 b
               WHERE b.out146_recv_sgbi_code = a.recv_sgbi_code);
  
    -- Cursor to populate all the segments other than envelop segments.
  
    CURSOR out_146_open_c(l_v_college swvedi_146_open.recv_sgbi_code%TYPE) IS
      SELECT *
        FROM swvedi_146_open a
       WHERE a.recv_sgbi_code = l_v_college
         AND EXISTS
       (SELECT 'x'
                FROM swvedi_out_146 b
               WHERE b.out146_recv_sgbi_code = a.recv_sgbi_code)
       ORDER BY a.recv_sgbi_code;
    out_146_row out_146_open_c%ROWTYPE;
    --> cursor that brigns missing date of birth
    CURSOR missing_date_of_birth_c IS
      SELECT * FROM swvedi_out_146 a WHERE a.out146_birth_date IS NULL;
  
    -- Populate elments of Envelop segments -- ISA and GS
  
    CURSOR out_146_c(l_v_trans_numb swvedi_out_146.out146_trans_numb%TYPE) IS
      SELECT *
        FROM swvedi_out_146
       WHERE out146_trans_numb = l_v_trans_numb;
  
    -- To build N1 and N4 segment for recieving institution.
  
    CURSOR out_xref_c(l_v_trans_numb swvedi_146_xref.trans_numb%TYPE) IS
      SELECT * FROM swvedi_146_xref WHERE trans_numb = l_v_trans_numb;
  
    CURSOR out_stvsbgi_c IS
      SELECT decode(stvsbgi_type_ind, 'H', 'KR', 'C', 'AT') qlfr_code
            ,decode(stvsbgi_type_ind, 'H', 'DD', 'C', 'PS') erp_tran_type
        FROM stvsbgi
       WHERE stvsbgi_code = l_stvsbgi_code;
  
    -- Populate elments of Envelop segments -- ISA and GS
  
    CURSOR swredit_enve_c
    (
      c_tset_code_in swredit.swredit_tset_code%TYPE
     ,c_sbgi_in      swredit.swredit_sbgi_code%TYPE
    ) IS
      SELECT a.swredit_enve_code
            ,a.swredit_env_qulfr_code
        FROM swredit a
       WHERE a.swredit_tset_code = c_tset_code_in
         AND a.swredit_sbgi_code = c_sbgi_in;
    ----
  
    FUNCTION wf_is_transaction_valied(st_bgn_rec out_146_open_c%ROWTYPE)
      RETURN BOOLEAN IS
      /*
      -- Thsi function validates each transaction
      */
      lv_b_valied BOOLEAN := TRUE;
      FUNCTION wf_is_valied_stbgn_segment RETURN BOOLEAN IS
        /*
          -- This function validates st segment
        */
        lv_valied_stbgn_segment BOOLEAN := TRUE;
      
        --wf_is_valied_stbgn_segment begin
      BEGIN
        --ST segment check begin
        -- ST01,02 are mandatory. Since 01 is hardcoded as 146
        -- 02 is checked for existence of value
        l_stage := 'before st segment check';
        IF st_bgn_rec.ref_numb IS NULL THEN
          l_stage                 := 'ST01 is invalid';
          lv_valied_stbgn_segment := FALSE;
        END IF; -- st_bgn_rec.ref_numb
        --ST segment check end
        --BGN segment check we have only 01,02,03,04,05
        --BGN01,BGN02,BGN03 are mandatory
        -- BGN01 is purpose_code, BGN02 is ref_numb
        -- BGN03 value is derived from to_char(SYSDATE, 'YYYYMMDD').
        -- so we need to check only for purporse code and ref_numb
        -- Since BGN03 and BGN04 is generated from sysdate,
        -- we do mandatory test only for
        -- 01, and 02.
        --condition C0504 test -- If BGN05 is present, then BGN04 is required
        -- Since BGN04 is derived from sysdate and BGN05 is hard coded and is
        -- valied code i.e ET,
        -- we need not do this test.
        IF st_bgn_rec.purpose_code IS NULL OR st_bgn_rec.ref_numb IS NULL THEN
          l_stage                 := 'BGN01 OR BGN02 IS NULL';
          lv_valied_stbgn_segment := FALSE;
        END IF; --st_bgn_rec.purpose_code IS NULL or st_bgn_rec.ref_numb
        --check for bgn01 value
        IF st_bgn_rec.purpose_code NOT IN ('00', '07', '18') THEN
          l_stage                 := 'BGN01 has invalid value';
          lv_valied_stbgn_segment := FALSE;
        END IF; --IF st_bgn_rec.purpose_code
      
        RETURN lv_b_valied;
      END wf_is_valied_stbgn_segment;
    
      FUNCTION wf_is_valied_erprefdmg_segs(p_trans_numb_in swbotrn.swbotrn_trans_numb%TYPE)
        RETURN BOOLEAN IS
        /*
          -- This function validates erp, ref, bgn segments
        */
        lv_valied_erprefdmg_segs BOOLEAN := TRUE;
        lv_stvsbgi_code          stvsbgi.stvsbgi_code%TYPE;
        lv_erp_tran_type         VARCHAR2(10);
        lv_qlfr_code             VARCHAR2(10);
        lv_erp_sbgi_count        NUMBER(2);
        lv_erp_type_count        NUMBER(2);
        out_146_b_rec            out_146_c%ROWTYPE;
        out_xref_a_rec           out_xref_c%ROWTYPE;
        out_xref_loop            NUMBER(2);
        --wf_is_lv_valied_erprefdmg_segs begin
      BEGIN
        out_146_b_rec     := NULL;
        lv_stvsbgi_code   := NULL;
        lv_erp_sbgi_count := 0;
        l_stage           := ' in wf_is_lv_valied_erprefdmg_segs before out_146_a_rec';
        FOR out_146_a_rec IN out_146_c(p_trans_numb_in)
        LOOP
          lv_erp_sbgi_count := lv_erp_sbgi_count + 1;
          lv_stvsbgi_code   := out_146_a_rec.out146_recv_sgbi_code;
          l_stvsbgi_code    := out_146_a_rec.out146_recv_sgbi_code;
          out_146_b_rec     := out_146_a_rec;
        END LOOP; --out_146_a_rec
        lv_erp_type_count := 0;
        l_stage           := ' in wf_is_lv_valied_erprefdmg_segs before out_stvsbgi_rec';
        FOR out_stvsbgi_rec IN out_stvsbgi_c
        LOOP
          lv_erp_type_count := lv_erp_type_count + 1;
          lv_erp_tran_type  := out_stvsbgi_rec.erp_tran_type;
          lv_qlfr_code      := out_stvsbgi_rec.qlfr_code;
        
        END LOOP; --out_stvsbgi_rec
      
        --ERP SEGMENT CHECK
        l_stage := ' in wf_is_lv_valied_erprefdmg_segs before ERP SEG check ';
        -- ERP SEG repeat check it should be 1.
        IF lv_erp_sbgi_count <> 1 OR lv_erp_type_count <> 1 THEN
          l_stage                  := 'ERP Segment repeat error';
          lv_valied_erprefdmg_segs := FALSE;
        END IF; --lv_erp_sbgi_count <> 1 or lv_erp_type_count <> 1
        --CHECK FOR MANDATORY ELEMENT ERP01 IS MANDATORY ELEMENT
        --lv_erp_tran_type IS ERP01
        IF lv_erp_tran_type IS NULL THEN
          l_stage                  := 'Mandatory ERP01 is missing';
          lv_valied_erprefdmg_segs := FALSE;
        END IF; -- lv_erp_tran_type
        -- CHECK FOR ERP01 VALUE it should be IN ('DD','DP',PS')
        IF lv_erp_tran_type NOT IN ('DD', 'DP', 'PS') THEN
          l_stage                  := 'Invalid ERP01 value';
          lv_valied_erprefdmg_segs := FALSE;
        END IF; --lv_erp_tran_type
        --ERP03 value check it should be in ('R4','R2','R3','R5')
        /* IF out_146_b_rec.out_146_ref_qual NOT IN ('R4', 'R2', 'R3', 'R5') THEN
          l_stage := 'Invalid ERP03 value and value is '||out_146_b_rec.out_146_ref_qual;
          lv_valied_erprefdmg_segs := FALSE;
        END IF; --st_bgn_rec.out_146_ref_qual NOT IN ('R4','R2','R3','R5')*/
      
        --ERP SEGMENT CHECK END
      
        -- REF SEGMENT CHECK BEGIN
        /*
           RULES:
           1.REF01 is Mandatory and should be in values like
           ('28','30','48','49','4A','50','56','57','C0','LR','MV','SY')
           2.At least one of REF02 or REF03 is required
        
        */
        -- REF SEGMENT CHECK END
        --RULE1
        IF out_146_b_rec.out_146_ref_qual NOT IN
           ('28', '30', '48', '49', '4A', '50', '56', '57', 'C0', 'LR', 'MV',
            'SY') THEN
          l_stage                  := 'Invalid REF01 value';
          lv_valied_erprefdmg_segs := FALSE;
        END IF; --st_bgn_rec.out_146_ref_qual NOT IN ('28','30','48','49'
        --END RULE1
        --RULE2
        -- Since we generate only REF02 we should see that this is not null
        IF out_146_b_rec.out146_ssn IS NULL THEN
          l_stage                  := 'REF02 is missing';
          lv_valied_erprefdmg_segs := FALSE;
        END IF; -- st_bgn_rec.out146_ssn
        --END RULE2
        -- DMG SEGMENT CHECK BEGIN
        /*
          RULES:
          we are using DMG01,DMG02,DMG03 elements under DMG segment.
          Rule1. DMG01 should have value within ('CM','CY','D8','DB')
            (Since it is hard coded as D8, this rule satisfies.
        
          Rule2. DMG02 should be in the format specified in DMG01
                 this is derived as to_char(out_146_rec.out146_birth_date, 'YYYYMMDD')
                 which statisfies this rule.
          Rule3. DMG03 should have values within('F','M','U');
          Rule4. If either DMG01 or DMG02 is present, then the other is required.
                 Since DMG01 is hard coded as D8, we should check for DMG02 for null
        
        */
      
        -- Rule3 BEGIN
        IF (out_146_b_rec.out146_sex NOT IN ('F', 'M', 'U')) THEN
          l_stage                  := 'Invalid DMG03 value';
          lv_valied_erprefdmg_segs := FALSE;
        END IF; --(out_146_b_rec.out146_sex NOT IN ('F','M','U') )
      
        -- Rule3 END
        -- Rule4 BEGIN
        IF (out_146_b_rec.out146_birth_date IS NULL) THEN
          l_stage                  := 'DMG02 is missing';
          lv_valied_erprefdmg_segs := FALSE;
        END IF; --(out_146_b_rec.out146_birth_date is null)
        -- Rule4 END
      
        -- DMG SEGMENT CHECK END
      
        --SST SEGMENT CHECK START
        /*
           RULES:
            SST segment is built only when SST03 is not null.
            we are using SST02,SST03,elements under SST segments.
            Rule1. SST02 should have value within ('CM','CY','D8','DB')
              (Since it is hard coded as D8, this rule satisfies.
        
            Rule2. SST03 should be in the format specified in SST02
                   this is derived as to_char(ut146_sorhsch_grad_date, 'YYYYMMDD')
                   which statisfies this rule.
            Rule3. If either SST02 or SST03 is present, then the other is required.
                   Since SST02 is hard coded as D8, we should check for SST03 for null.
                   Since SST segment is built only when SST03 is not null, we need not check
                   this.
        
        */
        --SST SEGMENT CHECK END
        --N1 SEGMENT LOOP CHECK BEGIN
        /*
           We are using N101, N102, N103,N104 elements
           N1(Sender segment) Since everyelement is hard coded as per requirement,
                  we need not look for validation.
           PER(Sender segment) of N1 loop is also hard coded and is as per
                  requirement. we need not validate that.
           Rules: (For N1(recv) segment only.)
           Rule1. N1 should have 2 loops.(one is for sender and another is for receiver).
                  N1 sender loop is hard coded. So, this is always 1.
                  N1 receiver loop is derived from out_xref_c cursor. We should make sure
                     that this always returns 1 record.
          Rule2.  N101 should have value within(''AS','AT','KS','KR').
                  qlfr code
          Rule3.  N103 should have values within ('71','72','73','74','77','78','CB','CS')
          Rule4.  At least one of N102 or N103 is required
          Rule5.  If either N103 or N104 is present, then the other is required.
        
        
        */
        --rule1 begin
        out_xref_loop  := 0;
        out_xref_a_rec := NULL;
        FOR out_xref_rec IN out_xref_c(p_trans_numb_in)
        LOOP
          --dbms_output.put_line('out sbgi is '||out_xref_rec.recv_sgbi_code);
          out_xref_loop  := out_xref_loop + 1;
          out_xref_a_rec := out_xref_rec;
          --dbms_output.put_line('out sbgi2 is '||out_xref_a_rec.recv_sgbi_code);
        END LOOP;
        --dbms_output.put_line('out sbgi3 is '||out_xref_a_rec.recv_sgbi_code);
        IF out_xref_loop <> 1 THEN
          l_stage                  := 'Wrong number of N1 loops and loops are ' ||
                                      to_char(out_xref_loop);
          lv_valied_erprefdmg_segs := FALSE;
        END IF; --out_xref_loop <>1
        --rule1 end
        -- rul2 begin
        IF lv_qlfr_code NOT IN ('AS', 'AT', 'KS', 'KR') THEN
          l_stage                  := 'Invalid N101 value';
          lv_valied_erprefdmg_segs := FALSE;
        END IF; --lv_qlfr_code not in('AS','AT','KS','KR')
        -- rule2 end
        --Rule3 begin
        IF out_xref_a_rec.sbgi_qlfr NOT IN
           ('71', '72', '73', '74', '77', '78', '75', 'CB', 'CS') THEN
          l_stage                  := 'Invalid N103 value';
          lv_valied_erprefdmg_segs := FALSE;
        END IF; --sbgi_qlfr not in ('71','72','73','74','77','78','CB','CS')
        --Rule3 end
        --Rule4 begin
        IF out_xref_a_rec.sbgi_desc IS NULL AND
           out_xref_a_rec.sbgi_qlfr IS NULL THEN
          l_stage                  := 'At least one of N102 or N103 is required. N102 = ' ||
                                      out_xref_a_rec.sbgi_desc ||
                                      ' N103 = ' ||
                                      out_xref_a_rec.sbgi_qlfr;
          lv_valied_erprefdmg_segs := FALSE;
        END IF;
        --Rule4 end
        --Rule5 begin
        IF out_xref_a_rec.sbgi_qlfr IS NOT NULL OR
           out_xref_a_rec.recv_sgbi_code IS NOT NULL THEN
          IF out_xref_a_rec.sbgi_qlfr IS NULL OR
             out_xref_a_rec.recv_sgbi_code IS NULL THEN
            l_stage                  := 'If either N103 or N104 is present, then the other is required.';
            lv_valied_erprefdmg_segs := FALSE;
          END IF; --out_xref_a_rec.sbgi_qlfr is  null and  out_xref_a_rec.recv_sgbi_code is null
        END IF; --out_xref_a_rec.sbgi_qlfr is not null or out_xref_a_rec.recv_sgbi_code is not null
        --Rule5 end
        --N4(N1 loop) (Recv segment) Start
        /*
           We are using N401,N402 elements. Both are not mandatory elements.
           Rules:
           Rule 1. N402 should be with in ('AL','AK','AZ','AR','CA','CZ','CO','CT','DE','DC','FL','GA','GU','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','PR','RI','SC','SD','TN','TX','UT','VT','VA','VI','WA','WV','WI','WY')
        
        
        
        */
        --N4(N1 loop) (Recv segment) End
        IF out_146_b_rec.out146_recv_stat_code NOT IN
           ('AL', 'AK', 'AZ', 'AR', 'CA', 'CZ', 'CO', 'CT', 'DE', 'DC', 'FL',
            'GA', 'GU', 'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME',
            'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
            'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'PR', 'RI', 'SC',
            'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'VI', 'WA', 'WV', 'WI', 'WY') THEN
        
          l_stage                  := 'Invalid N402' || 'the value is ' ||
                                      out_146_b_rec.out146_recv_stat_code;
          lv_valied_erprefdmg_segs := FALSE;
        END IF; -- out_146_b_rec.out146_recv_stat_code not in  ('KS','KY',--)
      
        --N1 SEGMENT LOOP CHECK END
        --IN1 Segment loop check begin
        /*
           Rules:
           Rule1. IN1 loop can have maximum of 15 loops.
                  We hard coded IN1 segment as per requirement  has only one loop
                  So, this is satisfied.
           Rule2. IN2(IN1 loop) can have 10 segment repeats.
                  We have hard coded 5 loops. So, this is satisfied.
           Rule3. IN201 is Mandatory.
                  we have hard coded values. So values can not be null.
                  This rule is satisfied.
           Rule4. IN201 element can have values within ('01','02','03','04','05','06','07','08','09','12','14','15','16','17','18','22')
                  We have hard coded values as '01','02','05','07','09' which are with in range.
                  This rule also satisfied.
           Rule5. IN202 is Mandatory.
                  We are building IN2 segment only when IN202 segment is not null.
                  So this rule is also satisfied.
        */
        --IN1 Segment loop check end
      
        RETURN lv_valied_erprefdmg_segs;
      END wf_is_valied_erprefdmg_segs;
    
    BEGIN
      --wf_is_transaction_valied begin
      l_stage     := 'before calling wf_is_valied_stbgn_segment';
      lv_b_valied := wf_is_valied_stbgn_segment;
      IF lv_b_valied THEN
        l_stage     := 'before wf_is_valied_erprefdmg_segs';
        lv_b_valied := wf_is_valied_erprefdmg_segs(st_bgn_rec.trans_numb);
      END IF; --if lv_b_valied
    
      RETURN lv_b_valied;
    END wf_is_transaction_valied;
  
    ----------
  
    -- Main Procedure Starts Here.
  
  BEGIN
    l_file_count := 0;
  
    -- Assigning Directory Name and Type as T or P
  
    IF p_dir_in IS NOT NULL THEN
      l_dir_name := p_dir_in;
    ELSE
      l_dir_name := c_dir_name;
    END IF; -- p_dir_in IS NOT NULL
  
    IF p_type_in IS NOT NULL THEN
      l_type := p_type_in;
    END IF; -- p_type_in IS NOT NULL
  
    -- Generating Unique file name for every Institution
    -- Using ws_out146_file_seq.
  
    SELECT ws_out146_file_seq.nextval INTO l_file_name_seq FROM dual;
    l_file_name := 'O146_' || to_char(SYSDATE, 'MMDD') || l_file_name_seq ||
                   '.EDI';
    l_v_college := NULL;
  
    FOR college_rec IN college_c
    LOOP
      l_group_count := 0;
      l_col_count   := 0;
      l_count       := 0;
      l_v_college   := college_rec.inst_code;
      -- version Q start
      l_valied_no_transactions := 0;
      -- version Q END
    
      FOR out_146_open_rec IN out_146_open_c(l_v_college)
      LOOP
        BEGIN
          -- version L start
          p_success_out := TRUE;
          /*
            IF out_146_open_rec.ref_numb IS NULL OR
               out_146_open_rec.purpose_code IS NULL THEN
              l_stage           := 'Mandatory Elements are missing ';
              l_mandatory_check := FALSE;
              RAISE le_mandatory_exception;
            ELSE
              l_file_open       := TRUE;
              l_mandatory_check := TRUE;
            END IF; --  out_146_open_rec.ref_numb IS NULL OR out_146_open_rec.purpose_code IS NULL
          */
          -- version L end
          -- version L start
          -- version Q start
          --l_valied_no_transactions := 0;
          -- version Q END
          l_stage              := 'before calling wf_is_transaction_valied';
          l_valied_transaction := wf_is_transaction_valied(out_146_open_rec);
          IF l_valied_transaction THEN
            l_valied_no_transactions := l_valied_no_transactions + 1;
          ELSE
            RAISE le_mandatory_exception;
          END IF; --l_valied_transaction
          IF l_valied_no_transactions = 1 THEN
            IF NOT utl_file.is_open(l_fileid) THEN
              l_fileid := utl_file.fopen(l_dir_name, l_file_name, 'W');
            END IF; -- l_Mandatory_Check
            l_stage := 'before getting sequence';
            SELECT ws_isasegment_seq.nextval
              INTO l_isasegment_seq
              FROM dual;
            SELECT ws_groupsegment_seq.nextval
              INTO l_groupsegment_seq
              FROM dual;
          
            IF swredit_enve_c%ISOPEN THEN
              CLOSE swredit_enve_c;
            END IF;
            OPEN swredit_enve_c('146', college_rec.inst_code);
            FETCH swredit_enve_c
              INTO l_enve_code
                  ,l_env_qlfr_code;
            IF swredit_enve_c%NOTFOUND THEN
              NULL;
              l_enve_code     := 'FIRNX25';
              l_env_qlfr_code := 'ZZ';
            END IF;
            l_stage := 'before creating ISA segment';
            CLOSE swredit_enve_c;
            l_strbffr := 'ISA|00|          |00|          |22|' ||
                         l_host_inst_code || '         |' ||
                         l_env_qlfr_code || '|' ||
                         rpad(l_enve_code, 15, ' ') || '|' ||
                         to_char(SYSDATE, 'YYMMDD') || '|' ||
                         to_char(SYSDATE, 'HH24MI') || '|' || 'U|00401|' ||
                         lpad(l_isasegment_seq, 9, '0') || '|' || '0|' ||
                         l_type || '|~' || '^';
            utl_file.put_line(l_fileid, l_strbffr);
            l_strbffr := 'GS|RY|' || l_host_inst_code || '|' || l_enve_code /*college_rec.inst_code*/
                         || '|' || to_char(SYSDATE, 'YYYYMMDD') || '|' ||
                         to_char(SYSDATE, 'HH24MISS') || '|' ||
                         lpad(l_groupsegment_seq, 9, '0') || '|' ||
                         'X|004010ED0040^';
            utl_file.put_line(l_fileid, l_strbffr);
          
          END IF; --l_valied_no_transactions = 1
          IF l_valied_no_transactions >= 1 THEN
            -- version L end
            -- version L start
            /*
            IF l_mandatory_check THEN
            */
            -- version L start
            --       IF NOT utl_file.is_open(l_fileid) THEN
            --    l_fileid := utl_file.fopen(l_dir_name, l_file_name, 'W');
            -- version L start
            /*
              ELSE
                l_file_open := FALSE;
            */
            -- version L end
            --    END IF; -- l_Mandatory_Check
          
            l_count       := 0;
            l_group_count := l_group_count + 1;
            l_col_count   := l_col_count + 1;
          
            -- ST Segment
            l_stage           := 'Creating ST Segment for outbound 146';
            l_tran_set_number := out_146_open_rec.trans_numb;
            l_count           := l_count + 1;
            l_strbffr         := 'ST|' || '146' || '|' ||
                                 out_146_open_rec.ref_numb || '^';
            utl_file.put_line(l_fileid, l_strbffr);
            -- BGN Segment
          
            l_stage   := 'Creating BGN Segment for outbound 146';
            l_count   := l_count + 1;
            l_strbffr := 'BGN|' || out_146_open_rec.purpose_code || '|' ||
                         out_146_open_rec.ref_numb || '|' ||
                         to_char(SYSDATE, 'YYYYMMDD') || '|' ||
                         to_char(SYSDATE, 'hh24mi') || '|' || 'ET^';
            utl_file.put_line(l_fileid, l_strbffr);
            -- ERP Segment
          
            l_stage        := 'Creating ERP Segment for outbound 146';
            l_v_trans_numb := out_146_open_rec.trans_numb;
          
            IF out_146_c%ISOPEN THEN
              CLOSE out_146_c;
            END IF;
          
            --stvsbgi_c;
            --END IF;
            out_146_rec := NULL;
            OPEN out_146_c(l_v_trans_numb);
            FETCH out_146_c
              INTO out_146_rec;
            CLOSE out_146_c;
            l_stvsbgi_code := out_146_rec.out146_recv_sgbi_code;
            --CLOSE out_146_c;
            --IF out_stvsbgi_c%ISOPEN THEN
            --   CLOSE out_
          
            --OPEN out_stvsbgi_c;
            --FETCH out_stvsbgi_c INTO out_stvsbgi_rec;
            --CLOSE out_stvsbgi_c;
            FOR out_stvsbgi_rec IN out_stvsbgi_c
            LOOP
              l_erp_tran_type := out_stvsbgi_rec.erp_tran_type;
              l_qlfr_code     := out_stvsbgi_rec.qlfr_code;
            END LOOP;
          
            l_count   := l_count + 1;
            l_strbffr := 'ERP|' || l_erp_tran_type || '||' ||
                         out_146_rec.out146_action_code || '^';
            utl_file.put_line(l_fileid, l_strbffr);
            --- REF Segment
          
            l_stage   := 'Creating REF Segment for outbound 146';
            l_count   := l_count + 1;
            l_strbffr := 'REF|' ||
                         ltrim(rtrim(out_146_rec.out_146_ref_qual)) || '|' ||
                         out_146_rec.out146_ssn || '^';
            utl_file.put_line(l_fileid, l_strbffr);
            --- DMG Segment
          
            l_stage   := 'Creating DMG Segment for outbound 146';
            l_count   := l_count + 1;
            l_strbffr := 'DMG|D8|' ||
                         to_char(out_146_rec.out146_birth_date, 'YYYYMMDD') || '|' ||
                         out_146_rec.out146_sex || '^';
            utl_file.put_line(l_fileid, l_strbffr);
            --- SST Segment
            l_stage := 'Creating SST Segment for outbound 146';
          
            IF out_146_rec.out146_sorhsch_grad_date IS NOT NULL THEN
              l_count := l_count + 1;
              -- USF Mods HSHEKHAR 11/12/2002 Begin
              -- Modified the string to properly generate the SST segment. Added a blank before the D8 element.
              l_strbffr := 'SST||D8|' || to_char(out_146_rec.out146_sorhsch_grad_date,
                                                 'YYYYMMDD') || '^';
              -- USF End 11/12/2002
              utl_file.put_line(l_fileid, l_strbffr);
            END IF; -- out_146_rec.out146_sorhsch_grad_date IS NOT NULL
          
            --- N1 and N4 Segment for Sender
            l_stage := 'Creating N1 and N4 Segment for sender for outbound 146';
            l_count := l_count + 2;
            utl_file.put_line(l_fileid,
                              'N1|AS|' || l_host_inst_desc || '|73|' ||
                               l_host_inst_code || '^'); --Introduced variable instead of hardcoded institution description
          
            IF l_host_addr_line1 IS NOT NULL THEN
              utl_file.put_line(l_fileid,
                                'N3|' || l_host_addr_line1 || '|' ||
                                 l_host_addr_line2 || '^'); --Introduced variable instead of hardcoded institution description
              l_count := l_count + 1;
            END IF;
          
            utl_file.put_line(l_fileid,
                              'N4|' || l_host_city || '|' || l_host_state || '|' ||
                               l_host_zip || '|US^'); -- Introducesd variables instead of hard codings
            -- PER Segment
          
            l_stage := 'Creating PER Segment for outbound 146';
            l_count := l_count + 1;
            utl_file.put_line(l_fileid, 'PER|RG|STUDENT RECORDS^');
            --- N1 and N4 Segment for Reciever
          
            l_stage := 'Creating N1 and N4 Segment Reciever for outbound 146';
          
            IF out_xref_c%ISOPEN THEN
              CLOSE out_xref_c;
            END IF;
            -- ver M starts
            out_xref_rec := NULL;
            --ver M ends
            OPEN out_xref_c(l_v_trans_numb);
            FETCH out_xref_c
              INTO out_xref_rec;
            CLOSE out_xref_c;
            l_count   := l_count + 1;
            l_strbffr := 'N1|' || l_qlfr_code || '|' ||
                         out_xref_rec.sbgi_desc || '|' ||
                         out_xref_rec.sbgi_qlfr || '|' ||
                         out_xref_rec.recv_sgbi_code || '^';
            utl_file.put_line(l_fileid, l_strbffr);
            l_count   := l_count + 1;
            l_strbffr := 'N4|' || out_146_rec.out146_recv_city || '|' ||
                         out_146_rec.out146_recv_stat_code || '^';
            utl_file.put_line(l_fileid, l_strbffr);
            --- IN1 Segment
          
            l_stage := 'Creating IN1 Segment for outbound 146';
            l_count := l_count + 1;
            utl_file.put_line(l_fileid, 'IN1|1|04|S2^');
            -- IN2 Segment. Can be upto 5 individual segment as per the out view.
          
            l_stage := 'Creating IN2 Segment for outbound 146';
          
            IF out_146_rec.out146_name_prefix IS NOT NULL THEN
              l_count   := l_count + 1;
              l_strbffr := 'IN2|01|' || out_146_rec.out146_name_prefix || '^';
              utl_file.put_line(l_fileid, l_strbffr);
            END IF; --out_146_rec.out146_name_prefix IS NOT NULL
          
            IF out_146_rec.out146_first_name IS NOT NULL THEN
              l_count   := l_count + 1;
              l_strbffr := 'IN2|02|' || out_146_rec.out146_first_name || '^';
              utl_file.put_line(l_fileid, l_strbffr);
            END IF; -- out_146_rec.out146_first_name IS NOT NULL
          
            IF out_146_rec.out146_middle_initial IS NOT NULL THEN
              l_count   := l_count + 1;
              l_strbffr := 'IN2|07|' || out_146_rec.out146_middle_initial || '^';
              utl_file.put_line(l_fileid, l_strbffr);
            END IF; -- out_146_open_rec.out146_middle_initial IS NOT NULL
          
            IF out_146_rec.out146_last_name IS NOT NULL THEN
              l_count   := l_count + 1;
              l_strbffr := 'IN2|05|' || out_146_rec.out146_last_name || '^';
              utl_file.put_line(l_fileid, l_strbffr);
            END IF; -- out_146_rec.out146_last_name IS NOT NULL
          
            IF out_146_rec.out146_name_suffix IS NOT NULL THEN
              l_count   := l_count + 1;
              l_strbffr := 'IN2|09|' || out_146_rec.out146_name_suffix || '^';
              utl_file.put_line(l_fileid, l_strbffr);
            END IF; -- out_146_rec.out146_name_suffix IS NOT NULL
          
            -- SE Segment
          
            l_stage   := 'Creating SE Segment for outbound 146';
            l_count   := l_count + 1;
            l_strbffr := 'SE|' || to_char(l_count) || '|' ||
                         out_146_open_rec.ref_numb || '^';
            utl_file.put_line(l_fileid, l_strbffr);
          
            -- Updating  views....
            -- Mpella 12/13/2002 - added update of occurence_date, when
            --  sent_indicator is updated.
            UPDATE swvedi_146_open
               SET sent_indicator = 'Y'
                  ,occurence_date = SYSDATE
             WHERE trans_numb = out_146_open_rec.trans_numb;
          
            COMMIT;
            -- version M start
            p_success_out := TRUE;
          
          END IF; -- l_valied_no_transactions >=1
          /*
          END IF; --l_Mandatory_Check
          */
          -- version M end
        EXCEPTION
          WHEN le_mandatory_exception THEN
            wp_handle_error_db('EDI', 'wp_generate_outbound_146_db',
                               'BUSINESS',
                               'le_mandatory_exception encountered for trans numb' ||
                                to_char(out_146_open_rec.trans_numb) ||
                                'at state ' || l_stage, l_success, l_message);
            p_success_out := FALSE;
            p_message_out := l_stage;
            -- version Q start
          --utl_file.fclose(l_fileid);
          -- version Q END
          WHEN OTHERS THEN
            wp_handle_error_db('EDI', 'wp_generate_outbound_146', 'ORACLE',
                               'Encountered for trans numb ' ||
                                to_char(out_146_open_rec.trans_numb) ||
                                'Error ' || to_char(SQLCODE) || ' : ' ||
                                substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                               l_success, l_message);
            p_success_out := FALSE;
            p_message_out := l_stage;
            -- version Q start
          --utl_file.fclose(l_fileid);
          -- version Q END
        END;
      END LOOP; -- out_146_open_rec.
    
      IF l_group_count > 0 THEN
        l_strbffr := 'GE|' || l_group_count || '|' ||
                     lpad(l_groupsegment_seq, 9, '0');
        l_strbffr := rtrim(l_strbffr, '|') || '^';
        utl_file.put_line(l_fileid, l_strbffr);
        l_strbffr := 'IEA|1|' || lpad(l_isasegment_seq, 9, '0');
        l_strbffr := rtrim(l_strbffr, '|') || '^';
        utl_file.put_line(l_fileid, l_strbffr);
      END IF; -- l_group_count > 0
    END LOOP; -- END OF college_c
  
    utl_file.fclose(l_fileid);
    COMMIT;
    --> populate error table with missing date of birth
    /* FOR missing_date_of_birth_rec IN missing_date_of_birth_c LOOP
      INSERT INTO swrterr
        (swrterr_err_id,
         swrterr_err_code,
         swrterr_err_value,
         swrterr_user_process,
         swrterr_dcmt_seqno,
         swrterr_activity_date)
      VALUES
        (ws_swrterr_seq.NEXTVAL,
         'SENDTRQST',
         'For Id :' || missing_date_of_birth_rec.out146_ssn ||
         ' missing Birth date to process Transcript Request',
         'wsakedi.wp_generate_outbound_146',
         l_dcmt_seqno,
         SYSDATE);
    END LOOP; --missing_date_of_birth_c
    COMMIT;*/
  EXCEPTION
    WHEN le_mandatory_exception THEN
      wp_handle_error_db('EDI', 'wp_generate_outbound_146_db', 'BUSINESS',
                         'le_mandatory_exception encountered at state ' ||
                          l_stage, l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN utl_file.invalid_path THEN
      wp_handle_error_db('Invalid Path', 'wp_generate_outbound_146_db',
                         'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN utl_file.invalid_mode THEN
      wp_handle_error_db('Invalid File opening Mode',
                         'wp_generate_outbound_146_db', 'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN utl_file.invalid_filehandle THEN
      wp_handle_error_db('Invalid File Handle',
                         'wp_generate_outbound_146_db', 'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN utl_file.invalid_operation THEN
      wp_handle_error_db('Invalid Operation', 'wp_generate_outbound_146_db',
                         'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN utl_file.write_error THEN
      wp_handle_error_db('Write Error', 'wp_generate_outbound_146_db',
                         'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN utl_file.internal_error THEN
      wp_handle_error_db('Internal Error', 'wp_generate_outbound_146_db',
                         'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
    WHEN OTHERS THEN
      wp_handle_error_db('Error in generating outbound 146',
                         'wp_generate_outbound_146_db', 'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_stage,
                         l_success, l_message);
      p_success_out := FALSE;
      p_message_out := l_stage;
      utl_file.fclose(l_fileid);
  END; --  wp_generate_outbound_146.

  PROCEDURE wp_load_inbound_130
  (
    p_success_out OUT BOOLEAN
   ,p_message_out OUT VARCHAR2
  ) IS
  
    --*****************************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wp_load_inbound_130
    --  Process Associated : EDI
    --  Business Logic :
    --   This procedure loads all inbound transcripts(TS130) into banner
    --   work load area. Process gets all documents that belong to
    --   inbound transcripts from EDI work load area(swtwls, swtwle)
    --   tables and verifies whther they are valied ones against
    --   EDI acknowledgment load area table(swteaks, swteake).
    --   If the transcripts are valied, then only this process loads
    --   transcrips into banner load area.
    --  Documentation Links:
    --  G:\Documentation\Technical Specifications\EDI\
    --   Q202074 EDI Tool replacement\inbound130 mapping.doc
    --
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User    Reason For Change
    -- -----  ---  ---------  -----------  ------  -----------------------
    --  n/a   A   B5-002941  20-AUG-2002  VBANGALO   Initial Creation.
    --  n/a   B   B5-002941  08-NOV-2002  VBANGALO   Modified code to update
    --                                               course number and tilte
    --                                               only when they are null.
    --  n/a   D   B5-002968  15-NOV-2002  VBANGALO   Modified code to load
    --                                               only CLAST components
    --                                               into test score tables.
    --  n/a   J   B5-003259  22-JUL-2003  VBANGALO   Modified code to load
    --                                               PCL segment as per new
    --                                               changes in swrspcl table.
    --                                               Also, when inserting zip code
    --                                               it is truncated to first 5
    --                                               digits.
    --  n/a   L   B5-003304  05-SEP-2003  Arunion    Modified so we read N1 segment
    --                                               after CRS segment.
    --  n/a   M   B5-003482  04-DEC-2003  VBANGALO   Took out changes made by Arunion
    --                                               since that requiremnt is not required.
    --        R   O6-003797  09-JUL-2004  VBANGALO   Modified code to truncate override
    --                                               zip code to nine charecters.
    --        U   UNF-001019 25-JUL-2005  VBANGALO   shrcrsr_drop_date loading is commented out
    --                                               since it is not used in edi load process
    --                                               either in PS or HS.
    --        V   FAU-??     19-JAN-2006  VBANGALO   Modified code to include
    --                                               document(clob) in shbhead.
    --  1.01.01  08-000452   14-oct-2010  RVOGETI    Modified to load EDI Immunization data,
    --                                               per project 10-0018
    --
    -- Parameter Information:
    -- ------------
    --  p_success_out    out parameter  set to TRUE if process is success
    --                                  set to FALSE if process is failed.
    --  p_message_out    out parameter  message.
    --*****************************************************************************
    --
    le_exception1 EXCEPTION; --business exception raised when requirement1 is not met
    l_state               VARCHAR2(2000);
    l_message_out         VARCHAR2(500);
    l_success_out         BOOLEAN;
    l_id_doc_key          shbhead.shbhead_id_doc_key%TYPE;
    l_id_edi_key          shbhead.shbhead_id_edi_key%TYPE;
    l_xset_code           shbhead.shbhead_xset_code%TYPE;
    l_ackkey_t            shbhead.shbhead_ackkey_t%TYPE;
    l_send_date           shbhead.shbhead_send_date%TYPE;
    l_send_time           shbhead.shbhead_send_time%TYPE;
    l_stim_code           shbhead.shbhead_stim_code%TYPE;
    l_sid_ssnum           shbhead.shbhead_sid_ssnum%TYPE;
    l_sid_agency_num      shbhead.shbhead_sid_agency_num%TYPE;
    l_sid_agency_desc     shbhead.shbhead_sid_agency_desc%TYPE;
    l_head_count          NUMBER(4) := 0;
    l_ref_seg_rep         NUMBER(2) := 0;
    l_n1_loop_repat       NUMBER(2) := 0;
    l_in1_loop_repeat     NUMBER(2) := 0;
    l_head_nte_count      NUMBER(2) := 0;
    l_xprp_code           shbhead.shbhead_xprp_code%TYPE;
    l_xrsn_code           shbhead.shbhead_xrsn_code%TYPE;
    l_iden_nte_count      NUMBER(2) := 0;
    l_sst_loop_repeat     NUMBER(3) := 0;
    l_street_line1        shriden.shriden_street_line1%TYPE;
    l_street_line2        shriden.shriden_street_line2%TYPE;
    l_city                shriden.shriden_city%TYPE;
    l_stat_code           shriden.shriden_stat_code%TYPE;
    l_zip                 shriden.shriden_zip%TYPE;
    l_natn_code           shriden.shriden_natn_code%TYPE;
    l_mail_address_exists BOOLEAN;
    l_sum_loop_repeat     NUMBER(1) := 0;
    l_suma_nte_count      NUMBER(3) := 0;
    l_ses_loop_repeat     NUMBER(4) := 0;
    -- Two new variables for transient student transcripts
    l_note_type       VARCHAR2(4);
    l_comment         swrnote.swrnote_comment%TYPE;
    l_sums_loop_reat  NUMBER(1) := 0;
    l_ases_count      NUMBER(2) := 0;
    l_crs_loop_repeat NUMBER(2) := 0;
    l_deg_loop_repeat NUMBER(2) := 0;
    l_sums_nte_count  NUMBER(1) := 0;
    l_crsr_nte_count  NUMBER(2) := 0;
    l_fos_count       NUMBER(2) := 0;
    l_degr_nte_count  NUMBER(2) := 0;
    l_lx_count        NUMBER(2) := 0;
    l_no_elements     NUMBER(2) := 0;
    l_tst_sequence    NUMBER(4) := 0;
    l_sbt_sequence    NUMBER(4) := 0;
    l_tsts_nte_count  NUMBER(4) := 0;
    -- ver X start start
    l_deg_n1_count NUMBER(2) := 0;
    -- ver X start end
    l_temp_date             DATE := NULL;
    l_tst_administered_date DATE := NULL;
    l_tst_norm_date         DATE := NULL;
    l_doc_seq_no            NUMBER;
    --USF D BEGIN
    l_load_tst_seg BOOLEAN := TRUE;
    --USF D END
    c_interchange_cntrl_hdr_seg   CONSTANT CHAR(3) := 'ISA';
    c_interchange_cntrl_trl_seg   CONSTANT CHAR(3) := 'IEA';
    c_functional_gruop_hdr_seg    CONSTANT CHAR(2) := 'GS';
    c_functional_gruop_trl_seg    CONSTANT CHAR(2) := 'GE';
    c_interchange_trn_hdr_seg     CONSTANT CHAR(2) := 'ST';
    c_interchange_trn_trl_seg     CONSTANT CHAR(2) := 'SE';
    c_tr_set_response_trailer     CONSTANT CHAR(3) := 'AK5';
    c_educational_record_purpose  CONSTANT CHAR(3) := 'ERP';
    c_begining_segment            CONSTANT CHAR(3) := 'BGN';
    c_social_security_number_code CONSTANT CHAR(2) := 'SY';
    c_agency_student_number_code  CONSTANT CHAR(2) := '48';
    c_accepted_transaction        CONSTANT CHAR(1) := 'A';
    c_first_element               CONSTANT NUMBER(1) := 1;
    c_transacript                 CONSTANT CHAR(3) := '130';
    c_ref_segment                 CONSTANT CHAR(3) := 'REF';
    c_demographic_information     CONSTANT CHAR(3) := 'DMG';
    c_note_segment                CONSTANT CHAR(3) := 'NTE';
    c_name_code                   CONSTANT CHAR(2) := 'N1';
    c_additional_name_code        CONSTANT CHAR(2) := 'N2';
    c_address_information_code    CONSTANT CHAR(2) := 'N3';
    c_geographic_location_code    CONSTANT CHAR(2) := 'N4';
    c_admin_communication_contact CONSTANT CHAR(3) := 'PER';
    c_individual_id_code          CONSTANT CHAR(3) := 'IN1';
    c_individual_name_str_comp    CONSTANT CHAR(3) := 'IN2';
    c_ps_ender                    CONSTANT CHAR(2) := 'AS';
    c_ps_recipient                CONSTANT CHAR(2) := 'AT';
    c_hs_recipient                CONSTANT CHAR(2) := 'KR';
    c_hs_sender                   CONSTANT CHAR(2) := 'KS';
    c_acad_ses_header             CONSTANT CHAR(3) := 'SES';
    c_academic_summary            CONSTANT CHAR(3) := 'SUM';
    c_course_record               CONSTANT CHAR(3) := 'CRS';
    c_degree_record               CONSTANT CHAR(3) := 'DEG';
    c_field_of_study              CONSTANT CHAR(3) := 'FOS';
    c_assigned_number             CONSTANT CHAR(2) := 'LX';
    -- ver 1.01.01 start
    c_immunization_record CONSTANT CHAR(3) := 'IMM';
    -- ver 1.01.01 end
    c_req_att_prof_code     CONSTANT CHAR(3) := 'RAP';
    c_previous_college_code CONSTANT CHAR(3) := 'PCL';
    c_test_score_code       CONSTANT CHAR(3) := 'TST';
    c_subtest_code          CONSTANT CHAR(3) := 'SBT';
    lv_domestic_addr_ind VARCHAR2(1) := 'N';
    l_element_table      wsaklnutil.varchar2_tabtype;
    l_segment            VARCHAR2(4);
    l_sender_code        CHAR(2);
    c_max_elements_in_segment CONSTANT NUMBER(2) := 25;
    le_swrssre EXCEPTION;
    PRAGMA EXCEPTION_INIT(le_swrssre, -1);
    --> debug variables
    l_element1 VARCHAR2(200);
    l_element2 VARCHAR2(200);
    l_element3 VARCHAR2(200);
    l_element4 VARCHAR2(200);
    l_element5 VARCHAR2(200);
  
    --> This cursor gets all accepted inbound 130 transaction sets.
    --> checks ak501 element of ack load area that has element value 'A'
    CURSOR in_transcript_c IS
      SELECT DISTINCT c.swtewls_dcmt_seq dcmt
        FROM swtewls c
       WHERE c.swtewls_type = '130'
         AND EXISTS
       (SELECT 'x'
                FROM swteake a
               WHERE a.swteake_dcmt_seqno = c.swtewls_dcmt_seq
                 AND a.swteake_line_num IN
                     (SELECT b.swteaks_line_num
                        FROM swteaks b
                       WHERE b.swteaks_dcmt_seq = a.swteake_dcmt_seqno
                         AND b.swteaks_seg = c_tr_set_response_trailer --'AK5'
                      )
                 AND a.swteake_elm_value = c_accepted_transaction --'A'
                 AND a.swteake_elm_seq = c_first_element)
       ORDER BY dcmt; --1
  
    CURSOR transcript_segment_c(c_dcmt_in swtewls.swtewls_dcmt_seq%TYPE) IS
      SELECT a.swtewls_seg      transcript_segment
            ,a.swtewls_line_num line_number
        FROM swtewls a
       WHERE a.swtewls_dcmt_seq = c_dcmt_in
       ORDER BY line_number;
  
    CURSOR element_values_c
    (
      c_dcmt_in swtewls.swtewls_dcmt_seq%TYPE
     ,c_line_in swtewls.swtewls_line_num%TYPE
    ) IS
      SELECT b.swtewle_elm_seq   element_sequence
            ,b.swtewle_elm_value element_value
        FROM swtewle b
       WHERE b.swtewle_dcmt_seqno = c_dcmt_in
         AND b.swtewle_line_num = c_line_in
       ORDER BY b.swtewle_line_num
               ,b.swtewle_elm_seq;
  
    --> This cursor fetches details of segment ie.. elemet valus of a segment
    CURSOR transcript_details_c_2(c_dcmt_in swtewls.swtewls_dcmt_seq%TYPE) IS
      SELECT a.swtewls_seg       transcript_segment
            ,b.swtewle_elm_seq   element_sequence
            ,b.swtewle_elm_value element_value
        FROM swtewls a
            ,swtewle b
       WHERE a.swtewls_dcmt_seq = c_dcmt_in
         AND a.swtewls_dcmt_seq = b.swtewle_dcmt_seqno
         AND a.swtewls_line_num = b.swtewle_line_num
       ORDER BY b.swtewle_line_num
               ,b.swtewle_elm_seq;
  
    PROCEDURE wp_initialize_pltable IS
    
      /*
           This procedure initializes l_element_table elements.
      */
    BEGIN
      FOR idx IN 1 .. c_max_elements_in_segment
      LOOP
        l_element_table(idx) := NULL;
      END LOOP; --idx IN 1..c_max_elements_in_segment
    END wp_initialize_pltable;
  
    FUNCTION wf_get_date
    (
      p_date_qual_code_in VARCHAR2
     ,p_date_code_in      VARCHAR2
    ) RETURN DATE IS
      l_result DATE := NULL;
    BEGIN
      IF p_date_qual_code_in IS NOT NULL AND p_date_code_in IS NOT NULL THEN
        l_result := NULL;
      
        IF p_date_qual_code_in = 'CM' THEN
          l_result := to_date(p_date_code_in, 'YYYYMM');
        ELSIF p_date_qual_code_in = 'CY' THEN
          l_result := to_date(p_date_code_in, 'YYYY');
        ELSIF p_date_qual_code_in = 'D8' THEN
          l_result := to_date(p_date_code_in, 'YYYYMMDD');
        ELSIF p_date_qual_code_in = 'DB' THEN
          l_result := to_date(p_date_code_in, 'MMDDYYYY');
        END IF; /* p_date_qual_code_in = 'CM'  */
      END IF; /* p_date_qual_code_in IS NOT NULL AND
                                                                                                  p_date_code_in IS NOT NULL*/
    
      RETURN l_result;
    END wf_get_date;
    --> Main procedure for wp_load_inbound_130 starts here.
    --> NOTE: wshkedi.dcmt_seqno is package variable set by pre insert trigger
    --> of shbhead table.
  BEGIN
  
    --> for each valied transcript..
    l_state := 'Before opening in_transcript_c cursor';
  
    FOR in_transcript_rec IN in_transcript_c
    LOOP
      BEGIN
        l_doc_seq_no := NULL;
        l_doc_seq_no := in_transcript_rec.dcmt;
        --> for each segment of a transcript
        --dbms_output.put_line(to_char(in_transcript_rec.dcmt));
        FOR transcript_segment_rec IN transcript_segment_c(in_transcript_rec.dcmt)
        LOOP
          l_no_elements := 0;
          wp_initialize_pltable;
        
          --> get all element values.
          FOR element_values_rec IN element_values_c(in_transcript_rec.dcmt,
                                                     transcript_segment_rec.line_number)
          LOOP
            --> load element values into pltable.
            l_element_table(element_values_rec.element_sequence) := element_values_rec.element_value;
            /* DBMS_OUTPUT.put_line (
                  TO_CHAR (element_values_rec.element_sequence)
               || ' '
               || element_values_rec.element_value
            );*/
          END LOOP; --element_values_c
        
          l_no_elements := l_element_table.count;
          --> now that we have element value in pl sql table,
          --> load load area as per mapping document.
          l_state   := 'Before processing ST segment';
          l_segment := transcript_segment_rec.transcript_segment;
        
          --> If the segment belongs to header segment, initialize
          --> variables.
          IF transcript_segment_rec.transcript_segment =
             c_interchange_trn_hdr_seg --'ST'
           THEN
            l_head_count          := 1;
            l_id_doc_key          := l_element_table(1);
            l_id_edi_key          := l_element_table(2);
            l_sid_ssnum           := NULL;
            l_sid_agency_num      := NULL;
            l_sid_agency_desc     := NULL;
            l_ref_seg_rep         := 0;
            l_lx_count            := 0;
            l_n1_loop_repat       := 0;
            l_head_nte_count      := 0;
            l_in1_loop_repeat     := 0;
            l_xprp_code           := NULL;
            l_xrsn_code           := NULL;
            l_iden_nte_count      := 0;
            l_sst_loop_repeat     := 0;
            l_sum_loop_repeat     := 0;
            l_mail_address_exists := FALSE;
            l_tst_sequence        := 0;
            l_ses_loop_repeat     := 0;
            l_load_tst_seg        := TRUE;
          ELSIF transcript_segment_rec.transcript_segment =
                c_assigned_number --LX
           THEN
            l_lx_count := 1;
          END IF; -- transcript_segment_rec.transcript_segment = c_interchange_trn_hdr_seg
        
          --> if segments belongs to header block i.e before lx segment..
          IF l_lx_count = 0 THEN
            --> .. process BGN segment.
            IF transcript_segment_rec.transcript_segment =
               c_begining_segment --'BGN'
             THEN
              l_state     := 'Processing BGN segment';
              l_xset_code := l_element_table(1);
              l_ackkey_t  := l_element_table(2);
              l_send_date := l_element_table(3);
              l_send_time := l_element_table(4);
              l_stim_code := l_element_table(5);
              --> process ERP segment. Insert into shbhead.
            ELSIF transcript_segment_rec.transcript_segment =
                  c_educational_record_purpose --('ERP')
            /*l_seg = 'BGN'*/
             THEN
              l_state     := 'Processing ERP segment';
              l_xprp_code := l_element_table(1);
              l_xrsn_code := l_element_table(2);
              l_state     := ' Before inserting into shbhead table';
            
              -- ver V start. FAU mods brought to USF/UNF
              l_clob := NULL;
              l_clob := wf_build_edi_tran_clob(l_doc_seq_no);
              -- ver V end
            
              INSERT INTO shbhead
                (shbhead_id_doc_key
                ,shbhead_id_edi_key
                ,shbhead_xset_code
                ,shbhead_ackkey_t
                ,shbhead_send_date
                ,shbhead_send_time
                ,shbhead_stim_code
                ,shbhead_xprp_code
                ,shbhead_xrsn_code
                ,shbhead_id_tporg
                ,shbhead_id_date_key
                ,shbhead_activity_date)
              VALUES
                (l_id_doc_key
                ,l_id_edi_key
                ,l_xset_code
                ,l_ackkey_t
                ,l_send_date
                ,l_send_time
                ,l_stim_code
                ,l_xprp_code
                ,l_xrsn_code
                ,'11111'
                , --> dummy value. Later gets updated
                 to_char(SYSDATE, 'YYMMDD')
                ,SYSDATE);
            
              -- ver v start
              INSERT INTO saturn.swtdcmt
                (swtdcmt_dcmt_seqno
                ,swtdcmt_document)
              VALUES
                (wshkedi.dcmt_seqno
                ,l_clob);
              -- ver v end
            
              l_state := 'Before inserting into swbo131 table';
            
              INSERT INTO swbo131 (swbo131_sent_indicator) VALUES ('N');
              --> process REF segment.
            
            ELSIF transcript_segment_rec.transcript_segment = c_ref_segment --'REF' -->l_seg = 'BGN'
             THEN
              l_state := 'Processing REF segment';
              --> count ref segment repeats
              l_ref_seg_rep := l_ref_seg_rep + 1;
            
              --> update shbhead social security number if
              --> ref01 = 'SY'
              IF l_element_table(1) = c_social_security_number_code --'SY'
               THEN
                l_sid_ssnum := l_element_table(2);
                l_state     := 'Before updating shbhead whith ssn';
              
                UPDATE shbhead
                   SET shbhead_sid_ssnum = l_sid_ssnum
                 WHERE shbhead_dcmt_seqno = wshkedi.dcmt_seqno;
                --> update shbhead agency number code
                --> if ref01 = 48.
              ELSIF l_element_table(1) = c_agency_student_number_code --'48'
               THEN
                l_sid_agency_num  := l_element_table(2);
                l_sid_agency_desc := l_element_table(3);
                l_state           := 'Before updating shbhead whith agency num and desc';
              
                UPDATE shbhead
                   SET shbhead_sid_agency_num  = l_sid_agency_num
                      ,shbhead_sid_agency_desc = l_sid_agency_desc
                 WHERE shbhead_dcmt_seqno = wshkedi.dcmt_seqno;
              END IF;
            
              l_element1 := l_element_table(1);
              l_element2 := l_element_table(2);
              l_element3 := l_element_table(3);
              l_state    := 'Before inserting into swbo131_ref';
            
              INSERT INTO swbo131_ref
                (seqno
                ,ref01
                ,ref02
                ,ref03)
              VALUES
                (l_ref_seg_rep
                ,l_element_table(1)
                ,l_element_table(2)
                ,l_element_table(3));
              --> process DMG information
            ELSIF transcript_segment_rec.transcript_segment =
                  c_demographic_information --'DMG' -->l_seg = 'BGN'
             THEN
              l_state := 'Before updating shbhead with DMG segment values';
            
              UPDATE shbhead
                 SET shbhead_dob_qual      = l_element_table(1)
                    ,shbhead_dob_date_code = l_element_table(2)
                    ,shbhead_gender        = l_element_table(3)
                    ,shbhead_marital       = l_element_table(4)
                    ,shbhead_ethnic        = l_element_table(5)
                    ,shbhead_citizen       = l_element_table(6)
                    ,shbhead_home_cntry    = l_element_table(7)
               WHERE shbhead_dcmt_seqno = wshkedi.dcmt_seqno;
            ELSIF transcript_segment_rec.transcript_segment =
                  c_req_att_prof_code --RAP  -->l_seg = 'BGN'
             THEN
              l_state := 'Before inserting swrsrap with RAP segment values';
            
              IF l_element_table(6) IS NOT NULL AND
                 l_element_table(7) IS NOT NULL THEN
                l_temp_date := wf_get_date(l_element_table(6),
                                           l_element_table(7));
              END IF; /* l_element_table(6) IS NOT NULL AND
                                                                                                                                                                                                                                   l_element_table(7) IS NOT NULL*/
            
              l_state := 'before inserting swrsrap table with RAP segment';
            
              INSERT INTO swrsrap
                (swrsrap_test_reqt_code
                ,swrsrap_name_main_catg
                ,swrsrap_name_less_catg
                ,swrsrap_usage_ind
                ,swrsrap_cond_resp_code
                ,swrsrap_rap_date
                ,swrsrap_activity_date)
              VALUES
                (l_element_table(1)
                ,l_element_table(2)
                ,l_element_table(3)
                ,l_element_table(4)
                ,l_element_table(5)
                ,l_temp_date
                ,SYSDATE);
              --> process PCL segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_previous_college_code --PCL -->l_seg = 'BGN'
             THEN
              l_state := 'Before insrting into swrspcl table with PCL segment info';
            
              INSERT INTO swrspcl
                (swrspcl_id_qual_code
                ,swrspcl_inst_id_code
                ,swrspcl_date_qlfr_code
                ,swrspcl_dates_attended
                ,swrspcl_aced_deg_code
                ,swrspcl_deg_confered
                ,swrspcl_inst_desc
                ,swrspcl_activity_date)
              VALUES
                (l_element_table(1)
                ,l_element_table(2)
                ,l_element_table(3)
                ,l_element_table(4)
                ,l_element_table(5)
                ,l_element_table(6)
                ,l_element_table(7)
                ,SYSDATE);
              --> process HEAD NTE segment.
            ELSIF transcript_segment_rec.transcript_segment =
                  c_note_segment --'NTE' -->l_seg = 'BGN'
                  AND l_n1_loop_repat = 0 THEN
              l_head_nte_count := l_head_nte_count + 1;
              l_state          := 'before inserting HEAD note comments';
            
              INSERT INTO swrnote
                (swrnote_note_type
                ,swrnote_parent_loop
                ,swrnote_child_loop
                ,swrnote_seqno
                ,swrnote_comment)
              VALUES
                ('HEAD'
                ,1
                ,1
                ,l_head_nte_count
                ,l_element_table(2));
              --> process n1 segment.
            ELSIF transcript_segment_rec.transcript_segment = c_name_code --'N1' -->l_seg = 'BGN'
                  AND l_in1_loop_repeat = 0 THEN
              l_n1_loop_repat := l_n1_loop_repat + 1;
              l_state         := 'before inserting N1 segment values in shrhdr4 table';
            
              INSERT INTO shrhdr4
                (shrhdr4_activity_date
                ,shrhdr4_enty_code
                ,shrhdr4_enty_name_1
                ,shrhdr4_inql_code
                ,shrhdr4_inst_code
                ,shrhdr4_domestic_addr_ind)
              VALUES
                (SYSDATE
                ,l_element_table(1)
                ,substr(l_element_table(2), 1, 35)
                ,l_element_table(3)
                ,l_element_table(4)
                ,'N');
            
              --> update shbhead table with sender information.
              IF l_element_table(1) IN (c_ps_ender, c_hs_sender)
              -- ('AS', 'KS')
               THEN
                l_state       := 'Updating shbhead table id tporg col. with sender info';
                l_sender_code := l_element_table(1);
              
                UPDATE shbhead
                   SET shbhead_id_tporg = l_element_table(4)
                 WHERE shbhead_dcmt_seqno = wshkedi.dcmt_seqno;
              END IF; -->elm (1) IN ('AS', 'KS')
              --> process N2 segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_additional_name_code --'N2' --(N1) -->l_seg = 'BGN'
                  AND l_in1_loop_repeat = 0 THEN
              l_state := 'Updating header4 with N2 segment';
            
              UPDATE shrhdr4
                 SET shrhdr4_enty_name_2 = substr(l_element_table(1),1,35)
                    ,shrhdr4_enty_name_3 = substr(l_element_table(2),1,35)
               WHERE shrhdr4_dcmt_seqno = wshkedi.dcmt_seqno;
              --> process N3 segment.
            ELSIF transcript_segment_rec.transcript_segment =
                  c_address_information_code --'N3' -->l_seg = 'BGN'
                  AND l_in1_loop_repeat = 0 AND
                  l_sender_code IN (c_ps_ender, c_hs_sender) THEN
              l_state := 'Updating header4 with N3 segment.';
            
              UPDATE shrhdr4
                 SET shrhdr4_street_line1 = l_element_table(1)
                    ,shrhdr4_street_line2 = l_element_table(2)
               WHERE shrhdr4_dcmt_seqno = wshkedi.dcmt_seqno
                 AND shrhdr4.shrhdr4_enty_code = l_sender_code;
              --> process N4 segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_geographic_location_code --'N4' -->l_seg = 'BGN'
                  AND l_in1_loop_repeat = 0 AND
                  l_sender_code IN (c_ps_ender, c_hs_sender) THEN
              l_state := 'Updating header4 with N4 segment';
            
              UPDATE shrhdr4 a
                 SET a.shrhdr4_city      = l_element_table(1)
                    ,a.shrhdr4_stat_code = l_element_table(2)
                    ,a.shrhdr4_zip       = substr(l_element_table(3), 1, 5)
                    ,a.shrhdr4_natn_code = l_element_table(4)
               WHERE a.shrhdr4_dcmt_seqno = wshkedi.dcmt_seqno
                 AND a.shrhdr4_enty_code = l_sender_code;
              --> process PER segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_admin_communication_contact --'PER' -->l_seg = 'BGN'
                  AND l_in1_loop_repeat = 0 AND
                  l_sender_code IN (c_ps_ender, c_hs_sender) THEN
              l_state := 'Updating header4 with PER segment.';
            
              UPDATE shrhdr4 a
                 SET a.shrhdr4_ctfn_code    = l_element_table(1)
                    ,a.shrhdr4_contact_name = substr(l_element_table(2),1,35)
                    ,a.shrhdr4_coql_code    = l_element_table(3)
                    ,a.shrhdr4_comm_no      = l_element_table(4)
               WHERE a.shrhdr4_dcmt_seqno = wshkedi.dcmt_seqno
                 AND a.shrhdr4_enty_code = l_sender_code;
              --> process IN1 segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_individual_id_code --IN1-->transcript_segment_rec.transcript_segment = 'BGN'
             THEN
              l_state := 'Updating shriden with IN1 segment';
            
              IF l_element_table(2) = '04' --this makes IN1 seg as non loop segment
               THEN
                l_in1_loop_repeat := l_in1_loop_repeat + 1;
                l_street_line1    := NULL;
                l_street_line2    := NULL;
                l_city            := NULL;
                l_stat_code       := NULL;
                l_zip             := NULL;
                l_natn_code       := NULL;
              
                INSERT INTO shriden
                  (shriden_idql_code
                  ,shriden_idnm_code
                  ,shriden_enid_code
                  ,shriden_rnql_code
                  ,shriden_ref_numb
                  ,shriden_rltn_code
                  ,shriden_domestic_addr_ind
                  ,shriden_activity_date)
                VALUES
                  (l_element_table(1)
                  ,l_element_table(2)
                  ,l_element_table(3)
                  ,l_element_table(4)
                  ,l_element_table(5)
                  ,l_element_table(6)
                  ,'N'
                  ,SYSDATE);
              END IF; -->end of if l_element_table(2) = '04'
              --> prcoess IN2 Segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_individual_name_str_comp --IN2
                  AND l_in1_loop_repeat > 0 AND l_sst_loop_repeat = 0 -->transcript_segment_rec.transcript_segment = 'BGN'
             THEN
              l_state := 'Updating shriden with IN2 segment';
            
              IF l_element_table(1) = '14' THEN
                UPDATE shriden
                   SET shriden_agency_name = substr(l_element_table(2),1,35)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              ELSIF l_element_table(1) = '16' THEN
                -->l_element_table(1) = '14'
                UPDATE shriden
                   SET shriden_composite_name = substr(l_element_table(2),1,35)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              ELSIF l_element_table(1) = '12' THEN
                -->l_element_table(1) = '14'
                UPDATE shriden
                   SET shriden_combined_name = substr(l_element_table(2),1,35)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              ELSIF l_element_table(1) = '15' THEN
                -->l_element_table(1) = '14'
                UPDATE shriden
                   SET shriden_former_name = substr(l_element_table(2),1,35)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              ELSIF l_element_table(1) = '09' THEN
                -->l_element_table(1) = '14'
                UPDATE shriden
                   SET shriden_name_suffix = substr(l_element_table(2),1,35)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              ELSIF l_element_table(1) = '08' THEN
                -->l_element_table(1) = '14'
                UPDATE shriden
                   SET shriden_middle_initial_2 = substr(l_element_table(2),1,35)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              ELSIF l_element_table(1) = '07' THEN
                -->l_element_table(1) = '14'
                UPDATE shriden
                   SET shriden_middle_initial_1 = substr(l_element_table(2),1,35)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              ELSIF l_element_table(1) = '04' THEN
                -->l_element_table(1) = '14'
                UPDATE shriden
                   SET shriden_middle_name_2 = substr(l_element_table(2),1,35)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              ELSIF l_element_table(1) = '03' THEN
                -->l_element_table(1) = '14'
                UPDATE shriden
                   SET shriden_middle_name_1 = substr(l_element_table(2),1,35)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              ELSIF l_element_table(1) = '06' THEN
                -->l_element_table(1) = '14'
                UPDATE shriden
                   SET shriden_first_initial = substr(l_element_table(2),1,35)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              ELSIF l_element_table(1) = '02' THEN
                -->l_element_table(1) = '14'
                UPDATE shriden
                   SET shriden_first_name = l_element_table(2)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              ELSIF l_element_table(1) = '01' THEN
                -->l_element_table(1) = '14'
                UPDATE shriden
                   SET shriden_name_prefix = substr(l_element_table(2),1,35)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              ELSIF l_element_table(1) = '05' THEN
                -->l_element_table(1) = '14'
                UPDATE shriden
                   SET shriden_last_name = substr(l_element_table(2),1,35)
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              END IF; -->l_element_table(1) = '14'
              --> process N3(IN1) segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_address_information_code --N3
                  AND l_in1_loop_repeat > 0 AND l_sst_loop_repeat = 0 -->transcript_segment_rec.transcript_segment = 'BGN'
             THEN
              l_street_line1 := l_element_table(1);
              l_street_line2 := l_element_table(2);
              --> process N4(N3) segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_geographic_location_code --N4
                  AND l_in1_loop_repeat > 0 AND l_sst_loop_repeat = 0 -->transcript_segment_rec.transcript_segment = 'BGN'
             THEN
              l_state     := 'Before updating shriden with N3(IN1) and N4(N3) segments';
              l_city      := l_element_table(1);
              l_stat_code := l_element_table(2);
              l_zip       := substr(l_element_table(3), 1, 5);
              l_natn_code := l_element_table(4);
            
              IF NOT l_mail_address_exists THEN
                UPDATE shriden
                   SET shriden.shriden_street_line1 = l_street_line1
                      ,shriden.shriden_street_line2 = l_street_line2
                      ,shriden.shriden_city         = l_city
                      ,shriden.shriden_stat_code    = l_stat_code
                      ,shriden.shriden_zip          = substr(l_zip, 1, 5)
                      ,shriden.shriden_natn_code    = l_natn_code
                 WHERE shriden_dcmt_seqno = wshkedi.dcmt_seqno;
              END IF; --> NOT  mail_address_exists
            
              IF l_element_table(5) = 'M' THEN
                l_mail_address_exists := TRUE;
              END IF; -->l_element_table(4) = 'M'
              ---
              --> process NTE(IN1) segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_note_segment --NTE
                  AND l_in1_loop_repeat > 0 AND l_sst_loop_repeat = 0 AND
                  l_xrsn_code != 'S20' --> transcript_segment_rec.transcript_segment = 'BGN'
             THEN
              l_state          := ' inserting comment table with IDEN information.. NTE(N1)';
              l_iden_nte_count := l_iden_nte_count + 1;
            
              INSERT INTO swrnote
                (swrnote_note_type
                ,swrnote_parent_loop
                ,swrnote_child_loop
                ,swrnote_seqno
                ,swrnote_comment)
              VALUES
                ('IDEN'
                ,1
                ,l_in1_loop_repeat
                ,l_iden_nte_count
                ,l_element_table(2));
              --> Process SST segment
            ELSIF transcript_segment_rec.transcript_segment = 'SST' --> transcript_segment_rec.transcript_segment = 'BGN'
             THEN
              l_state           := 'before inserting swracad table with SST table.';
              l_sst_loop_repeat := l_sst_loop_repeat + 1;
            
              INSERT INTO swracad
                (swracad_sst_seqno
                ,swracad_grad_type
                ,swracad_grad_date_qual
                ,swracad_grad_date
                ,swracad_elig_rtrn
                ,swracad_elig_date_qual
                ,swracad_elig_date
                ,swracad_enrl_stat
                ,swracad_levl_code
                ,swracad_resd_code)
              VALUES
                (l_sst_loop_repeat
                ,l_element_table(1)
                ,l_element_table(2)
                ,l_element_table(3)
                ,l_element_table(4)
                ,l_element_table(5)
                ,l_element_table(6)
                ,l_element_table(7)
                ,l_element_table(8)
                ,l_element_table(9));
              --> process TST segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_test_score_code --TST
             THEN
              --USF D BEGIN
              IF TRIM(l_element_table(1)) = '9FL' AND
                 upper(TRIM(l_element_table(2))) LIKE '%CLAST%' THEN
                l_load_tst_seg := TRUE;
              ELSE
                l_load_tst_seg := FALSE;
              END IF; /*
                                                                                                                                                                                                                           trim(l_element_table(1)) = '9FL'
                                                                                                                                                                                                                           AND upper(l_element_table(2)) LIKE 'CLSAT%'
                                                                                                                                                                                                                           */
              IF l_load_tst_seg THEN
                --USF D END
                l_tst_sequence := l_tst_sequence + 1;
                l_sbt_sequence := 0;
              
                IF l_element_table(3) IS NOT NULL AND
                   l_element_table(4) IS NOT NULL THEN
                  l_temp_date := NULL;
                  l_temp_date := wf_get_date(l_element_table(3),
                                             l_element_table(4));
                END IF; /* l_element_table(3) IS NOT NULL AND
                                                                                                                                                                                                                                                                   l_element_table(4) IS NOT NULL*/
              
                l_state := ' Before inserting swrstst table with TST segment.';
              
                INSERT INTO swrstst
                  (swrstst_seqno
                  ,swrstst_test_reqt_code
                  ,swrstst_name
                  ,swrstst_administered_date
                  ,swrstst_ref_id_form
                  ,swrstst_ref_id_test
                  ,swrstst_grad_level_code
                  ,swrstst_test_grad_level_code
                  ,swrstst_norm_date_range
                  ,swrstst_norm_type
                  ,swrstst_norm_period
                  ,swrstst_language_code
                  ,swrstst_tst_date_range
                  ,swrstst_cond_resp_inf_code
                  ,swrstst_cond_resp_admin_code
                  ,swrstst_activity_date)
                VALUES
                  (l_tst_sequence
                  ,l_element_table(1)
                  ,l_element_table(2)
                  ,l_temp_date
                  ,l_element_table(5)
                  ,l_element_table(6)
                  ,l_element_table(7)
                  ,l_element_table(8)
                  ,l_element_table(9)
                  ,l_element_table(10)
                  ,l_element_table(11)
                  ,l_element_table(12)
                  ,l_element_table(13)
                  ,l_element_table(14)
                  ,l_element_table(15)
                  ,SYSDATE);
                --USF D BEGIN
              END IF; --l_load_tst_seg
              --USF D END
              --> Process SBT segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_subtest_code --SBT
                 --USF D BEGIN
                  AND l_load_tst_seg
            --USF D END
             THEN
              l_state        := 'Before inserting swrssbt table with SBT segment info.';
              l_sbt_sequence := l_sbt_sequence + 1;
            
              INSERT INTO swrssbt
                (swrssbt_stst_seqno
                ,swrssbt_seqno
                ,swrssbt_subset_code
                ,swrssbt_name
                ,swrssbt_activity_date)
              VALUES
                (l_tst_sequence
                ,l_sbt_sequence
                ,l_element_table(1)
                ,l_element_table(2)
                ,SYSDATE);
              --> process SRE segment
            ELSIF transcript_segment_rec.transcript_segment = 'SRE'
                 --USF D BEGIN
                  AND l_load_tst_seg
            -- USF D END
             THEN
              l_tsts_nte_count := 0;
            
              BEGIN
                INSERT INTO swrssre
                  (swrssre_stst_seqno
                  ,swrssre_ssbt_seqno
                  ,swrssre_test_qual_code
                  ,swrssre_test_desc
                  ,swrssre_activity_date)
                VALUES
                  (l_tst_sequence
                  ,l_sbt_sequence
                  ,l_element_table(1)
                  ,l_element_table(2)
                  ,SYSDATE);
              EXCEPTION
                WHEN le_swrssre THEN
                  NULL;
              END;
            ELSIF transcript_segment_rec.transcript_segment = 'NTE' AND
                  l_sbt_sequence > 0 AND l_xrsn_code != 'S20' THEN
              l_tsts_nte_count := l_tsts_nte_count + 1;
            
              INSERT INTO swrnote
                (swrnote_note_type
                ,swrnote_parent_loop
                ,swrnote_child_loop
                ,swrnote_seqno
                ,swrnote_comment)
              VALUES
                ('TSTS'
                ,l_tst_sequence
                ,l_sbt_sequence
                ,l_tsts_nte_count
                ,l_element_table(2));
              --> process SUM segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_academic_summary --SUM  --> transcript_segment_rec.transcript_segment = 'BGN'
             THEN
              l_state           := 'Before inserting shrsuma with SUM segment';
              l_sum_loop_repeat := l_sum_loop_repeat + 1;
              l_suma_nte_count  := 0;
              l_sbt_sequence    := 0;
            
              INSERT INTO shrsuma
                (shrsuma_gpa_seqno
                ,shrsuma_activity_date
                ,shrsuma_ctyp_code
                ,shrsuma_slvl_code
                ,shrsuma_gpa_hours
                ,shrsuma_hours_attempted
                ,shrsuma_hours_earned
                ,shrsuma_gpa_low
                ,shrsuma_gpa_high
                ,shrsuma_gpa
                ,shrsuma_gpa_excess_ind
                ,shrsuma_class_rank
                ,shrsuma_class_size
                ,shrsuma_rdql_code
                ,shrsuma_rank_date) --, --shrsuma_seqno,
              --shrsuma_cum_sum)--, shrsuma_dyas_attended)
              --,shrsuma_days_absent)--, shrsuma_gpa_quality_pts)
              VALUES
                (l_sum_loop_repeat
                ,SYSDATE
                ,l_element_table(1)
                ,l_element_table(2)
                ,l_element_table(4)
                ,l_element_table(5)
                ,l_element_table(6)
                ,l_element_table(7)
                ,l_element_table(8)
                ,l_element_table(9)
                ,l_element_table(10)
                ,l_element_table(11)
                ,l_element_table(12)
                ,l_element_table(13)
                ,l_element_table(14)); --,
              -- SJM Commented out since GPA_SEQNO valuies is same as SEQ_NO value l_sum_loop_repeat,
              -- l_element_table (3));--SJM, l_element_table (15));
              -- SJM Commented out since GPA is recalulated l_element_table (16), l_element_table (17));
              --> process NTE(SUM) segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_note_segment --NTE
                  AND l_sum_loop_repeat > 0 --> transcript_segment_rec.transcript_segment = 'BGN'
             THEN
              l_state          := 'Before inserting comment table swrnote with NTE(SUM) info.';
              l_suma_nte_count := l_suma_nte_count + 1;
            
              INSERT INTO swrnote
                (swrnote_note_type
                ,swrnote_parent_loop
                ,swrnote_child_loop
                ,swrnote_seqno
                ,swrnote_comment)
              VALUES
                ('SUMA'
                ,1
                ,l_sum_loop_repeat
                ,l_suma_nte_count
                ,l_element_table(2));
              ---
              /* transcript_segment_rec.transcript_segment = C_begining_segment--'BGN'*/
            
            END IF;
          END IF; --lx_count = 0
        
          --> processing of detail segments starts here.
          IF l_lx_count > 0 THEN
            -- ver 1.01.01 start
            --> process IMM segment
            IF transcript_segment_rec.transcript_segment =
               c_immunization_record --IMM
             THEN
              BEGIN
                --> convert the immunization date based on the format
                --> given, if the date and the format are not empty
                l_temp_date := NULL;
                IF l_element_table(2) IS NOT NULL AND
                   l_element_table(3) IS NOT NULL THEN
                  l_temp_date := wf_get_date(l_element_table(2),
                                             l_element_table(3));
                END IF;
              
                l_state := 'Before inserting ' || TRIM(l_element_table(1)) || '-' ||
                           TRIM(l_element_table(4)) ||
                           ' shrmedi with IMM segment values';
              
                INSERT INTO shrmedi
                  (shrmedi_medi_code
                  ,shrmedi_medi_code_date
                  ,shrmedi_comment
                  ,shrmedi_activity_date
                  ,shrmedi_user_id
                  ,shrmedi_data_origin)
                VALUES
                  (TRIM(l_element_table(1)) || '-' ||
                   TRIM(l_element_table(4))
                  ,l_temp_date
                  ,NULL
                  ,SYSDATE
                  ,'EDI'
                  ,'EDI');
              EXCEPTION
                WHEN OTHERS THEN
                
                  wp_handle_error_db('EDI', 'wp_load_inbound_130', 'ORACLE',
                                     'Encountered ' || to_char(SQLCODE) ||
                                      ' : ' || substr(SQLERRM, 1, 250) ||
                                      ' At ' || l_state, l_success_out,
                                     l_message_out);
              END;
            END IF; -- transcript_segment_rec.transcript_segment (IMM)
            -- ver 1.01.01 end
          
            --> process SES segment.
            IF transcript_segment_rec.transcript_segment =
               c_acad_ses_header --SES
             THEN
            
              l_state           := 'Before inserting SES info in shrases';
              l_ses_loop_repeat := l_ses_loop_repeat + 1;
              l_sums_loop_reat  := 0;
              l_crs_loop_repeat := 0;
              l_deg_loop_repeat := 0;
              l_ases_count      := 0;
            
              INSERT INTO shrases
                (shrases_seqno
                ,shrases_activity_date
                ,shrases_start_date
                ,shrases_sess_no
                ,shrases_school_year
                ,shrases_sntp_code
                ,shrases_sess_name
                ,shrases_sbql_code
                ,shrases_begin_date
                ,shrases_seql_code
                ,shrases_end_date
                ,shrases_slvl_code
                ,shrases_crql_code
                ,shrases_curr_code
                ,shrases_curr_name
                ,shrases_honr_code
                ,shrases_domestic_addr_ind)
              VALUES
                (l_ses_loop_repeat
                ,SYSDATE
                ,l_element_table(1)
                ,l_element_table(2)
                ,l_element_table(3)
                ,l_element_table(4)
                ,l_element_table(5)
                ,l_element_table(6)
                ,l_element_table(7)
                ,l_element_table(8)
                ,l_element_table(9)
                ,l_element_table(10)
                ,l_element_table(11)
                ,l_element_table(12)
                ,l_element_table(13)
                ,l_element_table(14)
                ,'N');
              --> process NTE(SES) segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_note_segment --NTE
                 
                  AND l_ses_loop_repeat > 0 AND l_sums_loop_reat = 0 AND
                  l_crs_loop_repeat = 0 AND l_deg_loop_repeat = 0 THEN
            
              -- IF the type of 130 transcript being processed is an S20, Cost of Attendance, then
              -- set up the note types to be used that will separate them from other note types for
              -- inserts in wp_get_comments_db into swrcmnt.
            
              IF l_xrsn_code != 'S20' THEN
                l_note_type := 'ASES';
                l_comment   := l_element_table(2);
                l_state     := 'Before inserting ASES comments in swrnote table.';
              ELSE
              
                IF l_element_table(1) = 'CTF' THEN
                  l_comment   := 'Tuition & Fees' || l_element_table(2);
                  l_note_type := l_element_table(1);
                
                ELSIF l_element_table(1) = 'CRB' THEN
                  l_comment   := 'Room & Board.' || l_element_table(2);
                  l_note_type := l_element_table(1);
                
                ELSIF l_element_table(1) = 'CBS' THEN
                  l_comment   := 'Books & Supplies.' || l_element_table(2);
                  l_note_type := l_element_table(1);
                
                ELSIF l_element_table(1) = 'CTR' THEN
                  l_comment   := 'Transportation.' || l_element_table(2);
                  l_note_type := l_element_table(1);
                
                ELSIF l_element_table(1) = 'CPE' THEN
                  l_comment   := 'Personal Expenses.' || l_element_table(2);
                  l_note_type := l_element_table(1);
                END IF;
              
                l_state := 'Before inserting COA comments in swrnote table';
              
              END IF;
            
              l_ases_count := l_ases_count + 1;
            
              INSERT INTO swrnote
                (swrnote_note_type
                ,swrnote_parent_loop
                ,swrnote_child_loop
                ,swrnote_seqno
                ,swrnote_comment)
              VALUES
                (l_note_type
                ,l_ses_loop_repeat
                ,1
                ,l_ases_count
                ,l_comment);
            
              --> processing N1(SES) segment  --name
            ELSIF transcript_segment_rec.transcript_segment = c_name_code --N1
                  AND l_ses_loop_repeat > 0 AND l_sums_loop_reat = 0 AND
                  l_crs_loop_repeat = 0 AND l_deg_loop_repeat = 0 THEN
              l_state := ' Before updating shrases table with N1(SES) segment';
            
              UPDATE shrases a
                 SET a.shrases_ovrd_code = l_element_table(1)
                    ,
                     -- ver Y start
                     a.shrases_inst_name_ovrd = substr(l_element_table(2), 1,
                                                       35)
                    ,
                     -- ver Y end
                     a.shrases_inql_code_ovrd = l_element_table(3)
                    ,a.shrases_inst_code_ovrd = l_element_table(4)
               WHERE a.shrases_dcmt_seqno = wshkedi.dcmt_seqno
                 AND a.shrases_seqno = l_ses_loop_repeat;
              --> process N3(SES) information .. address inf
            ELSIF transcript_segment_rec.transcript_segment =
                  c_address_information_code --N3
                  AND l_ses_loop_repeat > 0 AND l_sums_loop_reat = 0 AND
                  l_crs_loop_repeat = 0 AND l_deg_loop_repeat = 0 THEN
              l_state := ' before updating shrases with N3(SES) info';
            
              UPDATE shrases
                 SET shrases_street_line1_ovrd = l_element_table(1)
                    ,shrases_street_line2_ovrd = l_element_table(2)
               WHERE shrases_dcmt_seqno = wshkedi.dcmt_seqno
                 AND shrases_seqno = l_ses_loop_repeat;
              --> process N4(SES) segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_geographic_location_code --N4
                  AND l_ses_loop_repeat > 0 AND l_sums_loop_reat = 0 AND
                  l_crs_loop_repeat = 0 AND l_deg_loop_repeat = 0 THEN
              l_state := 'before updating shrases with N4(SES) segment';
            
              UPDATE shrases
                 SET shrases_city_ovrd      = l_element_table(1)
                    ,shrases_stat_code_ovrd = l_element_table(2)
                    ,
                     -- VER R START
                     --shrases_zip_ovrd = l_element_table (3),
                     shrases_zip_ovrd = substr(REPLACE(l_element_table(3),
                                                       '-', ''), 1, 9)
                    ,
                     -- VER R END
                     shrases_natn_code_ovrd = l_element_table(4)
               WHERE shrases_dcmt_seqno = wshkedi.dcmt_seqno
                 AND shrases_seqno = l_ses_loop_repeat;
              --> process SUM(SES) segment .. sessino summary
            ELSIF transcript_segment_rec.transcript_segment =
                  c_academic_summary --SUM
                  AND l_ses_loop_repeat > 0 AND l_crs_loop_repeat = 0 AND
                  l_deg_loop_repeat = 0 THEN
              l_sums_nte_count := 0;
              l_sums_loop_reat := l_sums_loop_reat + 1;
              l_state          := ' before inserting shrsums table with SUM(SES) segment info.';
              --> Insert only if the sum segment belongs to Sending Institution only.
              IF TRIM(l_element_table(2)) = 'F' THEN
              
                INSERT INTO shrsums
                  (shrsums_ases_seqno
                  , --shrsums_seqno,
                   shrsums_gpa_seqno
                  ,shrsums_ctyp_code
                  ,shrsums_slvl_code
                  ,shrsums_cum_sum
                  ,shrsums_gpa_hours
                  ,shrsums_hours_attempted
                  ,shrsums_hours_earned
                  ,shrsums_gpa_low
                  ,shrsums_gpa_high
                  ,shrsums_gpa
                  ,shrsums_gpa_excess_ind
                  ,shrsums_class_rank
                  ,shrsums_class_size
                  ,shrsums_rdql_code
                  ,shrsums_rank_date
                  ,shrsums_activity_date)
                VALUES
                  (l_ses_loop_repeat
                  , --l_sums_loop_reat,
                   l_sums_loop_reat --SJM 1
                  ,l_element_table(1)
                  ,l_element_table(2)
                  ,l_element_table(3)
                  ,l_element_table(4)
                  ,l_element_table(5)
                  ,l_element_table(6)
                  ,l_element_table(7)
                  ,l_element_table(8)
                  ,l_element_table(9)
                  ,l_element_table(10)
                  ,l_element_table(11)
                  ,l_element_table(12)
                  ,l_element_table(13)
                  ,l_element_table(14)
                  ,SYSDATE);
              END IF; /* trunc(l_element_table (2)) = 'F' */
              --> process NTE(SUM) segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_note_segment --NTE
                  AND l_ses_loop_repeat > 0 AND l_crs_loop_repeat = 0 AND
                  l_sums_loop_reat > 0 AND l_deg_loop_repeat = 0 THEN
              l_state          := 'before inserting comment table with NTE(SUM) segment info.';
              l_sums_nte_count := l_sums_nte_count + 1;
            
              INSERT INTO swrnote
                (swrnote_note_type
                ,swrnote_parent_loop
                ,swrnote_child_loop
                ,swrnote_seqno
                ,swrnote_comment)
              VALUES
                ('SUMS'
                ,l_ses_loop_repeat
                ,l_sums_loop_reat
                ,l_sums_nte_count
                ,l_element_table(2));
              --> process CRS(SES) segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_course_record --CRS
                  AND l_ses_loop_repeat > 0 AND l_deg_loop_repeat = 0 AND
                  l_xrsn_code != 'S20' THEN
              l_state           := ' before inserting shrcrsr table with CRS(SES) segment.';
              l_crs_loop_repeat := l_crs_loop_repeat + 1;
              l_crsr_nte_count  := 0;
            
              INSERT INTO shrcrsr
                (shrcrsr_ases_seqno
                ,shrcrsr_seqno
                ,shrcrsr_activity_date
                ,shrcrsr_basi_code
                ,shrcrsr_cred_code
                ,shrcrsr_hours_attempted
                ,shrcrsr_hours_earned
                ,shrcrsr_amcas_grade_qual
                ,shrcrsr_grade
                ,shrcrsr_honors_ind
                ,shrcrsr_course_level
                ,shrcrsr_repeat_ind
                ,shrcrsr_xcurr_code_qual
                ,shrcrsr_xcurr_code
                ,shrcrsr_quality_points
                ,shrcrsr_k12_grade_level
                ,shrcrsr_subj_code
                ,shrcrsr_crse_numb
                ,shrcrsr_crse_title
                ,shrcrsr_k12_days_attend
                ,shrcrsr_k12_days_absent
                ,
                 --shrcrsr_drop_date,   /* -- Version USF U */
                 shrcrsr_override_code)
              VALUES
                (l_ses_loop_repeat
                ,l_crs_loop_repeat
                ,SYSDATE
                ,l_element_table(1)
                ,l_element_table(2)
                ,l_element_table(3)
                ,l_element_table(4)
                ,l_element_table(5)
                ,l_element_table(6)
                ,l_element_table(7)
                ,l_element_table(8)
                ,l_element_table(9)
                ,l_element_table(10)
                ,substr(l_element_table(11), 1, 20)
                ,l_element_table(12)
                ,l_element_table(13)
                ,l_element_table(14)
                ,l_element_table(15)
                ,substr(l_element_table(16),1,35)
                ,l_element_table(17)
                ,l_element_table(18)
                ,
                 --l_element_table(19),/* -- Version USF U */
                 l_element_table(20));
              --> process REF(CRS) segment
            ELSIF transcript_segment_rec.transcript_segment = c_ref_segment --REF
                  AND l_ses_loop_repeat > 0 AND l_crs_loop_repeat > 0 AND
                  l_deg_loop_repeat = 0 THEN
              l_state := ' before updating shrcrsr table with REF(CRS) table.';
            
              UPDATE shrcrsr a
                 SET a.shrcrsr_crse_numb = l_element_table(2)
               WHERE a.shrcrsr_dcmt_seqno = wshkedi.dcmt_seqno
                 AND a.shrcrsr_ases_seqno = l_ses_loop_repeat
                 AND a.shrcrsr_seqno = l_crs_loop_repeat
                 AND shrcrsr_crse_numb IS NULL;
            
              UPDATE shrcrsr a
                 SET a.shrcrsr_crse_title = l_element_table(3)
               WHERE a.shrcrsr_dcmt_seqno = wshkedi.dcmt_seqno
                 AND a.shrcrsr_ases_seqno = l_ses_loop_repeat
                 AND a.shrcrsr_seqno = l_crs_loop_repeat
                 AND shrcrsr_crse_title IS NULL;
              --> process NTE(CRS) segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_note_segment --NTE
                  AND l_ses_loop_repeat > 0 AND l_crs_loop_repeat > 0 AND
                  l_deg_loop_repeat = 0 THEN
              l_crsr_nte_count := l_crsr_nte_count + 1;
              l_state          := ' before inserting comment table with NTE(CRS) segment.';
            
              INSERT INTO swrnote
                (swrnote_note_type
                ,swrnote_parent_loop
                ,swrnote_child_loop
                ,swrnote_seqno
                ,swrnote_comment)
              VALUES
                ('CRSR'
                ,l_ses_loop_repeat
                ,l_crs_loop_repeat
                ,l_crsr_nte_count
                ,l_element_table(2));
            
            ELSIF transcript_segment_rec.transcript_segment = c_name_code --N1(CRS)
                  AND l_crs_loop_repeat > 0 AND l_ses_loop_repeat > 0 AND
                  l_deg_loop_repeat = 0 THEN
              INSERT INTO swrcovd
                (swrcovd_ases_seqno
                ,swrcovd_crs_seqno
                ,swrcovd_identifier
                ,swrcovd_activity_date)
              VALUES
                (l_ses_loop_repeat
                ,l_crs_loop_repeat
                ,l_element_table(1)
                ,SYSDATE);
              -- USF M Begin
              /*
              -- USF L Begin
              --> Process N1 (CRS) segment.
              ELSIF     transcript_segment_rec.transcript_segment =
                                                        c_name_code -- N1
                     AND l_ses_loop_repeat > 0
                 --    AND l_sums_loop_reat = 0
                     AND l_crs_loop_repeat > 0
                     AND l_deg_loop_repeat = 0
              THEN
                 l_state :=
                       'Before inserting SWTCRSR table record';
                 INSERT INTO swtcrsr (swtcrsr_dcmt_seqno,swtcrsr_ases_seqno,
                                      swtcrsr_activity_date,swtcrsr_override_ind)
                        VALUES (wshkedi.dcmt_seqno,
                                l_ses_loop_repeat,
                                sysdate,
                                'Y');
              -- USF L End
              */
              -- USF M End
              --> process DEG(SES) segment.
            ELSIF transcript_segment_rec.transcript_segment =
                  c_degree_record --DEG
                  AND l_ses_loop_repeat > 0 THEN
              l_state           := ' before inserting swrdegr with DEG(SES) info.';
              l_deg_loop_repeat := l_deg_loop_repeat + 1;
              l_degr_nte_count  := 0;
              l_fos_count       := 0;
              l_deg_n1_count    := 0;
            
              INSERT INTO swrdegr
                (swrdegr_degr_seqno
                ,swrdegr_ases_seqno
                ,swrdegr_degr_code
                ,swrdegr_date_qual
                ,swrdegr_date_code
                ,swrdegr_desc
                ,swrdegr_honor_code)
              VALUES
                (l_deg_loop_repeat
                ,l_ses_loop_repeat
                ,l_element_table(1)
                ,l_element_table(2)
                ,l_element_table(3)
                ,l_element_table(4)
                ,l_element_table(5));
              --> process SUM(DEG) segment
            ELSIF transcript_segment_rec.transcript_segment = 'SUM' --DEG
                  AND l_ses_loop_repeat > 0 THEN
              l_temp_date := NULL;
            
              IF l_element_table(13) IS NOT NULL AND
                 l_element_table(14) IS NOT NULL THEN
                l_temp_date := wf_get_date(l_element_table(13),
                                           l_element_table(14));
              END IF; /* l_element_table(13) IS NOT NULL AND
                                                                                                                                                                                                                                   l_element_table(14) IS NOT NULL */
            
              l_state := 'before inserting swrsumd table with SUM(DEG) info.';
            
              INSERT INTO swrsumd
                (swrdegr_degr_seqno
                ,swrdegr_ases_seqno
                ,swrsumd_acad_type_code
                ,swrsumd_grad_level_code
                ,swrsumd_resp_code
                ,swrsumd_qty_gpa
                ,swrsumd_qty_hrs_attempt
                ,swrsumd_qty_hrs_earned
                ,swrsumd_range_min
                ,swrsumd_range_max
                ,swrsumd_acad_gpa
                ,swrsumd_gpa_resp_code
                ,swrsumd_class_rank
                ,swrsumd_tot_stud
                ,swrsumd_date
                ,swrsumd_no_of_days
                ,swrsumd_days_absent
                ,swrsumd_qty_points
                ,swrsumd_summary_source
                ,swrsumd_activity_date)
              VALUES
                (l_deg_loop_repeat
                ,l_ses_loop_repeat
                ,l_element_table(1)
                ,l_element_table(2)
                ,l_element_table(3)
                ,l_element_table(4)
                ,l_element_table(5)
                ,l_element_table(6)
                ,l_element_table(7)
                ,l_element_table(8)
                ,l_element_table(9)
                ,l_element_table(10)
                ,l_element_table(11)
                ,l_element_table(12)
                ,l_temp_date
                ,l_element_table(15)
                ,l_element_table(16)
                ,l_element_table(17)
                ,l_element_table(18)
                ,SYSDATE);
              --> process FOS(DEG) segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_field_of_study --FOS
                  AND l_deg_loop_repeat > 0 THEN
              l_state     := 'before inserting swrdfos table with FOS(DEG) info.';
              l_fos_count := l_fos_count + 1;
            
              INSERT INTO swrdfos
                (swrdfos_degr_seqno
                ,swrdfos_fos_seqno
                ,swrdfos_acad_field
                ,swrdfos_fos_code_qual
                ,swrdfos_fos_code
                ,swrdfos_fos_desc
                ,swrdfos_fos_honor_desc)
              VALUES
                (l_deg_loop_repeat
                ,l_fos_count
                ,l_element_table(1)
                ,l_element_table(2)
                ,l_element_table(3)
                ,l_element_table(4)
                ,l_element_table(5));
              -- ver X start
              --> process N1(DEG) segment
            ELSIF transcript_segment_rec.transcript_segment = c_name_code -- 'N1'
                  AND l_deg_loop_repeat > 0 AND l_deg_n1_count = 0 THEN
              l_deg_n1_count := l_deg_n1_count + 1;
              IF l_element_table(1) = 'OS' THEN
                UPDATE swrdegr a
                   SET a.swrdegr_override_ind = 'Y'
                 WHERE a.swrdegr_dcmt_seqno = wshkedi.dcmt_seqno
                   AND a.swrdegr_degr_seqno = l_deg_loop_repeat
                   AND a.swrdegr_ases_seqno = l_ses_loop_repeat;
              END IF;
              -- ver X end
              --> process NTE(DEG) segment
            ELSIF transcript_segment_rec.transcript_segment =
                  c_note_segment --NTE
                  AND l_deg_loop_repeat > 0 THEN
              l_degr_nte_count := l_degr_nte_count + 1;
              l_state          := ' before inserting comment table with NTE(DEG) info.';
            
              INSERT INTO swrnote
                (swrnote_note_type
                ,swrnote_parent_loop
                ,swrnote_child_loop
                ,swrnote_seqno
                ,swrnote_comment)
              VALUES
                ('DEGR'
                ,l_ses_loop_repeat
                ,l_deg_loop_repeat
                ,l_degr_nte_count
                ,l_element_table(2));
            END IF; -->transcript_segment_rec.transcript_segment = c_acad_ses_header--SES THEN
          END IF; -->l_lx_count > 1
        END LOOP; --transcript_segment_c
        COMMIT;
      EXCEPTION
        WHEN le_exception1 THEN
          ROLLBACK;
          --handele business exception here.
          wp_handle_error_db('EDI', 'wp_load_inbound_130', 'BUSINESS',
                             -- ver Y start
                             'IN document ' || to_char(l_doc_seq_no) ||
                              ' le_exception1 ||encountered at state ' ||
                              l_state || ' for edi key ' || l_id_edi_key,
                             -- ver Y end
                             l_success_out, l_message_out);
          p_success_out := FALSE;
          p_message_out := l_state;
          COMMIT;
        WHEN OTHERS THEN
          --DBMS_OUTPUT.put_line (TO_CHAR (in_transcript_rec.dcmt));
          ROLLBACK;
          -- handle oracle errors here.
          wp_handle_error_db('EDI', 'wp_load_inbound_130', 'ORACLE',
                             -- ver Y start
                             'IN document ' || to_char(l_doc_seq_no) ||
                              ' edi key ' || l_id_edi_key || ' Encountered ' ||
                              to_char(SQLCODE) || ' : ' ||
                              substr(SQLERRM, 1, 250) || ' At ' || l_state,
                             -- ver Y end
                             l_success_out, l_message_out);
          p_success_out := FALSE;
          p_message_out := l_state;
          COMMIT;
        
      END;
    END LOOP; -- in_transcript_c
  
    COMMIT;
    p_success_out := TRUE;
    p_message_out := l_state;
    -- much more code
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      -- handle oracle errors here.
      wp_handle_error_db('EDI', 'wp_load_inbound_130', 'ORACLE',
                         'Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_state,
                         l_success_out, l_message_out);
      COMMIT;
      p_success_out := FALSE;
      p_message_out := l_state;
  END wp_load_inbound_130;

  PROCEDURE wp_load_inbound_status
  (
    p_message_out OUT VARCHAR2
   ,p_success_out OUT BOOLEAN
  ) IS
    --
    --***********************************************************************
    --
    --  University of South Florida
    --  Student Information System
    --  Program Unit Information
    --
    --  General Information
    --  -------------------
    --  Program Unit Name  : wp_load_inbound_status
    --  Process Associated : EDI
    --  Business Logic :
    --   This procedure loads all inbound trnasactions' status
    --  into status table swtetss.
    --  Documentation Links:
    --
    -- Audit Trail
    -- -----------
    --  Src   USF
    --  Ver   Ver  Package    Date         User       Reason For Change
    -- -----  ---  ---------  -----------  ------     -----------------------
    --  n/a   A   B5-002941  20-AUG-2002  VBANGALO   Initial Creation.
  
    -- Parameter Information:
    -- ------------
    --  p_success_out    out parameter  set to TRUE if process is success
    --                                  set to FALSE if process is failed.
    --  p_message_out    out parameter  message.
    --
    --************************************************************************
    l_transaction_type swtewls.swtewls_type%TYPE;
    l_inst_code        swtewle.swtewle_elm_value%TYPE;
    l_transaction_ack  VARCHAR2(5);
    l_control_number   swtewle.swtewle_elm_value%TYPE;
    l_message_out      VARCHAR2(500);
    l_success_out      BOOLEAN;
    l_state            VARCHAR2(2000);
    l_dcmt_seqno       swtewle.swtewle_dcmt_seqno%TYPE := NULL;
  
    CURSOR incoming_transactions_c IS
      SELECT DISTINCT a.swtewls_dcmt_seq dcmt FROM swtewls a;
  
    CURSOR transaction_type_c(c_dcmt_seqno_in swtewle.swtewle_dcmt_seqno%TYPE) IS
      SELECT a.swtewls_type transaction_type
        FROM swtewls a
       WHERE a.swtewls_dcmt_seq = c_dcmt_seqno_in
         AND a.swtewls_line_num = 3;
  
    CURSOR inst_code_c(c_dcmt_seqno_in swtewle.swtewle_dcmt_seqno%TYPE) IS
      SELECT a.swtewle_elm_value inst_code
        FROM swtewle a
       WHERE a.swtewle_dcmt_seqno = c_dcmt_seqno_in
         AND a.swtewle_line_num = 2
         AND a.swtewle_elm_seq = 2;
  
    CURSOR control_number_c(c_dcmt_seqno_in swtewle.swtewle_dcmt_seqno%TYPE) IS
      SELECT a.swtewle_elm_value control_number
        FROM swtewle a
       WHERE a.swtewle_dcmt_seqno = c_dcmt_seqno_in
         AND a.swtewle_line_num = 3
         AND a.swtewle_elm_seq = 2;
  
    CURSOR transaction_ack_c(c_dcmt_seqno_in swtewle.swtewle_dcmt_seqno%TYPE) IS
      SELECT a.swteake_elm_value transaction_ack
        FROM swteake a
       WHERE a.swteake_elm_seq = 1
         AND a.swteake_dcmt_seqno = c_dcmt_seqno_in
         AND a.swteake_line_num =
             (SELECT b.swteaks_line_num
                FROM saturn.swteaks b
               WHERE b.swteaks_dcmt_seq = a.swteake_dcmt_seqno
                 AND b.swteaks_seg = 'AK5');
    /*
    CURSOR get_inst_code_c (c_dcmt_seqno_in  swtewle.swtewle_dcmt_seqno%TYPE) IS
    SELECT a.swtewle_elm_value
    FROM swtewle a
    WHERE a.swtewle_dcmt_seqno = c_dcmt_seqno_in
    AND a.swtewle_elm_seq = 4
    AND a.swtewle_line_num =
    (SELECT * FROM swtewls b
     WHERE b.swtewls_dcmt_seq = a.swtewle_dcmt_seqno
      AND b.swtewls_seg = 'N1'
      AND EXISTS
      (SELECT 'x' FROM swtewle c
        WHERE c.swtewle_dcmt_seqno = b.swtewls_dcmt_seq
          AND c.swtewle_line_num = b.swtewls_line_num
          AND c.swtewle_elm_seq = 1
          AND c.swtewle_elm_value IN ('AS,'KS'));*/
  
  BEGIN
    FOR incoming_transactions_rec IN incoming_transactions_c
    LOOP
      l_dcmt_seqno       := incoming_transactions_rec.dcmt;
      l_transaction_type := NULL;
      l_inst_code        := NULL;
      l_transaction_ack  := NULL;
      l_control_number   := NULL;
      FOR transaction_type_rec IN transaction_type_c(incoming_transactions_rec.dcmt)
      LOOP
        l_transaction_type := transaction_type_rec.transaction_type;
      END LOOP; --transaction_type_c
      FOR inst_code_rec IN inst_code_c(incoming_transactions_rec.dcmt)
      LOOP
        l_inst_code := inst_code_rec.inst_code;
      END LOOP; --inst_code_c
      FOR control_number_rec IN control_number_c(incoming_transactions_rec.dcmt)
      LOOP
        l_control_number := control_number_rec.control_number;
      END LOOP; --control_number_c
      FOR transaction_ack_rec IN transaction_ack_c(incoming_transactions_rec.dcmt)
      LOOP
        l_transaction_ack := transaction_ack_rec.transaction_ack;
      END LOOP; --transaction_ack_c
      IF l_transaction_ack IS NULL THEN
        l_transaction_ack := 'NP';
      END IF; --l_transaction_ack
      BEGIN
        /*     dbms_output.put_line(to_char(incoming_transactions_rec.dcmt)||' '||
                                    l_transaction_type||' '||
                                    'IN'||' '||
                                    l_inst_code||' '||
                                    l_control_number||' '||
                                    'SYSDATE'||' '||
                                     'NULL'||' '||
                                    l_transaction_ack);
        */
        INSERT INTO swtetss
          (swtetss_dcmt_seq
          ,swtetss_trans_set_id
          ,swtetss_trans_inout_type
          ,swtetss_inst_code
          ,swtetss_ctrl_num
          ,swtetss_date_processed
          ,swtetss_997_file_name
          ,swtetss_status)
        VALUES
          (incoming_transactions_rec.dcmt
          ,l_transaction_type
          ,'IN'
          ,l_inst_code
          ,l_control_number
          ,SYSDATE
          ,NULL
          ,l_transaction_ack);
      
      EXCEPTION
        WHEN OTHERS THEN
          -- dbms_output.put_line(to_char(incoming_transactions_rec.dcmt)||' '||substr(SQLERRM,1,200));
          NULL;
      END;
      COMMIT;
    END LOOP; --incoming_transactions_rec
    p_message_out := 'Done';
    p_success_out := TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      -- handle oracle errors here.
      wp_handle_error_db('EDI', 'wp_load_inbound_status', 'ORACLE',
                         'IN document ' || to_char(l_dcmt_seqno) ||
                          ' Encountered ' || to_char(SQLCODE) || ' : ' ||
                          substr(SQLERRM, 1, 250) || ' At ' || l_state,
                         l_success_out, l_message_out);
      COMMIT;
      p_success_out := FALSE;
      p_message_out := l_state;
  END wp_load_inbound_status;
BEGIN
  NULL;
END wsakedi;
/
