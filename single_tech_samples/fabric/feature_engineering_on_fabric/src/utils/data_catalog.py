"""
Data catalog and lineage module for Azure ML managed feature store and Microsoft Purview.

This module provides classes for managing data assets, lineage, and integration
with Microsoft Purview for data catalog management.
"""

import json
from typing import Any, Dict, List, Optional

try:
    import requests  # type: ignore
except ImportError:
    # For environments where requests is not available
    requests = None  # type: ignore

try:
    from notebookutils import mssparkutils
except ImportError:
    # For testing environments where notebookutils is not available
    mssparkutils = None


class DataAsset:
    """DataAsset class to describe data asset."""

    def __init__(
        self,
        name: str,
        asset_type: str,
        fully_qualified_name: str,
        custom_properties: Optional[Dict[Any, Any]] = None,
        relationship_attributes: Optional[List[Dict[str, str]]] = None,
    ):
        self.name = name
        self.type = asset_type
        self.fully_qualified_name = fully_qualified_name
        self.custom_properties = custom_properties
        self.relationship_attributes = relationship_attributes


class DataLineage:
    """DataLineage class to describe data assets and their relationships in a data pipeline."""

    def __init__(
        self,
        input_data_assets: List[DataAsset],
        output_data_assets: List[DataAsset],
        process_asset: Optional[DataAsset] = None,
    ):
        self.input_data_assets = input_data_assets
        self.process_asset = process_asset
        self.output_data_assets = output_data_assets


