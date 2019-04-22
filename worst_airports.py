import psycopg2
import numpy as np
import plotly
import plotly.plotly as py
import plotly.graph_objs as go 
import pandas as pd
from pandas import DataFrame


try: 
    # Connect to the database! Be sure to put in your user and 
    # password. Im a big dummy and I use the same password 
    # for everything so im not comfortable leaving it there
    # but if someone is, we could all just query from
    # that persons database
    conn = psycopg2.connect("""
                            dbname='csci403' 
                            user='madelinemckune' 
                            host='flowers.mines.edu' 
                            password='1Rgmisll!!'
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
#cur.execute("""
#            SELECT port.city, AVG(f.dep_delay), port.longitude, port.latitude from flights AS f, airport AS port WHERE #f.origin_airport_id = port.id AND f.dep_delay IS NOT NULL GROUP BY (port.city, port.longitude, port.latitude) ORDER BY AVG(f.dep_delay) DESC LIMIT 100;
#            """)


cur.execute("""
    SELECT port.city, w.dep_delay, port.longitude, port.latitude
    FROM worst_delays AS w, airport AS port 
    WHERE w.id = port.id 
    ORDER BY w.dep_delay DESC
    LIMIT 200;
""")

# Stores all the data from the cursor.execute into an
# array (tuple??). the variable rows now contains everything
# I queried and can be used later 
df = DataFrame(cur.fetchall())
#delay_table.columns = cur.column_names

#close the cursor
cur.close()

#rename the column headers
df.columns = ['Name', 'Delay_Time', 'lon', 'lat']

#print the data
#print(delay_table.head())

print (df)

#plotting
df.head()
df['text'] = df['Name'] + '<br>Delay_Time ' + (df['Delay_Time']).astype(str)+' minutes'
limits = [(0,10),(11,25),(26,50),(51,100), (101, 1000)]
colors = ["rgb(171,7,28)","rgb(189,66,51)","rgb(207,126,74)","rgb(225,186,97)","rgb(244,246,121)"]
cities = []
scale = 2. * max(df['Delay_Time']) / (45 ** 2)
print (scale)

for i in range(len(limits)):
    lim = limits[i]
    df_sub = df[lim[0]:lim[1]]
    city = go.Scattergeo(
        locationmode = 'USA-states',
        lon = df_sub['lon'],
        lat = df_sub['lat'],
        text = df_sub['text'],
        marker = go.scattergeo.Marker(
            size = df_sub['Delay_Time']/scale,
            color = colors[i],
            line = go.scattergeo.marker.Line(
                width=0.5, color='rgb(40,40,40)'
            ),
            sizemode = 'area'
        ),
        name = '{0} - {1}'.format(lim[0],lim[1]) )
    cities.append(city)

layout = go.Layout(
        title = go.layout.Title(
            text = '2015 US Airports With the Worst Delay Times<br>(Click legend to toggle traces)'
        ),
        showlegend = True,
        geo = go.layout.Geo(
            scope = 'usa',
            projection = go.layout.geo.Projection(
                type='albers usa'
            ),
            showland = True,
            landcolor = 'rgb(217, 217, 217)',
            subunitwidth=1,
            countrywidth=1,
            subunitcolor="rgb(255, 255, 255)",
            countrycolor="rgb(255, 255, 255)"
        )
    )

fig = go.Figure(data=cities, layout=layout)
plotly.offline.plot(fig, filename='d3-bubble-map-populations.html')






