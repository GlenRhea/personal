from os import getenv
import pymssql
import sys
from datetime import datetime
from time import strptime
import os.path
import re
p = re.compile('^[A-Z][a-z]*\s*[0-9]*\s[0-9]*:[0-9]*:[0-9]*\s')

#conn = pymssql.connect(server, user, password, "tempdb")
conn = pymssql.connect(host='server', user='user', password='password', database='db')
cursor = conn.cursor()
#create table
#cursor.execute("""
#IF OBJECT_ID('syslogs', 'U') IS NOT NULL
#    DROP TABLE syslogs
#CREATE TABLE syslogs (
#    entryid int,
#    entrydate date NOT NULL,
#    host VARCHAR(150),
#    message VARCHAR(100),
#    PRIMARY KEY(entryid)
#)
#""")

#check the args
if len(sys.argv) == 2:
	if os.path.isfile(sys.argv[1]):
		f=open(sys.argv[1],'r')
	else:
		print "The input file doesn't exist!"
		exit(1)
else:
	print "Usage: " + sys.argv[0] + " pathtofile"
	exit(1)

space = " "

#load the data
try:
	for line in f.readlines():
		#print line
		if p.match(line):
			splitline = line.split()
			entrydate = str(strptime(splitline[0],'%b').tm_mon) + "/" + splitline[1] + "/" + str(datetime.now().year) + " " + splitline[2]
			#print entrydate
			host = splitline[3]
			#print host
			message = space.join(splitline[4:]).replace("'","''")
			#print message
			cursor.execute("INSERT INTO syslogs values('" + entrydate + "','" + host + "','" + message + "' )")
		else:
			print "Invalid data! " + line
	conn.commit()
except pymssql.DatabaseError, err:
	print str(err)
#cursor.executemany(
#    "INSERT INTO persons VALUES (%d, %s, %s)",
#    [(1, 'John Smith', 'John Doe'),
#     (2, 'Jane Doe', 'Joe Dog'),
#     (3, 'Mike T.', 'Sarah H.')])
# you must call commit() to persist your data if you don't set autocommit to True

#cursor.execute('SELECT * FROM persons WHERE salesrep=%s', 'John Doe')
#row = cursor.fetchone()
#while row:
#    print("ID=%d, Name=%s" % (row[0], row[1]))
#    row = cursor.fetchone()

conn.close()
