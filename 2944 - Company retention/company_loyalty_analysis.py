from pathlib import Path
import sys
from math import floor
import pandas as pd
from datetime import datetime, date
from rsrc.functions import (read_query, chances_mssg, compute_scoring
    , rearrange_values, add_churn_column, datediff_to_seconds, seconds_to_hms
    , print_execution_time, setup_logging
    )


# Setting up logging
logger = setup_logging(name='company_retention')
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

# Setting amount of companies to focus on
try:
    n = int(sys.argv[1])
except IndexError:
    n = 50
finally:
    print('\n', f'n: {n}')

# Getting list of company IDs
with open('rsrc/excluded_companies_ids.txt', 'r') as comp_list:
    excluded_companies = tuple(int(line.strip()) for line in comp_list)

with open('rsrc/company_id_list.txt', 'r') as comp_list:
    companies_list = comp_list.read()\
        .replace('(', '')\
        .replace(')', '')\
        .split(',')
    companies_list = tuple(
        int(c) for c in companies_list if int(c) not in excluded_companies
        )

queries_path = 'rsrc/queries/{filename}.sql'
csv_output_path = 'output/csv/{output_name}.csv'
csv_rsrc_path = 'rsrc/csv/{filename}.csv'

# Getting companies with active contracts
query_filename = 'active_contracts'
query = read_query(
    queries_path.format(filename=query_filename)
    )
active_contracts_cies = tuple(
    pd.read_sql(query, cnx).company_id.to_list()
    )

# Template for companies info
query_filename = 'template_companies_in'
with open(queries_path.format(filename=query_filename), 'r') as query_file:
    query_template = query_file.read()

# Execution time tracking
execution_start = execution_middle = datetime.today()

"""
    CONTRACTS APPROACH
"""

print('\n')
mssg = 'Start contracts approach'
logger.info(mssg)
print('-'*30, mssg, '-'*30)

# Getting raw data
query_filename = 'company_loyalty_stats_contracts_approach'
query = read_query(
    queries_path.format(filename=query_filename)
    # , companies_list
    )

contracts_info = pd.read_sql(query, cnx, index_col='company_id')

# Saving contract raw data into dictionary
df_dict = {
    'contracts_info': {
        'query': query
        , 'Dataframe': contracts_info
    }
}

# Filtering
df_contracts = contracts_info.loc[
    contracts_info.index.isin(companies_list)
    ].copy()
df_contracts = df_contracts[df_contracts.avg_contract_price > 0]

# Filtering companies with at least 6 months using fetcher
df_contracts = df_contracts.loc[df_contracts.days_in_fetcher > 180]

# Creating loyalty field
df_contracts['loyalty'] = 'Most loyal company'
df_contracts.loc[
    df_contracts['days_in_fetcher'] <= df_contracts.days_in_fetcher.mean()
    , 'loyalty'
] = 'Least loyal company'

# Creating active_contract_flag field
df_contracts['active_contract_flag'] = False
df_contracts.loc[
    df_contracts.index.isin(active_contracts_cies)
    , 'active_contract_flag'
] = True

# Saving into dictionary
df_dict.update({
    'contracts_approach': {
        'query': None
        , 'Dataframe': df_contracts
        , 'top_companies': (top_ids_ca := tuple(
                    df_contracts.nlargest(n, 'days_in_fetcher').index.to_list()
                    ))
        , 'bottom_companies': (bottom_ids_ca := tuple(
                    df_contracts.nsmallest(n, 'days_in_fetcher').index.to_list()
                    ))
        }
    })

# saving non revenue companies
df_cust_no_rv = contracts_info[contracts_info.avg_contract_price == 0].copy()

mssg = f'Top {n} loyal companies:\n{top_ids_ca}'
logger.info(mssg)
print(mssg, sep='\n')
mssg = f'Bottom {n} loyal companies:\n{top_ids_ca}'
logger.info(mssg)
print(mssg, sep='\n')

# Execution time tracking
mssg = 'Finished in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f'{mssg} {seconds_to_hms(seconds)}'
logger.info(mssg)
execution_middle = datetime.today()

"""
    COMPANY EVENTS APPROACH
"""
print('\n')
mssg = 'Start events approach'
logger.info(mssg)
print('-'*30, mssg, '-'*30)

# Getting raw data
query_filename = 'company_loyalty_stats_events_approach'
query = read_query(
    queries_path.format(filename=query_filename)
    # , companies_list
    )

events_info = pd.read_sql(query, cnx, index_col='company_id')

# Saving events raw data into dictionary
df_dict.update({
    'events_info': {
        'query': query
        , 'Dataframe': events_info
        }
    })


# Filtering
df_events = events_info.loc[
    events_info.index.isin(companies_list)
    ].copy()
