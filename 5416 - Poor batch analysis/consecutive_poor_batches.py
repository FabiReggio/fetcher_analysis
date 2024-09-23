from pathlib import Path
import sys
import pandas as pd
from datetime import datetime, timedelta
from email import encoders
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
import smtplib
import json
from time import sleep
import subprocess

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
with open('vpn_config.txt') as f:
    conn_cmd = str(f.readline().strip())
    disconn_cmd = str(f.readline().strip())

subprocess.call(conn_cmd)
sleep(10)
cnx = get_connection(CONFIG_PATH, 'DEV')

df_raw = pd.read_sql(
    open('batches_dislike_rates.sql').read()
    , cnx
    )
cnx.close()
subprocess.call(disconn_cmd)

# Working with copy DataFrame
df = df_raw.copy()
df['poor_batch'] = False
df.loc[
    df.dislike_rate > 0.5
    , 'poor_batch'
] = True

# Building consecutive poor batches column
df = pd.concat(
    [
        df
        , (
            df['poor_batch']
            * (pd.concat(
                [
                    (df['poor_batch'] != df['poor_batch'].shift()).cumsum()
                    , df['position_id']
                ]
                , axis=1
            ).groupby(['position_id', 'poor_batch']).cumcount() + 1 
            )
        ).rename('consecutive_poor')
    ]
    , axis=1
)

# 1st_poor_batch column
df['1st_poor_batch'] = None
df.loc[
    df.consecutive_poor == 1
    , '1st_poor_batch'
] = df['dislike_rate']
# 2nd_poor_batch column
df['2nd_poor_batch'] = None
df.loc[
    df.consecutive_poor == 2
    , '2nd_poor_batch'
] = df['dislike_rate']
# 3rd_poor_batch column
df['3rd_poor_batch'] = None
df.loc[
    df.consecutive_poor == 3
    , '3rd_poor_batch'
] = df['dislike_rate']

# resolve_batch column
df['resolved_batch'] = ~df['poor_batch']

# Dropping useless columns
drop_columns = [
    'caliber_id'
    , 'candidate_count'
    , 'dislike_count'
    , 'dislike_rate'
    , 'poor_batch'
]

df.drop(
    columns=drop_columns
    , inplace=True
    )

# Saving to CSV
month = (datetime.today() - timedelta(weeks=3)).strftime('%B %Y').lower()
filename = f'poor_consecutive_batches_{month.replace(" ", "_")}.csv'
if df.empty: raise Exception('Pandas resulting data frame is empty')
df.to_csv(filename, index=None, header=True)

# Sending email
## connect to server
with open('credentials.json', 'r') as file:
    credentials = json.load(file)

username = credentials['user']
password = credentials['password']
server = smtplib.SMTP('smtp.gmail.com:587')
server.ehlo()
server.starttls()
server.login(username, password)

## preparing email
msg = MIMEMultipart()
with open('email_config.json') as j:
    email_config = json.load(j)

msg['From'] = email_config['from']
recipients = email_config['recipients']
msg['To'] = ", ".join(recipients)
msg['Subject'] = email_config['subject'].format(month = month.capitalize())
email_body = email_config['body'].format(month = month.capitalize())

msg.attach(MIMEText(email_body, 'plain'))
maintype = 'application'
subtype = 'vnd.ms-excel'

with open(filename, 'rb') as fp:
    attachment = MIMEBase(maintype, subtype)
    attachment.set_payload(fp.read())
    encoders.encode_base64(attachment)

attachment.add_header("Content-Disposition", "attachment", filename=filename)
msg.attach(attachment)

## sending email and closing server
print(f"Sending email to {msg['To']}")
try:
    response = not server.sendmail(msg['From'], recipients , msg.as_string())
    print(f"Email '{msg['Subject']}' sent to {msg['To']} from {msg['From']}")
except Exception as e:
    print(e)
finally:
    server.quit()