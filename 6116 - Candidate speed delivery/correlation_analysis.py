from pathlib import Path
import sys
import pandas as pd
from dython.nominal import ( # dython
    cramers_v as cv
    )


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

# getting query and data frame
with open('position_speed_delivery.sql') as f:
    query = f.read()

query = query.replace('{{', '{').replace('}}', '}')

Nth_candidate = 50
days_until = f'days_until_{Nth_candidate}th_candidate'
n_days = 30
x_var = ['candidates_per_week', 'days_until_50th_candidate']
target_var = ['interested_count', 'hires_count']

df = pd.read_sql(
    query.format(
        Nth_candidate=Nth_candidate
        , company_id=1
        )
    , cnx
    )

# Mean dataset
df_mean = df.groupby(by=[days_until]).mean()
df_mean.reset_index(inplace=True)
# Median dataset
df_median = df.groupby(by=[days_until]).median()
df_median.reset_index(inplace=True)


for curr_df in [df_mean, df_median]:
    print('Looking for lineal correlation')
    # Looking for lineal correlation
    curr_df[[
        days_until
        , 'candidates_per_week'
        , 'interested_count'
        , 'hires_count'
        ]].corr('pearson').loc[
            [ #rows
                'days_until_50th_candidate'
                , 'candidates_per_week'
            ]
            , [ # columns
                'interested_count'
                , 'hires_count'
            ]
        ]
    print('Looking for non-lineal correlation')
    print('\tFor all the dataset')
    # Looking for non-lineal correlation
    # categorical_features = df_mean.select_dtypes(include=['object']).columns.tolist()
    for x in x_var:
    for x in x_var:
        for t in target_var:
            print(f"{x}-{t} Cramer's V: ", cv(curr_df[x], curr_df[t], bias_correction=False))
    print(f'\tFor first {n_days} days')
    curr_df_n_days = curr_df.query(f'{days_until} <= {n_days}')
    for x in x_var:
        for t in target_var:
            print(f"{x}-{t} Cramer's V: ", cv(curr_df_n_days[x], curr_df_n_days[t], bias_correction=False))