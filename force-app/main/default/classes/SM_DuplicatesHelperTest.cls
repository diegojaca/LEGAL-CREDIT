/**
 * @description       :
 * @author            : diego.jacanamijoy@gmail.com
 * @group             :
 * @last modified on  : 06-10-2022
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   12-23-2020   diego.jacanamijoy@gmail.com   Initial Version
 * 1.1   10-06-2022   jpachon.ariza@gmail.com       Company Lead field added
**/
@IsTest
public with sharing class SM_DuplicatesHelperTest {

    @TestSetup
    static void makeData(){
        insert SM_TestSmartDataFactory.getCompanySetting();

        Lead lead = SM_TestSmartDataFactory.getLead();
        lead.SM_ManuallyCreated__c = false;
        insert lead;

        insert SM_TestSmartDataFactory.getUser();
    }

    @IsTest
    static void createTrakingInboundLeadsOk(){
        Lead oldLead = [SELECT Name, Phone, Email, LeadSource, Owner.Profile.Name, Company FROM Lead LIMIT 1];

        User user = [SELECT Id FROM User WHERE Username = 'Test_@moneeUserName.com' LIMIT 1];

        Lead lead = SM_TestSmartDataFactory.getLead();
        lead.SM_ManuallyCreated__c = false;
        lead.Phone = '123456';
        lead.OwnerId = user.Id;
        lead.SM_ManuallyCreated__c = true;
        insert lead;

        lead = [SELECT Name, Phone, Email, LeadSource, Owner.Profile.Name FROM Lead WHERE Id =: lead.Id];

        Test.startTest();
            SM_DuplicatesHelper.createTrakingInboundLeads(new Map<Lead, Lead[]>{ oldLead => new List<Lead>{ lead } });
        Test.stopTest();
        System.assertEquals(1, [SELECT Count() FROM SM_Tracking_Inbound__c], 'Three record was expected');
    }

    @IsTest
    static void createTrakingInboundAccountOk(){
        Lead newLead = [SELECT Phone, Email, LeadSource, Company FROM Lead LIMIT 1];

        Account oldAccount = SM_TestSmartDataFactory.getPersonAccount();
        oldAccount.Phone = '123456';
        oldAccount.OwnerId = [SELECT Id FROM User LIMIT 1].Id;
        insert oldAccount;

        Test.startTest();
            SM_DuplicatesHelper.createTrakingInboundAccount(new Map<Lead, Set<Account>>{ newLead => new Set<Account>{ oldAccount } });
        Test.stopTest();
        System.assertEquals(1, [SELECT Count() FROM SM_Tracking_Inbound__c], 'Three record was expected');
    }
}