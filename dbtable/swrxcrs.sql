--***********************************************************************
--
--  University of South Florida
--  Student Information System
--  Program Unit Information
--
--  General Information
--  -------------------
--  Table Name  : swrxcrs
--  Process Associated: Excess Credit Hours 
--  Object Source File Location and Name : dbtable\swrxcrs.sql
--  Business Logic : 
--   This script creates table swrxcrs
--
--
-- Audit Trail (in descending date order)
-- --------------------------------------  
--  Version  Issue      Date         User         Reason For Change
--  -------  ---------  -----------  --------     -----------------------
--     1     OASBAN-90  2/7/2013       RVOGETI     Initial Creation 
--   
--************************************************************************
DROP TABLE saturn.swrxcrs;

CREATE TABLE saturn.swrxcrs
(
  swrxcrs_pidm              NUMBER(8)   NOT NULL,
  swrxcrs_term_code         VARCHAR2(6) NOT NULL,
  swrxcrs_subj_code         VARCHAR2(4) NOT NULL,
  swrxcrs_crse_numb         VARCHAR2(5) NOT NULL,
  swrxcrs_ip_comp_flg       VARCHAR2(1),
  swrxcrs_grde_code         VARCHAR2(6),
  swrxcrs_credit_hrs        NUMBER(7,3),
  swrxcrs_exempt_type       VARCHAR2(30),
  swrxcrs_nondeg_exmpt_flg  VARCHAR2(1),  
  swrxcrs_excess_flg        VARCHAR2(1),
  swrxcrs_activity_date     DATE NOT NULL
)
;

create index SWRXCRS_KEY_IDX on SATURN.SWRXCRS (SWRXCRS_PIDM, SWRXCRS_TERM_CODE);  

-- Add comments to the table
comment on table SATURN.SWRXCRS
  is 'This table contains all completed and in-process courses per student per term';
  
-- Add comments to the columns 
comment on column SATURN.SWRXCRS.swrxcrs_pidm
  is 'Internal identification number of the student';
comment on column SATURN.SWRXCRS.swrxcrs_term_code
  is 'Term this course was taken';
comment on column SATURN.SWRXCRS.swrxcrs_subj_code
  is 'Subject Code';
comment on column SATURN.SWRXCRS.swrxcrs_crse_numb
  is 'Course Number';
comment on column SATURN.SWRXCRS.swrxcrs_ip_comp_flg
  is 'Flag to indicate if this is an in-progress or completed course';
comment on column SATURN.SWRXCRS.swrxcrs_grde_code
  is 'Course Grade';
comment on column SATURN.SWRXCRS.swrxcrs_credit_hrs
  is 'Credit Hours';
comment on column SATURN.SWRXCRS.swrxcrs_exempt_type
  is 'Type of Exemption on this course';
comment on column SATURN.SWRXCRS. swrxcrs_nondeg_exmpt_flg
   is 'Flag to indicate this is a non degree applicable exempted course'; 
comment on column SATURN.SWRXCRS.swrxcrs_excess_flg
  is 'Flag to indicate if this course is considered as excess or not';
comment on column SATURN.SWRXCRS.swrxcrs_activity_date
  is 'Date this record was last updated';
