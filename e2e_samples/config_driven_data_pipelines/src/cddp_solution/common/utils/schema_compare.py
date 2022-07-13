
from cddp_solution.common.utils.CddpException import CddpException


def validate_schema(schema, dataframe):
    """
    Validate if the dataframe matches the schema.

    Parameters
    ----------
    schema : StructType

    dataframe : Spark Dataframe


    Returns
    ----------
    True

    Raises
    ----------
    CddpException
        when any column in schema is not found in the dataframe
    """
    fields_1 = schema.fields
    fields_2 = dataframe.schema.fields

    for field_1 in fields_1:
        found = False
        for field_2 in fields_2:
            if(field_1.name == field_2.name and
               field_1.dataType == field_2.dataType and
               field_1.nullable == field_2.nullable):
                found = True
                break
        if not found:
            error_message = f"Column {field_1.name} {field_1.dataType} {field_1.nullable} not found!"
            raise CddpException(f"[CddpException|SchemaNotEqualError] {error_message}")

    return True
