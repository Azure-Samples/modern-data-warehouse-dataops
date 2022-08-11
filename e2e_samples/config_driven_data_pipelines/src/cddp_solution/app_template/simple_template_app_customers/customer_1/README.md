# {{ app_name }} - {{ customer_name }}

1. Master Data Ingestion

```shell
cd src
python -m cddp_solution.common.master_data_ingestion_runner {{ app_name }} {{ customer_name }}
```

2. Master Data Transformation

```shell
cd src
python -m cddp_solution.common.master_data_transformation_runner {{ app_name }} {{ customer_name }}
```

3. Event Data Transformation

```shell
cd src
python -m cddp_solution.common.event_data_transformation_runner {{ app_name }} {{ customer_name }}
```

4. Master Data Curation

```shell
cd src
python -m cddp_solution.common.master_data_curation_runner {{ app_name }} {{ customer_name }}
```

5. Event Data Curation

```shell
cd src
python -m cddp_solution.common.event_data_curation_runner {{ app_name }} {{ customer_name }}
```
