/**
 * @description       : class Test of SM_OpportunityLineItemHandler
 * @author            : cjimenez@legal-credit.com
 * @group             :
 * @last modified on  : 07-24-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date          Author                        Modification
 * 1.0   11-02-2021   cjimenez@legal-credit.com  Initial Version
**/
@IsTest
public with sharing  class SM_OpportunityLineItemHandlerTest {

    @TestSetup
    static void updateOldDataOk(){
        Test.startTest();
        Account account = SM_TestSmartDataFactory.getPersonAccount();
        account.PersonEmail='legal_credit@gmail.com.invalid';
        insert account;
        ChargentBase__Gateway__c Gt = SM_TestSmartDataFactory.getGateway();
        insert Gt;
        SM_Company_setting__c companySettingObj = SM_TestSmartDataFactory.getCompanySettingPMethod(Gt.Id);
        insert companySettingObj;
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        opp.AccountId = account.Id;
        opp.SM_Company_Setting__c = companySettingObj.Id;
        insert opp;
        APXTConga4__Conga_Solution__c conga4CongaSolutionObj = SM_TestSmartDataFactory.getConga4CongaSolutionObj();
        insert conga4CongaSolutionObj;
        Process_automation_by_product_family__c processautomationProductfamilyObj = SM_TestSmartDataFactory.getProcessautomationProductfamily(companySettingObj.id,conga4CongaSolutionObj.id);
        insert processautomationProductfamilyObj;
        Product2 productObj = SM_TestSmartDataFactory.getproduct2NoInsert();
        productObj.Process_automation_by_product_family__c = processautomationProductfamilyObj.Id;
        productObj.Family = 'Credit rectification';
        productObj.SM_Product_type__c='Sale';
        insert productObj;
        OpportunityLineItem opportunityLineItemObj = SM_TestSmartDataFactory.getOpportunityLineItem();
        opportunityLineItemObj.OpportunityId=opp.id;
        opportunityLineItemObj.Quantity=1;
        opportunityLineItemObj.TotalPrice = 1200;
        opportunityLineItemObj.Product2Id=productObj.id;
        insert opportunityLineItemObj;
        Test.stopTest();

    }

    @IsTest
    static void createBundleTestOk(){

        Id recordTypeBundle = SM_Utils.getRecordTypeIdByDeveloperName('Product2', 'Bundle');

        //get opp
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        insert opp;

        //create oppLineItem
        OpportunityLineItem oppLit = SM_TestSmartDataFactory.getOpportunityLineItem();
        System.assertEquals(1, [SELECT COUNT() FROM OpportunityLineItem], 'Must return one oppLineItem record');

        //Update P2 to bundle
        update new Product2(ID = oppLit.Product2Id, recordTypeId = recordTypeBundle);
        System.assertEquals('Bundle', [SELECT recordType.Name FROM Product2 WHERE Id =: oppLit.Product2Id LIMIT 1].recordType.Name, 'Don´t match recordtypename');

        //Create childs bundle
        Product2 childP21 = SM_TestSmartDataFactory.getProduct2ByRecordTypeName('Unit Product');
        PricebookEntry pbe1 = SM_TestSmartDataFactory.getPricebookEntry().clone();
        pbe1.product2Id = childP21.Id;
        insert pbe1;

        System.assertEquals('Unit Product', [SELECT recordType.Name FROM Product2 WHERE Id =: childP21.Id LIMIT 1].recordType.Name, 'Don´t match recordtypename');
        SM_Product_per_bundle__c childBundle1 = new SM_Product_per_bundle__c(SM_Bundle__c = oppLit.Product2Id, SM_Product__c = childP21.Id, SM_AC_value_in_the_bundle__c = 20000);
        insert childBundle1;

        Product2 childP22 = SM_TestSmartDataFactory.getProduct2ByRecordTypeName('Unit Product');
        PricebookEntry pbe2 = SM_TestSmartDataFactory.getPricebookEntry().clone();
        pbe2.product2Id = childP22.Id;
        insert pbe2;

        SM_Product_per_bundle__c childBundle2 = new SM_Product_per_bundle__c(SM_Bundle__c = oppLit.Product2Id, SM_Product__c = childP22.Id, SM_AC_value_in_the_bundle__c = 30000);
        insert childBundle2;
        System.assertEquals(2, [SELECT COUNT() FROM SM_Product_per_bundle__c], 'Must return tow product bundle record');

        Test.startTest();
            //Add oppLineItem to opp
            oppLit.OpportunityId = opp.Id;
            insert oppLit;

            System.assertEquals(3, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId =: opp.Id], 'Must return one oppLineItem record');
            //Get new data
            oppLit = [SELECT SM_AC_Price__c, UnitPrice, SM_Monthly_Offer__c FROM OpportunityLineItem WHERE Id = :oppLit.Id LIMIT 1];
            System.assertEquals(0, oppLit.SM_AC_Price__c, 'Must return zero SM_AC_Price__c');
            System.assertEquals(0, oppLit.UnitPrice, 'Must return zero UnitPrice');
            System.assertEquals(0, oppLit.SM_Monthly_Offer__c, 'Must return zero SM_Monthly_Offer__c');
        Test.stopTest();

    }


    @IsTest
    static void validateProductsByFamily(){

        // Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        // Test.startTest();
        // Boolean exceptionThrown = false;

        // try {

        //     OpportunityLineItem opportunityLineItemObj = SM_TestSmartDataFactory.getOpportunityLineItem();
        //     opportunityLineItemObj.OpportunityId=opp.id;
        //     opportunityLineItemObj.Quantity=2;
        //     opportunityLineItemObj.TotalPrice = 1200;
        //     opportunityLineItemObj.Product2Id=prod.id;
        //     insert opportunityLineItemObj;
        //     System.assertEquals(0, [SELECT Count() FROM OpportunityLineItem], 'More than one rectification product');

        // } catch (Exception e) {
        //     exceptionThrown = true;

        //     // assert
        //     Boolean expectedExceptionThrown =  (e.getMessage().contains('error msg')) ? true : false;
        //     System.AssertEquals(false, expectedExceptionThrown, e.getMessage());
        // }

        //  Test.stopTest();
    }

}