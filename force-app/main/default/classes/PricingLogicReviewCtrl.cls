public with sharing class PricingLogicReviewCtrl {

    private static String qcpId;
    private static String qcpName = System.Label.QCPName; //Label pointing to QCP Name for your Org
    private static Integer idCount = 0; //not used, but leaving or row uniqueness in future
    private static Map<String,Map<String,Schema.SObjectField>> mapObj2FieldMap = 
        new Map<String,Map<String,Schema.SObjectField>>();

    //Map to build sequential processing number - based on pricing waterfall
    //https://help.salesforce.com/s/articleView?id=sf.cpq_quote_calc_process.htm&type=5
    private static Map<String,Integer> mapSequence = new Map<String,Integer>{
        'On Initialization' => 1,
        'onInit' => 2,
        'onBeforeCalculate' => 3,
        'Before Calculate' => 4,
        'onBeforePriceRules' => 5,
        'On Calculate' => 6,
        'onAfterPriceRules' => 7,
        'After Calculate' => 8,
        'onAfterCalculate' => 9 
    };

    @AuraEnabled (cacheable=true)
    public static List<wrapPR> getLogic(){
        
        //Combined list of QCP and Price Rules (in wrapper) to pass back to LWC
        List<wrapPR> listPriceReview = new List<wrapPR>();
        
        /*********************************** QCP START *******************************************/
        
        //Build logic to query the QCP
        SBQQ__CustomScript__c qcp = new SBQQ__CustomScript__c();
        if(Test.isRunningTest()){  //if test class, then use default Test Name.  
            qcpName = 'TestQCP';
        }    
        try{
            qcp = [SELECT Id, SBQQ__Code__c 
                   FROM SBQQ__CustomScript__c 
                   WHERE Name = :qcpName LIMIT 1];  
        }catch(Exception e){
            throw new AuraHandledException('No QCP Found');
        }                     
        String qcpString = qcp.SBQQ__Code__c; //field from QCP that holds javascript logic.
        qcpId = qcp.Id; //use to form URL for QCP
        
        //After Calculate Section
        String stringOnAfterCalculate = 
            qcpString.split('function onAfterCalculate')[1].split('Promise.resolve')[0];
        Set<String> afterCalcSet = getMatches(stringOnAfterCalculate);
        for(String eachField : afterCalcSet){
            wrapPR thisWrapPR = buildWrapPR(eachField,'onAfterCalculate');
            listPriceReview.add(thisWrapPR);
        }
        String afterCalcRaw = qcpString.split('function onAfterCalculate')[0];
        
        //After Price Rule Section
        String stringOnAfterPriceRules = 
            afterCalcRaw.split('function onAfterPriceRules')[1].split('Promise.resolve')[0];
        Set<String> afterPRSet = getMatches(stringOnAfterPriceRules);
        for(String eachField : afterPRSet){
            wrapPR thisWrapPR = buildWrapPR(eachField,'onAfterPriceRules');
            listPriceReview.add(thisWrapPR);
        }
        String afterPRRaw = afterCalcRaw.split('function onAfterPriceRules')[0];
        
        //Before Price Rule Section
        String stringOnBeforePriceRules = 
            afterPRRaw.split('function onBeforePriceRules')[1].split('Promise.resolve')[0];
        Set<String> beforePRSet = getMatches(stringOnBeforePriceRules);
        for(String eachField : beforePRSet){
            wrapPR thisWrapPR = buildWrapPR(eachField,'onBeforePriceRules');
            listPriceReview.add(thisWrapPR);
        }
        String beforePRRaw = afterPRRaw.split('function onBeforePriceRules')[0];
        
        //Before Calculation Section
        String stringOnBeforeCalculate = 
            beforePRRaw.split('function onBeforeCalculate')[1].split('Promise.resolve')[0];
        Set<String> beforeCalcSet = getMatches(stringOnBeforeCalculate);
        for(String eachField : beforeCalcSet){
            wrapPR thisWrapPR = buildWrapPR(eachField,'onBeforeCalculate');
            listPriceReview.add(thisWrapPR);
        }
        String beforeCalcRaw = beforePRRaw.split('function onBeforeCalculate')[0];
        
        //On Initialization Section
        String stringOnInit = 
            beforeCalcRaw.split('function onInit')[1].split('Promise.resolve')[0];
        Set<String> onInitSet = getMatches(stringOnInit);
        for(String eachField : onInitSet){
            wrapPR thisWrapPR = buildWrapPR(eachField,'onInit');
            listPriceReview.add(thisWrapPR);
        }

        //---------------------------------- QCP END -------------------------------------------/
        
        //---------------------------- PRICE ACTION START --------------------------------------/
        
        //Build logic to query Price Actions for Active Price Rules only
        List<SBQQ__PriceRule__c> listPR = [SELECT Id, SBQQ__EvaluationEvent__c, Name,
                                              (SELECT Id, SBQQ__TargetObject__c, SBQQ__Field__c,
                                                SBQQ__Formula__c, SBQQ__ValueField__c
                                               FROM SBQQ__PriceActions__r 
                                               ORDER BY SBQQ__Field__c ASC) 
                                           FROM SBQQ__PriceRule__c WHERE SBQQ__Active__c = TRUE];
        List<String> splitEval = new List<String>();
        for(SBQQ__PriceRule__c pr: listPR){
            Integer splitCount = 0;
            //Break the Price Rules into groups based on Evaluation Event.
            if(pr.SBQQ__EvaluationEvent__c.contains(';')){
                splitEval = pr.SBQQ__EvaluationEvent__c.split(';'); //some may have multiple
                splitCount = splitEval.size();
            }
            //Loop through the related Price Actions for each Price Rule and add to Wrapper.
            for(SBQQ__PriceAction__c pa : pr.SBQQ__PriceActions__r){
                Set<String> setFieldsFromFormula = new Set<String>();
                wrapPR thisWrapPR = new wrapPR();
                if(idCount == 0){
                    thisWrapPR.unq = 1;
                } 
                if(idCount > 0){
                    thisWrapPR.unq = idCount + 1;
                } 
                thisWrapPR.obj = pa.SBQQ__TargetObject__c;
                thisWrapPR.fld = pa.SBQQ__Field__c;
                //Label will be messy as standard will not be api name.
                /*thisWrapPR.fldlabel = getFieldLabel(pa.SBQQ__TargetObject__c,pa.SBQQ__Field__c);
                if(thisWrapPR.fldlabel != null){
                    thisWrapPR.fld += ' ('+ thisWrapPR.fldlabel + ')';
                }*/
                //Start add function to get the values from formula and source fields
                if(pa.SBQQ__Formula__c != null){
                    thisWrapPR.sourceformflds = 
                        String.join(new List<String>(getFormulaMatches(pa.SBQQ__Formula__c)),', ');
                }else if(pa.SBQQ__ValueField__c != null){
                    thisWrapPR.sourceformflds = pa.SBQQ__ValueField__c;
                }
                //End add function to get the values from formula and source fields
                if(splitCount == 0){
                    thisWrapPR.timing = pr.SBQQ__EvaluationEvent__c;
                    thisWrapPR.seq = mapSequence.get(pr.SBQQ__EvaluationEvent__c);
                }else{
                    thisWrapPR.timing = splitEval[0];
                    thisWrapPR.seq = mapSequence.get(thisWrapPR.timing);
                }
            	thisWrapPR.source = 'Price Rule';
                thisWrapPR.parentUrl = '/'+pr.Id;
                thisWrapPR.parentName = pr.Name;
                idCount ++;
                listPriceReview.add(thisWrapPR);
                //if multiple events, assign field to each timing group by cloning and looping
                if(splitCount > 0){ 
                    for(Integer i=1; i< splitCount; i++){
                        wrapPR cloneWrap = thisWrapPR.clone();
                        cloneWrap.unq = idCount + 1;
                    	cloneWrap.timing = splitEval[i];
                    	cloneWrap.seq = mapSequence.get(cloneWrap.timing);
                        idCount ++;
                    	listPriceReview.add(cloneWrap);
                    }  
                }
            }
        }

        /***************************** PRICE ACTION END **************************************/

        return listPriceReview;  //final wrapper list to return to lwc
    }
    
    //Internal function to build the wrapper object
    private static wrapPR buildWrapPR(String fieldName,String calcTiming){
        wrapPR thisWrapPR = new wrapPR();
        thisWrapPR.timing = calcTiming;
        if(idCount == 0){
            thisWrapPR.unq = 1;
        } 
        if(idCount > 0){ 
            thisWrapPR.unq = idCount + 1;
        }
        thisWrapPR.fld = fieldName;
        thisWrapPR.obj = 'Quote Line';
        thisWrapPR.source = 'QCP';
        thisWrapPR.parentUrl = '/'+qcpId;
        thisWrapPR.parentName = 'QCP';
        thisWrapPR.seq = mapSequence.get(thisWrapPR.timing);
        idCount ++;
        return thisWrapPR;
    }

    //Internal function to run through matcher to get results from within tags
    //Instead of repeating fields multple times for QCP, we'll put to set for uniqueness
    private static Set<String> getMatches (String inputBlock){
        Set<String> returnResultsSet = new Set<String>();

        //Match custom fields - for SBQQ this is fine aside from Id - not important for function
        Matcher single = Pattern.compile(Pattern.quote('line.record["') + '(.*?__c)'
            + Pattern.quote('"]')).matcher(inputBlock);

        //this tested a bit faster than doing two matchers and find.
        while(single.find()){
            String match = '';
            if(single.group(1).contains('__r\"][\"')){
                match = single.group(1).replace('\"', '').replace('][','.');
            }else{
                match = single.group(1);
            }
            returnResultsSet.add(match);  
        }
        return returnResultsSet;
    }

    //Internal function to run through formula and return fields found there.
    private static Set<String> getFormulaMatches(String inputField){
        Set<String> returnResultsSet = new Set<String>();

        //Match fields - for SBQQ these will all be custom except Id.
        Matcher single = Pattern.compile('(?i)\\b\\w*' + Pattern.quote('__c') + '\\w*\\b').matcher(inputField);

        while(single.find()){
            String match = '';
            match = single.group(0);
            returnResultsSet.add(match);  
        }
        return returnResultsSet;
    }

    /*
    //Build label from api name for usability
    private static String getFieldLabel(String objectApiName, String fieldApiName){
        if(!mapObj2FieldMap.containsKey(objectApiName)){
            mapObj2FieldMap.put(objectApiName,Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap());
        }
        return mapObj2FieldMap.get(objectApiName).get(fieldApiName).getDescribe().getLabel();
    }

    //Custom picklist values will be proper Object Api Name
    //Standard package picklist values (Quote, Quote Line) will be label instead.
    private static String getObjectApiName(String objectLabel){}
    */
    
    //Wrapper class definition
    public class wrapPR {
        @AuraEnabled
        public integer seq {get;set;}
        @AuraEnabled 
        public integer unq {get;set;} //not used, but leaving for row uniqueness in future
        @AuraEnabled
        public string obj {get;set;}
        @AuraEnabled
        public string fld {get;set;}
        //@AuraEnabled
        //public string fldlabel {get;set;}
        @AuraEnabled
        public string timing {get;set;}
        @AuraEnabled
        public string source {get;set;}
        @AuraEnabled
        public string parentUrl {get;set;}
        @AuraEnabled
        public string parentName {get;set;}
        @AuraEnabled
        public string sourceformflds {get;set;}
    }

}