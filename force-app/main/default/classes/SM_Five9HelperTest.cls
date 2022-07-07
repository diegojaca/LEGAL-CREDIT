/**
 * @description       : Test
 * @author            : jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 01-15-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-23-2020   jpachon@legal-credit.com   Initial Version
**/
@IsTest
public with sharing class SM_Five9HelperTest {

    private static final String LEAD_FIVE9_LIST_NAME = 'Test class - New Leads';
    private static final String OPP_FIVE9_LIST_NAME = 'Test class - New Opportunities';
    private static String five9RTName = SM_SetupCallsDistributeHelper.recordType.five9List;

    @TestSetup
    static void makeData(){
        
        Five9LSP__Five9_LSP_Settings__c f9Settings = SM_TestSmartDataFactory.getFive9Settings();
        insert f9Settings;

        SM_Company_setting__c lcsCompanySetting = SM_TestSmartDataFactory.getCompanySetting();
        lcsCompanySetting.SM_Destination_Bussines_Unit__c = 'Legal credit solutions';
        insert new List<SM_Company_setting__c>{lcsCompanySetting};

        Five9LSP__Five9_List__c leadFive9List = SM_TestSmartDataFactory.getFive9List(LEAD_FIVE9_LIST_NAME, 'Lead');
        Five9LSP__Five9_List__c oppFive9List = SM_TestSmartDataFactory.getFive9List(OPP_FIVE9_LIST_NAME, 'Opportunity');
        insert new List<Five9LSP__Five9_List__c>{leadFive9List, oppFive9List};


        // JSPA - SFDCMP-75 - TO DO - Send new record type parameter
        SM_Setup_calls_distribute__c leadSetupCallDistribute =  SM_TestSmartDataFactory.getSetupCallDistribute(five9RTName, lcsCompanySetting.Id, leadFive9List.Id, 'Lead', 'New', 'New');
        leadSetupCallDistribute.Name = 'Setup calls distribute to Lead';
        SM_Setup_calls_distribute__c oppSetupCallDistribute =  SM_TestSmartDataFactory.getSetupCallDistribute(five9RTName, lcsCompanySetting.Id, oppFive9List.Id, 'Opportunity', 'New', 'New');
        oppSetupCallDistribute.Name = 'Setup calls distribute to Opportunity';
        insert new List<SM_Setup_calls_distribute__c>{leadSetupCallDistribute, oppSetupCallDistribute};

    }

    @IsTest
    static void testSendLead(){

        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        List<Lead> leads = new List<Lead>();
        Lead newLead = SM_TestSmartDataFactory.getLead();
        newLead.Phone = '9999999';
        newLead.Status = 'New';
        newLead.SM_Lead_Disposition__c = 'New';
        newLead.SM_Destination_business_unit__c = 'Legal credit solutions';
        newLead.SM_Call_Inbound__c = false;
        leads.add(newLead);
        
        Test.startTest();
            System.runAs(salesUser){
                insert leads;
            }
        Test.stopTest();

        List<SM_Company_setting__c> companySettingLst = [SELECT Id FROM SM_Company_setting__c WHERE SM_Destination_Bussines_Unit__c = 'Legal credit solutions'];
        System.assertEquals(1, companySettingLst.size(), 'Shoul have only one compay setting record');
        List<SM_Setup_calls_distribute__c> setupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Lead' AND SM_Stage_or_Status__c = 'New' AND SM_Disposition__c = 'New'];
        System.assertEquals(1, setupCallLst.size(), 'Shoul have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> recordsCreated = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Lead__c =: newLead.Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, recordsCreated.size(), 'Should have only one five9 list item record');
        
    }

    @IsTest
    static void testSendOpportunity(){
        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        List<SM_Company_setting__c> companySettingLst = [SELECT Id FROM SM_Company_setting__c WHERE SM_Destination_Bussines_Unit__c = 'Legal credit solutions'];
        System.assertEquals(1, companySettingLst.size(), 'Shoul have only one compay setting record');

        List<Opportunity> opportunities = new List<Opportunity>();
        Opportunity newOpp = SM_TestSmartDataFactory.getOpportunity();        
        newOpp.StageName = 'New';
        newOpp.SM_Opportunity_Disposition__c = 'New';
        newOpp.SM_Company_Setting__c = companySettingLst.get(0).Id;
        opportunities.add(newOpp);

        Test.startTest();
            System.runAs(salesUser){
                insert opportunities;
            }
        Test.stopTest();

        List<SM_Setup_calls_distribute__c> setupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Opportunity' AND SM_Stage_or_Status__c = 'New' AND SM_Disposition__c = 'New'];
        System.assertEquals(1, setupCallLst.size(), 'Shoul have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> recordsCreated = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Opportunity__c =: newOpp.Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, recordsCreated.size(), 'Should have only one five9 list item record');

    }

}