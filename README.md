# CPQ - Pricing Logic Review

This tool is for use in troubleshooting the Salesforce CPQ Price Waterfall.  

**Disclaimer**:  This is a very picky tool built to aid in an incredibly tedious process.  I am not a professional app developer as you'll obviously notice.  Hopefully it's still useful for your purposes.

## CPQ Price Waterfall Background:
- Salesforce Help:  https://help.salesforce.com/s/articleView?id=sf.cpq_quote_calc_process.htm&type=5
- Laid out in nicer format:  https://archwise.io/cpq-pricing-logic-quickview/

## What Does it Do?
- Scans your QCP File for Field API Names
- Checks Price Action target fields for API Names
- Buckets referenced fields by Source
- Orders referenced fields by Price Waterfall step
- Searchable and Sortable Table with Hyperlinks to records.

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
- SBQQ Package must be installed. 


## Installation
- Create Custom Label titled 'QCPName' with your SBQQ__CustomScript__c record api name.
- Create Controller and Test class from repository
- Note:  Depending on SBQQ version, you may have to adjust class .xml for dependency matching.
- Create LWC from repository
- Deploy LWC against Lightning App Page, Home Page or Lightning Record Page.

## Instructions
- Use it.