# Filtering companies with at least 6 months using fetcher
df_events = df_events.loc[df_events.days_in_fetcher > 180]

# Creating loyalty field
df_events['loyalty'] = 'Most loyal company'
df_events.loc[
    df_events['days_in_fetcher'] <= df_events.days_in_fetcher.mean()
    , 'loyalty'
] = 'Least loyal company'

# Creating active_contract_flag field
df_events['active_contract_flag'] = False
df_events.loc[
    df_events.index.isin(active_contracts_cies)
    , 'active_contract_flag'
] = True

# Saving into dictionary
df_dict.update({
    'events_approach': {
        'query': None
        , 'Dataframe': df_events
        , 'top_companies': (top_ids_ea := tuple(
                    df_events.nlargest(n, 'days_in_fetcher').index.to_list()
                    ))
        , 'bottom_companies': (bottom_ids_ea := tuple(
                    df_events.nsmallest(n, 'days_in_fetcher').index.to_list()
                    ))
        }
    })

mssg = f'Top {n} loyal companies:\n{top_ids_ea}'
logger.info(mssg)
print(mssg, sep='\n')
mssg = f'Bottom {n} loyal companies:\n{top_ids_ea}'
logger.info(mssg)
print(mssg, sep='\n')

# Execution time tracking
mssg = 'Finished in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f'{mssg} {seconds_to_hms(seconds)}'
logger.info(mssg)
execution_middle = datetime.today()

"""
    GETTING ADDITIONAL DATA
"""
print('\n')
mssg = 'Getting additional data'
logger.info(mssg)
print('-'*30, mssg, '-'*30)

"""
    usage stats
"""
# Getting usage raw data
query_filename = 'company_usage_stats'
query = read_query(
    queries_path.format(filename=query_filename)
    # , sel_ids
    )

usage_info = pd.read_sql(query, cnx, index_col='company_id')
usage_info['vetted_rate'] = 1-usage_info.loc[:, 'unvetted_rate']

# Saving raw data frame into dictionary
df_dict.update({
    'usage_info': {
        'query': query
        , 'Dataframe': usage_info
    }
})

# Execution time tracking
mssg = 'Done with usage data in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f'{mssg} {seconds_to_hms(seconds)}'
logger.info(mssg)
execution_middle = datetime.today()


"""
    days until first event data
"""

query_filename = 'company_days_until_first_event'
query = read_query(
    queries_path.format(filename=query_filename)
    )
df_days = pd.read_sql(query, cnx, index_col='company_id')

# Execution time tracking
mssg = 'Done with days until first event data in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f'{mssg} {seconds_to_hms(seconds)}'
logger.info(mssg)
execution_middle = datetime.today()


"""
    seats usage data
"""

query_filename = 'company_seats_used_rate'
query = read_query(
    queries_path.format(filename=query_filename)
    )
df_seats = pd.read_sql(query, cnx, index_col='company_id')

# Execution time tracking
mssg = 'Done with seats usage data in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f'{mssg} {seconds_to_hms(seconds)}'
logger.info(mssg)
execution_middle = datetime.today()


"""
    ats sync data
"""

query_filename = 'company_ats_sync'
query = read_query(
    queries_path.format(filename=query_filename)
    )
ats_sync = pd.read_sql(query, cnx, index_col='company_id')

# Execution time tracking
mssg = 'Done with ATS syn data in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f'{mssg} {seconds_to_hms(seconds)}'
logger.info(mssg)
execution_middle = datetime.today()


"""
    churned companies
"""

churn_year = (datetime.today().year) - 1
query_filename = 'churned_companies'
with open(queries_path.format(filename=query_filename)) as file:
    query = file.read().format(
        filter_flag='-- '
        , filter_values=''
        , churn_year=churn_year)

churned = pd.read_sql(query, cnx, index_col='company_id')
churned_list = tuple(churned.index.to_list())

# Execution time tracking
mssg = 'Done with churn data in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f'{mssg} {seconds_to_hms(seconds)}'
logger.info(mssg)
execution_middle = datetime.today()


"""
    raw (unaggregated) contracts data
"""

query_filename = 'contracts_raw'
# companies_target = tuple(export.loc[export[churn_column_name]].index.to_list())
query = read_query(
    queries_path.format(filename=query_filename)
    # , companies_target
    )
contract_zoom = pd.read_sql(query, cnx, index_col='company_id')

contract_status = {
    0: 'EXPIRED'
    , 1: 'ACTIVE'
    , 2: 'COMPANY_REVOKED'
    , 3: 'INACTIVE'
    , 4: 'CANCELED'
}

contract_zoom.replace({'status': contract_status}, inplace=True)
# contract_zoom.to_excel('contract_zoom.xlsx')


