import requests
from msal import ConfidentialClientApplication


class Helper_Token:
    def __init__(
        self,
        tenant_id: str,
        app_id: str
    ) -> None: 
    
        self.tenant_id = tenant_id
        self.app_id = app_id   
    
    def get_token_ServPrincRead_token(self, scope:str, secret: str) -> str:
        authority = f'https://login.microsoftonline.com/{self.tenant_id}'
        app = ConfidentialClientApplication(
            client_id = self.app_id,
            authority=authority,
            client_credential=secret
        )


        token_response = app.acquire_token_for_client(scopes=[f'{scope}.default'])
        #print(token_response)
        access_token = token_response['access_token']

        return access_token

    def get_token_ServPrincRead(access_token:str) -> str:
        
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        }

        return headers
