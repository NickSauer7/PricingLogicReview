@isTest
public with sharing class PricingLogicReviewCtrlTest {

    @TestSetup
    static void createTestData(){
        //Create Price Rule
        List<SBQQ__PriceRule__c> listPR = new List<SBQQ__PriceRule__c>();
        SBQQ__PriceRule__c pr1 = new SBQQ__PriceRule__c();
        pr1.SBQQ__Active__c = true;
        pr1.SBQQ__EvaluationEvent__c = 'On Initialization;Before Calculate';
        pr1.SBQQ__TargetObject__c = 'Calculator';
        listPR.add(pr1);
        SBQQ__PriceRule__c pr2 = new SBQQ__PriceRule__c();
        pr2.SBQQ__Active__c = true;
        pr2.SBQQ__EvaluationEvent__c = 'On Calculate;After Calculate';
        pr2.SBQQ__TargetObject__c = 'Calculator';
        listPR.add(pr2);
        SBQQ__PriceRule__c pr3 = new SBQQ__PriceRule__c();
        pr3.SBQQ__Active__c = true;
        pr3.SBQQ__EvaluationEvent__c = 'Before Calculate';
        pr3.SBQQ__TargetObject__c = 'Calculator';
        listPR.add(pr3);
        insert listPR;
        //Create Price Action and associate to rule
        List<SBQQ__PriceAction__c> listPA = new List<SBQQ__PriceAction__c>();
        SBQQ__PriceAction__c pa1 = new SBQQ__PriceAction__c();
        pa1.SBQQ__Rule__c = pr1.Id;
        pa1.SBQQ__Field__c = 'testqlfield1__c';
        pa1.SBQQ__TargetObject__c = 'Quote Line';
        listPA.add(pa1);
        SBQQ__PriceAction__c pa2 = new SBQQ__PriceAction__c();
        pa2.SBQQ__Rule__c = pr3.Id;
        pa2.SBQQ__Field__c = 'testqlfield2__c';
        pa2.SBQQ__TargetObject__c = 'Quote Line';
        listPA.add(pa2);
        SBQQ__PriceAction__c pa3 = new SBQQ__PriceAction__c();
        pa3.SBQQ__Rule__c = pr2.Id;
        pa3.SBQQ__Field__c = 'testquotefield1__c';
        pa3.SBQQ__TargetObject__c = 'Quote';
        listPA.add(pa3);
        insert listPA;
        //Create QCP with field per method for testing.
        SBQQ__CustomScript__c qcp = new SBQQ__CustomScript__c();
        qcp.Name = 'TestQCP';
        qcp.SBQQ__QuoteLineFields__c = 'qcpqlfield1__c,qcpqlfield2__r';
        qcp.SBQQ__QuoteFields__c = 'qcpquotefield1__c';
        String qcpBuilder = 'test';
        qcpBuilder += 'export function onInit(quoteLineModels){ line.record[\"qcpqlfield1__c\"]; return Promise.resolve();} ';
        qcpBuilder += 'export function onBeforeCalculate(quote, lineModels, conn){ line.record[\"qcpqlfield1__c\"]; return Promise.resolve();} ';
        qcpBuilder += 'export function onBeforePriceRules(quoteModel, quoteLineModels, conn){ line.record[\"qcpqlfield1__c\"]; return Promise.resolve();} ';
        qcpBuilder += 'export function onAfterPriceRules(quoteModel, quoteLineModels, conn){ line.record[\"qcpqlfield1__c\"]; return Promise.resolve();} ';
        qcpBuilder += 'export function onAfterCalculate(quote, lines, conn){ line.record[\"qcpqlfield2__r\"][\"qcpquotefield1__c\"]; return Promise.resolve();} ';
        qcp.SBQQ__Code__c = qcpBuilder;
        insert qcp;
    }

    @isTest 
    static void getGetLogiShouldHave5Records(){
        Test.startTest();
        List<CPQ_PricingLogicCtrl.wrapPR> listWrap = new List<CPQ_PricingLogicCtrl.wrapPR>();
        listWrap = CPQ_PricingLogicCtrl.getLogic();
        Test.stopTest();

        //Should be 10 results overall - 5 from PR and 5 from QCP
        System.assert(listWrap.size() == 10, 'Wrapper should return 10 records overall');

        //Check break down between Product Rule/Action and QCP
        List<CPQ_PricingLogicCtrl.wrapPR> listPA = new List<CPQ_PricingLogicCtrl.wrapPR>();
        List<CPQ_PricingLogicCtrl.wrapPR> listQCP = new List<CPQ_PricingLogicCtrl.wrapPR>();
        for(CPQ_PricingLogicCtrl.wrapPR ele : listWrap){
            if(ele.source == 'Price Rule'){
                listPA.add(ele);
            }else{
                listQCP.add(ele);
            }
        }
        //Should be 5 Product Action results
        System.assert(listPA.size() == 5, 'Price Rule should return 5 records overall');
        //Should be 5 total QCP results
        System.assert(listQCP.size() == 5, 'QCP should return 5 records overall');
    }

}