import numpy as np
import pandas as pd
import logging
from pathlib import Path

def read_query(query_file: str, filter_values: str = None):
    with open(query_file, 'r') as file:
        if not filter_values:
            filter_flag = '--'
        else:
            filter_flag = ''
        return file.read().format(
            filter_flag=filter_flag
            , filter_values=filter_values
        )

def qfile_to_df(query_path, connection, **kwargs):
    query = read_query(query_path)
    df = pd.read_sql(query, connection, **kwargs)
    return df

def chances_mssg(chances: int):
    if chances == 1:
        mssg = f'{chances} chance left'
    else:
        mssg = f'{chances} chances left'
    return mssg

def compute_scoring(x, columns_list):
    weight = 1/len(columns_list)
    row_value = weight * sum([x[col] for col in columns_list])
    return row_value

def rearrange_values(df_raw, columns_list=None, new_range=[0, 1]):
    df = df_raw.copy()
    
    if not columns_list:
        columns_list = df.select_dtypes(np.number).columns.tolist()
    else:
        pass
    
    max_values_list = [df[column].max() for column in columns_list]
    min_values_list = [df[column].min() for column in columns_list]
    new_min = min(new_range)
    new_max = max(new_range)
    new_values_range = new_max - new_min
    for col, current_max, current_min in zip(columns_list , max_values_list , min_values_list):
        df[col] = df[col].apply(
            lambda x: (
                    (x - current_min) / (current_max - current_min)
                ) * new_values_range + new_min
        )
    return df

def add_churn_column(df, churn_year):
    query_filename = 'rsrc/queries/churned_companies.sql'
    
    with open(query_filename, 'r') as file:
        query = file.read().format(
            filter_flag=''
            , filter_values=tuple(df.index.to_list())
            , churn_year=churn_year)
    churned = pd.read_sql(query, cnx, index_col='company_id')
    churned_list = tuple(churned.index.to_list())
    
    df[f'churned_{churn_year}'] = False
    df.loc[df.index.isin(churned_list), f'churned_{churn_year}'] = True

def split_date(df, date_field, prefix=''):
    df_new = df.copy()
    prefix = prefix + '_' if prefix else prefix
    df_new[prefix + 'year'] = pd.to_datetime(df_new[date_field]).dt.year
    df_new[prefix + 'month'] = pd.to_datetime(df_new[date_field]).dt.month
    df_new[prefix + 'day'] = pd.to_datetime(df_new[date_field]).dt.day
    return df_new

def seconds_to_hms(seconds):
    hours = seconds//3600
    minutes =  int(((seconds/3600) - hours) * 60)
    seconds = seconds - (hours * 3600 + minutes * 60)
    hms_dict = {'hours': hours, 'minutes': minutes, 'seconds': seconds}
    return hms_dict

def datediff_to_seconds(date1, date2):
    max_date = max(date1, date2)
    min_date = min(date1, date2)
    seconds = (max_date - min_date).seconds
    return seconds

def print_execution_time(date1, date2, message):
    seconds = datediff_to_seconds(date1, date2)
    print('' , f'{message} {seconds_to_hms(seconds)}', sep='\n')

def setup_logging(name, level=logging.INFO, fmt="%(asctime)s: %(message)s"):
    Path('logs').mkdir(parents = True, exist_ok = True)
    log_fn = f'logs/{name}.log'
    handler = logging.FileHandler(str(Path(log_fn).resolve()))
    formatter = logging.Formatter(
        fmt
        , datefmt='%m-%d-%Y %H:%M:%S UTC%z'
        )
    handler.setFormatter(formatter)

    logger = logging.getLogger(name)
    logger.setLevel(level)
    logger.addHandler(handler)

    return logger
