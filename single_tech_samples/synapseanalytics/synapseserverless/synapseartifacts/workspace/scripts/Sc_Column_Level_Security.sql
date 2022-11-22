/* RUN THIS STEPS with the user that executed the sample deployment - let's call it USER_1*/
/* Step 1:  - Log in to Synapse Studio with USER_1 and */
/*          - Replace the name of the AAD Group to AADGR<PROJECT_NAME><DEPLOYMENT_ID> you used on the deployment*/
/*          - Make sure you select the db_serverless instead of master under the Built-In pool */
/*          - and run the query: */
CREATE LOGIN [AADGR<PROJECT_NAME><DEPLOYMENT_ID>] FROM EXTERNAL PROVIDER;

/* Step 2: replace the same name after the LOGIN clause. Run the query.*/
CREATE USER [SynapseDbUser] FROM LOGIN [AADGR<PROJECT_NAME><DEPLOYMENT_ID>] ;

/* RUN THIS STEPS with the manually created AD user , let's call it USER_2*/
/* Step 3: Add USER_2 to AD Group AADGR<PROJECT_NAME><DEPLOYMENT_ID>*/
/* Step 4: Log in into Azure with  USER_2 */
/* Step 5: Navigate to Synapse Studio: https://web.azuresynapse.net/ and make sure you are logged with USER_2)*/
/* Step 6: Run the following query (make sure you are in the db_serverless database)*/
select airport_fee from VW_202010
/* Step 7: You should receive the following result: */
/* Content directory on path "<PATH TO NOT AUTHORIZED PATH>" cannot be listed:

/* Step 8: - Navigate to Storage Explorer and give specific ACL permissions to USER_2 just on the 2020 folder under the datalake container*/
/*         - Make sure you give the ACLs on all the folder hierarchy */
/*         - Run the same query again, it should succeed now */
select airport_fee from VW_202010
/* Result should be now: The SELECT permission was denied on the column 'airport_fee' of the object 'VW_202010', database 'db_serverless', schema 'dbo'.*/

/* Step 9: Run the following query on the Synapse Studio logged with USER_1  */
GRANT SELECT ON VW_202010(VendorID,total_amount) TO SynapseDbUser;


/* Step 10: Run the following query on the Synapse Studio logged with USER_2  */
select VendorID,total_amount from VW_202010

/* Step 11: You should be able to see the results as the AAD group is authorized on those 2 columns  */