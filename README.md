# Data pipeline supporting the new analytics dashboard  

## To add a new application

First, our service account must be given read permissions to the relevant GA account. Contact David Watkins at wwatkins@usgs.gov for instructions.

Information for each app is stored in `gaTable.yaml`. Follow the pattern of the existing entries. The viewID field is the most important field, as that is how the apps are distinguished throughout the codebase.  Adding a view which does not yet have any data may cause an error.

` `  
` `  

## Fill in a missing day/range for monitoring location pages daily summary job, if needed

There is a scheduled Jenkins job that should run every day and stash the summarized monitoring location uniquePageviews in s3 for the previous day. If for some reason it doesn't run or should error, you can run the Jenkins job manually again on the same day for the previous day, but after that you'll have to manually run it locally and catch the s3 repository up if needed.

To do that,

1. open project in Rstudio, open R/monitoring_location_pages_date_range_pull.R
2. ctrl+enter on the packages on lines 1-6 to load them
3. add new vars for start/end dates and the sequence instead of using lines 8-10, e.g.
```
fromDate <- as.Date("2021-06-01")
toDate <- as.Date("2021-06-08")
yesterday <- seq(from=fromDate, to=toDate, by='days')
```
4. to authenticate, save the secret JSON contents from Vault secret iidd-analytics/google_analytics_api to a local copy of the file (e.g. somefile.json) and then load it instead of using lines 12-14,, e.g.
```
gar_auth_service('~/.vizlab/somefile.json') 
``` 
5. ctrl+enter on the rest of the lines in the file (the for loop) to complete the data pull. files will write out to out/monitoring_location_pages 
6. to push them to s3, use the (saml2aws tool)[https://code.chs.usgs.gov/ctek/documentation/-/blob/master/how/onboarding.md#install-saml2aws-utility] in order to authenticate with aws and then push the parquet files you want to s3 using the cli, with a command such as the one below to copy all parquet files from the current directory 
```
aws s3 cp . s3://wma-analytics-data/monitoring_location_pages/production/parquet/ --recursive --include "*.parquet"
```