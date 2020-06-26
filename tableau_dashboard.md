# Overview

There are two Tableau Workbooks in both the development and production Tableau servers, Analytics Dashboard Exploration (ADE) and Executive Council Dashboard (ECD). The ADE workbook contains many additional views that are not present in the ECD, meant to provide richer content to product owners (POs), whereas the ECD is meant to provide a quicker/at-a-glance summary of the portfolio, suited for meeting the WMA Executive Council's needs.

# Maintenance

There are several places where there are filters or sets created in the Tableau workbooks that will need to be modified should the membership of the set of applications change. There are a few sets with specific applications identified as members, the Internet of Water (IoW) portfolio and the Flagship applications.

## In the ADE Workbook:

- filter in Flagship Apps Trends View worksheet on field App Name
- filter in Flagship Apps Trends Table worksheet on field App Name
- filter in IoW Trends View worksheet on field App Name
- filter in IoW Trends Table worksheet on field App Name
- set in IoW Apps worksheet called IoW Apps
- set in Flagship Apps worksheet called Flagship Apps

## In ECD Workbook:

- filter in Flagship Apps Trends View worksheet on field App Name
- filter in Flagship Apps Trends Table worksheet on field App Name
- set for Flagship Apps (these may all update if you update one since they are tied to the same dataset)
  - EC Portfolio Bar Chart2 worksheet
  - BAN Day of Week Views worksheet
  - BAN Devices worksheet
  - BAN Browsers worksheet
  - BAN Avg Session Duration worksheet
  - BAN Total Session Duration worksheet
  - BAN Total Sessions worksheet
  - BAN # of apps monitoring worksheet
  - BAN New Sessions worksheet
  - Trends Summary worksheet
  - Trend List worksheet
- set for IoW Apps in (these may all update if you update one since they are tied to the same dataset)
  - EC Portfolio Bar Chart2 worksheet
  - BAN Day of Week Views worksheet
  - BAN Devices worksheet
  - BAN Browsers worksheet
  - BAN Avg Session Duration worksheet
  - BAN Total Session Duration worksheet
  - BAN Total Sessions worksheet
  - BAN # of apps monitoring worksheet
  - BAN New Sessions worksheet
  - Trends Summary worksheet
  - Trend List worksheet

# Updating the dropdown list of applications in SharePoint List

