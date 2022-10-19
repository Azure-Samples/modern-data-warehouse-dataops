/* RUN THIS STEPS with the user that executed the sample deployment - let's call it USER_1*/
/* Step 1: Log in to Synapse Studio with USER_1 and replace the name of the AAD Group to AADGR<PROJECT_NAME><DEPLOYMENT_ID> you used on the deployment*/
/* and run the query: */
CREATE LOGIN [AADGR<PROJECT_NAME><DEPLOYMENT_ID>] FROM EXTERNAL PROVIDER;

/* Step 2: replace the same name after the LOGIN clause. Run the query.*/
CREATE USER [SynapseDbUser] FROM LOGIN [AADGR<PROJECT_NAME><DEPLOYMENT_ID>] ;

/* RUN THIS STEPS with the manually created AD user , let's call it USER_2*/
/* Step 3: Add USER_2 to AD Group AADGR<PROJECT_NAME><DEPLOYMENT_ID>*/
/* Step 4: Log in into Azure with  USER_2 */
/* Step 5: Navigate to Synapse Studio: https://web.azuresynapse.net/ and make sure you are logged with USER_2)*/
/* Step 6: Run the following query*/
select airport_fee from VW_202010
/* Step 7: You should receive the following result: */
/* The SELECT permission was denied on the column 'airport_fee' of the object 'VW_202010', database 'db_serverless', schema 'dbo'.*/

/* Step 8: Run the following query on the Synapse Studio logged with USER_1  */
GRANT SELECT ON VW_202010(VendorID,total_amount) TO SynapseDbUser;

/* Step 9: Run the following query on the Synapse Studio logged with USER_2  */
select VendorID,total_amount from VW_202010

/* Step 10: You should be able to see the results as the AAD group is authorized on those 2 columns  */