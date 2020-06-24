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
  - Trend List worksheet~~~~

# Updating the dropdown list of applications in SharePoint List

If the list of applications changes, the corresponding list of applications needs to be updated in the [SharePoint List/Form](https://doimspp.sharepoint.com/sites/USGSWaterMissionArea/SitePages/Google-Analytics-Event-Annotations---Entry-Form.aspx) to ensure POs can submit events for every app listed. With an alphabetized list in hand, visit

# Important data links/blends

The worksheets displaying Google Analytics Event Annotation data from SharePoint is a little complicated. The data blends/joins required within the worksheets include matching the fields from all_apps_traffic_data_3_years on Calculated FY, EqualizerDate and View Name. Without these relationships enabled in the view, the annotations won't appear on the session/user visit data.

# Forcing data updates from Athena

In order to force a data update in the Workbooks, navigate to the Tableau server, go to Explore -> All Data Sources, and click on the ... next to the name of the data source, and click 'Refresh Extracts' to enter a dialog window to request the extract be updated. They are currently updating automatically every weekday morning at 5AM CT.

The SharePoint List updates every weekday evening at 11pm CT.

# Embedded passwords

There are details about the connections as well as passwords embedded in the published data sources on both Tableau Servers. For the data coming from Athena, these details include the server location at AWS (athena.us-west-2.amazonaws.com), the port (443), the s3 staging directory (s3://water-athena-query-results), the accessKey and secretAccessKey. These secrets can be found in the Makerspace Vault in CHS.

The SharePoint Google Analytics Event Annotations are connected to the Tableau Workbook currently using my (mhines-usgs) USGS AD account, and while the password is embedded, it will have to be updated every time I change my password to ensure the connection remains functional. The other connection details include the [SharePoint Site](https://doimspp.sharepoint.com/sites/gs-wma-iidd-makerspace), edition (SharePoint Online), Authentication (Third-party SSO), username (mhines@usgs.gov), password (my AD password), and SSO Domain (blank/optional.)