# Execution time tracking
mssg = 'Done with raw contracts data in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f'{mssg} {seconds_to_hms(seconds)}'
logger.info(mssg)
execution_middle = datetime.today()


"""
    APPROACH SELECTION
"""
mssg = """
Which approach would you like to adopt?
\t1. Contracts approach
\t2. Events approach
Enter value: 
"""

# Selecting approach (contacts or events)
sel_approach = 2
"""
chances = 3
while chances > 0:
    sel_approach = input(mssg)
    try:
        sel_approach = int(sel_approach)
    except ValueError:
        sel_approach = None
    if sel_approach not in [1, 2]:
        chances -= 1
        print('\n',
            'Error! Select one of the provided values' if chances else ''
            , sep='')
        print(chances_mssg(chances), '\n'*2, sep='')
    else:
        break
"""

if sel_approach == 1:
    print('\n')
    mssg = 'Selected approach: Contracts'
    logger.info(mssg)
    print(mssg)
    top_ids = top_ids_ca
    bottom_ids = bottom_ids_ca
    sel_df = df_contracts
elif sel_approach == 2:
    print('\n')
    mssg = 'Selected approach: Events'
    logger.info(mssg)
    print(mssg)
    top_ids = top_ids_ea
    bottom_ids = bottom_ids_ea
    sel_df = df_events
else:
    top_ids = top_ids_ca
    bottom_ids = bottom_ids_ca
    sel_df = df_events
    print('\n')
    mssg = 'Events approach selected by default'
    logger.info(mssg)
    print(mssg)

sel_ids = (top_ids + bottom_ids)

"""
    MERGING ADDITIONAL DATA
"""

# Adding contracts data
sel_df = sel_df.merge(
    contracts_info
    , suffixes=('', 'ci')
    , left_index=True
    , right_index=True
    )

# Adding seats data
sel_df = sel_df.merge(
    df_seats['seats_used']
    , how='left'
    , on='company_id'
    )

# Adding days data
sel_df = sel_df.join(usage_info, rsuffix='_ui')

# Adding days data
sel_df = sel_df.merge(
    df_days
    , how='left'
    , on='company_id'
    )

# Adding days data
sel_df = sel_df.merge(
    df_seats['seats_used_rate']
    , how='left'
    , on='company_id'
    )

# Adding ats data
sel_df = sel_df.merge(
    ats_sync
    , how='left'
    , on='company_id'
    )

# Adding churn flag
churn_column_name = f'churned_{churn_year}'
sel_df[churn_column_name] = False
sel_df.loc[sel_df.index.isin(churned_list), churn_column_name] = True

"""
    SCORING
"""

# Getting overall price
sel_df['overall_price'] = sel_df['avg_contract_price'] * sel_df['contracts_count']

# Selecting variables to use for score
variables_for_score = [
    'days_in_fetcher'
    , 'overall_price'
    , 'emailed_rate'
    # , 'avg_contract_length_days'
    # , 'avg_contract_price'
    # , 'total_leads'
    # , 'vetted_rate'
]

sel_df['scoring'] = rearrange_values(sel_df, variables_for_score, [1, 5])\
    .apply(
        compute_scoring
        , axis=1
        , args=(variables_for_score,)
    )

# Filtering minimum contract price and leads per month
filtered = sel_df.loc[
    (sel_df['avg_contract_price'] > 500) \
    & (sel_df['managed_leads_paid_per_contract'] / sel_df['avg_contract_length_days'] * 30 > 80)
]


# Exporting
not_columns = ['seats_used_rate']
columns = [
          'company_name', 'days_in_fetcher', 'years_in_fetcher'
        , 'active_contract_flag', 'contracts_count', 'seats_paid_per_contract'
        , 'seats_used','managed_leads_paid_per_contract'
        , 'self_served_leads_paid_per_contract', 'avg_contract_price'
        , 'avg_contract_length_days', 'days_until_first_pos'
        , 'days_until_first_batch_sent', 'days_until_first_like'
        , 'days_until_first_email_sent', 'days_until_first_interested'
        , 'positions_count', 'batches_sent', 'total_leads'
    ] + [
        col for col in filtered.columns.to_list() if '_rate' in col
    ] + [
        col for col in filtered.columns.to_list() if 'churned_' in col
    ] + [
        'scoring'
    ]

columns = [col for col in columns if col not in not_columns]

top_n = filtered.nlargest(n, 'scoring')[columns]
top_n['loyalty'] = 'Most loyal company'
bottom_n = filtered.nsmallest(n, 'scoring')[columns]
bottom_n['loyalty'] = 'Least loyal company'

export = pd.concat(
    [
        top_n
        , bottom_n
    ]
)

