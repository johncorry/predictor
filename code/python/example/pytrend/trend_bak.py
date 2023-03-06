#!/usr/bin/python

print ("Test")

import pandas as pd
from pytrends.request import TrendReq
pytrend = TrendReq(hl='en-US', tz=360)
keywords = ['Python', 'R']
pytrend.build_payload(
     kw_list=keywords,
     cat=0,
     timeframe='today 3-m',
     geo='TW',
     gprop='')
data = pytrend.interest_over_time()
data= data.drop(labels=['isPartial'],axis='columns')
image = data.plot(title = 'Python V.S. R in last 3 months on Google Trends ')
fig = image.get_figure()
fig.savefig('figure.png')
data.to_csv('Py_VS_R.csv', encoding='utf_8_sig')
