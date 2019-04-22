# Database CSCI 403 Final Project stuff

# install DB connection package 
#install.packages("RPostgreSQL")

# load library
library(RPostgreSQL)
library(ggplot2)
library(fields)
library(caret)
library(plyr)
library(maps)
library(tidyverse)
library(ggmap)
library(ggthemes)
library(viridis)
library(data.table)

# Specifcy the type of database to connect to 
pg <- dbDriver("PostgreSQL")

# Open the connection
con <- dbConnect(pg,
                 user = "user", 
                 password = "password", 
                 host = "flowers.mines.edu", 
                 dbname = "csci403")


# See column names in tables
dbListFields(con, "flights")
dbListFields(con, "airline")
dbListFields(con, "airport")

# Query database and view results
# do some cool plotting
# query <- paste("SELECT ap.longitude lon, ap.latitude lat, f.dep_delay del",
#           "FROM flights f, airport ap", 
#           "WHERE f.origin_airport_id = ap.id",
#           "AND ap.longitude IS NOT NULL AND ap.latitude IS NOT NULL",
#           "AND ap.longitude > -130 AND ap.latitude > 15 AND ap.latitude < 50",
#           "FETCH FIRST 100000 ROWS ONLY;")
# 
# # get data for ML
# query <- paste("SELECT f.month, f.day, f.day_of_week," ,
#                "f.airline_id, f.origin_airport_id, f.dest_airport_id,",
#                "f.scheduled_dep_time, f.dep_delay, f.scheduled_time,",
#                "f.distance, f.scheduled_arr_time, ap1.city orig_city, ap1.state orig_state,",
#                "ap2.city dest_city, ap2.state dest_state",
#                "FROM flights f, airport ap1, airport ap2",
#                "WHERE f.origin_airport_id = ap1.id AND f.dest_airport_id = ap2.id;")

# get data for denver analysis
# query <- paste("select f.dest_airport_id, f.origin_airport_id, a1.city orig_city, f.dest_airport_id, a2.city dest_city, a2.longitude, a2.latitude",
#                "from flights f, airport a1, airport a2",
#                "where f.origin_airport_id = a1.id and a1.city = 'Denver' and f.dest_airport_id = a2.id")
# 
# query <- paste("select f.dest_city, f.freq, a.state ,a.longitude, a.latitude from",
#                "(select a2.city dest_city, count(*) freq",
#                "from flights f, airport a1, airport a2",
#                "where f.origin_airport_id = a1.id and a1.city = 'Denver' and f.dest_airport_id = a2.id",
#                "group by dest_city) f, airport a",
#                "where f.dest_city = a.city",
#                "and a.state != 'HI' and a.state != 'AK' and country = 'USA';")

query <- paste("select a.name, a.city, f.freq, a.state ,a.longitude, a.latitude from",
               "(select a2.id dest_city_id, count(*) freq",
               "from flights f, airport a1, airport a2",
               "where f.origin_airport_id = a1.id and a1.city = 'Denver' and f.dest_airport_id = a2.id",
               "group by dest_city_id) f, airport a",
               "where f.dest_city_id = a.id",
               "and a.state != 'HI' and a.state != 'AK' and country = 'USA';")

dbsq <- dbSendQuery(con, query)

res <- fetch(dbsq, n = -1)

# group citites with same names into the same data set - choose first set of coords as the correct one
while(any(duplicated(res$city) == TRUE)){
  i <- which(duplicated(res$city))[1]
  all <- which(res$city == res$city[i])
  rep <- all[all != i]
  
  res$freq[i] <- res$freq[i] + res$freq[rep]
  res <- res[-rep,]
}

data <- res[order(res$freq),]
names(data) <- c("name", "city" ,"freq", "state" ,"long", "lat")

fwrite(data, "denver_most_popular_cities.csv")

data_cut <- data[data$freq > 3400,]

US <- map_data("usa") 
states <- map_data("state")

ggplot(US, aes(x = long, y = lat, group = group)) +
  geom_polygon(data = states, col = "white", fill = "grey") +
  geom_point(data = data, aes(group = 1, col = freq, size = freq), alpha = 0.7) +
  geom_text(data = data_cut, aes(group = 1, label = city)) +
  coord_map() +
  theme_map() +
  scale_color_viridis(name = "Flights") +
  scale_size_continuous(range = c(0,20), guide = FALSE)

#which day is most populat to fly?
query <- paste("select f.day_of_week, count(*) from flights f, airport a",
               "where f.origin_airport_id = a.id and a.city = 'Denver'",
               "group by day_of_week;")
dbsq <- dbSendQuery(con, query)

res2 <- fetch(dbsq, n = -1)

res3 <- res2

dow <- c("M", "T", "W", "Th", "F", "Sa", "Su")
for(i in 1:nrow(res2)){
  res3[i,"day_of_week"] <- dow[res2[i, "day_of_week"]]
}


ggplot(data = res3, aes(x = day_of_week, y = count)) +
  geom_bar(stat = "identity", color = "black" ,fill = "steelblue") +
  theme_minimal() + 
  scale_x_discrete(limits=dow) +
  ylab("Number of Flights in 2015") +
  xlab("Day of Week") 


# Flight departure time analysis
query <- paste("select f.dep_time from flights f, airport a",
               "where f.origin_airport_id = a.id and a.city = 'Denver';")

dbsq <- dbSendQuery(con, query)
res4 <- fetch(dbsq, n = -1)

ggplot(data = res4, aes(x = dep_time)) +
  geom_histogram(breaks = seq(0,2400,100), color = "black", fill = "steelblue") + 
  theme_minimal() +
  xlab("Departure Time (Military)") +
  ylab("Number of Flights in 2015")

#Make some cool plot with circle size representing # of flights at the lat long values on a plot of the US!



##### Machine Learning crud that didn't work so well
predictors <- c("month","day","day_of_week", "airline_id", "origin_airport_id", "dest_airport_id", "distance")
out <- "dep_delay"

# convert categorical into integer
res$airline_id <- as.integer(factor(res$airline_id))
res$origin_airport_id <- as.integer(factor(res$origin_airport_id))
res$dest_airport_id <- as.integer(factor(res$dest_airport_id))

# Take like 10,000 rows
n <- 20000
trainp <- 0.75
ind <- sample(1:nrow(res),n, replace = FALSE)
index <- sample(1:n, n*trainp, replace = FALSE)

trainSet <- res[ind[index],]
testSet <- res[ind[-index],]

models <- list()
models[[1]] <- train(trainSet[,predictors],trainSet[,out],method = "knn", tuneLength = 10)

cl <- makeCluster(detectCores())
registerDoParallel(cl)
models[[2]] <- train(trainSet[,predictors],trainSet[,out],method = "parRF", trControl = trainControl("cv", number = 10))
stopCluster(cl)
registerDoSEQ()

models[[3]] <- train(trainSet[,predictors],trainSet[,out],method = "nnet")

pred <- extractPrediction(models, testX = testSet[,predictors], testY = testSet[,out])
pred_sep <- split(pred, pred$model)

tt <- "Test"
lapply(pred_sep, function(x){
  xn <- x[x$dataType == tt,]
  ds <- defaultSummary(xn)
  
  plot(xn$obs, xn$pred, main = toString(xn$model[1]), xlab = "Actual Value", ylab = "Predicted Value")
  abline(0,1, col = "red", lwd = 1.25)
  return(ds)
})

# Disconnect database connection when done
dbDisconnect(con)