# Exporting to csv
saving_path = csv_output_path.format(output_name='top_bottom_comp_scoring')
export.to_csv(saving_path)
mssg = f'Data frame saved in {saving_path}'
logger.info(mssg)
print(mssg)

# Execution time tracking
mssg = 'Done computing scoring in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f'{mssg} {seconds_to_hms(seconds)}'
logger.info(mssg)
execution_middle = datetime.today()


"""
    Generatting CSVs with company's loyalty
"""
mssg = "Generatting CSVs with company's loyalty for vetting evolution analysis"
logger.info(mssg)
print(mssg)

comp_scoring = events_info.merge(
        usage_info['emailed_rate']
        , how='left'
        , on='company_id'
    )\
    .merge(
        contracts_info[['avg_contract_price', 'contracts_count']]
        , how='left'
        , on='company_id'
    )

comp_scoring['overall_price'] = comp_scoring['avg_contract_price'] * comp_scoring['contracts_count']
comp_scoring = comp_scoring.loc[comp_scoring['days_in_fetcher'] != 0]

# Filling NaN in overall_price
comp_scoring = comp_scoring.copy()

bins_size = 100
dif_range = comp_scoring['days_in_fetcher'].max() - comp_scoring['days_in_fetcher'].min()
bins_amount = floor(dif_range / bins_size)

## creating days_in_fetcher bins
temp_variables = ['binned', 'overall_price_mean', 'left', 'right']
bin_name = temp_variables[0]
temp_var = temp_variables[1]
left_name = temp_variables[2]
right_name = temp_variables[3]
target_var = 'overall_price'

comp_scoring[bin_name] = pd.cut(comp_scoring['days_in_fetcher'], bins_amount)
## opening bins into its boundaries
comp_scoring[left_name] = comp_scoring[bin_name].apply(lambda x: x.left)
comp_scoring[right_name] = comp_scoring[bin_name].apply(lambda x: x.right)

## creating data frame with bins target variable mean
var_means = comp_scoring.groupby(bin_name).mean().loc[:, variables_for_score]
var_means.columns = [col + '_mean' for col in var_means.columns]
comp_scoring = comp_scoring.merge(
    var_means[temp_var]
    , how='left'
    , left_on=bin_name
    , right_index=True
    )

## filling null values with the temp variable
comp_scoring[target_var] = comp_scoring[target_var].fillna(comp_scoring[temp_var])

comp_scoring.drop(columns=temp_variables, inplace=True)

comp_scoring['scoring'] = rearrange_values(comp_scoring, variables_for_score, [1, 5])\
    .apply(
        compute_scoring
        , axis=1
        , args=(variables_for_score,)
    )

comp_scoring['loyalty'] = 'Most loyal company'
comp_scoring.loc[
    # comp_scoring['scoring'] <= comp_scoring['scoring'].describe().loc['75%']
    comp_scoring['scoring'] <= comp_scoring['scoring'].mean()
    , 'loyalty'
] = 'Least loyal company'


saving_path = csv_rsrc_path.format(filename='comp_scoring')
comp_scoring.to_csv(saving_path)
mssg = f"Company loyalty CSV saved into {saving_path}"
logger.info(mssg)
print(mssg)


# Execution time tracking
mssg = 'Done with company loyalty CSV in'
print_execution_time(datetime.today(), execution_middle, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_middle)
mssg = f'{mssg} {seconds_to_hms(seconds)}'
logger.info(mssg)
execution_middle = datetime.today()


"""
# ADDTIONAL METRICS
# Filtering
df_focus = usage_info.loc[usage_info.index.isin(sel_ids)].copy()
df_focus['company_ranking'] = f'Top {n} company'
df_focus.loc[
    df_focus.index.isin(bottom_ids)
    , 'company_ranking'
] = f'Bottom {n} company'

# Gathering additional data
df_final = df_focus.merge(
    sel_df[['days_in_fetcher', 'loyalty']]
    , how='left'
    , on='company_id'
    )

final_columns = [col for col in df_final.columns.to_list() if '_rate' in col]
final_columns.append('company_ranking')

# Calculating mean for every rate
summary_data = df_final[final_columns].groupby('company_ranking').mean()
"""

# Closing connection
cnx.close()

"""
    RUNNING VETTING EVOLUTION ANALYSIS
"""

print('\n')
exec(open('vetting_evolution.py').read())

# Execution time tracking
logger = setup_logging(name='company_retention')
mssg = 'Total execution time:'
print_execution_time(datetime.today(), execution_start, mssg)
seconds = datediff_to_seconds(datetime.today(), execution_start)
mssg = f'{mssg} {seconds_to_hms(seconds)}'
logger.info(mssg)
