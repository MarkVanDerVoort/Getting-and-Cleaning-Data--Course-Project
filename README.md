Retrieving Human Activity Recognition Data
========================================================

Usage: Run the script supplied in `run_analysis.R`

After running the script the following files are available in the current directory:

* `means per subject and activity.txt`:  The tidied output file. This file contains the intended tidied dataset
* `UCI HAR Dataset`: a local version of the data supplied at https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip . 

Workings
-----------------------------------

The script performs the following actions:

1. Retrieve the inputdata (if not already available)
2. Merge the test and training datasets.
3. Discard the measurements we do not need
4. Rename the remaining variabels
5. Write the output to the file `means per subject and activity.txt`
