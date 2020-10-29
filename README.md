# Data pipeline supporting the new analytics dashboard  

## To add a new application

First, our service account must be given read permissions to the relevant GA account. Contact David Watkins at wwatkins@usgs.gov for instructions.

Information for each app is stored in `gaTable.yaml`. Follow the pattern of the existing entries. The viewID field is the most important field, as that is how the apps are distinguished throughout the codebase.  Adding a view which does not yet have any data may cause an error.

