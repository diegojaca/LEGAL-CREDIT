/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 02-25-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   12-06-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
@IsTest
public with sharing class SM_AccountDuplicateControllerTest {
    
    @TestSetup
    static void makeData(){
        //Insert company setting
        insert SM_TestSmartDataFactory.getCompanySetting();
        //Insert Account
        Account account = SM_TestSmartDataFactory.getPersonAccount();
        account.PersonEmail = 'test.monee@test.com';
        account.Phone = '313666777';
        insert account;

        //Insert opp
        Opportunity opportunity = SM_TestSmartDataFactory.getOpportunity();
        opportunity.StageName = SM_OpportunityHelper.stageName.paymentProcess;
        opportunity.SM_Opportunity_Disposition__c = SM_OpportunityHelper.dispositions.sale;
        opportunity.AccountId = account.Id;
        insert opportunity;
    }

    @IsTest
    static void getDuplicatesAccountsByLeadOk(){
        //Insert Lead
        Lead lead = SM_TestSmartDataFactory.getLead();
        lead.Phone = '313666777';
        lead.LeadSource = 'Facebook Ads';
        lead.Email = 'test.monee@test.com';
        insert lead;


        Test.startTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
            SM_AccountDuplicateController accountDuplicateController = new SM_AccountDuplicateController();
            Map<Lead, Set<Account>> accountsByLead = accountDuplicateController.getDuplicatesAccountsByLead(new List<Lead>{lead});
            system.assertEquals(true, accountsByLead.containsKey(lead), 'Should contains the lead');
            system.assertEquals(1, accountsByLead.get(lead).size(), 'Should contains a account duplicated');
            system.assertEquals(acc.Id, new List<Account>(accountsByLead.get(lead))[0].Id, 'The ids do not match');
        Test.stopTest();
    }

    @IsTest
    static void getOpportunityByDuplicateAccountOk(){
        Lead lead = SM_TestSmartDataFactory.getLead();
        lead.Phone = '313666777';
        lead.LeadSource = 'Facebook Ads';
        lead.Email = 'test.monee@test.com';
        insert lead;

        Account acc = [SELECT Id FROM Account LIMIT 1];

        List<Opportunity> opportunities = [SELECT Name, Account.Name, StageName, SM_Contract_Stage__c, RecordType.DeveloperName, RecordType.Name, 
                                                Owner.Profile.Name, OwnerId 
                                            FROM Opportunity];

        Test.startTest();
        SM_AccountDuplicateController accountDuplicateController = new SM_AccountDuplicateController();
            String oppId = accountDuplicateController.getOpportunityByDuplicateAccount(opportunities, lead, acc);
        Test.stopTest();
        System.assertNotEquals(opportunities[0].Id, oppId, 'Not the expected id');
    }
}