from mysql.connector import connection # mysql-connector-python
import pandas as pd
from dython.nominal import ( # dython
    cramers_v as cv
    )
from pathlib import Path
from datetime import datetime
import sys

# Setting up connection
## getting get_connection method and config file
subdir_count = 3
subdir_append = '../' * subdir_count
subdir_config = '../' * (subdir_count + 1)
sys.path.append(subdir_append)
from db import get_connection
CONFIG_PATH = [f"{subdir_config}config.ini"]
## connection
cnx = get_connection(CONFIG_PATH, 'DEV')


query = open('queries/unaggregated_query.sql').read()
print('Running query...', '\n')
df = pd.read_sql(query, con=cnx)
# persist on csv
str_date = datetime.today().strftime('%Y-%m-%d')
str_time = datetime.today().strftime('%H%M%S')
filepath_csv = f'csv/{str_date}'
path_csv = Path(filepath_csv)
path_csv.mkdir(parents=True, exist_ok=True)
filename = f'{str(path_csv)}/unaggregated_results_{str_time}.csv'
df.to_csv(filename, index=False, sep=';')


print('Data frame sample:', '\n')
print(df.head(), '\n'*2)

print('-'*80)
print("Pearson's correlation coefficient for numerical features:", '\n')
print(df.corr('pearson').interest_flag, '\n'*2)

target_var = 'interest_flag'
columns = df.columns.tolist()
columns.remove(target_var)

print('-'*80)
print("Categorical features analysis by Cramers V coefficient:", '\n')
categorical_features = df.select_dtypes(include=['object']).columns.tolist()
for c in categorical_features:
    print(f"{c} Cramer's V: ", cv(df[c], df[target_var]))

# Analysing each feature separately

cols_to_analyze = [
    'remote_work'
    , 'visa_sponsorship'
    , 'relocation'
    , 'company_name'
    , 'company_age'
    , 'company_size_range'
    , 'location'
    , 'industry'
    ]

final_var = 'interest_rate'

for c in cols_to_analyze:
    # middle ground data frames
    df_raw = df[[c, target_var]]
    df_count = df_raw.groupby(c).count()
    df_sum = df_raw.groupby(c).sum()
    # ultimate data frame
    df_final = pd.concat([(df_sum / df_count), df_count], axis=1)
    df_final.columns = [final_var, 'count']
    df_final.sort_values(final_var, ascending=False)
    # persist on csv
    filename = f'{str(path_csv)}/{final_var}_by_{c}_{str_time}.csv'
    df_final.to_csv(filename, sep=';')

to_from_company_query = open('queries/to_from_company_query.sql').read()
df_companies = pd.read_sql(to_from_company_query, con=cnx)

filename = f'{str(path_csv)}/to_from_company_{str_time}.csv'
df_companies.to_csv(filename, index=False, sep=';')