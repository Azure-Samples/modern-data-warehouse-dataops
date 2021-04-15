# DataOps - Dataset versioning demo
This sample demonstrates how data pipeline copy versioned data into Data Lake.

# Story
Contoso provides ML based loan prediction feature to end users. For keeping end-user experience, they want to keep updateing ML model with latest data. It helps Contoso to keep end user satisfaction high and subscription-based contract.

For achieving it, data scientists (DS) asks data engineers to save multiple-version data (ex. v0 data is saved in 2020, v1 data is saved in 2021). It helps DS to manage data and trained model. For saving cost, data engineers want to copy data with shorter duration.

# Solution overview
The solution support to achieve requirements described above.
- Data Pipeline (Azure Data Factory) copy **versioned data** from source to sink
- DS can read versioned data from Data Bricks. They can specify version number when they load data from Delta Lake.
- Data pipeline utilize watermark to see new/updated data in the data soruce. It helps to **copy data with shorter duration**.
- Terraform helps enginners to provision expected infrastructure.
- Local python script inject data to data source (SQL Database) incrementally, so that you can simulate data source update(ex. you can inject 2020 data at first, then inject 2021 data to data source).

![architecture](./docs/images/architecture.PNG)

## Data we uses
We refers [LendingClub issued Loans](https://www.kaggle.com/husainsb/lendingclub-issued-loans?select=lc_loan.csv) data hosted by Kaggle. We utilize it because popular data helps our end users to catch up this sample.

## How to use the sample
1. Sign-up to  [Kaggle](https://www.kaggle.com/)
1. If you agree Kaggle terms of use, please download (LendingClub issued Loans)[https://www.kaggle.com/husainsb/lendingclub-issued-loans?select=lc_loan.csv] data
<Will update based on demo discussion>