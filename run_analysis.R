
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
test_data <- cbind(subject_test, y_test, x_test)
# check if the column names and structure looks OK
dim(test_data) # 2947 x 563 
test_data[1:3, 1:5]

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
train_data <- cbind(subject_train, y_train, x_train)
# check if the column names and structure looks OK
dim(train_data) # 7352 x 563 
train_data[1:3,1:5]

#combine test and train data 
# since test data and train data are just different observations, having the same structure we row bind them
data <- rbind(test_data, train_data)
dim(data) # 10299 x 563

# let's check the number of labels in the activity_labels (which is kind of master data, in DBMS terms)
nrow(activity_labels) # 6
# validate number of unique labels in data set
length(unique(data$activity_label)) # 6
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
#  V1
#1  4
#2  5
#3  6
#4 44
#5 45
#6 46

dim(data) # 10299 x 563
# select the columns with relevant feature index, plus the first two columns (subject and label)
extractedData <- select(data, c(1, 2, rel_features[,1] + 2))
dim(extractedData) # 10299 x 68

extractedData[1:3, 1:8]
#  subject activity_label         V4         V5         V6        V44        V45        V46
#1       2              5 -0.9384040 -0.9200908 -0.6676833 -0.9254273 -0.9370141 -0.5642884
#2       2              5 -0.9754147 -0.9674579 -0.9449582 -0.9890571 -0.9838872 -0.9647811
#3       2              5 -0.9938190 -0.9699255 -0.9627480 -0.9959365 -0.9882505 -0.9815796

#############################################################################
# 3. Use descriptive activity names to name the activities in the data set  #
#############################################################################
# activity labels are the second column of our data set (see above)
# it contains an index for the activity label, 
# the descriptive activity names can be read from the activity_labels table:
activity_labels
#  V1                 V2
#1  1            WALKING
#2  2   WALKING_UPSTAIRS
#3  3 WALKING_DOWNSTAIRS
#4  4            SITTING
#5  5           STANDING
#6  6             LAYING

# use simple subsetting to select the descriptive activity names in the second column of the activity_labels table
extractedData <- mutate(extractedData, activity_label = activity_labels[activity_label,2])
extractedData[1:3, 1:8]
#  subject activity_label         V4         V5         V6        V44        V45        V46
#1       2       STANDING -0.9384040 -0.9200908 -0.6676833 -0.9254273 -0.9370141 -0.5642884
#2       2       STANDING -0.9754147 -0.9674579 -0.9449582 -0.9890571 -0.9838872 -0.9647811
#3       2       STANDING -0.9938190 -0.9699255 -0.9627480 -0.9959365 -0.9882505 -0.9815796


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
extractedData[1:3, 1:5]
#  subject activity_label         V4         V5         V6
#1       2       STANDING -0.9384040 -0.9200908 -0.6676833
#2       2       STANDING -0.9754147 -0.9674579 -0.9449582
#3       2       STANDING -0.9938190 -0.9699255 -0.9627480

colNames <- names(extractedData[,3:68])
# remove the "V" at the beginning to get the pure indexes
featureIndexes <- substr(colNames,2,nchar(colNames))
#use subsetting on features table to get the descriptive feature names
newNames <- c(names(extractedData[,1:2]), as.character(features[featureIndexes,2]))
names(extractedData) <- newNames

#check the result
extractedData[1:3, c(1:3, 66:68)]
#  subject activity_label tBodyAcc-std()-X fBodyBodyAccJerkMag-mean() fBodyBodyGyroMag-mean() fBodyBodyGyroJerkMag-mean()
#1       2       STANDING       -0.9384040                 -0.8950612              -0.7706100                  -0.8901655
#2       2       STANDING       -0.9754147                 -0.9454372              -0.9244608                  -0.9519774
#3       2       STANDING       -0.9938190                 -0.9710690              -0.9752095                  -0.9856888

