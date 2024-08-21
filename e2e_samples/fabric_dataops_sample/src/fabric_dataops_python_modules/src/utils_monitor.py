def query_app_insights(
    log_workspace_id: str, query: str, timedelta_in_mins: Optional[int] = 15
) -> Union[None, int]:
    # time delta ensures we are only looking in to data from past few mins specified
    try:
        response = client.query_workspace(
            log_workspace_id, query, timespan=timedelta(minutes=timedelta_in_mins)
        )
        if response.status == LogsQueryStatus.SUCCESS:
            data = response.tables
            # print(data[0].rows)
            count = data[0].rows[0][0]
            column_names = data[0].columns
        else:
            # LogsQueryPartialResult - handle error here
            error = response.partial_error
            data = response.partial_data
            count = None
            print(error)

    except HttpResponseError as err:
        print("something fatal happened")
        print(err)
    else:
        return count