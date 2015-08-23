
###################################################################
# 1. Merge the training and the test sets to create one data set. #
###################################################################

if (!file.exists("accelerometerData.zip")) {
    fileURL <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
    download.file(fileURL, destfile = "./accelerometerData.zip", method = "curl")
} else {
    print("the zip file has already been downloaded")
}

if (!file.exists("UCI HAR Dataset")) {
    unzip("./accelerometerData.zip")
} else {
    print("the file has already been unzipped.")
}

#read common data
activity_labels <- read.table("./UCI HAR Dataset/activity_labels.txt", header = FALSE)
dim(activity_labels) # 6 x 2

features <- read.table("./UCI HAR Dataset/features.txt", header = FALSE)
dim(features) # 561 x 2
head(features)

#read test data 
library(dplyr)
#x_test
x_test <- read.table("./UCI HAR Dataset/test/X_test.txt", header = FALSE)
dim(x_test) # 2947 x 561 
#y_test 
y_test <- read.table("./UCI HAR Dataset/test/y_test.txt", header = FALSE)
dim(y_test) # 2947 x 1
#subject_test 
subject_test <- read.table("./UCI HAR Dataset/test/subject_test.txt", header = FALSE)
dim(subject_test) # 2947 x 1
#before combinign test data by columns, it would be better to rename the column names, 
# because the first column of all 3 data.frames are the same "V1", and this might be confusing.
y_test <- rename(y_test, activity_label = V1)
subject_test <- rename(subject_test, subject = V1)
# we could rename V1..V561 columns as the feature names, simply by names(x_test) <- features[,2] 
#  but we rather not do it since the feature descriptions contain duplicates, 
#  and we would anyway access specific features by column index

#combine test data: The order of the columns below is important. We put x_test on the left, 
 # the indexes (or the location) of the first 561 columns should remain the same, 
 # because the features table contain the column index and relevant feature description 
 # and this mapping should be stable
test_data <- cbind(x_test, subject_test, y_test)
# check if the column names and structure looks OK
dim(test_data) # 2947 x 563 
test_data[1:3,1:5]

#read train data
#x_train
x_train <- read.table("./UCI HAR Dataset/train/X_train.txt", header = FALSE)
dim(x_train) # 7352 x 561
# y_train
y_train <- read.table("./UCI HAR Dataset/train/y_train.txt", header = FALSE)
dim(y_train) # 7352 x 1
# subject_train
subject_train <- read.table("./UCI HAR Dataset/train/subject_train.txt", header = FALSE)
dim(subject_train) #7532 x 1

# just like above, we rename first:
y_train <- rename(y_train, activity_label = V1)
subject_train <- rename(subject_train, subject = V1)
# we could rename V1..V561 columns as the feature names, simply by names(x_train) <- features[,2] 
#  but we rather not do it since the feature descriptions contain duplicates, 
#  and we would anyway access specific features by column index
#column-bind train data
train_data <- cbind(x_train, subject_train, y_train)
# check if the column names and structure looks OK
dim(train_data) # 7352 x 563 
train_data[1:3,1:5]

#combine test and train data 
# since test data and train data are just different observations, having the same structure we row bind them
data <- rbind(test_data, train_data)
dim(data) # 10299 x 563

# let's check the number of labels in the quasi master data (in DBMS terms)
nrow(activity_labels) # 6
# validate number of unique labels in data set
length(unique(data$label)) # 6
#Whenever necessary different label IDs (1:6) in the data set can be mapped using the activity_labels, which is kind of a master data table, in terms of DBMS

###################################################################
# 2. Extract only the measurements on the mean and std.dev.      #
###################################################################

# Looking at the features.info, and features files it is clear that the measurements on mean and std.dev.
#   are those which end with "-mean()" and "-std()"

#using features dataFrame, which contain features on its rows, we filter relevant features:
# -std() features
 std_features <- filter(features, grepl('-std()', V2, fixed = TRUE))
 nrow(std_features) # 33 
# -mean() features (we are excluding -meanFreq(), by usgin fixed = TRUE to search exact phrase)
 mean_features <- filter(features, grepl('-mean()', V2, fixed = TRUE))
