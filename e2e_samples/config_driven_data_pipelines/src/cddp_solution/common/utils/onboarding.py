import json
import os


def output(config):
    current_dir_path = os.path.dirname(os.path.realpath(__file__))
    fileDirectory = os.path.dirname(current_dir_path)
    dir_path = os.path.join(fileDirectory, 'customers')

    with open(dir_path+"/"+config["customer_id"]+".json", 'w') as f:
        f.write(json.dumps(config, sort_keys=True))


def customer_1():

    master_data_source = ["""ID,Fruit,Color,Price
1,Red Grape,Red, 2.0
2,Peach,Yellow,3.0
3,Orange,Orange, 2.0
4,Green Apple,Green, 3.0
5,Fiji Apple,Red, 3.5
6,Banana,Yellow, 1.0
7,Green Grape, Green,2.0"""]

    master_data_transform_sql = ["""
    SELECT ID,Fruit, Price FROM INPUT_DATA_VIEW
    """]

    event_data_source = "eventhubs.connectionString"

    master_data_table_names = ["fruits"]
    event_data_table_names = ["fruits_events"]
    curated_data_table_names = ["fruits_sales"]

    event_data_transform_sql = ["""
    select m.ID, m.Fruit, m.Price, e.amount, e.ts from events e
    left outer join fruits m
    ON e.id=m.ID
    and m.row_active_start_ts<=e.ts
    and m.row_active_end_ts>e.ts
    """]

    event_data_curation_sql = ["""
    select m.ID, m.Fruit, count(m.ID) as sales_count, sum(m.Price*m.amount) as sales_total from fruits_events m
    group by m.ID, m.Fruit
    """]

    return {
        "customer_id": "customer_1",
        "master_data_storage_path": "master_data_storage",
        "event_data_storage_path": "event_data_storage",
        "serving_data_storage_path": "serving_data_storage",
        "master_data_source": master_data_source,
        "master_data_transform_sql": master_data_transform_sql,
        "master_data_table_names": master_data_table_names,
        "event_data_source": event_data_source,
        "event_data_transform_sql": event_data_transform_sql,
        "event_data_table_names": event_data_table_names,
        "event_data_curation_sql": event_data_curation_sql,
        "curated_data_table_names": curated_data_table_names
    }


def customer_2():

    master_data_source = ["""ID,shuiguo,yanse,jiage
1,Red Grape,Red, 2.5
2,Peach,Yellow,3.5
3,Orange,Orange, 2.3
4,Green Apple,Green, 3.5
5,Fiji Apple,Red, 3.4
6,Banana,Yellow, 1.2
7,Green Grape, Green,2.2"""]

    master_data_transform_sql = ["""
    SELECT ID, shuiguo as Fruit, jiage as Price FROM INPUT_DATA_VIEW
    """]

    event_data_source = "eventhubs.connectionString"

    master_data_table_names = ["fruits"]
    event_data_table_names = ["fruits_events"]
    curated_data_table_names = ["fruits_sales"]

    event_data_transform_sql = ["""
    select m.ID, m.Fruit, m.Price, e.amount, e.ts from events e
    left outer join fruits m
    ON e.id=m.ID
    and m.row_active_start_ts<=e.ts
    and m.row_active_end_ts>e.ts
    """]

    event_data_curation_sql = ["""
    select m.ID, m.Fruit, count(m.ID) as sales_count, sum(m.Price*m.amount) as sales_total from fruits_events m
    group by m.ID, m.Fruit
    """]

    return {
        "customer_id": "customer_2",
        "master_data_storage_path": "master_data_storage",
        "event_data_storage_path": "event_data_storage",
        "serving_data_storage_path": "serving_data_storage",
        "master_data_source": master_data_source,
        "master_data_transform_sql": master_data_transform_sql,
        "master_data_table_names": master_data_table_names,
        "event_data_source": event_data_source,
        "event_data_transform_sql": event_data_transform_sql,
        "event_data_table_names": event_data_table_names,
        "event_data_curation_sql": event_data_curation_sql,
        "curated_data_table_names": curated_data_table_names
    }


output(customer_1())
output(customer_2())
