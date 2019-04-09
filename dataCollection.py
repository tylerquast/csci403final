import psycopg2
import matplotlib.pyplot as plt; plt.rcdefaults()
import numpy as np
import matplotlib.pyplot as plt

try: 
    # Connect to the database! Be sure to put in your user and 
    # password. Im a big dummy and I use the same password 
    # for everything so im not comfortable leaving it there
    # but if someone is, we could all just query from
    # that persons database
    conn = psycopg2.connect("""
                            dbname='csci403' 
                            user='***CHANGE ME****' 
                            host='flowers.mines.edu' 
                            password='***CHANGE ME***'
                            """) 
    print("Connected succesfully! \n")
except: 
    print("I am unable to connect")

# Create a cursor object. This must be done to read
# from the database
cur = conn.cursor()

# cursor.execute is where all querying happens.
# place any sql command we have learned in between
# three double quote (") (notice i only queried the first
# three rows. Theres a lot more data in this table)
cur.execute("""
            SELECT * from airport fetch first 3 rows only;

            """)

# Stores all the data from the cursor.execute into an
# array (tuple??). the variable rows now contains everything
# I queried and can be used later 
rows = cur.fetchall()

# I found this online. it just prints all the column header
# names. Could be useful later
print("Here are all header titles for the airport table")
column_names = [desc[0] for desc in cur.description]
print(column_names)
print(len(column_names))
print()

# Prints out everything queried above. Just loops through
# the rows variable and prints each row.
print ("\nPrint everything queried above\n")
for row in rows:
    print (row)







# A moc graph for testing!
# Create a dictionary (key, value) data structure
dictionary = {}
# do my query. Select all states from the airports table
cur.execute("""
            SELECT state from airport;

            """)
# add all this data a value rows
rows = cur.fetchall()
# Clean up the data. Loop through rows, and check if the
# current value is in the dictionary. If not add it. If 
# so increment the number of times it has been seen
for row in rows:
    if row[0] in dictionary:
        # Its already there
        dictionary[row[0]] += 1
    else:
        # its not in there
        dictionary[row[0]] = 1
# Create arrays to hold all the data. This will be sent
# to the graphing function
names = []
vals = []
for val in dictionary:
    names.append(val)
    vals.append(dictionary[val])

# A simple box chart i found here: https://pythonspot.com/matplotlib-bar-chart/
objects = names 
y_pos = np.arange(len(objects))
performance = vals 
 
plt.bar(y_pos, performance, align='center', alpha=0.5)
plt.xticks(y_pos, objects)
plt.ylabel('Usage')
plt.title('Programming language usage')
 
plt.show()