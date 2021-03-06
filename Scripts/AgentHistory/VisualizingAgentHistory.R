#install.packages("odbc")
#install.packages("ggplot2")
#install.packages("dplyr")
#install.packages("lubridate")
#install.packages("scales")

library(odbc)
library(ggplot2)
library(dplyr)
library(lubridate)
library(scales)


Sys.setenv(TZ='GMT')

MSDB <- dbConnect(odbc::odbc(),
                 Driver    = "SQL Server", 
                 Server    = "localhost",
                 Database  = "msdb",
                 Trusted_Connection = 'Yes')

SQLStmt <- sprintf("declare @date varchar(8)
    select @date = '20171001'
    exec sp_help_jobhistory @start_run_date = @date, @mode='FULL'")



rs <- dbSendQuery(MSDB, SQLStmt)

# Warning is normal in this case on a guid, can use 
# try catch to deal with warning can be created
# https://github.com/r-dbi/odbc/pull/29

msdbAgentHist <- dbFetch(rs)

# house keeping 
dbClearResult(rs)
dbDisconnect(MSDB)

keepCopy <- msdbAgentHist

# Save an object to a file
#saveRDS(msdbAgentHist, file = "C:/Users/adminshep/Documents/msdbAgentHist.rds")
# Restore the object
#msdbAgentHist <- readRDS(file = "/Users/Shep/Azure Share/DSVM1/msdb/msdbAgentHist.rds")


# cleanup the date so it is usable!
# get rid of any duration = 0 
# filter is part of dplyr

# this will keep only the dates greater than a specific date
#msdbAgentHist <- filter(msdbAgentHist, run_date >= "20171101")

#this will keep only dates > max(run_date)-2 or how ever many days you want to go back
#msdbAgentHist <- keepCopy
#msdbAgentHist <- filter(msdbAgentHist, run_date >= max(run_date)-1)
#msdbAgentHist <- filter(msdbAgentHist, run_date <= min(run_date)+1)
msdbAgentHist <- filter(msdbAgentHist, run_date == "20171031")


#run_duration comes in as INT, so ? 59 in this case will be 59 seconds, 
msdbAgentHist <- filter(msdbAgentHist, run_duration > 1)
msdbAgentHist <- filter(msdbAgentHist, step_id > 0)

msdbAgentHist$run_time[msdbAgentHist$run_time == "0"] <- "000000"

# work on the dates
msdbAgentHist$run_date <- ymd(msdbAgentHist$run_date)
msdbAgentHist$run_duration <-as.character(msdbAgentHist$run_duration)


#Create a combied column with start date and time
#due to the weay msdb time is stored this wioll require some engineering. 
msdbAgentHist$run_StartTime   <- "XXX"
msdbAgentHist$run_StartDate   <- "XXX"
msdbAgentHist$run_StartDateTime   <- "XXX"
msdbAgentHist$run_StartHour <- "XXX"
msdbAgentHist$run_EndTime   <- "XXX"
msdbAgentHist$run_EndDate   <- "XXX"
msdbAgentHist$run_EndDateTime   <- "XXX"


# MSDB date is stored as actual time but not formatted, so turn it into date time
# If you porefer to do this in SQL, there is a function in MSDB called 

rows <- nrow(msdbAgentHist)
for (i in 1:rows){
  if (nchar(msdbAgentHist$run_time[i]) == 6){
    msdbAgentHist$run_StartTime[i] <-   format(strptime(msdbAgentHist$run_time[i], "%H%M%S"),format="%H:%M:%S")
  }
  
  else if (nchar(msdbAgentHist$run_time[i]) == 5){
    msdbAgentHist$run_time[i] <- paste("0", msdbAgentHist$run_time[i], sep='') 
    msdbAgentHist$run_StartTime[i] <-   format(strptime(msdbAgentHist$run_time[i], "%H%M%S"),format="%H:%M:%S")
    
  }
  else if (nchar(msdbAgentHist$run_time[i]) == 4){
    msdbAgentHist$run_time[i] <- paste("00", msdbAgentHist$run_time[i], sep='') 
    msdbAgentHist$run_StartTime[i] <-   format(strptime(msdbAgentHist$run_time[i], "%H%M%S"),format="%H:%M:%S")
    
  }
  else if (nchar(msdbAgentHist$run_time[i]) == 3){
    msdbAgentHist$run_time[i] <- paste("000", msdbAgentHist$run_time[i], sep='') 
    msdbAgentHist$run_StartTime[i] <-   format(strptime(msdbAgentHist$run_time[i], "%H%M%S"),format="%H:%M:%S")
  }
  else if (nchar(msdbAgentHist$run_time[i]) == 2){
    msdbAgentHist$run_time[i] <- paste("0000", msdbAgentHist$run_time[i], sep='') 
    msdbAgentHist$run_StartTime[i] <-   format(strptime(msdbAgentHist$run_time[i], "%H%M%S"),format="%H:%M:%S")
  }
  else if (nchar(msdbAgentHist$run_time[i]) == 1){
    msdbAgentHist$run_time[i] <- paste("00000", msdbAgentHist$run_time[i], sep='') 
    msdbAgentHist$run_StartTime[i] <-   format(strptime(msdbAgentHist$run_time[i], "%H%M%S"),format="%H:%M:%S")
  }
}
#Format and store start time
msdbAgentHist$run_StartDateTime <- as.POSIXct(paste(msdbAgentHist$run_date, msdbAgentHist$run_StartTime), format="%Y-%m-%d %H:%M:%S")
msdbAgentHist$run_StartDate <- msdbAgentHist$run_date
msdbAgentHist$run_StartHour <- hour(msdbAgentHist$run_StartDateTime)

#MSDB date is stored as actual time but not formatted, so turn it into date time
for (i in 1:rows){
  if (nchar(msdbAgentHist$run_duration[i]) == 6){
    msdbAgentHist$run_duration[i] <-   format(strptime(msdbAgentHist$run_duration[i], "%H%M%S"),format="%H:%M:%S")
  }
  
  else if (nchar(msdbAgentHist$run_duration[i]) == 5){
    msdbAgentHist$run_duration[i] <- paste("0", msdbAgentHist$run_duration[i], sep='') 
    msdbAgentHist$run_duration[i] <-   format(strptime(msdbAgentHist$run_duration[i], "%H%M%S"),format="%H:%M:%S")
    
  }
  else if (nchar(msdbAgentHist$run_duration[i]) == 4){
    msdbAgentHist$run_duration[i] <- paste("00", msdbAgentHist$run_duration[i], sep='') 
    msdbAgentHist$run_duration[i] <-   format(strptime(msdbAgentHist$run_duration[i], "%H%M%S"),format="%H:%M:%S")
    
  }
  else if (nchar(msdbAgentHist$run_duration[i]) == 3){
    msdbAgentHist$run_duration[i] <- paste("000", msdbAgentHist$run_duration[i], sep='') 
    msdbAgentHist$run_duration[i] <-   format(strptime(msdbAgentHist$run_duration[i], "%H%M%S"),format="%H:%M:%S")
    
  }
  else if (nchar(msdbAgentHist$run_duration[i]) == 2){
    msdbAgentHist$run_duration[i] <- paste("0000", msdbAgentHist$run_duration[i], sep='') 
    msdbAgentHist$run_duration[i] <-   format(strptime(msdbAgentHist$run_duration[i], "%H%M%S"),format="%H:%M:%S")
    
  }
  else if (nchar(msdbAgentHist$run_duration[i]) == 1){
    msdbAgentHist$run_duration[i] <- paste("00000", msdbAgentHist$run_duration[i], sep='') 
    msdbAgentHist$run_duration[i] <-   format(strptime(msdbAgentHist$run_duration[i], "%H%M%S"),format="%H:%M:%S")
  }
}
# Divide date up by Date, Date time, and elasped time
msdbAgentHist$run_EndDateTime <- as.POSIXct(msdbAgentHist$run_StartDateTime,format="%H:%M:%S") + period_to_seconds(hms(msdbAgentHist$run_duration))
msdbAgentHist$run_EndTime <- format(msdbAgentHist$run_EndDateTime,format="%H:%M:%S")
msdbAgentHist$run_EndDate <- format(msdbAgentHist$run_EndDateTime,format="%Y-%m-%d")
msdbAgentHist$MinutesElapsed <- hour(hms(msdbAgentHist$run_duration)) * 60  + minute(hms(msdbAgentHist$run_duration))


ggplot(msdbAgentHist, aes(run_StartHour, run_StartDateTime)) + 
  geom_rect(aes(ymin = run_StartDateTime,
                ymax = run_EndDateTime, 
                xmin = (run_StartHour ),
                xmax = (run_StartHour + .75),
                fill=step_name,
                color=step_name))+
  scale_x_continuous(breaks = round(seq(min(msdbAgentHist$run_StartHour), 
                                        max(msdbAgentHist$run_StartHour), 
                                        by = 2))) +
  scale_y_datetime(date_labels = "%Y %b %d %H:%M:%S",
                   breaks = date_breaks("4 hour"), # cahnge this for the volume dates on the y axis
                   minor_breaks = date_breaks("4 hour")) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))+
  theme(legend.key.size = unit(.5,"line")) +
  guides(fill=guide_legend(ncol=1)) +
  labs(title = "SQL Agent History", x = "Start Hour", y = "Duration")


ggplot(msdbAgentHist, aes(run_StartHour, run_StartDateTime)) + 
  geom_rect(aes(ymin = run_StartDateTime,
                ymax = run_EndDateTime, 
                xmin = (run_StartHour ),
                xmax = (run_StartHour + .75),
                fill=step_name,
                color=step_name))+
  facet_wrap(~job_name) +
  scale_x_continuous(breaks = round(seq(min(msdbAgentHist$run_StartHour), 
                                        max(msdbAgentHist$run_StartHour), 
                                        by = 2))) +
  scale_y_datetime(date_labels = "%Y %b %d %H:%M:%S",
                   breaks = date_breaks("12 hour"),
                   minor_breaks = date_breaks("12 hour")) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))+
  theme(legend.key.size = unit(1,"line")) +
  labs(title = "SQL Agent History", x = "Start Hour", y = "Duration")
