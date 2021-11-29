### This packages will filter the data from a dataframe based on the filter criteria


## Configuration Parameters
* key_col : pass the column name, based on the values of this column we will partition the data.
* filter_criteria : This takes a list of values from "key_col" column which will be used for filtering the data.


Ex:
* Config : {"key_col" : "region", "filter_criteria" : ["Asia"]}