############################################################################################################
# 5. create independent tidy data set with the average of each variable for each activity and each subject.#
############################################################################################################
library(reshape2)
#melt all measures into 1 column
meltData <- melt(extractedData, id=c("activity_label", "subject"), measure.vars=3:68)
head(meltData)
#  activity_label subject         variable      value
#1       STANDING       2 tBodyAcc-std()-X -0.9384040
#2       STANDING       2 tBodyAcc-std()-X -0.9754147
#3       STANDING       2 tBodyAcc-std()-X -0.9938190
#4       STANDING       2 tBodyAcc-std()-X -0.9947428
#5       STANDING       2 tBodyAcc-std()-X -0.9938525
#6       STANDING       2 tBodyAcc-std()-X -0.9944552

#cast: for mean of each variable: back to tidy format
avgPerSubjectAndActivity <- dcast(meltData, activity_label + subject ~ variable, mean)
avgPerSubjectAndActivity[1:40,1:5]
#    activity_label subject tBodyAcc-std()-X tBodyAcc-std()-Y tBodyAcc-std()-Z
#1          LAYING       1       -0.9280565       -0.8368274       -0.8260614
#2          LAYING       2       -0.9740595       -0.9802774       -0.9842333
#3          LAYING       3       -0.9827766       -0.9620575       -0.9636910
#4          LAYING       4       -0.9541937       -0.9417140       -0.9626673
#5          LAYING       5       -0.9659345       -0.9692956       -0.9685625
#6          LAYING       6       -0.9340494       -0.9246448       -0.9252161
#7          LAYING       7       -0.9365136       -0.9262627       -0.9529784
#8          LAYING       8       -0.9430412       -0.9348912       -0.9324915
#9          LAYING       9       -0.9423331       -0.9162928       -0.9407073
#10         LAYING      10       -0.9682837       -0.9464543       -0.9594715
#11         LAYING      11       -0.9847773       -0.9721969       -0.9713112
#12         LAYING      12       -0.9553187       -0.9490720       -0.9483338
#13         LAYING      13       -0.9688920       -0.9509479       -0.9503930
#14         LAYING      14       -0.9175019       -0.9096970       -0.9003319
#15         LAYING      15       -0.9722556       -0.9627594       -0.9295868
#16         LAYING      16       -0.9736914       -0.9430612       -0.9654903
#17         LAYING      17       -0.9729606       -0.9447929       -0.9534767
#18         LAYING      18       -0.9845276       -0.9861609       -0.9876587
#19         LAYING      19       -0.9650196       -0.9734500       -0.9846728
#20         LAYING      20       -0.9622491       -0.9640982       -0.9725720
#21         LAYING      21       -0.9550199       -0.9569594       -0.9456538
#22         LAYING      22       -0.9477353       -0.9132763       -0.9429458
#23         LAYING      23       -0.9567564       -0.9763098       -0.9732235
#24         LAYING      24       -0.9679840       -0.9831265       -0.9735670
#25         LAYING      25       -0.9091165       -0.6917707       -0.7172620
#26         LAYING      26       -0.9694454       -0.9832314       -0.9845000
#27         LAYING      27       -0.9784552       -0.9837360       -0.9866370
#28         LAYING      28       -0.9688883       -0.9453868       -0.9564503
#29         LAYING      29       -0.9842196       -0.9902409       -0.9872551
#30         LAYING      30       -0.9763625       -0.9542018       -0.9670442
#31        SITTING       1       -0.9772290       -0.9226186       -0.9395863
#32        SITTING       2       -0.9868223       -0.9507045       -0.9598282
#33        SITTING       3       -0.9710101       -0.8566178       -0.8751102
#34        SITTING       4       -0.9803099       -0.8902240       -0.9322030
#35        SITTING       5       -0.9809450       -0.9043351       -0.9260947
#36        SITTING       6       -0.9801649       -0.9236821       -0.9257971
#37        SITTING       7       -0.9726684       -0.9094547       -0.8565329
#38        SITTING       8       -0.9790262       -0.9273320       -0.9395530
#39        SITTING       9       -0.9572278       -0.8751414       -0.8320019
#40        SITTING      10       -0.9829018       -0.9179795       -0.9678270

#write table
write.table(avgPerSubjectAndActivity, row.name=FALSE, file="avgPerSubjectAndActivity.txt")
