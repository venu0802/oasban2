--***********************************************************************
--
--  University of South Florida
--  Student Information System
--  Program Unit Information
--
--  General Information
--  -------------------
--  Table Name  : swrxcrh
--  Process Associated: Excess Credit Hours 
--  Object Source File Location and Name : dbtable\swrxcrh.sql
--  Business Logic : 
--   This script creates table swrxcrh
--
--
-- Audit Trail (in descending date order)
-- --------------------------------------  
--  Version  Issue      Date         User         Reason For Change
--  -------  ---------  -----------  --------     -----------------------
--     1     OASBAN-90  2/7/2013       RVOGETI     Initial Creation 
--   
--************************************************************************
DROP TABLE saturn.swrxcrh;

CREATE TABLE saturn.swrxcrh
(
  swrxcrh_pidm                  NUMBER(8)   NOT NULL,
  swrxcrh_term_code_eff         VARCHAR2(6) NOT NULL,
  swrxcrh_admit_term_code       VARCHAR2(6),
  swrxcrh_stu_class             VARCHAR2(2),
  swrxcrh_in_state_ind          VARCHAR2(1),
  swrxcrh_degree_app_hrs        NUMBER(5,2),
  swrxcrh_degree_pgm_hrs        NUMBER(5,2),
  swrxcrh_threshold_hrs         NUMBER(5,2),
  swrxcrh_attempted_hrs         NUMBER(5,2),  
  swrxcrh_non_deg_appl_xfer_hrs NUMBER(5,2),  
  swrxcrh_exempted_hrs          NUMBER(5,2),  
  swrxcrh_unused_hrs            NUMBER(5,2),  
  swrxcrh_excess_hrs            NUMBER(5,2),  
  swrxcrh_excess_hrs_chrgd_cum  NUMBER(5,2),  
  swrxcrh_term_chgbl_excess_hrs NUMBER(5,2),  
  swrxcrh_excess_hrs_cnt_dwn    NUMBER(5,2),  
  swrxcrh_activity_date         DATE NOT NULL
)
;

-- Add comments to the table
comment on table saturn.swrxcrh
  is 'Student Excess Hours Table';
  
-- Add comments to the columns 
comment on column saturn.swrxcrh.swrxcrh_pidm
  is 'Internal identification number of the student';
comment on column saturn.swrxcrh.swrxcrh_term_code_eff
  is 'Effective term associated with this record';  
comment on column saturn.swrxcrh.swrxcrh_admit_term_code
  is 'Admit Term of the student';  
comment on column saturn.swrxcrh.swrxcrh_stu_class
  is 'Classification Code of the student';  
comment on column saturn.swrxcrh.swrxcrh_in_state_ind
  is 'In State or Out of State Indicator of the student';  
comment on column saturn.swrxcrh.swrxcrh_degree_app_hrs
  is 'Hours that are applicable towards the degree of the student';
comment on column saturn.swrxcrh.swrxcrh_degree_pgm_hrs
  is 'Program Hours needed to complete the degree';    
comment on column saturn.swrxcrh.swrxcrh_threshold_hrs
  is 'Number of Allowed Hours before excess hours are charged';    
comment on column saturn.swrxcrh.swrxcrh_attempted_hrs
  is 'Total Number of Attempted Hours (from History and In Progress hours)';    
comment on column saturn.swrxcrh.swrxcrh_non_deg_appl_xfer_hrs
  is 'Total Number Non Degree Applicable Transfer Hours';    
comment on column saturn.swrxcrh.swrxcrh_exempted_hrs
  is 'Total Number of Exempted Hours';    
comment on column saturn.swrxcrh.swrxcrh_unused_hrs
  is 'Total Number of Unused Hours';    
comment on column saturn.swrxcrh.swrxcrh_excess_hrs
  is 'Total Number of Excess Hours';    
comment on column saturn.swrxcrh.swrxcrh_excess_hrs_chrgd_cum
  is 'Cumulative Excess Hours Charged';    
comment on column saturn.swrxcrh.swrxcrh_term_chgbl_excess_hrs
  is 'Total Number of Hours that are Chargeable for this term';    
comment on column saturn.swrxcrh.swrxcrh_excess_hrs_cnt_dwn
  is 'Number of Hours remaining before Excess Hours are charged';    
comment on column saturn.swrxcrh.swrxcrh_activity_date
  is 'Date when the record was created or updated';    

alter table SATURN.SWRXCRH
  add constraint PK_SWRXCRH primary key (SWRXCRH_PIDM, SWRXCRH_TERM_CODE_EFF);
