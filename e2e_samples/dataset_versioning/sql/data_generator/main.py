import argparse
import pandas as pd
import sys

from keyvault_wrapper import KeyvaultWrapper
from sql_wrapper import SqlWrapper
from process import Process


def read_csv(path: str) -> pd.DataFrame:
    """
    Read csv and modify datatype

    :param path: path to csv
    :type path: str
    :return: dataframe with required columns
    :rtype: pd.DataFrame
    """
    df = pd.read_csv(path)
    df = df[['id',
             'loan_amnt',
             'annual_inc',
             'dti',
             'delinq_2yrs',
             'total_acc',
             'total_pymnt',
             'issue_d',
             'earliest_cr_line',
             'loan_status']]
    df['issue_d'] = pd.to_datetime(df['issue_d'])
    df['earliest_cr_line'] = pd.to_datetime(df['earliest_cr_line'])
    return df


def main(KeyvaultWrapper, SqlWrapper, Process, args_input):
    """
    main function to call argument parser to call the job chosen by the user

    :param KeyvaultWrapper
    :type Keyvaultwrapper: Keyvaultwrapper
    :param SqlWrapper
    :type SqlWrapper: SqlWrapper
    :param Process
    :type Process: Process
    """
    my_parser = argparse.ArgumentParser(description='''
    This is the script to insert versioned dataset to sql.
    You can also clean up sql table and deltalake with this script.
    Infrastructure should be provisioned in dataset_versioning/infra directroy.
    ''')
    my_parser.add_argument(
        '-c',
        '--clean',
        default=False,
        action='store_true',
        help='Truncate table and cleanup deltalake')
    my_parser.add_argument(
        '-v',
        '--version',
        action='store',
        type=int,
        help='Version of data to insert to sql')
    my_parser.add_argument(
        '-p',
        '--path',
        action='store',
        type=str,
        help='Path for the source csv file')
    my_parser.add_argument(
        '-k',
        '--keyvault',
        action='store',
        type=str,
        required=True,
        help='Uri of keyvault')
    args = my_parser.parse_args(args_input)

    if not args.clean:
        if args.version is None or args.path is None:
            my_parser.error('version and path are both required')
            raise SystemExit

    keyvault = KeyvaultWrapper(args.keyvault)
    sql = SqlWrapper(keyvault)

    if args.clean:
        sql.clean_up()
    else:
        df = read_csv(args.path)
        df = Process(df).filter_with_version(args.version)
        sql.insert_to_sql(df)


if __name__ == '__main__':
    main(KeyvaultWrapper, SqlWrapper, Process, sys.argv[1:])
