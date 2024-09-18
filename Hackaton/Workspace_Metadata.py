
import requests
import json
import pandas as pd



class Workspace_Metadata:

    def __init__(
        self,
        header: str,
    ) -> None:
        self.header= header
       
    def Workspace_List(self)-> str:
        """
        List all wotkspace the token has access
        : Token Header
        :return: a list of workspace
        """
        url_get= "https://api.fabric.microsoft.com/v1/workspaces"
        response_status = requests.get(url_get, headers=self.header)
        response_data = response_status.json()
        status = response_data.get('status')
        workspace_ids = []

        workspacevalue=response_data.get("value", {})
        for workspaceid in workspacevalue:
            workspace_id = workspaceid["id"]
            if workspace_id:  # Check if 'id' exists before adding
                workspace_ids.append(workspace_id)
    
        return workspace_ids
           
       

    def Workspace_Scan(self, workspacevalue:str)-> str:
        """
        Workspace Scan ID
        :workspacevalue workspace id from Workspace_List
        :return: scan id to be used in the workspace metadata function
        """
        url = "https://api.powerbi.com/v1.0/myorg/admin/workspaces/getInfo"

        payload = {
            "workspaces": [f"{workspacevalue}"],
        }


        response = requests.post(url,json=payload,  headers=self.header)
        response.raise_for_status()
        response = response.json()
        scan_id= response.get("id", [])
        return scan_id

    def Workspace_Metadata(self,scan_id:str)-> str:
        """
        Workspace Metadata
        :scan_id from the Workspace_Scan
        :return: JSON response with the metadata information
        """
        url_get= f"https://api.powerbi.com/v1.0/myorg/admin/workspaces/scanResult/{scan_id}"
        response_status = requests.get(url_get, headers=self.header)
        response_status = response_status.json()
        return response_status
