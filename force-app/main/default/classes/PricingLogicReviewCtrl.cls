public with sharing class PricingLogicReviewCtrl {

    private static Integer idCount = 0;
    private static String stringOnInit;
    private static String stringOnBeforeCalculate;
    private static String stringOnBeforePriceRules;
    private static String stringOnAfterPriceRules;
    private static String stringOnAfterCalculate;
    private static String afterCalcRaw;
    private static String afterPRRaw;
    private static String beforePRRaw;
    private static String beforeCalcRaw;
    private static String qcpId;
    private static String qcpName = System.Label.QCPName; //Label pointing to QCP Name for your Org

    //Map to build sequential processing number - based on pricing waterfall
    //https://help.salesforce.com/s/articleView?id=sf.cpq_quote_calc_process.htm&type=5
    private static Map<String,Integer> seqMap = new Map<String,Integer>{
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

        //Section Lists out of QCP - one per QCP method.
        Set<String> afterCalcList = new Set<String>();
        Set<String> afterPRList = new Set<String>();
        Set<String> beforePRList = new Set<String>();
        Set<String> beforeCalcList = new Set<String>();
        Set<String> onInitList = new Set<String>();
        
        //Combined list of QCP and Price Rules (in wrapper) to pass back to LWC
        List<wrapPR> listPriceReview = new List<wrapPR>();
        
        /*********************************** QCP START *******************************************/
        
        //Build logic to query the QCP
        SBQQ__CustomScript__c qcp = new SBQQ__CustomScript__c();
        if(Test.isRunningTest()){  //if test class, then use default Test Name.  
            qcpName = 'TestQCP';
        }    
        qcp = [SELECT Id, SBQQ__Code__c FROM SBQQ__CustomScript__c WHERE Name = :qcpName LIMIT 1];                              
        String qcpString = qcp.SBQQ__Code__c; //field from QCP that holds javascript logic.
        qcpId = qcp.Id; //use to form URL for QCP
        
        //After Calculate Section
        stringOnAfterCalculate = qcpString.split('function onAfterCalculate')[1].split('Promise.resolve')[0];
        afterCalcList = listMatches(stringOnAfterCalculate);
        for(String eachField : afterCalcList){
            wrapPR thisWrapPR = buildWrapPR(eachField,'onAfterCalculate');
            listPriceReview.add(thisWrapPR);
        }
        afterCalcRaw = qcpString.split('function onAfterCalculate')[0];
        
        //After Price Rule Section
        stringOnAfterPriceRules = afterCalcRaw.split('function onAfterPriceRules')[1].split('Promise.resolve')[0];
        afterPRList = listMatches(stringOnAfterPriceRules);
        for(String eachField : afterPRList){
            wrapPR thisWrapPR = buildWrapPR(eachField,'onAfterPriceRules');
            listPriceReview.add(thisWrapPR);
        }
        afterPRRaw = afterCalcRaw.split('function onAfterPriceRules')[0];
        
        //Before Price Rule Section
        stringOnBeforePriceRules = afterPRRaw.split('function onBeforePriceRules')[1].split('Promise.resolve')[0];
        beforePRList = listMatches(stringOnBeforePriceRules);
        for(String eachField : beforePRList){
            wrapPR thisWrapPR = buildWrapPR(eachField,'onBeforePriceRules');
            listPriceReview.add(thisWrapPR);
        }
        beforePRRaw = afterPRRaw.split('function onBeforePriceRules')[0];
        
        //Before Calculation Section
        stringOnBeforeCalculate = beforePRRaw.split('function onBeforeCalculate')[1].split('Promise.resolve')[0];
        beforeCalcList = listMatches(stringOnBeforeCalculate);
        for(String eachField : beforeCalcList){
            wrapPR thisWrapPR = buildWrapPR(eachField,'onBeforeCalculate');
            listPriceReview.add(thisWrapPR);
        }
        beforeCalcRaw = beforePRRaw.split('function onBeforeCalculate')[0];
        
        //On Initialization Section
        stringOnInit = beforeCalcRaw.split('function onInit')[1].split('Promise.resolve')[0];
        onInitList = listMatches(stringOnInit);
        for(String eachField : onInitList){
            wrapPR thisWrapPR = buildWrapPR(eachField,'onInit');
            listPriceReview.add(thisWrapPR);
        }

        /*********************************** QCP END *******************************************/
        
        /***************************** PRICE ACTION START **************************************/
        
        //Build logic to query Price Actions for Active Price Rules only
        List<SBQQ__PriceRule__c> listPR = [SELECT Id, SBQQ__EvaluationEvent__c, Name,
                                              (SELECT Id, SBQQ__TargetObject__c, SBQQ__Field__c 
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
                wrapPR thisWrapPR = new wrapPR();
                if(idCount == 0) thisWrapPR.unq = 1;
                if(idCount > 0) thisWrapPR.unq = idCount;
                thisWrapPR.obj = pa.SBQQ__TargetObject__c;
            	thisWrapPR.fld = pa.SBQQ__Field__c;
                if(splitCount == 0){
                    thisWrapPR.timing = pr.SBQQ__EvaluationEvent__c;
                    thisWrapPR.seq = seqMap.get(pr.SBQQ__EvaluationEvent__c);
                }else{
                    thisWrapPR.timing = splitEval[0];
                    thisWrapPR.seq = seqMap.get(thisWrapPR.timing);
                }
            	thisWrapPR.source = 'Price Rule';
                thisWrapPR.parentUrl = '/'+pr.Id;
                thisWrapPR.parentName = pr.Name;
                idCount ++;
                listPriceReview.add(thisWrapPR);
                if(splitCount > 0){
                    for(Integer i=1; i< splitCount; i++){
                        wrapPR cloneWrap = thisWrapPR.clone();
                        cloneWrap.unq = idCount;
                    	cloneWrap.timing = splitEval[i];
                    	cloneWrap.seq = seqMap.get(cloneWrap.timing);
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
        if(idCount == 0) thisWrapPR.unq = 1;
        if(idCount > 0) thisWrapPR.unq = idCount + 1;
        thisWrapPR.fld = fieldName;
        thisWrapPR.obj = 'Quote Line';
        thisWrapPR.source = 'QCP';
        thisWrapPR.parentUrl = '/'+qcpId;
        thisWrapPR.parentName = 'QCP';
        thisWrapPR.seq = seqMap.get(thisWrapPR.timing);
        idCount ++;
        return thisWrapPR;
    }

    //Internal function to run through matcher to get results from within tags
    private static Set<String> listMatches (String inputBlock){
        Set<String> returnResultsList = new Set<String>();

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
            returnResultsList.add(match);  
        }
        return returnResultsList;
    }
    
    //Wrapper class definition
    public class wrapPR {
        @AuraEnabled
        public integer seq {get;set;}
        @AuraEnabled
        public integer unq {get;set;}
        @AuraEnabled
        public string obj {get;set;}
        @AuraEnabled
        public string fld {get;set;}
        @AuraEnabled
        public string timing {get;set;}
        @AuraEnabled
        public string source {get;set;}
        @AuraEnabled
        public string parentUrl {get;set;}
        @AuraEnabled
        public string parentName {get;set;}
    }

}