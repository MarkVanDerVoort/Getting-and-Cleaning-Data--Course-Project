# =================================================================
# Discarding derived data, tidying up
# =================================================================

# get only mean and std
names.all <- names(combined)
mean.or.std <- function(name){
  regexpr("(std|mean)\\(",name) != -1  #enforce opening bracket to filter out meanFreq derived values
}
#The name starts with t, since names starting with f are derived
#frequency domain values
time.measurement <- function(name){
  regexpr("t",name) == 1    #"start with t"
}
#The name does not mention jerk (since these are derived values)
no.jerk <- function(name){
  regexpr("[jJ]erk",name) == -1
}
#The name does not include Mag, since these values are derived
no.magnitude <- function(name){
  regexpr("[Mm]ag",name) == -1
}
#The name is either subject or activity
subject.or.activity <- function(name){
  regexpr("^([Ss]ubject|[Aa]ctivity)$",name) == 1
}

# =================================================================
# Getting measurement names into R style
# =================================================================

#remove parentheses from a string
no.parens <- function(s){
  gsub("\\(\\)","",s)
}
#replace minus with R style dot (.)
dotted.minus <- function(s){
  gsub("-",".",s)
}
#remove leading t since it is redundant
no.leading.t <- function(s){
  gsub("^t","",s)
}
#replace camelCasing with R dot-separation
dot.camel.case <- function(s){
  gsub("([a-zA-Z])([A-Z])","\\1.\\L\\2",s,perl=TRUE)
}



# =================================================================
# Start of script
# =================================================================

# This script is to be run from the project directory
data.directory <- "UCI HAR Dataset"
data.file <- "dataset UCI HAR.txt"
means.file <- "means per subject and activity.txt"
data.dirty.file <- "dataset UCI HAR -dirty-.RData"
start.directory = getwd()


# reads content of a directory
read.dir <- function(dir.name = "train", activity.labels, attributes) {
  x.file.name <- paste("X_",dir.name,".txt",sep="")
  file.name <- file.path(".",dir.name,x.file.name)
  x <- read.table(file.name, sep="")
  names(x) <- attributes
  
  # get activities in plain english (maybe merge here??)
  y.file.name <- paste("y_",dir.name,".txt",sep="")
  file.name <- file.path(".",dir.name, y.file.name)
  y <- read.table(file.name, sep="")
  names(y) <- "Activity"
  y$Activity <- as.factor(y$Activity)
  levels(y$Activity) <- activity.labels
  
  # get subjects
  subject.file.name <- paste("subject_",dir.name,".txt",sep="")
  file.name <- file.path(".",dir.name, subject.file.name)
  subjects <- read.table(file.name, sep="")
  names(subjects) = "subject"
  subjects$subject = as.factor(subjects$subject)
  
  #combine in a single dataframe
  cbind(x,subjects, y)
}

# Download data if not already existing
# Assuming we put the data in a subdirectory rather than
# directly in the working directory
if (!file.exists(data.directory)){
  local.zip <- "UCI HAR Dataset.zip"
  download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip",
                local.zip,
                method="curl")
  unzip(local.zip)
  file.remove(local.zip)
}
stopifnot(file.exists(data.directory))
if (file.exists(data.dirty.file)){
  load(data.dirty.file)
} else {  
  setwd(data.directory)
  
  # get labels
  labels <- read.table("activity_labels.txt", sep="")
  activity.labels <- as.character(labels$V2)
  rm(labels)
  
  # get attributes
  attributes.tmp <- read.table("features.txt", sep="")
  attributes <- attributes.tmp$V2
  rm(attributes.tmp)
  
  train <- read.dir("train",activity.labels,attributes)
  test <- read.dir("test",activity.labels,attributes)
  
  combined <- rbind(train,test)  #no need to discern the sets
  setwd(start.directory)         #tbd, look at tryCatch
  save(combined, file = data.dirty.file)
}

names.all <- names(combined)
names.ok <- sapply(names.all,
                   function(x){
                     (mean.or.std(x) &         #as stated in the problem
                      time.measurement(x) &    #discard derived frequency domain measurements
                      no.jerk(x) &             #discard derived jerk measurements
                      no.magnitude(x)) |       #discard derived magnitude measurements
                     subject.or.activity(x)})  #include subject and activity columns
small <- combined[ , names.ok]


#returns a name where
#  all characters are lowercase
#  original Camelcasing has been replaced with dot-separation
#  original hyphen separation has been replaced with dot-separation
#  no redundant t-prefix is present
beautify <- function(s){
  tolower(dot.camel.case(no.leading.t(dotted.minus(no.parens(s)))))
}

names(small) <- beautify(names(small))
write.table(small,data.file,sep="\t")

# ===============================
# Creating second dataset
install.packages("reshape2")
library(reshape2)

melted <- melt(small, id=c("activity","subject"))
means.per.subject.and.activity <- dcast(melted, subject + activity ~ ... , mean)
write.table(means.per.subject.and.activity,means.file)


