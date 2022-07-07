/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 04-05-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   04-05-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
@IsTest
public without sharing class SM_TrackingInboundHandlerTest {

    @TestSetup
    static void makeData(){
        SM_Company_setting__c companySettings = SM_TestSmartDataFactory.getCompanySetting();
        insert new List<SM_Company_Setting__c>{companySettings};
        Lead ld = SM_TestSmartDataFactory.getLead();
        insert new List<Lead>{ld};
        Account acc = SM_TestSmartDataFactory.getPersonAccount();
        insert new List<Account>{acc};
    }

    @IsTest
    static void testLeadTrackingInbound(){
        List<Lead> ld = [SELECT Id FROM Lead];
        System.assertEquals(1, ld.size(), 'Should have only one lead record');

        Test.startTest();
        SM_Tracking_Inbound__c trackIn = SM_TestSmartDataFactory.getTrackingInbound('Facebook adds');
        trackIn.SM_LeadId__c = ld.get(0).Id;
        insert trackIn;
        Test.stopTest();

        Lead updatedLead = [SELECT Id, SM_Contact_Attempts_Quantity__c, SM_Last_Contact_Attempt_Date__c FROM Lead WHERE Id =: ld.get(0).Id];
        System.assertEquals(1, updatedLead.SM_Contact_Attempts_Quantity__c, 'The result is not the expected');
        System.assertNotEquals(null, updatedLead.SM_Last_Contact_Attempt_Date__c, 'The result must not be null');
    }

    @IsTest
    static void testAccountTrackingInbound(){
        List<Account> accs = [SELECT Id FROM Account];
        System.assertEquals(1, accs.size(), 'Should have only one account record');

        Test.startTest();
        SM_Tracking_Inbound__c trackIn = SM_TestSmartDataFactory.getTrackingInbound('Facebook adds');
        trackIn.SM_AccountId__c = accs.get(0).Id;
        insert trackIn;
        Test.stopTest();

        Account updatedAccount = [SELECT Id, SM_Contact_Attempts_Quantity__c, SM_Last_Contact_Attempt_Date__c FROM Account WHERE Id =: accs.get(0).Id];
        System.assertEquals(1, updatedAccount.SM_Contact_Attempts_Quantity__c, 'The result is not the expected');
        System.assertNotEquals(null, updatedAccount.SM_Last_Contact_Attempt_Date__c, 'The result must not be null');
    }
}