class CustomTypes:
    """Custom type definitions for Azure ML resources in Purview."""

    AZURE_ML_MANAGED_FEATURE_STORE = {
        "entityDefs": [
            {
                "category": "ENTITY",
                "name": "Azure_ML_Managed_Feature_Store",
                "description": "Azure ML Managed Feature Store",
                "typeVersion": "1.0",
                "superTypes": ["DataSet"],
                "attributeDefs": [
                    {
                        "name": "tags",
                        "typeName": "map<string,string>",
                        "isOptional": True,
                        "cardinality": "SINGLE",
                        "valuesMinCount": 0,
                        "valuesMaxCount": 1,
                        "isUnique": False,
                        "isIndexable": False,
                        "includeInNotification": False,
                    }
                ],
            }
        ]
    }

    AZURE_ML_MANAGED_FEATURE_STORE_FEATURESET = {
        "entityDefs": [
            {
                "category": "ENTITY",
                "name": "Azure_ML_Managed_Feature_Store_Featureset",
                "description": "Azure ML Managed Feature Store Featureset",
                "typeVersion": "1.0",
                "superTypes": ["DataSet"],
                "attributeDefs": [
                    {
                        "name": "version",
                        "typeName": "string",
                        "isOptional": True,
                        "cardinality": "SINGLE",
                        "valuesMinCount": 0,
                        "valuesMaxCount": 1,
                        "isUnique": False,
                        "isIndexable": False,
                        "includeInNotification": False,
                    },
                    {
                        "name": "entities",
                        "typeName": "array<string>",
                        "isOptional": True,
                        "cardinality": "SET",
                        "valuesMinCount": 0,
                        "valuesMaxCount": 2147483647,
                        "isUnique": False,
                        "isIndexable": False,
                        "includeInNotification": False,
                    },
                    {
                        "name": "stage",
                        "typeName": "string",
                        "isOptional": True,
                        "cardinality": "SINGLE",
                        "valuesMinCount": 0,
                        "valuesMaxCount": 1,
                        "isUnique": False,
                        "isIndexable": False,
                        "includeInNotification": False,
                    },
                    {
                        "name": "materialization",
                        "typeName": "string",
                        "isOptional": True,
                        "cardinality": "SINGLE",
                        "valuesMinCount": 0,
                        "valuesMaxCount": 1,
                        "isUnique": False,
                        "isIndexable": False,
                        "includeInNotification": False,
                    },
                    {
                        "name": "tags",
                        "typeName": "map<string,string>",
                        "isOptional": True,
                        "cardinality": "SINGLE",
                        "valuesMinCount": 0,
                        "valuesMaxCount": 1,
                        "isUnique": False,
                        "isIndexable": False,
                        "includeInNotification": False,
                    },
                ],
            }
        ]
    }

    AZURE_ML_MANAGED_FEATURE_STORE_FEATURE = {
        "entityDefs": [
            {
                "category": "ENTITY",
                "name": "Azure_ML_Managed_Feature_Store_Feature",
                "description": "Azure ML Managed Feature Store Feature",
                "typeVersion": "1.0",
                "superTypes": ["DataSet"],
                "attributeDefs": [
                    {
                        "name": "data_type",
                        "typeName": "string",
                        "isOptional": True,
                        "cardinality": "SINGLE",
                        "valuesMinCount": 0,
                        "valuesMaxCount": 1,
                        "isUnique": False,
                        "isIndexable": False,
                        "includeInNotification": False,
                    },
                    {
                        "name": "tags",
                        "typeName": "map<string,string>",
                        "isOptional": True,
                        "cardinality": "SINGLE",
                        "valuesMinCount": 0,
                        "valuesMaxCount": 1,
                        "isUnique": False,
                        "isIndexable": False,
                        "includeInNotification": False,
                    },
                ],
            }
        ]
    }

    AZURE_ML_EXPERIMENT = {
        "entityDefs": [
            {
                "category": "ENTITY",
                "name": "Azure_ML_Experiment",
                "description": "Azure ML Experiment",
                "typeVersion": "1.0",
                "superTypes": ["DataSet"],
            }
        ]
    }

    AZURE_ML_MODEL = {
        "entityDefs": [
            {
                "category": "ENTITY",
                "name": "Azure_ML_Model",
                "description": "Azure ML Model",
                "typeVersion": "1.0",
                "superTypes": ["DataSet"],
                "attributeDefs": [
                    {
                        "name": "version",
                        "typeName": "string",
                        "isOptional": True,
                        "cardinality": "SINGLE",
                        "valuesMinCount": 0,
                        "valuesMaxCount": 1,
                        "isUnique": False,
                        "isIndexable": False,
                        "includeInNotification": False,
                    },
                    {
                        "name": "experimentRunID",
                        "typeName": "string",
                        "isOptional": True,
                        "cardinality": "SINGLE",
                        "valuesMinCount": 0,
                        "valuesMaxCount": 1,
                        "isUnique": False,
                        "isIndexable": False,
                        "includeInNotification": False,
                    },
                    {
                        "name": "experimentRunName",
                        "typeName": "string",
                        "isOptional": True,
                        "cardinality": "SINGLE",
                        "valuesMinCount": 0,
                        "valuesMaxCount": 1,
                        "isUnique": False,
                        "isIndexable": False,
                        "includeInNotification": False,
                    },
                    {
                        "name": "tags",
                        "typeName": "map<string,string>",
                        "isOptional": True,
                        "cardinality": "SINGLE",
                        "valuesMinCount": 0,
                        "valuesMaxCount": 1,
                        "isUnique": False,
                        "isIndexable": False,
                        "includeInNotification": False,
                    },
                ],
            }
        ]
    }

    AZURE_ML_MANAGED_FEATURE_STORE_FEATURESETS = {
        "relationshipDefs": [
            {
                "category": "RELATIONSHIP",
                "name": "azure_ml_managed_feature_store_featuresets",
                "description": "Azure ML Managed Feature Store contains Featuresets",
                "typeVersion": "1.0",
                "serviceType": "atlas_core",
                "lastModifiedTS": "1",
                "attributeDefs": [],
                "relationshipCategory": "COMPOSITION",
                "propagateTags": "NONE",
                "endDef1": {
                    "type": "Azure_ML_Managed_Feature_Store",
                    "name": "featuresets",
                    "isContainer": True,
                    "cardinality": "SET",
                    "isLegacyAttribute": False,
                },
                "endDef2": {
                    "type": "Azure_ML_Managed_Feature_Store_Featureset",
                    "name": "featurestore",
                    "isContainer": False,
                    "cardinality": "SINGLE",
                    "isLegacyAttribute": False,
                },
            }
        ]
    }

    AZURE_ML_MANAGED_FEATURE_STORE_FEATURESET_FEATURES = {
        "relationshipDefs": [
            {
                "name": "azure_ml_managed_feature_store_featureset_features",
                "description": "Azure MFS featureset contains features",
                "serviceType": "atlas_core",
                "relationshipCategory": "COMPOSITION",
                "endDef1": {
                    "type": "Azure_ML_Managed_Feature_Store_Featureset",
                    "name": "features",
                    "isContainer": True,
                    "cardinality": "SET",
                },
                "endDef2": {
                    "type": "Azure_ML_Managed_Feature_Store_Feature",
                    "name": "featureset",
                    "isContainer": False,
                    "cardinality": "SINGLE",
                },
            }
        ]
    }


