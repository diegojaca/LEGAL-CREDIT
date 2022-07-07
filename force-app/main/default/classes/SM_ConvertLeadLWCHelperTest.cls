/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 02-23-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   02-22-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
@IsTest
public without sharing class SM_ConvertLeadLWCHelperTest {

    private static final String EMAIL = 'helper.class@test.com';
    private static final String DESTINATION_BUSINESS_UNIT = 'Legal credit solutions';
    private static final String TRACKING_INBOUND_NAME = 'Tracking Inbound 1';

    @TestSetup
    static void makeData(){
        SM_Company_setting__c companySettings = SM_TestSmartDataFactory.getCompanySetting();
        companySettings.SM_Destination_Bussines_Unit__c = DESTINATION_BUSINESS_UNIT;
        insert companySettings;

        SM_Conversion_Fields_Mapping__c settings = SM_TestSmartDataFactory.getConversionFieldMappingObj(companySettings.Id, 'Lead', 'Account', 'Email', 'PersonEmail');
        SM_Conversion_Fields_Mapping__c settings2 = SM_TestSmartDataFactory.getConversionFieldMappingObj(companySettings.Id, 'Lead', 'Account', 'FirstName', 'FirstName');
        SM_Conversion_Fields_Mapping__c settings3 = SM_TestSmartDataFactory.getConversionFieldMappingObj(companySettings.Id, 'Lead', 'Account', 'LastName', 'LastName');
        SM_Conversion_Fields_Mapping__c settings4 = SM_TestSmartDataFactory.getConversionFieldMappingObj(companySettings.Id, 'Lead', 'Opportunity', 'Email', 'SM_Email__c');
        insert new List<SM_Conversion_Fields_Mapping__c>{settings, settings2, settings3, settings4};

        Lead newLead = SM_TestSmartDataFactory.getLead().clone();
        newLead.Email = EMAIL;
        newLead.SM_Destination_business_unit__c = DESTINATION_BUSINESS_UNIT;
        newLead.SM_ManuallyCreated__c = true;
        insert new List<Lead>{newLead};

        Account acc = SM_TestSmartDataFactory.getPersonAccount().clone();
        acc.PersonEmail = EMAIL;
        insert new List<Account>{acc};

        Opportunity opp = SM_TestSmartDataFactory.getOpportunity().clone();
        opp.AccountId = acc.Id;
        insert new List<Opportunity>{opp};

        SM_Tracking_Inbound__c ti = SM_TestSmartDataFactory.getTrackingInbound(TRACKING_INBOUND_NAME);
        ti.SM_LeadId__c = newLead.Id;
        insert new List<SM_Tracking_Inbound__c>{ti};

        Task tsk = SM_TestSmartDataFactory.getTask();
        tsk.WhoId = newLead.Id;
        insert new List<Task>{tsk};
    }

    @IsTest
    static void testGetInfoLead(){
        System.debug('Executing testGetInfoLead');

        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        List<Lead> newLead = [SELECT Id FROM Lead WHERE Email =: EMAIL];
        System.assertEquals(1, newLead.size(), 'Should have only one lead record');

        Lead leadInfo;
        Test.startTest();
        System.runAs(salesUser){
            leadInfo = SM_ConvertLeadLWCHelper.getInfoLead(newLead.get(0).Id);
        }
        Test.stopTest();
        System.assertNotEquals(null, leadInfo, 'The lead record must not be null');
    }

    @IsTest
    static void testGetDuplicatesAccountsByLead(){
        System.debug('Executing testGetDuplicatesAccountsByLead');

        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        List<Lead> newLead = [SELECT Id, Phone, Email, SM_Destination_business_unit__c FROM Lead WHERE Email =: EMAIL];
        System.assertEquals(1, newLead.size(), 'Should have only one lead record');

        List<Account> duplicateAcc;
        Test.startTest();
        System.runAs(salesUser){
            duplicateAcc = SM_ConvertLeadLWCHelper.getDuplicatesAccountsByLead(newLead.get(0));
            System.debug('duplicateAcc: ' + duplicateAcc);
        }
        Test.stopTest();
        System.assertEquals(1, duplicateAcc.size(), 'Should have only one account duplicate record');
    }


    @IsTest
    static void testGetFieldsMappingToConvertRecord(){
        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        List<SM_Company_setting__c> companySettings = [SELECT Id FROM SM_Company_Setting__c WHERE SM_Destination_Bussines_Unit__c =: DESTINATION_BUSINESS_UNIT];
        System.assertEquals(1, companySettings.size(), 'Should have only one lead record');

        Map<String, String> fieldsToMap;
        Test.startTest();
        System.runAs(salesUser){
            fieldsToMap = SM_ConvertLeadLWCHelper.getFieldsMappingToConvertRecord(companySettings.get(0).Id, 'Lead', 'Account');
            System.assertEquals(3, fieldsToMap.size(), 'Should have four records');
            fieldsToMap = SM_ConvertLeadLWCHelper.getFieldsMappingToConvertRecord(companySettings.get(0).Id, 'Lead', 'Opportunity');
            System.assertEquals(1, fieldsToMap.size(), 'Should have only one record');
        }
        Test.stopTest();
        
    }

    @IsTest
    static void testCreateAccount(){
        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        List<SM_Company_setting__c> companySettings = [SELECT Id FROM SM_Company_Setting__c WHERE SM_Destination_Bussines_Unit__c =: DESTINATION_BUSINESS_UNIT];
        System.assertEquals(1, companySettings.size(), 'Should have only one lead record');

        List<Lead> newLead = [SELECT Id, Phone, Email, FirstName, LastName, SM_Destination_business_unit__c FROM Lead WHERE Email =: EMAIL];
        System.assertEquals(1, newLead.size(), 'Should have only one lead record');        

        Account acc;
        Test.startTest();
        System.runAs(salesUser){
            Map<String, String> leadToAccountMap = SM_ConvertLeadLWCHelper.getFieldsMappingToConvertRecord(companySettings.get(0).Id, 'Lead', 'Account');
            acc = SM_ConvertLeadLWCHelper.createAccount(newLead.get(0).Id, leadToAccountMap);
        }
        Test.stopTest();
        System.assertNotEquals(null, acc, 'The account record must not be null');
        System.assertEquals(newLead.get(0).Email, acc.PersonEmail, 'The Email field must be equals');
        System.assertEquals(newLead.get(0).FirstName, acc.FirstName, 'The FirstName field must be equals');
        System.assertEquals(newLead.get(0).LastName, acc.LastName, 'The LastName field must be equals');
        
    }

    @IsTest
    static void testCreateOpportunity(){

        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        List<SM_Company_setting__c> companySettings = [SELECT Id FROM SM_Company_Setting__c WHERE SM_Destination_Bussines_Unit__c =: DESTINATION_BUSINESS_UNIT];
        System.assertEquals(1, companySettings.size(), 'Should have only one lead record');

        List<Lead> newLead = [SELECT Id, Phone, Email, FirstName, LastName, SM_Destination_business_unit__c FROM Lead WHERE Email =: EMAIL];
        System.assertEquals(1, newLead.size(), 'Should have only one lead record');        

        List<Account> acc = [SELECT Id FROM Account WHERE PersonEmail =: EMAIL];
        System.assertEquals(1, acc.size(), 'Should have only one lead record');        
       
        
        Opportunity opp;
        Test.startTest();
        System.runAs(salesUser){
            Map<String, String> leadToOppMap = SM_ConvertLeadLWCHelper.getFieldsMappingToConvertRecord(companySettings.get(0).Id, 'Lead', 'Opportunity');
            opp = SM_ConvertLeadLWCHelper.createOpportunity(newLead.get(0).Id, acc.get(0).Id, companySettings.get(0).Id, leadToOppMap);
        }
        Test.stopTest();
        System.assertNotEquals(null, opp, 'The account record must not be null');
        System.assertEquals(newLead.get(0).Email, opp.SM_Email__c, 'The Email field must be equals');
        
    }

    @IsTest
    static void testGetTrackingInboundToUpdate(){
        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        List<Lead> newLead = [SELECT Id, Phone, Email, FirstName, LastName, SM_Destination_business_unit__c FROM Lead WHERE Email =: EMAIL];
        System.assertEquals(1, newLead.size(), 'Should have only one lead record');        

        List<Account> acc = [SELECT Id FROM Account WHERE PersonEmail =: EMAIL];
        System.assertEquals(1, acc.size(), 'Should have only one lead record');        

        List<SM_Tracking_Inbound__c> trackingInbound;
        Test.startTest();
        System.runAs(salesUser){
            trackingInbound = SM_ConvertLeadLWCHelper.getTrackingInboundToUpdate(newLead.get(0).Id, acc.get(0).Id);
        }
        Test.stopTest();
        System.assertEquals(1, trackingInbound.size(), 'The tracking Inbound list must have only one record');
        System.assertEquals(acc.get(0).Id, trackingInbound.get(0).SM_AccountId__c, 'The tracking inbound record must have the account field filled');
        
    }

    @IsTest
    static void testFillFields(){
        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        List<SM_Company_setting__c> companySettings = [SELECT Id FROM SM_Company_Setting__c WHERE SM_Destination_Bussines_Unit__c =: DESTINATION_BUSINESS_UNIT];
        System.assertEquals(1, companySettings.size(), 'Should have only one lead record');

        List<Lead> newLead = [SELECT Id, Phone, Email, FirstName, LastName, SM_Destination_business_unit__c FROM Lead WHERE Email =: EMAIL];
        System.assertEquals(1, newLead.size(), 'Should have only one lead record');        

        List<Account> acc = [SELECT Id FROM Account WHERE PersonEmail =: EMAIL];
        System.assertEquals(1, acc.size(), 'Should have only one lead record');        

        Test.startTest();
        System.runAs(salesUser){
            Map<String, String> leadToAccountMap = SM_ConvertLeadLWCHelper.getFieldsMappingToConvertRecord(companySettings.get(0).Id, 'Lead', 'Account');
            SM_ConvertLeadLWCHelper.fillFields('Lead', (SObject)newLead.get(0), 'Account', acc.get(0), leadToAccountMap);
        }
        Test.stopTest();
        System.assertEquals(newLead.get(0).Email, acc.get(0).PersonEmail, 'The Email field must be equals');
        System.assertEquals(newLead.get(0).FirstName, acc.get(0).FirstName, 'The FirstName field must be equals');
        System.assertEquals(newLead.get(0).LastName, acc.get(0).LastName, 'The LastName field must be equals');
    }

    @IsTest
    static void testFillAditionalFields(){
        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        List<SM_Company_setting__c> companySettings = [SELECT Id FROM SM_Company_Setting__c WHERE SM_Destination_Bussines_Unit__c =: DESTINATION_BUSINESS_UNIT];
        System.assertEquals(1, companySettings.size(), 'Should have only one lead record');

        List<Account> acc = [SELECT Id FROM Account WHERE PersonEmail =: EMAIL];
        System.assertEquals(1, acc.size(), 'Should have only one lead record');        

        Opportunity opp = new Opportunity();
        Test.startTest();
        System.runAs(salesUser){
            SM_ConvertLeadLWCHelper.fillAditionalFields(opp, acc.get(0).Id, companySettings.get(0).Id);
        }
        Test.stopTest();
        System.assertEquals('New', opp.StageName, 'The Stage Name field must be New');
        System.assertEquals(acc.get(0).Id, opp.AccountId, 'The Account field must be equals');
        System.assertEquals(companySettings.get(0).Id, opp.SM_Company_Setting__c, 'The company settings field must be equals');
        
    }

    @IsTest
    static void testCopyLeadDataToOpportunity(){
        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        List<Lead> newLead = [SELECT Id, Phone, Email, FirstName, LastName, SM_Destination_business_unit__c FROM Lead WHERE Email =: EMAIL];
        System.assertEquals(1, newLead.size(), 'Should have only one lead record');

        List<Opportunity> opp = [SELECT Id FROM Opportunity WHERE Account.PersonEmail =: EMAIL];
        System.assertEquals(1, opp.size(), 'Should have only one opportunity record');

        Test.startTest();
        System.runAs(salesUser){
            SM_ConvertLeadLWCHelper.copyLeadDataToOpportunity(newLead.get(0).Id, opp.get(0).Id);
        }
        Test.stopTest();
        List<Task> tsk = [SELECT Id, WhatId FROM Task];
        System.assertEquals(1, tsk.size(), 'Should have only one task record');
        System.assertEquals(opp.get(0).Id, tsk.get(0).WhatId, 'Should have only one task record');
        
    }
}