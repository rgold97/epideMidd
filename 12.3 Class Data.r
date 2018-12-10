library(tidyverse)
library(data.table)
library(rvest)

classes <- fread("Classes.csv")

classes$room[which(classes$room == "MRE")] <- "MFH"
classes$room[which(classes$room == "VFH")] <- "MFH"
classes$room[which(classes$room == "SQA")] <- "MFH"

mon <- classes %>%
  filter(str_detect(days, "M") == TRUE) %>%
  filter(rounded.start == rounded.end - 1) %>%
  group_by(rounded.start, room) %>%
  summarize(num.students = sum(enroll))

tues <- classes %>%
  filter(str_detect(days, "T") == TRUE) %>%
  filter(rounded.start == rounded.end - 1) %>%
  group_by(rounded.start, room) %>%
  summarize(num.students = sum(enroll))

wed <- classes %>%
  filter(str_detect(days, "W") == TRUE) %>%
  filter(rounded.start == rounded.end - 1) %>%
  group_by(rounded.start, room) %>%
  summarize(num.students = sum(enroll))

thurs <- classes %>%
  filter(str_detect(days, "R") == TRUE) %>%
  filter(rounded.start == rounded.end - 1) %>%
  group_by(rounded.start, room) %>%
  summarize(num.students = sum(enroll))

fri <- classes %>%
  filter(str_detect(days, "F") == TRUE) %>%
  filter(rounded.start == rounded.end - 1) %>%
  group_by(rounded.start, room) %>%
  summarize(num.students = sum(enroll))

mon.schedules <- as.data.frame(matrix("h", nrow = 2390, ncol = 24),
                               stringsAsFactors = FALSE)
tues.schedules <- as.data.frame(matrix("h", nrow = 2390, ncol = 24),
                                stringsAsFactors = FALSE)
wed.schedules <- as.data.frame(matrix("h", nrow = 2390, ncol = 24),
                               stringsAsFactors = FALSE)
thurs.schedules <- as.data.frame(matrix("h", nrow = 2390, ncol = 24),
                                 stringsAsFactors = FALSE)
fri.schedules <- as.data.frame(matrix("h", nrow = 2390, ncol = 24),
                               stringsAsFactors = FALSE)


for(start in unique(mon$rounded.start)){
  hour.schedule <- mon %>%
    filter(rounded.start == start)
  
  for(i in 1:nrow(hour.schedule)) {
    studs <- hour.schedule[i, ]$num.students
    place <- hour.schedule[i, ]$room
    for(student in sample(which(mon.schedules[ , start] == "h"), studs)){
      mon.schedules[student, start] <- place
    }
  }
}

for(start in unique(tues$rounded.start)){
  hour.schedule <- tues %>%
    filter(rounded.start == start)
  
  for(i in 1:nrow(hour.schedule)) {
    studs <- hour.schedule[i, ]$num.students
    place <- hour.schedule[i, ]$room
    for(student in sample(which(tues.schedules[ , start] == "h"), studs)){
      tues.schedules[student, start] <- place
    }
  }
}

for(start in unique(wed$rounded.start)){
  hour.schedule <- wed %>%
    filter(rounded.start == start)
  
  for(i in 1:nrow(hour.schedule)) {
    studs <- hour.schedule[i, ]$num.students
    place <- hour.schedule[i, ]$room
    for(student in sample(which(wed.schedules[ , start] == "h"), studs)){
      wed.schedules[student, start] <- place
    }
  }
}

for(start in unique(thurs$rounded.start)){
  hour.schedule <- thurs %>%
    filter(rounded.start == start)
  
  for(i in 1:nrow(hour.schedule)) {
    studs <- hour.schedule[i, ]$num.students
    place <- hour.schedule[i, ]$room
    for(student in sample(which(thurs.schedules[ , start] == "h"), studs)){
      thurs.schedules[student, start] <- place
    }
  }
}

for(start in unique(fri$rounded.start)){
  hour.schedule <- fri %>%
    filter(rounded.start == start)
  
  for(i in 1:nrow(hour.schedule)) {
    studs <- hour.schedule[i, ]$num.students
    place <- hour.schedule[i, ]$room
    for(student in sample(which(fri.schedules[ , start] == "h"), studs)){
      fri.schedules[student, start] <- place
    }
  }
}


#data frame dining services
meal_times <- c(7, 8, 9, 11, 12, 13, 17, 18, 19)
ross.prop <- 0.36
proc.prop <- 0.37
atw.prop <- 0.27

proc.count <- c(55, 274, 219, 95, 476, 381, 96, 480, 384)
ross.count <- c(49, 243, 194, 164, 410, 246, 111, 554, 443)
atw.count <- c(40, 202, 162, 134, 309, 185, 0, 0, 0)

sched <- thurs.schedules

for(i in 1:length(meal_times)){
  time <- meal_times[i]
  for(student in sample(which(sched[, time] == "h"),
                              proc.count[i])) {
    sched[student, time] <- "ProctorDining"
  }
  for(student in sample(which(sched[, time] == "h"),
                              ross.count[i])) {
    sched[student, time] <- "RCD"
  }
  for(student in sample(which(sched[, time] == "h"),
                              atw.count[i])) {
    sched[student, time] <- "ATD"
  }
}

thurs.schedules <- sched

#make all hs between 9 am and 11 pm free
free_times <- c(9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23)

toy.schedules <- mon.schedules

for(i in 1:nrow(toy.schedules)) {
  for(time in free_times) {
    if(toy.schedules[i, time] == "h"){
      toy.schedules[i, time] <- "f"
    }
  }
}

#run for each mon-fri
for(i in 1:nrow(mon.schedules)) {
  for(time in free_times) {
    if(mon.schedules[i, time] == "h"){
      mon.schedules[i, time] <- "f"
    }
  }
}

fwrite(mon.schedules, "mon_schedules.csv")
fwrite(tues.schedules, "tues_schedules.csv")
fwrite(wed.schedules, "wed_schedules.csv")
fwrite(thurs.schedules, "thurs_schedules.csv")
fwrite(fri.schedules, "fri_schedules.csv")


weekend_meal_times <- c(9, 10, 11, 12, 13, 17, 18, 19)

sun.schedules <- as.data.frame(matrix("h", nrow = 2390, ncol = 24),
                                 stringsAsFactors = FALSE)
sat.schedules <- as.data.frame(matrix("h", nrow = 2390, ncol = 24),
                               stringsAsFactors = FALSE)


proc.count <- c(139, 139, 416, 416, 139, 89, 444, 355)
ross.count <- c(0, 416, 416, 416, 139, 89, 444, 355)

for(i in 1:length(weekend_meal_times)){
  time <- weekend_meal_times[i]
  for(student in sample(which(sun.schedules[, time] == "h"),
                        proc.count[i])) {
    sun.schedules[student, time] <- "ProctorDining"
  }
  for(student in sample(which(sun.schedules[, time] == "h"),
                        ross.count[i])) {
    sun.schedules[student, time] <- "RCD"
  }
}


free_times <- c(10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23)

for(i in 1:nrow(sun.schedules)) {
  for(time in free_times) {
    if(sun.schedules[i, time] == "h"){
      sun.schedules[i, time] <- "f"
    }
  }
}

fwrite(sat.schedules, "sat_schedules.csv")
fwrite(sun.schedules, "sun_schedules.csv")


