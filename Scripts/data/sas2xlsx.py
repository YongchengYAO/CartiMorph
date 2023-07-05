import pandas as pd
import argparse

# create argument parser
parser = argparse.ArgumentParser()
parser.add_argument('--sas', type=str, help='path to .sas7dat file')
parser.add_argument('--xlsx', type=str, help='path to output .xlsx file')
args, unknown = parser.parse_known_args()

# read .sas7dat file using pandas
data = pd.read_sas(args.sas)

# decode byte strings to regular strings
data = data.applymap(lambda x: x.decode() if isinstance(x, bytes) else x)

# write data to .xlsx file
data.to_excel(args.xlsx, index=False)