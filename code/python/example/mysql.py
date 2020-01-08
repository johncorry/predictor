#!/usr/bin/python

import mysql.connector

print('Beginning to connect to the DB with mysql.connector')

#cour $Location = "dbi:mysql:PriceData:datastore.c6lgnooprssz.ap-southeast-2.rds.amazonaws.com";

config = {
  'user': 'jcorry',
  'password': 'iona22',
  'host': 'datastore.c6lgnooprssz.ap-southeast-2.rds.amazonaws.com',
  'database': 'AFLData',
  'raise_on_warnings': True
}

cnx = mysql.connector.connect(**config)

cnx.close()
