
## Codebook for the resultant tidy data set. 

As part of the Course Project for Getting and Cleaning Data course by Coursera.

The details of the raw data can be found under the following links:
http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones 

The resultant tidy data set contains one observation at each row.
The first 2 columns provide the activity label and the subject.
The rest 66 columns contain one feature per column.

The features are the averages per subject and per activity (of the mean and standard deviation) on the 33 variables collected.

The test data is composed of the following 3 files. They were read into seperate 
objects. The dimensions are as follows:
dim(x_test) # 2947 x 561 
dim(y_test) # 2947 x 1
dim(subject_test) # 2947 x 1

Before combinign test data by columns, it would be better to rename the column names, 
because the first column of all 3 data.frames are the same "V1", and this might be confusing.
We could rename V1..V561 columns as the feature names, simply by names(x_test) <- features[,2] 
but we rather not do it since the feature descriptions contain duplicates, 
and we would anyway access specific features by column index

Combine test data: 
The order of the columns below is important. We put x_test on the left, 
 the indexes (or the location) of the first 561 columns should remain the same, 
 because the features table contain the column index and relevant feature description 
 and this mapping should be stable.
 
Similarly, here are the train data files, with dimensions:
dim(x_train) # 7352 x 561
dim(y_train) # 7352 x 1
dim(subject_train) #7532 x 1

Combine train data:
Train data were merged similarly.

Combine test and train data 
Since test data and train data are just different observations, having the same structure we row bind them:
data <- rbind(test_data, train_data)
dim(data) # 10299 x 563

Descriptive names
The descriptive activity names can be read from the activity_labels table:
  V1                 V2
1  1            WALKING
2  2   WALKING_UPSTAIRS
3  3 WALKING_DOWNSTAIRS
4  4            SITTING
5  5           STANDING
6  6             LAYING

Since row names are equal to the first column values, which are the label indexes,
 we can use simple subsetting to select the descriptive activity names in the second column. 
 
The descriptive variable names are stored in the second column of features table
head(features,3)
  V1                V2
1  1 tBodyAcc-mean()-X
2  2 tBodyAcc-mean()-Y
3  3 tBodyAcc-mean()-Z

note that the first column, having the indexes for the features, have the same value as the row names.
 which allows us to be able to use simpler subsetting, instead of dplyr::filter
The variable names in our extracted data set contains these indexes, following a "V" yet:
extractedData[1:3, 1:3]
          V4         V5         V6
1 -0.9384040 -0.9200908 -0.6676833
2 -0.9754147 -0.9674579 -0.9449582
3 -0.9938190 -0.9699255 -0.9627480

Use subsetting on features table to get the descriptive feature names
newNames <- c(as.character(features[featureIndexes,2]), names(extractedData[,67:68]))
names(extractedData) <- newNames

the resultant tidy data:
extractedData[1:3, c(1:3, 66:68)]
  tBodyAcc-std()-X tBodyAcc-std()-Y tBodyAcc-std()-Z fBodyBodyGyroJerkMag-mean() subject    activity_label
1       -0.9384040       -0.9200908       -0.6676833                  -0.8901655       2          STANDING
2       -0.9754147       -0.9674579       -0.9449582                  -0.9519774       2          STANDING
3       -0.9938190       -0.9699255       -0.9627480                  -0.9856888       2          STANDING
