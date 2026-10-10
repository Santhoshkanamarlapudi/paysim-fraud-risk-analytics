-- 01_create_database_and_table.sql
-- Purpose: create the database and the raw staging table.
-- The raw table mirrors the PaySim CSV exactly and is never modified.

CREATE DATABASE paysim_fraud;
USE paysim_fraud;

CREATE TABLE raw_transactions (
    step            INT,
    type            VARCHAR(20),
    amount          DECIMAL(15,2),
    nameOrig        VARCHAR(20),
    oldbalanceOrg   DECIMAL(15,2),
    newbalanceOrig  DECIMAL(15,2),
    nameDest        VARCHAR(20),
    oldbalanceDest  DECIMAL(15,2),
    newbalanceDest  DECIMAL(15,2),
    isFraud         TINYINT,
    isFlaggedFraud  TINYINT
);
