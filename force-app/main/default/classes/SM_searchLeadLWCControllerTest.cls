/**
 * @description       :
 * @author            : diego.jacanamijoy@gmail.com
 * @group             :
 * @last modified on  : 06-10-2022
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   11-11-2020   diego.jacanamijoy@gmail.com   Initial Version
 * 1.1   10-06-2022   jpachon.ariza@gmail.com       Company Lead field added
**/
@isTest
public with sharing class SM_searchLeadLWCControllerTest {

    @TestSetup
    static void makeData(){
        User user = SM_TestSmartDataFactory.getUser();
        insert user;
        insert SM_TestSmartDataFactory.getCompanySetting();
        Lead lead = SM_TestSmartDataFactory.getLead();
        lead.Phone = '3105223325';
        lead.OwnerId = user.Id;
        insert lead;
    }

    @IsTest
    static void getRequiredsFieldsByCompanyError(){
        Test.startTest();
            String companySettingName = 'Test';
            SM_Company_setting__c companySetting;
            try {
                companySetting = SM_CompanySettingHelper.getCompanySettingByName(companySettingName);
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
            System.assertEquals(null, companySetting, 'should not return a record');
        Test.stopTest();
    }

    @IsTest
    static void validateDuplicatesOk(){
        User user = [SELECT Id FROM User WHERE Username = 'Test_@moneeUserName.com' LIMIT 1];

        Lead lead = SM_TestSmartDataFactory.getLead();
        lead.Phone = '3105223325';
        lead.OwnerId = user.Id;
        insert lead;
        lead = [SELECT Owner.Profile.Name, Phone, Email, LeadSource, Company FROM Lead WHERE Id =: lead.Id LIMIT 1];
        SM_searchLeadLWCController.DuplicateWraper wraperResult =  SM_searchLeadLWCController.validateDuplicates(lead.Id, 'Legal credit solutions');
        System.assertNotEquals(null, wraperResult, 'Must return a record');
    }

    @IsTest
    static void unifyLeadsOk(){

        Lead oldLead = [SELECT Owner.Profile.Name, Phone, Email, LeadSource, Company FROM Lead  LIMIT 1];

        User user = [SELECT Id FROM User WHERE Username = 'Test_@moneeUserName.com' LIMIT 1];

        Lead lead = SM_TestSmartDataFactory.getLead();
        lead.Phone = '31052233252';
        lead.Email = 'test@test.com2';
        lead.OwnerId = user.Id;
        insert lead;

        lead = [SELECT Owner.Profile.Name, Phone, Email, LeadSource FROM Lead WHERE Id =: lead.Id LIMIT 1];
        Test.startTest();
            String idResult = SM_searchLeadLWCController.unifyLeads(oldLead.Id, lead, 'Legal credit solutions');
        Test.stopTest();
        System.assertNotEquals(null, idResult, 'Must return a record');
    }

    @IsTest
    static void unifyLeadsError(){
        Test.startTest();
        	String idResult;
            try{
             	idResult = SM_searchLeadLWCController.unifyLeads(null, null, 'Legal credit solutions');
            }catch(Exception e){
                system.debug('Error');
            }
        Test.stopTest();
        System.assertEquals(null, idResult, 'Must return a record');
    }

    @IsTest
    static void unifyAccountWithLeadOk(){
        Lead oldLead = [SELECT Owner.Profile.Name, Phone, Email, LeadSource, Company FROM Lead  LIMIT 1];
        Account acc = SM_TestSmartDataFactory.getPersonAccount();
        acc.Phone = '312334455';
        insert acc;
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity().clone();
        opp.AccountId = acc.Id;
        opp.RecordTypeId = SM_Utils.getRecordTypeIdByDeveloperName('Opportunity', SM_OpportunityHelper.recordType.legalCreditSolutions);
        insert opp;
        opp = [SELECT Name, StageName, SM_Contract_Stage__c,Account.Name,RecordType.DeveloperName, RecordType.Name, Owner.Profile.Name, OwnerId  FROM Opportunity WHERE Id =: opp.Id];
        Test.startTest();
            String idOpp = SM_searchLeadLWCController.unifyAccountWithLead(oldLead.Id, acc, new List<Opportunity>{opp}, 'Legal credit solutions');
        Test.stopTest();
        System.assertNotEquals(null, idOpp, 'Must return a record');
    }

    @IsTest
    static void unifyAccountWithLeadError(){
        Test.startTest();
        	String idOpp;
        	try{
        		idOpp = SM_searchLeadLWCController.unifyAccountWithLead(null, null, new List<Opportunity>(), 'Legal credit solutions');
            }catch(Exception e){
                system.debug('Error');
            }

        Test.stopTest();
        System.assertEquals(null, idOpp, 'Must return a record');
    }

    @IsTest
    static void getAllCompanysSettings(){
        Test.startTest();
        	SM_searchLeadLWCController.getAllCompanysSettings();
        Test.stopTest();
    }

    @IsTest
    static void createTrackingInbound(){
        Lead oldLead = [SELECT Owner.Profile.Name, Phone, Email, LeadSource, Company FROM Lead  LIMIT 1];

        Test.startTest();
        	SM_searchLeadLWCController.createTrackingInbound(oldLead.Id, 'Legal credit solutions');
        Test.stopTest();
    }
}