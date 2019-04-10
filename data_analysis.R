# Database CSCI 403 Final Project stuff

# install DB connection package 
#install.packages("RPostgreSQL")

# load library
library(RPostgreSQL)
library(ggplot2)

# Specifcy the type of database to connect to 
pg <- dbDriver("PostgreSQL")

# Open the connection
con <- dbConnect(pg,
                 user = "USERNAME", 
                 password = "PASSWORD", 
                 host = "flowers.mines.edu", 
                 dbname = "csci403")


# See column names in tables
dbListFields(con, "flights")
dbListFields(con, "airline")
dbListFields(con, "airport")

# Query database and view results
query <- paste("SELECT ap.state orig_airport, AVG(f.dep_delay)",
          "FROM flights f, airport ap", 
          "WHERE f.origin_airport_id = ap.id",
          "GROUP BY ap.state",
          "FETCH FIRST 100 ROWS ONLY;")
dbsq <- dbSendQuery(con, query)

res <- fetch(dbsq, n = -1)

p <- ggplot(data = res, aes(x = orig_airport, y = avg)) +
     geom_col(fill = "steelblue")+
     theme_minimal()
p

# Disconnect database connection when done
dbDisconnect(con)