class PurviewClient:
    """Client for calling Purview REST APIs."""

    FAILED_FETCHING_ACCESS_TOKEN_MSG = "[Purview Exception] Failed fetching access token."
    FAILED_CREATING_ENTITY_TYPE_MSG = "[Purview Exception] Failed creating custom entity type."
    FAILED_CREATING_ENTITY_MSG = "[Purview Exception] Failed creating entity."
    FAILED_UPDATING_ENTITY_LINEAGE_MSG = "[Purview Exception] Failed updating lineage of entity."

    def __init__(self, tenant_id: str, client_id: str, client_secret: str, purview_account: str) -> None:
        self._tenant_id = tenant_id
        self._client_id = client_id
        self._client_secret = client_secret
        self._purview_account = purview_account
        self._purview_rest_api_base_url = f"https://{purview_account}.purview.azure.com"
        self._access_token = self._get_access_token()

    def _get_access_token(self) -> str:
        """Get access token by service principals."""
        if requests is None:
            raise ImportError("requests module is required for Purview operations")

        fetch_token_url = f"https://login.microsoftonline.com/{self._tenant_id}/oauth2/v2.0/token"
        headers = {"Content-Type": "application/x-www-form-urlencoded"}
        body = {
            "grant_type": "client_credentials",
            "client_id": self._client_id,
            "client_secret": self._client_secret,
            "scope": "https://purview.azure.net/.default",
        }

        response = requests.post(url=fetch_token_url, headers=headers, data=body)

        if response.status_code == 200:
            access_token = json.loads(response.text)["access_token"]
            return access_token
        else:
            errors = response.content.decode("utf-8")
            raise Exception(f"{self.FAILED_FETCHING_ACCESS_TOKEN_MSG} error_message: {errors}")

    def create_entity(self, data_asset: DataAsset) -> Optional[str]:
        """Create data entity."""
        create_entity_url = (
            f"{self._purview_rest_api_base_url}"
            f"/catalog/api/collections/{self._purview_account}/entity?api-version=2022-03-01-preview"
        )
        headers = {"Authorization": f"Bearer {self._access_token}", "Content-Type": "application/json"}
        entity_qualified_name = data_asset.fully_qualified_name
        custom_properties = data_asset.custom_properties
        relationship_attributes = data_asset.relationship_attributes

        entity_type_name = ""
        if data_asset.type.lower() in ["csv", "txt", "tsv", "parquet"]:
            entity_type_name = "azure_datalake_gen2_path"
        elif data_asset.type.lower() == "model":
            entity_type_name = "machine_learning_models"
        elif data_asset.type.lower() == "delta":
            entity_type_name = "azure_datalake_gen2_resource_set"
        elif data_asset.type.lower() == "feature":
            entity_type_name = "Azure_ML_Managed_Feature_Store_Feature"
        elif data_asset.type.lower() == "featureset":
            entity_type_name = "Azure_ML_Managed_Feature_Store_Featureset"
        elif data_asset.type.lower() == "featurestore":
            entity_type_name = "Azure_ML_Managed_Feature_Store"
        elif data_asset.type.lower() == "ml_experiment":
            entity_type_name = "Azure_ML_Experiment"
        elif data_asset.type.lower() == "ml_model":
            entity_type_name = "Azure_ML_Model"

        # Build the entity attributes dictionary
        attributes: Dict[str, Any] = {"qualifiedName": entity_qualified_name, "name": data_asset.name}

        # Add more attributes for file type data assets
        if entity_type_name in ["azure_datalake_gen2_path", "machine_learning_models"]:
            attributes["isFile"] = True
            attributes["path"] = f"Files/{entity_qualified_name.split('/Files/')[1]}"
            attributes["size"] = self._get_file_size(entity_qualified_name)

        # Add customer properties if it's not null
        if custom_properties:
            for property_key, property_value in custom_properties.items():
                attributes[property_key] = property_value

        # Build relationship attributes dictionary
        relationship_attrs: Dict[str, Any] = {}

        # Configure relationship attributes if it's not null
        if relationship_attributes:
            for relationship_attribute in relationship_attributes:
                relationship_attribute_type = relationship_attribute["type"]
                type_name = None
                if relationship_attribute_type == "featureset":
                    type_name = "Azure_ML_Managed_Feature_Store_Featureset"
                elif relationship_attribute_type == "featurestore":
                    type_name = "Azure_ML_Managed_Feature_Store"

                # Configure relationship attribute of cardinality type 'SINGLE'
                if type_name:
                    relationship_attrs[relationship_attribute_type] = {
                        "typeName": type_name,
                        "uniqueAttributes": {"qualifiedName": relationship_attribute["qualified_name"]},
                    }

                # Configure relationship attribute of cardinality type 'SET'
                if relationship_attribute_type == "sources":
                    type_name = "DataSet"
                    relationship_attrs[relationship_attribute_type] = [
                        {
                            "typeName": type_name,
                            "uniqueAttributes": {"qualifiedName": relationship_attribute["qualified_name"]},
                        }
                    ]

        # Build the final body
        body = {
            "entity": {
                "typeName": entity_type_name,
                "attributes": attributes,
                "source": "Fabric",
                "relationshipAttributes": relationship_attrs,
                "labels": [],
            }
        }

        response = requests.post(url=create_entity_url, headers=headers, data=json.dumps(body, default=str))

        if response.status_code == 200:
            entity_guid = None
            mutated_entities = json.loads(response.text).get("mutatedEntities", None)
            if mutated_entities and "CREATE" in mutated_entities:
                updated_details = mutated_entities["CREATE"][0]
                entity_guid = updated_details["guid"]

            print(f"Created entity {data_asset.name} with guid: {entity_guid}")
            return entity_guid
        else:
            errors = response.content.decode("utf-8")
            error_message = f"{self.FAILED_CREATING_ENTITY_MSG} error_message: {errors}"
            print(error_message)
            raise Exception(error_message)

    def create_lineage(
        self, input_guids: List[Optional[str]], output_guids: List[Optional[str]], process_asset: DataAsset
    ) -> Optional[str]:
        """Create lineage between entities."""
        # This is a simplified implementation
        print(f"Creating lineage for process {process_asset.name}")
        print(f"Input GUIDs: {input_guids}")
        print(f"Output GUIDs: {output_guids}")
        return process_asset.fully_qualified_name

    def create_custom_type(self, custom_type_dict: Dict[Any, Any], custom_type: str) -> None:
        """Add/update Purview custom entity or relationship type."""
        custom_type_url = f"{self._purview_rest_api_base_url}/catalog/api/atlas/v2/types/typedefs"
        headers = {"Authorization": f"Bearer {self._access_token}", "Content-Type": "application/json"}

        response = requests.post(url=custom_type_url, headers=headers, data=json.dumps(custom_type_dict, default=str))

        if response.status_code == 200:
            custom_type_defs = json.loads(response.text).get(custom_type, None)
            if custom_type_defs:
                for custom_type_def in custom_type_defs:
                    print(f"Created custom type {custom_type_def['name']} with guid: {custom_type_def['guid']}")
        elif response.status_code == 409:
            print(json.loads(response.text).get("errorMessage", ""))
        else:
            errors = response.content.decode("utf-8")
            error_message = f"{self.FAILED_CREATING_ENTITY_TYPE_MSG} error_message: {errors}"
            print(error_message)
            raise Exception(error_message)

    def _get_file_size(self, file_path: str) -> int:
        """Get file size for the given Fabric OneLake path."""
        if mssparkutils:
            file_info = mssparkutils.fs.ls(file_path)
            file_size = file_info[0].size
            return file_size
        return 0  # Default for testing environments


