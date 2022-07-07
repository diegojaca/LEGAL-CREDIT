/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 09/02/2021
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-24-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
@IsTest
public with sharing class SM_LeadHelperTest {
    
    @TestSetup
    static void makeData(){
        //Insert company setting
        insert SM_TestSmartDataFactory.getCompanySetting();
        //Insert Lead
        insert SM_TestSmartDataFactory.getLead();
    }

    @IsTest
    static void getLeadByIdOk(){
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
            Lead leadResult = SM_LeadHelper.getLeadById(lead.Id);
            system.assertEquals(lead.Id, leadResult.Id, 'Did not return the correct id');
        Test.stopTest();
    }

    @IsTest
    static void getLeadByIdError(){
        Test.startTest();
            Lead leadResult = SM_LeadHelper.getLeadById('123456');
            system.assertEquals(null, leadResult, 'Should return null');
        Test.stopTest();
    }

    @IsTest
    static void getLeasByDinamicQueryOk(){
        Test.startTest();
            String query = 'SELECT Id FROM Lead LIMIT 1';
            Lead[] leads = SM_LeadHelper.getLeasByDinamicQuery(query);
            system.assertEquals(1, leads.size(), 'Should return 1 record');
        Test.stopTest();
    }
    
    @IsTest
    static void getLeasByDinamicQueryError(){
        Test.startTest();
            String query = 'SELECT Id FROM Lead WHERE Id = 1234 LIMIT 1';
            Lead[] leads = SM_LeadHelper.getLeasByDinamicQuery(query);
            system.assertEquals(0, leads.size(), 'Should return  0 record');
        Test.stopTest();
    }

    @IsTest
    static void updateOldRecordAccountOk(){
        Lead lead = [SELECT Email, Phone, SM_Destination_business_unit__c FROM Lead LIMIT 1];
        lead.Email = 'testemail@test.com';
        //create account
        Account acc = SM_TestSmartDataFactory.getPersonAccount();
        insert acc;
        acc = [SELECT PersonEmail, Phone FROM Account WHERE Id =: acc.Id];
        Test.startTest();
            SM_LeadHelper.updateOldRecord(lead, acc);
            System.assertEquals('testemail@test.com', acc.PersonEmail, 'The Email was not updated');
        Test.stopTest();    
    }

    @IsTest
    static void updateOldRecordLeadOk(){
        Lead lead = [SELECT Email, Phone, SM_Destination_business_unit__c FROM Lead LIMIT 1];
        lead.Email = 'testemail@test.com';
        //create Lead
        Lead leadUpd = SM_TestSmartDataFactory.getLead();
        insert leadUpd;
        leadUpd = [SELECT Email, Phone FROM Lead WHERE Id =: leadUpd.Id LIMIT 1];
        Test.startTest();
            SM_LeadHelper.updateOldRecord(lead, leadUpd);
            System.assertEquals('testemail@test.com', leadUpd.Email, 'The Email was not updated');
        Test.stopTest();    
    }

    @IsTest
    static void updateOldRecordOK(){
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        lead.Email = 'tes.lead@test.com';
        lead.DoNotCall = true;
        update lead;

        Account account = SM_TestSmartDataFactory.getPersonAccount();
        account.PersonEmail = '';
        insert account;
        
        account = [SELECT PersonEmail, PersonDoNotCall FROM Account WHERE Id =: account.Id LIMIT 1];

        Test.startTest();
            SM_LeadHelper.updateOldRecord(lead, account, new Map<String, String>{ 'Email' => 'PersonEmail', 'DoNotCall' => 'PersonDoNotCall' });
        Test.stopTest();

        System.assertEquals(lead.Email, account.PersonEmail, 'Not update the account');
        System.assertEquals(lead.DoNotCall, account.PersonDoNotCall, 'Not update the account');
        System.assertEquals(true, account.PersonDoNotCall, 'Not update the account');
    }
    
    @IsTest
    static void getLeadWithRequiredFieldsById(){
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        SM_Company_setting__c companySetting = [SELECT SM_Required_fields__c, SM_Fields_to_validate_duplicates__c, SM_Fields_to_validate_duplicates2__c FROM SM_Company_setting__c LIMIT 1];
        Test.startTest();
            lead = SM_LeadHelper.getLeadWithRequiredFieldsById(lead.Id, companySetting);
        Test.stopTest();
        system.assertNotEquals(null, lead, 'Must return one record of lead');
    }
}