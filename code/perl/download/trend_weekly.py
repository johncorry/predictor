#!/usr/bin/python

from pytrends.request import TrendReq
import pandas as pd
import numpy as np
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("trend_str")
args = parser.parse_args()
#print(">" , args.trend_str , "<")

pytrend = TrendReq()
keywords = [args.trend_str]

#print(keywords)

pytrend.build_payload(
     kw_list=keywords,
     cat=7,
     #timeframe='2019-07-03 2020-07-03',
     timeframe='today 5-y',
     #timeframe='all',
     #timeframe='today 3-m',
     geo='AU',
     gprop='')

data = pytrend.interest_over_time()
#print(data)

#for col in data.columns: 
#    print(col) 

for date in data.index:
    print(date,  data.loc[date, args.trend_str], data.loc[date, "isPartial"])

