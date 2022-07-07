/**
 * @description       : Test class of SM_ConvertLeadLWCController and SM_ConvertLeadLWCHelper
 * @author            : jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 02-22-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-23-2020   jpachon@legal-credit.com   Initial Version
**/
@IsTest
public with sharing class SM_ConvertLeadLWCControllerTest {

    private static final String EMAIL_LEAD = 'newLead@test.com';
    private static final String PHONE_LEAD = '1234567';
    private static final String EMAIL_LEAD_2 = 'newLeadToAccount@test.com';
    private static final String PHONE_LEAD_2 = '7654321';

    @TestSetup
    static void makeData(){
        SM_Company_setting__c companySettings = SM_TestSmartDataFactory.getCompanySetting();
        insert companySettings;

        List<SM_Conversion_Fields_Mapping__c> conversionFieldsMapping = new List<SM_Conversion_Fields_Mapping__c>();
        SM_Conversion_Fields_Mapping__c settings = new SM_Conversion_Fields_Mapping__c(SM_Company_Setting__c = companySettings.Id, SM_Source_Object__c = 'Lead', SM_Target_Object__c = 'Account', SM_Source_Field__c = 'Email', SM_Target_Field__c = 'PersonEmail');
        conversionFieldsMapping.add(settings);
        SM_Conversion_Fields_Mapping__c settings2 = new SM_Conversion_Fields_Mapping__c(SM_Company_Setting__c = companySettings.Id, SM_Source_Object__c = 'Lead', SM_Target_Object__c = 'Account', SM_Source_Field__c = 'Email', SM_Target_Field__c = 'PersonEmail');
        conversionFieldsMapping.add(settings2);
        SM_Conversion_Fields_Mapping__c settings3 = new SM_Conversion_Fields_Mapping__c(SM_Company_Setting__c = companySettings.Id, SM_Source_Object__c = 'Lead', SM_Target_Object__c = 'Account', SM_Source_Field__c = 'FirstName', SM_Target_Field__c = 'FirstName');
        conversionFieldsMapping.add(settings3);
        SM_Conversion_Fields_Mapping__c settings4 = new SM_Conversion_Fields_Mapping__c(SM_Company_Setting__c = companySettings.Id, SM_Source_Object__c = 'Lead', SM_Target_Object__c = 'Account', SM_Source_Field__c = 'LastName', SM_Target_Field__c = 'LastName');
        conversionFieldsMapping.add(settings4);
        SM_Conversion_Fields_Mapping__c settings5 = new SM_Conversion_Fields_Mapping__c(SM_Company_Setting__c = companySettings.Id, SM_Source_Object__c = 'Lead', SM_Target_Object__c = 'Opportunity', SM_Source_Field__c = 'FirstName', SM_Target_Field__c = 'Description');
        conversionFieldsMapping.add(settings5);
        insert conversionFieldsMapping;

        List<Lead> leads =  new List<Lead>();
        Lead newLead = SM_TestSmartDataFactory.getLead().clone();
        newLead.Email = EMAIL_LEAD;
        newLead.Phone = PHONE_LEAD;
        newLead.SM_ManuallyCreated__c = true;
        leads.add(newLead);

        Lead leadToConvertInOpp = SM_TestSmartDataFactory.getLead().clone();
        leadToConvertInOpp.Email = EMAIL_LEAD_2;
        leadToConvertInOpp.Phone = PHONE_LEAD_2;
        leadToConvertInOpp.SM_ManuallyCreated__c = true;
        leads.add(leadToConvertInOpp);
        System.debug('test - leads: ' + leads);
        insert leads;

        SM_Tracking_Inbound__c trackIn = new SM_Tracking_Inbound__c(SM_LeadId__c = newLead.Id);
        insert trackIn;
        
        Account acc = SM_TestSmartDataFactory.getPersonAccount();
        acc.PersonEmail = EMAIL_LEAD_2;
        insert acc;

    }

    @IsTest
    static void testLeadWithoutAccount(){
        List<Lead> leads = [SELECT Id FROM Lead WHERE Email =: EMAIL_LEAD];
        System.assertEquals(1, leads.size(), 'Should have only one lead record');
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];
        Test.startTest();
        System.runAs(salesUser){
            SM_ConvertLeadLWCController.ResultWrapper result = SM_ConvertLeadLWCController.executeConvertLead(leads.get(0).Id);
            System.assertEquals(true, result.isSuccess, 'The result is not the expected');
            System.assertEquals(result.leadObj.Id, leads.get(0).Id, 'The result is not the expected');
            System.assertEquals(0, result.accounts.size(), 'Should not have any account created');
        }
        Test.stopTest();        
    }

    @IsTest
    static void testConvertLeadToAccountAndOpportunity(){
        List<Lead> leads = [SELECT Id, SM_Company_Setting__c FROM Lead WHERE Email =: EMAIL_LEAD];
        System.assertEquals(1, leads.size(), 'Should have only one lead record');
        System.assertNotEquals(null, leads.get(0).SM_Company_Setting__c, 'This record should have a related Company Settings Record');
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];
        Test.startTest();
        System.runAs(salesUser){
            SM_ConvertLeadLWCController.ResultWrapper result = SM_ConvertLeadLWCController.convertLeadToAccount(leads.get(0).Id, leads.get(0).SM_Company_Setting__c);
            System.assertEquals(true, result.isSuccess, 'The result is not the expected');
            System.assertEquals(1, result.accounts.size(), 'Should have an account record created');
            System.assertNotEquals(null, result.opp, 'Should have an opportunity record created');
        }
        Test.stopTest();
    }

    @IsTest
    static void testConvertLeadIntoAnOpportunity(){
        List<Lead> leads = [SELECT Id, Email, Phone FROM Lead WHERE Email =: EMAIL_LEAD_2];
        System.assertEquals(1, leads.size(), 'Should have only one lead record');
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];
        Test.startTest();
        System.runAs(salesUser){
            SM_ConvertLeadLWCController.ResultWrapper result = SM_ConvertLeadLWCController.executeConvertLead(leads.get(0).Id);
            System.assertEquals(result.leadObj.Id, leads.get(0).Id, 'The result is not the expected');
            System.assertEquals(1, result.accounts.size(), 'Should have any account created');
            SM_ConvertLeadLWCController.ResultWrapper resultOpp = SM_ConvertLeadLWCController.createOpportunity(result.leadObj.Id, result.accounts.get(0).Id, result.leadObj.SM_Company_Setting__c);
            System.assertEquals(true, resultOpp.isSuccess, 'The result is not the expected');
            System.assertNotEquals(null, resultOpp.opp, 'Should have an opportunity record created');
            System.assertEquals(true, resultOpp.opp.SM_Conversion_opportunity__c, 'The SM_Conversion_opportunity__c field value is not the expected');
        }
        Test.stopTest();        
    }

    @IsTest
    static void testConvertLeadToAccountAndOpportunityError(){
        List<Lead> leads = [SELECT Id, SM_Company_Setting__c FROM Lead WHERE Email =: EMAIL_LEAD];
        System.assertEquals(1, leads.size(), 'Should have only one lead record');
        System.assertNotEquals(null, leads.get(0).SM_Company_Setting__c, 'This record should have a related Company Settings Record');
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];
        Test.startTest();
        System.runAs(salesUser){
            SM_ConvertLeadLWCController.ResultWrapper result = SM_ConvertLeadLWCController.convertLeadToAccount(leads.get(0).Id, 'Error');
            System.assertEquals(false, result.isSuccess, 'The result is not the expected');
            System.assertEquals('There is no fields mapping to convertion process', result.errorMessage, 'The error message is not the expected');
        }
        Test.stopTest();
    }

    @IsTest
    static void testFieldsMappingError(){
        List<SM_Conversion_Fields_Mapping__c> conversionFieldsMapping = [SELECT Id FROM SM_Conversion_Fields_Mapping__c WHERE SM_Target_Field__c = 'LastName'];
        delete conversionFieldsMapping;
        List<Lead> leads = [SELECT Id, SM_Company_Setting__c FROM Lead WHERE Email =: EMAIL_LEAD];
        System.assertEquals(1, leads.size(), 'Should have only one lead record');
        System.assertNotEquals(null, leads.get(0).SM_Company_Setting__c, 'This record should have a related Company Settings Record');
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];
        Test.startTest();
        System.runAs(salesUser){
            SM_ConvertLeadLWCController.ResultWrapper result = SM_ConvertLeadLWCController.convertLeadToAccount(leads.get(0).Id, leads.get(0).SM_Company_Setting__c);
            System.assertEquals(false, result.isSuccess, 'The result is not the expexted');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSetAccountInTrackingInbound(){
        Account acc = SM_TestSmartDataFactory.getPersonAccount().clone();
        insert acc;
        List<Lead> leads = [SELECT Id, SM_Company_Setting__c FROM Lead WHERE Email =: EMAIL_LEAD];
        System.assertEquals(1, leads.size(), 'Should have only one lead record');        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        insert opp;
        Test.startTest();
        System.runAs(salesUser){
            SM_ConvertLeadLWCController.updateTrackingInboundRecordsAndConvertLead(leads.get(0).Id, acc.Id, opp.Id);
        }
        Test.stopTest();
        List<SM_Tracking_Inbound__c> trackInLst = [SELECT Id, SM_LeadId__c, SM_LeadId__r.Name, SM_AccountId__c FROM SM_Tracking_Inbound__c];
        System.assertEquals(1, trackInLst.size(), 'Should have only one lead record');
        System.assertEquals(acc.Id, trackInLst.get(0).SM_AccountId__c, 'Should have only one lead record');
        
    }

    @IsTest
    static void updateOldAccount(){
        
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        insert opp;
        
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        lead.Email = 'tes.lead@test.com';
        update lead;

        Task task = new Task(Description = 'Test', WhoId = lead.Id, ActivityDate = system.today());
        insert task;

        Event event = new Event(Description = 'Test', WhoId = lead.Id, DurationInMinutes = 12, ActivityDate = system.today(), ActivityDateTime = system.now());
        insert event;

        Account account = [SELECT Phone, PersonEmail FROM Account LIMIT 1];
        account.PersonEmail = '';
        update account;

        SM_Company_setting__c cs = [SELECT Name FROM SM_Company_setting__c LIMIT 1];
        
        Test.startTest();
            SM_ConvertLeadLWCController.updateOldAccount(lead.Id, account,cs.Name, opp.Id);
            account = [SELECT Phone, PersonEmail FROM Account LIMIT 1];
            opp = [SELECT Id, (SELECT WhatId FROM Tasks), (SELECT WhatId FROM Events) FROM Opportunity WHERE Id =: opp.Id LIMIT 1];
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Lead WHERE Id =: Lead.Id], 'The lead must be removed');
        System.assertEquals(lead.Email, account.PersonEmail, 'Not update the account');
    }

}