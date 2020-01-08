#!/usr/bin/python


import wget

print('Beginning file download with wget module')

url = 'http://www.fanfooty.com.au/resource/draw.php'  
wget.download(url, 'AFL_Results.dat')  
