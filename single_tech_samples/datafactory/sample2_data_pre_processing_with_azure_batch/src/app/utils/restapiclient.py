"""This is a http client helper for making http rest api calls.
"""
from typing import Any
import requests


class HttpClient:
    """Rest api client
    """
    def patch(self, url: str, data: Any):
        """Make a put request to update an existing resource.

        Args:
            url (str): put url
            data (Any): data to be updated.

        Returns:
            _type_: json object
        """
        response = requests.patch(url=url, json=data, verify=False)
        return ResponseObject(response.status_code, response)

    def get(self, url: str):
        """Make a get request to get an existing resource.

        Args:
            url (str): put url

        Returns:
            _type_: json object
        """
        response = requests.get(url=url, verify=False)
        return ResponseObject(response.status_code, response)
        
class ResponseObject:
    """Response object to be used with rest api call responses.
    """
    def __init__(self, code, data):
        self.code = code
        self.data = data
    code: int
    data: Any
