/* eslint-disable no-console */
import { LightningElement,wire,track } from 'lwc';
import getLogic from '@salesforce/apex/PricingLogicReviewCtrl.getLogic';

export default class PricingLogicReview extends LightningElement {

    @track error;
    @track data;
    @track spinner = false;
    @track datanew = [];
    @track datatemp = [];
    @track resultsSize = 0;
    wiredLogicResult;
    @track sortedBy = 'seq';
    @track sortedDirection = 'asc';
    @track columns = [{
        label: 'Sequence',
        fieldName: 'seq',
        type: 'text',
        sortable: true,
        initialWidth: 120,
    },
    {
        label: 'Type',
        fieldName: 'source',
        type: 'text',
        sortable: true,
        initialWidth: 200,
    },
    {
        label: 'Timing',
        fieldName: 'timing',
        type: 'text',
        sortable: true,
    },
    {
        label: 'Parent',
        fieldName: 'parentUrl',
        type: 'url',
        typeAttributes: {
            label: { 
                fieldName: 'parentName' 
            }, 
            target: '_blank'
        },
        sortable: true,
    },
    {
        label: 'Field',
        fieldName: 'fld',
        type: 'text',
        sortable: true,
        initialWidth: 400,
    }
    ];
    @track options = [
        {label:"All",value:""}
    ];
    @track timingFilter = '';
    @track searchFilter = '';
    
    /*api v55 - supports virtual rendering.  giving error in table, so not using.
    //https://help.salesforce.com/s/articleView?id=release-notes.rn_lc_datatable.htm&type=5&release=238
    renderConfig = {
        virtualize: 'vertical'
    };*/

    get options(){
        return this.options;
    }

    //Dynamic set return or filter results in lightning card title
    get cardtitle(){
        return `Price Waterfall Overview (${this.resultsSize})`;
    }

    @wire (getLogic,{})
    wiredLogic(result){
        this.spinner = true;
        this.wiredLogicResult = result;
        if(result.data){
            this.spinner = false;
            let checkUnique = false;
            this.data = result.data;
            for(let i = 0; i < this.data.length; i++){
                checkUnique = this.options.filter( opt => (opt.label === this.data[i].timing));
                if(checkUnique == false){
                    this.options = [...this.options, {label: this.data[i].timing, value: this.data[i].timing}];
                }
            }
            this.datanew = [...this.data];
            this.sortData('seq','asc');
            this.resultsSize = this.datanew.length;
        }else if(result.error){
            this.spinner = false;
            this.error = result.error;
            console.error(this.error);
            //consider adding additional error logic here as needed in your organization.
        }
    }

    handleOption(event){
        this.timingFilter = event.target.value;
        this.filterData(this.searchFilter,this.timingFilter);
    }

    handleSearch(event){
        this.searchFilter = event.target.value;
        //Add timeout to prevent DOM exception for lightning-datatable
        setTimeout( () => {
            this.filterData(this.searchFilter,this.timingFilter);  
        }, 1000);
    }

    filterData(search,option){
        let regexsearch = new RegExp(search,'gi');
        //getting error on child node when using lightning-datatable unless timeout set.
        if(option != '' && option != 'All'){
            this.datanew = this.data.filter(row => row.timing == option && regexsearch.test(row.fld));
        }else{
            this.datanew = this.data.filter(row => regexsearch.test(row.fld));
        }
        this.resultsSize = this.datanew.length;
        this.sortData('seq','asc');
    }

    sortData(fieldName, sortDirection){
        let temp = JSON.parse(JSON.stringify(this.datanew));
        temp.sort((a,b) => {
            if(a[fieldName] < b[fieldName])
                return sortDirection === 'asc' ? -1 : 1;
            else if(a[fieldName] > b[fieldName])
                return sortDirection === 'asc' ? 1 : -1;
            else
                return 0;
        });
        this.datanew = temp;
    }

    updateColumnSorting(event){
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy,this.sortedDirection);       
    }

}