# CPQ - Pricing Logic Review

This tool is for use in troubleshooting the Salesforce CPQ Price Waterfall.  

## What Does it Do?
- Scans your QCP File for Field API Names
- Checks Price Action target fields for API Names
- Buckets referenced fields by Source
- Orders referenced fields by Price Waterfall step
- Searchable and Sortable Table with Hyperlinks to records.

## What Doesn't it Do?
- Does not read Price Action formula fields - only target fields

## Requirements
- QCP must be structured in recommended format and exported all methods:  https://developer.salesforce.com/docs/atlas.en-us.222.0.cpq_dev_plugins.meta/cpq_dev_plugins/cpq_dev_jsqcp_methods.htm
- Highly suggest using the following extension for vs code:  https://marketplace.visualstudio.com/items?itemName=paustint.sfdc-qcp-vscode-extension


## Installation
- Create Custom Label titled 'QCPName' with your SBQQ__CustomScript__c record api name.
- Create Controller and Test class from repository
- Create LWC from repository
- Deploy LWC against Lightning App Page, Home Page or Lightning Record Page.

## Instructions
- Use it.