nrow(mean_features) #33
# all relevant features: row bind and select V1 column containing feature column indexes
 rel_features <- (select(rbind(std_features, mean_features), V1))
 nrow(rel_features) #66
 head(rel_features)

dim(data) # 10299 x 563
# select the columns with relevant feature index, plus the last two columns (subject and label)
extractedData <- select(data, c(rel_features[,1], 562, 563))
dim(extractedData) # 10299 x 68

#############################################################################
# 3. Use descriptive activity names to name the activities in the data set  #
#############################################################################
# activity labels are the last column of our data set
extractedData[1:3,64:68]
#         V516       V529       V542 subject activity_label
#1 -0.8950612 -0.7706100 -0.8901655       2               5
#2 -0.9454372 -0.9244608 -0.9519774       2               5
#3 -0.9710690 -0.9752095 -0.9856888       2               5

# it contains an index for the activity label, 
# the descriptive activity names can be read from the activity_labels table:
#  V1                 V2
#1  1            WALKING
#2  2   WALKING_UPSTAIRS
#3  3 WALKING_DOWNSTAIRS
#4  4            SITTING
#5  5           STANDING
#6  6             LAYING

# since row names are equal to the first column values, which are the label indexes,
#  we can use simple subsetting to select the descriptive activity names in the second column
extractedData <- mutate(extractedData, activity_label = activity_labels[activity_label,2])
extractedData[1:3,64:68]
#   V516       V529       V542      subject    activity_label
#1 -0.8950612 -0.7706100 -0.8901655       2          STANDING
#2 -0.9454372 -0.9244608 -0.9519774       2          STANDING
#3 -0.9710690 -0.9752095 -0.9856888       2          STANDING

#########################################################################
# 4. Appropriately labels the data set with descriptive variable names. #
#########################################################################

# The descriptive variable names are stored in the second column of features table
head(features,3)
#  V1                V2
#1  1 tBodyAcc-mean()-X
#2  2 tBodyAcc-mean()-Y
#3  3 tBodyAcc-mean()-Z

# note that the first column, having the indexes for the features, have the same value as the row names.
#  which allows us to be able to use simpler subsetting, instead of dplyr::filter
# The variable names in our extracted data set contains these indexes, following a "V" yet:
extractedData[1:3, 1:3]
#          V4         V5         V6
#1 -0.9384040 -0.9200908 -0.6676833
#2 -0.9754147 -0.9674579 -0.9449582
#3 -0.9938190 -0.9699255 -0.9627480

colNames <- names(extractedData[,1:66])
# remove the "V" at the beginning to get the pure indexes
featureIndexes <- substr(colNames,2,nchar(colNames))
#use subsetting on features table to get the descriptive feature names
newNames <- c(as.character(features[featureIndexes,2]), names(extractedData[,67:68]))
names(extractedData) <- newNames

#check the result
extractedData[1:3, c(1:3, 66:68)]
#  tBodyAcc-std()-X tBodyAcc-std()-Y tBodyAcc-std()-Z fBodyBodyGyroJerkMag-mean() subject    activity_label
#1       -0.9384040       -0.9200908       -0.6676833                  -0.8901655       2          STANDING
#2       -0.9754147       -0.9674579       -0.9449582                  -0.9519774       2          STANDING
#3       -0.9938190       -0.9699255       -0.9627480                  -0.9856888       2          STANDING

############################################################################################################
# 5. create independent tidy data set with the average of each variable for each activity and each subject.#
############################################################################################################
library(reshape2)
meltedData <- melt(extractedData, id.vars=c("activity_label", "subject"))

act_subj <- group_by(meltedData, activity_label, subject)
averagesPerSubjectAndActivity <- summarize(act_subj, average = mean(value))
averagesPerSubjectAndActivity
# activity_label subject    average
#1          LAYING       1 -0.6815820
#2          LAYING       2 -0.7431268
#3          LAYING       3 -0.7343477
#4          LAYING       4 -0.7286680
#5          LAYING       5 -0.7390854
#6          LAYING       6 -0.7144815
#7          LAYING       7 -0.7238571
#8          LAYING       8 -0.7224065
#9          LAYING       9 -0.7261465
#10         LAYING      10 -0.7514540
#..            ...     ...        ...