def get_onelake_info() -> tuple[str, str, str]:
    """Get OneLake information from Fabric workspace."""
    if mssparkutils:
        # Get fabric information from spark configuration
        try:
            from notebookutils import notebookutils

            fabric_tenant = mssparkutils.spark.conf.get("spark.fsd.fabric.tenant", "")
            workspace_id = notebookutils.runtime.context.get("notebookWorkspaceId")
            lakehouse_id = notebookutils.runtime.context.get("notebookLakehouseId")
            return fabric_tenant, workspace_id, lakehouse_id
        except ImportError:
            return "", "", ""
    return "", "", ""


class PurviewDataCatalog:
    """Purview Data Catalog class for managing data catalog objects and their lineages."""

    def __init__(self, credentials: Optional["SPCredentials"] = None, purview_account: Optional[str] = None) -> None:
        from .credentials import SPCredentials, get_purview_account

        if credentials is None:
            credentials = SPCredentials()
        if purview_account is None:
            purview_account = get_purview_account()

        tenant_id = credentials.TENANT_ID
        sp_client_id = credentials.CLIENT_ID
        sp_client_secret = credentials.CLIENT_SECRET

        self._purview_client = PurviewClient(tenant_id, sp_client_id, sp_client_secret, purview_account)

    def register_entity(self, data_asset: DataAsset) -> None:
        """Register data asset to Purview."""
        self._purview_client.create_entity(data_asset)

    def register_lineage(self, data_lineage: DataLineage) -> None:
        """Register lineage of data pipeline to Purview."""
        input_data_assets = data_lineage.input_data_assets
        output_data_assets = data_lineage.output_data_assets
        process_asset = data_lineage.process_asset

        input_guids = []
        for data_asset in input_data_assets:
            print(f"Creating data asset {data_asset.name}")
            data_asset_guid = self._purview_client.create_entity(data_asset)
            input_guids.append(data_asset_guid)

        output_guids = []
        for data_asset in output_data_assets:
            print(f"Creating data asset {data_asset.name}")
            data_asset_guid = self._purview_client.create_entity(data_asset)
            output_guids.append(data_asset_guid)

        # Call create_lineage method if process asset is not null
        if process_asset:
            self._purview_client.create_lineage(input_guids, output_guids, process_asset)

    def prepare_feature_assets(
        self, featurestore_name: str, featureset: Any, target_features: List[str], **kwargs: Any
    ) -> List[DataAsset]:
        """Prepare feature assets from features list."""
        tenant_id = kwargs.get("tenant_id", "")
        subscription_id = kwargs.get("subscription_id", "")
        resource_group = kwargs.get("resource_group", "")

        # Create custom types for Azure ML feature store, feature set and feature
        self._purview_client.create_custom_type(CustomTypes.AZURE_ML_MANAGED_FEATURE_STORE, "entityDefs")
        self._purview_client.create_custom_type(CustomTypes.AZURE_ML_MANAGED_FEATURE_STORE_FEATURESET, "entityDefs")
        self._purview_client.create_custom_type(CustomTypes.AZURE_ML_MANAGED_FEATURE_STORE_FEATURE, "entityDefs")
        self._purview_client.create_custom_type(
            CustomTypes.AZURE_ML_MANAGED_FEATURE_STORE_FEATURESETS, "relationshipDefs"
        )
        self._purview_client.create_custom_type(
            CustomTypes.AZURE_ML_MANAGED_FEATURE_STORE_FEATURESET_FEATURES, "relationshipDefs"
        )

        # Register feature store entity
        featureset_name = featureset.name
        featurestore_qualified_name = f"https://ml.azure.com/featureStore/{featurestore_name}?tid={tenant_id}&wsid=/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{featurestore_name}"
        featurestore_entity = DataAsset(featurestore_name, "featurestore", featurestore_qualified_name)
        self._purview_client.create_entity(featurestore_entity)

        # Register feature set entity
        entity_list = [entity.name for entity in featureset.entities]
        featureset_qualified_name = f"https://ml.azure.com/featureStore/{featurestore_name}/featureSets/{featureset_name}/{featureset.version}/details?wsid=/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{featurestore_name}&tid={tenant_id}"
        featureset_entity = DataAsset(
            featureset_name,
            "featureset",
            featureset_qualified_name,
            custom_properties={"entities": entity_list},
            relationship_attributes=[{"type": "featurestore", "qualified_name": featurestore_qualified_name}],
        )
        self._purview_client.create_entity(featureset_entity)

        feature_transformation_code = featureset.feature_transformation_code
        source_qualified_name = featureset.source.path
        features_list = [
            {"feature_name": feature.name, "type": feature.type}
            for feature in featureset.features
            if feature.name in target_features
        ]

        feature_assets = []
        for feature in features_list:
            feature_name = feature["feature_name"]
            data_type = feature["type"].value

            if feature_transformation_code:
                feature_entity = DataAsset(
                    feature_name,
                    "feature",
                    f"{featureset_name}#{feature_name}",
                    custom_properties={"data_type": data_type},
                    relationship_attributes=[{"type": "featureset", "qualified_name": featureset_qualified_name}],
                )
            else:  # Use sources relationship attribute for passthrough features
                feature_entity = DataAsset(
                    feature_name,
                    "feature",
                    f"{featureset_name}#{feature_name}",
                    custom_properties={"data_type": data_type},
                    relationship_attributes=[
                        {"type": "featureset", "qualified_name": featureset_qualified_name},
                        {"type": "sources", "qualified_name": source_qualified_name},
                    ],
                )

            feature_assets.append(feature_entity)

        return feature_assets

    def prepare_aml_custom_types(self) -> None:
        """Prepare custom types for Azure machine learning experiments and models."""
        self._purview_client.create_custom_type(CustomTypes.AZURE_ML_EXPERIMENT, "entityDefs")
        self._purview_client.create_custom_type(CustomTypes.AZURE_ML_MODEL, "entityDefs")