If the list of applications changes, the corresponding list of applications needs to be updated in the [SharePoint List/Form](https://doimspp.sharepoint.com/sites/USGSWaterMissionArea/SitePages/Google-Analytics-Event-Annotations---Entry-Form.aspx) to ensure POs can submit events for every app listed. With an updated alphabetized list in hand/in your clipboard, visit the actual [list address](https://doimspp.sharepoint.com/sites/USGSWaterMissionArea/Lists/Google%20Analytics%20Event%20Annotations/AllItems.aspx), click on the gear icon way up in the upper right corner of the list, and click on List Settings. Scroll down to where you see the Columns section on the page, click on the View Name Column name (it is a link even though it doesn't look like a link) and paste in your updated list over the top of the existing list in the view. Click the OK link in the lower right corner to save.

# Important data links/blends

The worksheets displaying Google Analytics Event Annotation data from SharePoint require several data blends to be set up in order to display correctly. The data blends/joins required within the worksheets include matching the fields from all_apps_traffic_data_3_years on Calculated FY, EqualizerDate and View Name. Without these relationships enabled in the view, the annotations won't appear on the session/user visit data.

# Forcing data updates from Athena

In order to force a data update in the Workbooks, navigate to the Tableau server, go to Explore -> All Data Sources, and click on the ... next to the name of the data source, and click 'Refresh Extracts' to enter a dialog window to request the extract be updated. They are currently updating automatically every weekday morning at 5AM CT.

The SharePoint List updates every weekday evening at 11pm CT.

# Embedded passwords

There are details about the connections as well as passwords embedded in the published data sources on both Tableau Servers. For the data coming from Athena, these details include the server location at AWS (athena.us-west-2.amazonaws.com), the port (443), the s3 staging directory (s3://water-athena-query-results), the accessKey and secretAccessKey. These secrets can be found in the Makerspace Vault in CHS.

The SharePoint Google Analytics Event Annotations are connected to the Tableau Workbook currently using my (mhines-usgs) USGS AD account, and while the password is embedded, it will have to be updated every time I change my password to ensure the connection remains functional. The other connection details include the [SharePoint Site](https://doimspp.sharepoint.com/sites/gs-wma-iidd-makerspace), edition (SharePoint Online), Authentication (Third-party SSO), username (mhines@usgs.gov), password (my AD password), and SSO Domain (blank/optional.)

# Editing and publishing workflow

If you want to make edits to the Tableau workbooks, first open Tableau Desktop and under the *Server* menu, sign into the internal server (https://tableau.chs.usgs.gov). Typically I'd suggest making the changes on development and testing them out after publishing on the desired Tableau server before then publishing them to the production server (https://tableau.usgs.gov).

After signing into the server, in Tableau Desktop, click on the *Server* menu again, then *Open Workbook*, and it will default to show you 'My Workbooks' which are workbooks you have authored. To select one from a shared area or shared development group, navigate in the drop down menu to *All Workbooks* and pick out either the Analytics Dashboard Exploration (detailed views) or the Executive Council Dashboard.

Once the workbook is open, make any necessary edits, and then go back to the *Server* menu, and click on *Publish Workbook*. It will open a dialog window asking about details of the publication such as where in the server (project) what to call it, etc. The important things to check before publishing are the Data Sources (click Edit) to make sure the passwords are embedded. You also have the options here to modify with checkboxes what worksheets actually are published/visible on Tableau Server.

After you publish and test on the development server, you can change the data source details so that they reconnect to the production data sources before publishing to the production server.

First, go to the *Data* menu, menu over of the data sources, select *Tableau Data Server*  then *Edit Server and Site Path*. Click the Change Sign In button and then select the production server (https://tableau.usgs.gov). (If you do not see it listed, open a new copy of Tableau Desktop, go to the Server menu, and click Sign In To Another Server, and connect there. Then return back to the other workbook/Tableau Desktop instance and it should appear now in that drop down).

After selection of the production server and clicking the Connect button, you will be presented with selecting either *Internal Guest Access* or *Public* as an option, in our case we want to push to the Internal production server which is only viewable to internal USGS network users.

Step 2 asks you to choose the data source from the production server, in our case we want to pick exactly the one we started this Edit Server and Site Path process for (as a hint, it is displayed in Step 3 below). Once you select it the Step 3 dialog box will become editable, and I remove the garbage they automatically tack on to leave the generic names more generic and less server specific. (e.g. if it defaults to state_traffic_population_percentages (analytics_test) | Project : WMAIIDD - Production (Internal), remove everything after (analytics_test)) for my example, the connection name ends up being state_traffic_population_percentages (analytics_test)

After you're sure you picked the right data source, click OK. Almost immediately it should ask in a new dialog window 'There are other Tableau data server sources. Choose Yes to modify all of them to point to the same server or No to cancel the change' - in our case we do want all the other sources to change to production too before we publish this workbook to the production server, so say YES. It will take a moment to respond while it reconnects all the data sources to the production server.

After it finishes and the Processing Request dialog window goes away, you can go up to the Server menu, and you should see you're now signed into the production server, click on Publish Workbook, verify the settings are correct, and click Publish. Ignore warnings about overriding the existing workbook, that is what we want to do, often.

## Other stuff about publishing

For the EC Dashboard, we do not publish with 'Show Sheets as Tabs' option, but for the ADE we do. We also only publish the EC Dashboard dashboard itself to the production/internal server, none of the other worksheets.

For ADE we only publish the Dashboards themselves to the production/internal server, but for the development server, we publish all the sheets/views.

Be mindful that there is a hardcoded button in the EC Dashboard that takes users from the EC view to the ADE dashboard with more detailed views, and it contains a hardcoded URL. Unfortunately this is currently a manual step that needs to be modified when publishing from one server to the other. if you make the red button active by clicking on the container for it in the EC Dashboard dashboard, you can click on the down caret/arrow and click Edit Image. This will give you the Target URL field that can be modified depending on where you're publishing to.

# Athena Data Sources

We currently have manually created these within the AWS S3 console (from Athena service, click on Create Table, from S3 bucket data, and fill in the dialog windows, the field name details below can be used to "bulk add" columns within each parquet file) however at some point we would like to create these via Cloudformation, although at this point in time there is some kind of permission issue we've encountered attempting to use CF.

```
table name: long_term_monthly
filename: long_term_monthly.parquet
path: s3://wma-analytics-data/dashboard/test/parquet/long_term_monthly/
year string,
month string,
sessions double,
avgSessionDuration double,
pageviewsPerSession double,
percentNewSessions double,
view_id string,
view_name string,
fiscal_year date,
backfill boolean

table name: page_load_30_days
path: s3://wma-analytics-data/dashboard/test/parquet/page_load/
filename: page_load_30_days.parquet
pagePath string,
pageLoadSample double,
avgPageLoadTime double,
avgPageDownloadTime double,
avgDomContentLoadedTime double,
exitRate double,
view_id string,
view_name string

table name: all_apps_traffic_data_3_years
filename: all_apps_traffic_data_3_years.parquet
path: s3://wma-analytics-data/dashboard/test/parquet/landing_exit_pages/
date date,
sessions double,
users double,
view_id string,
view_name string,
year date,
fiscal_year date

table name: year_month_week_traffic
path: s3://wma-analytics-data/dashboard/test/parquet/year_month_week/
filename: year_month_week_traffic.parquet
year_month_week_traffic.parquet
view_name string,
view_id string,
sessions double,
users double,
period string

table name: state_traffic_year_month_week
filename: state_traffic_year_month_week.parquet
path: s3://wma-analytics-data/dashboard/test/parquet/state_traffic/
state_traffic_year_month_week
region string,
country string,
sessions double,
view_id string,
view_name string,
period string

table name: all_apps_landing_exit_pages
path: s3://wma-analytics-data/dashboard/test/parquet/landing_exit_pages/
filename: all_apps_landing_exit_pages.parquet
landing_exit_pages
landingpagepath string,
secondpagepath string,
exitpagepath string,
sessions double,
view_id string,
view_name string

table name: summary_numbers
path: s3://wma-analytics-data/dashboard/test/parquet/summary_numbers/
file name: summary_numbers.parquet
deviceCategory string,
browser string,
dayOfWeekName string,
sessions double,
percentNewSessions double,
sessionDuration double,
view_id string,
view_name string,
period string,
newSessions double

table name: compared_to_last_year
path: s3://wma-analytics-data/dashboard/test/parquet/compared_to_last_year/
file name: compared_to_last_year.parquet
view_name string,
view_id string,
sessions_this_year double,
n_this_year bigint,
first_non_zero_date_this_year date,
sessions_last_year double,
n_last_year bigint,
first_non_zero_date_last_year date,
percent_change double,
period string

table name state_week_vs_year
path s3://wma-analytics-data/dashboard/test/parquet/state_week_vs_year/
file name state_week_vs_year.parquet
view_id string,
view_name string,
region string,
365_days double,
30_days double,
7_days double,
week_over_year double,
weekly_average double,
week_percent_from_average

table name state_traffic_population_percentages
path s3://wma-analytics-data/dashboard/test/parquet/state_traffic_population_percentages/
file name state_traffic_population_percentages.parquet
view_name string,
region string,
view_id string,
period string,
sessions double,
DIVISION string,
STATE bigint,
POPESTIMATE2019 bigint,
pop_pct double,
sessions_total_period double,
sessions_pct double,
sessions_population_ratio double,
country string
```
