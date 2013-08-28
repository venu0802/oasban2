--***********************************************************************  
--
--  University of South Florida 
--  Student Information System
--  Program Unit Information
--
--  General Information
--  -------------------
--  Table Name  : swrvdoc
--  Process Associated: Admission
--  Object Source File Location and Name : dbtable\swrvdoc_alt.sql
--  Business Logic : 
--   This SQL script renames a column in table SWRVDOC.
--
--
-- Audit Trail (in descending date order)
-- --------------------------------------  
--  Version  Issue       Date           User          Reason For Change
--  -------  ---------   -----------    --------      -----------------------
--     1     OASBAN-124  06/17/2013     HHNGO         Initial Creation to rename a column SWRVDOC_VZ_ID
--                                                    to SWRVDOC_CONF_NUMB.
--    
--************************************************************************

ALTER TABLE SATURN.SWRVDOC
  RENAME COLUMN SWRVDOC_VZ_ID TO SWRVDOC_CONF_NUMB;
	 