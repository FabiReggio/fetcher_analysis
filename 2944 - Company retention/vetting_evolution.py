from pathlib import Path
import sys
import pandas as pd
from datetime import datetime, date
from rsrc.functions import (
    read_query, qfile_to_df, datediff_to_seconds, seconds_to_hms
    , print_execution_time, setup_logging
    )

# Setting up logging
logger = setup_logging(name='vetting_evolution')
logger.info(f"NEW EXECUTION ON {datetime.now().strftime('%m-%d-%Y %H:%M:%S')}")

# Setting up connection
## getting get_connection method and config file
cwd = Path.cwd()
subdir_count = 0
while cwd.name != 'analytics-metabase':
    cwd = cwd.parent
    subdir_count += 1

subdir_append = '../' * subdir_count
subdir_config = '../' * (subdir_count + 1)
sys.path.append(subdir_append)
from db import get_connection
CONFIG_PATH = [f"{subdir_config}config.ini"]

## connection
cnx = get_connection(CONFIG_PATH, 'DEV')

# Getting list of company IDs
with open('rsrc/excluded_companies_ids.txt', 'r') as comp_list:
    excluded_companies = tuple(int(line.strip()) for line in comp_list)

# Setting files paths
queries_path = 'rsrc/queries/{filename}.sql'
csv_rsrc_path = 'rsrc/csv/{filename}.csv'
csv_output_path = 'output/csv/{output_name}.csv'

# Execution time tracking
execution_start = execution_middle = datetime.today()

"""
    CANDIDATES VETTING TIME EVOLUTION
"""
mssg = 'Start gathering vetting raw data'
logger.info(mssg)
print(mssg, '-'*30)

vetting_info = qfile_to_df(
    queries_path.format(filename='candidate_vetting')
    , cnx
    , index_col='company_id'
    )

# Execution time tracking
mssg = 'Done with vetting raw data in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f"""{mssg} {seconds_to_hms(seconds)}
Dataframe rows: {vetting_info.shape[0]}
Companies count: {vetting_info.index.unique().shape[0]}
"""
logger.info(mssg)
execution_middle = datetime.today()

# Manipulating data
vetting_info['vetting_date'] = pd.to_datetime(vetting_info['vetting_date'])
min_date = vetting_info.groupby('company_id').agg(first_date=('vetting_date', 'min'))
vetting_info = vetting_info.merge(
        min_date
        , how='left'
        , left_index=True
        , right_index=True
    )

vetting_info['vetting_date'] = vetting_info['vetting_date'].dt.normalize()
vetting_info['first_date'] = vetting_info['first_date'].dt.normalize()

vetting_info['days_from_start'] = (
    vetting_info['vetting_date']
    - vetting_info['first_date']
    ).dt.days

"""
    Getting customer loyalty
"""
# Getting raw data
source_file = csv_rsrc_path.format(filename='comp_scoring')
comp_loyalty = pd.read_csv(source_file, index_col='company_id')

vetting_info = vetting_info.merge(
    comp_loyalty['loyalty']
    , how='left'
    , on='company_id'
    )

# Execution time tracking
mssg = 'Done with manipulating data in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f'{mssg} {seconds_to_hms(seconds)}'
logger.info(mssg)
execution_middle = datetime.today()


# Exporting to csv
saving_path = csv_output_path.format(output_name='vetting_raw')
vetting_info.to_csv(saving_path)
mssg = f'Vetting raw data saved in {saving_path}'
logger.info(mssg)
print(mssg)


"""
    CUMULATING VETTING DATA
"""

variables = [
    'company_id'
    , 'company_name'
    , 'vetting_date'
    ]

df_cum = vetting_info.reset_index().groupby(
        by=variables
        , as_index=False
    )\
    .agg(
        vetted=('vetting_flag', 'sum')
    )

# Vetted cumulate
df_vetted = pd.concat(
    [
        df_cum.drop('vetted', axis=1)
        , (
            df_cum.groupby(by=variables[:-1] , as_index=False)\
                .expanding()\
                .agg('sum')\
                .reset_index()
        )['vetted']
    ]
    , axis=1
    )

# Unvetted cumulate
df_unvetted = vetting_info.loc[vetting_info.vetting_flag == 0]\
    .reset_index()\
    .groupby(
        by=variables
        , as_index=False
    )\
    .agg(
        unvetted=('vetting_flag', 'count')
    )

df_unvetted = pd.concat(
    [
        df_unvetted.drop('unvetted', axis=1)
        , (
            df_unvetted.groupby(by=variables[:-1] , as_index=False)\
                .expanding()\
                .agg('sum')\
                .reset_index()
        )['unvetted']
    ]
    , axis=1
    )

# Replace vetted and merge with unvetted
df_cum['vetted'] = df_vetted['vetted']
df_cum = df_cum.merge(
    df_unvetted
    , on=variables
    , how='outer'
    )

# Fill NaN
for cid in df_cum.company_id.unique():
    df_cum.loc[df_cum.company_id == cid, 'unvetted'] = df_cum.loc[df_cum.company_id == cid, 'unvetted'].fillna(method='ffill')

df_cum['vetted'] = df_cum.fillna(0)['vetted']
df_cum['unvetted'] = df_cum.fillna(0)['unvetted']

# Create final columns and metrics
df_cum['total_leads'] = df_cum['vetted'] + df_cum['unvetted']
df_cum['vetting_rate'] = df_cum['vetted'] / df_cum['total_leads']

df_cum.set_index('company_id', inplace=True)

# Add first_date column
df_cum = df_cum.merge(
    min_date
    , how='left'
    , on='company_id'
    )
# Compute days_from_start
df_cum['days_from_start'] = (
    df_cum['vetting_date']
    - df_cum['first_date']
    ).dt.days

# Add loyalty column
df_cum = df_cum.merge(
    comp_loyalty['loyalty']
    , how='left'
    , on='company_id'
    )

# Execution time tracking
mssg = 'Done with vetting evolution data in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f"""{mssg} {seconds_to_hms(seconds)}
Dataframe rows: {df_cum.shape[0]}
Companies count: {df_cum.index.unique().shape[0]}
"""
logger.info(mssg)
execution_middle = datetime.today()


# Exporting to csv
saving_path = csv_output_path.format(output_name='vetting evolution')
df_cum.to_csv(saving_path)
mssg = f'Vetting evolution data saved in {saving_path}'
logger.info(mssg)
print(mssg)
    