/**
 * @description       : Test class to SM_TaskHandler
 * @author            : Jonathan S. Pachon Ariza -> jpachon.ariza@legal-credit.com
 * @group             : 
 * @last modified on  : 07-24-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log 
 * Ver   Date         Author                                                       Modification
 * 1.0   12-27-2020   Jonathan S. Pachon Ariza -> jpachon.ariza@legal-credit.com   Initial Version
**/
@IsTest
public with sharing class SM_TaskHandlerTest {

    private static final String EMAIL_LEAD = 'newLead@test.com';

    @TestSetup
    static void makeData(){
        Lead newLead = SM_TestSmartDataFactory.getLead().clone();
        newLead.Email = EMAIL_LEAD;
        newLead.SM_ManuallyCreated__c = true;
        insert newLead;        
    }

    @IsTest
    static void simulateLeadTaskFromFive9(){
        
        Profile salesAgentProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Agent' LIMIT 1];
        User salesAgentUser = [SELECT Id FROM User WHERE IsActive = TRUE AND ProfileId =: salesAgentProfile.Id LIMIT 1];
        List<SM_Category_and_Disposition__mdt> categoryAndDispositionLeads = [SELECT SM_SObject_Name__c, SM_Category__c, SM_Disposition__c FROM SM_Category_and_Disposition__mdt WHERE SM_Active__c = TRUE AND SM_SObject_Name__c = 'Lead'];
        System.assertNotEquals(0, categoryAndDispositionLeads.size(), 'Should have at least one Category and Disposition record active');
        SM_Category_and_Disposition__mdt confToLead = categoryAndDispositionLeads.get(0);
        List<Lead> leads = [SELECT Id FROM Lead];
        System.assertEquals(1, leads.size(), 'Should have only one lead record');
        Test.startTest();
        System.runAs(salesAgentUser){
            Task five9Task = new Task(WhoId = leads.get(0).Id, CallDisposition = confToLead.SM_Disposition__c, Five9__Five9SessionId__c = '12345678123456781234567812345678');
            insert five9Task;
        }
        Test.stopTest();
        List<Lead> updatedLeads = [SELECT Id, Status, SM_Lead_Disposition__c FROM Lead WHERE Id =: leads.get(0).Id];
        System.assertEquals(confToLead.SM_Category__c, updatedLeads.get(0).Status, 'The status is not the expected.');
        System.assertEquals(confToLead.SM_Disposition__c, updatedLeads.get(0).SM_Lead_Disposition__c, 'The disposition is not the expected.');
    }

    @IsTest
    static void validateOpportunityStageOk(){
        //get metadata
        SM_Category_and_Disposition__mdt cd = [SELECT SM_Category__c, SM_Disposition_Five9__c FROM SM_Category_and_Disposition__mdt WHERE SM_SObject_Name__c = 'Opportunity' LIMIT 1];
        Test.startTest();
            //create opp
            Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
            insert opp;

            //Create task
            Task task = new Task(WhatId = opp.Id, Five9__Five9SessionId__c = '123', CallDisposition = cd.SM_Disposition_Five9__c);
            insert task;
        Test.stopTest();
        //Get new stage of opp
        opp = [SELECT StageName FROM Opportunity WHERE Id =: opp.Id LIMIT 1];
        system.assertEquals(cd.SM_Category__c, opp.StageName, 'Stage not updated');
    }

}