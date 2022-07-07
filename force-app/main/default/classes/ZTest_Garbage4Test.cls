/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             :
 * @last modified on  : 07-19-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   06-02-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
@IsTest
public with sharing class ZTest_Garbage4Test {

    @IsTest
    static void methodName(){
        ZTest_Garbage4.testGarbage();
        insert new Task();
        Opportunity opp = new Opportunity(StageName = 'New', SM_Opportunity_Disposition__c = 'New', Name = 'Test', CloseDate = System.today());
        insert opp;
        Product2 productObj = SM_TestSmartDataFactory.getproduct2NoInsert();
        // productObj.Process_automation_by_product_family__c = processautomationProductfamilyObj.Id;
        productObj.Family = 'Credit rectification';
        productObj.SM_Product_type__c='Sale';
        insert productObj;

        OpportunityLineItem opportunityLineItemObj = SM_TestSmartDataFactory.getOpportunityLineItem();
        opportunityLineItemObj.OpportunityId=opp.id;
        opportunityLineItemObj.Quantity=1;
        opportunityLineItemObj.TotalPrice = 1200;
        opportunityLineItemObj.Product2Id=productObj.id;
        insert opportunityLineItemObj;

        ContactPointAddress cpa = SM_TestSmartDataFactory.getContactPointAddress('Street 1','BOG','CUN','111111','COL', 'Physical Address');
        cpa.Name = 'Temp';
        insert cpa;

        echosign_dev1__SIGN_Agreement__c Agre = SM_TestSmartDataFactory.getAgreement();
		insert agre;
        Agre.echosign_dev1__Status__c = 'Out for Signature';
        update agre;


    }
}