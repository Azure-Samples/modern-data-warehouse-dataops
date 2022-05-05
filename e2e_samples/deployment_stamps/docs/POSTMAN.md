
# Postman

Use Postman to test API app easily.

## Get WebApps token

Perform the following operations to get an access token.

1\. Click [+] from the **Postman tab**.

![image.png](./.images/postman-token1.PNG)

2\. Select **OAuth 2.0** from the **Authorization tab**.

![image.png](./.images/postman-token4.PNG)

3\. Enter the settings on the configuration. Please be noticed that the configuration required here belongs to the **center Tenant**.

![image.png](./.images/postman-token5.PNG)

4\. Click **Get New Access Token** to authenticate. Execute **Proceed** when authentication is completed.

![image.png](./.images/postman-token6.PNG)

5\. Copy the token obtained by performing authentication.

![image.png](./.images/postman-token2.PNG)

6\. Paste it in **CURRENT VALUE of AuthAccessToken** of Environment and save it.

![image.png](./.images/postman-token3.PNG)

*Tokens expire on a regular basis, so do the same when they expire.

## Retrieve

Set the Get Url as following and click "Send" button.

```text
https://{api-url}/v1/{tenantId}/devices/{deviceId}/Telemetries
```
