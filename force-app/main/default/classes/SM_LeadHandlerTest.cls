/**
 * @description       :
 * @author            : diego.jacanamijoy@gmail.com
 * @group             :
 * @last modified on  : 06-12-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                        Modification
 * 1.0   11-26-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
@IsTest
public with sharing class SM_LeadHandlerTest {

    private static final String F9_LIST_NAME_LEAD_NEW_NEW = 'Lead New New';
    private static final String F9_LIST_NAME_LEAD_NO_CONTACT_BUSY = 'Lead No Contact Busy';
    private static final String F9_LIST_NAME_LEAD_ORIENTED_EXPENSIVE = 'Lead Oriented Expensive';
    private static String five9SetupCallsRTName = SM_SetupCallsDistributeHelper.recordType.five9List;
    // private static String reminderSetupCallsRTName = SM_SetupCallsDistributeHelper.recordType.reminder;
    private static String reminderTaskRT = SM_Utils.getRecordTypeIdByDeveloperName('Task', SM_TaskHelper.recordType.reminder);

    @TestSetup
    static void makeData(){

        /* Data to test five9 list and reminder tasks */
        Five9LSP__Five9_LSP_Settings__c f9Settings = SM_TestSmartDataFactory.getFive9Settings();
        insert f9Settings;

        SM_Company_setting__c lcsCompanySetting = SM_TestSmartDataFactory.getCompanySetting().clone();
        lcsCompanySetting.SM_Destination_Bussines_Unit__c = 'Legal credit solutions';
        SM_Company_setting__c harmoneyCompanySetting = SM_TestSmartDataFactory.getCompanySetting().clone();
        // harmoneyCompanySetting.SM_Destination_Bussines_Unit__c = 'Harmoney';
        insert new List<SM_Company_setting__c>{lcsCompanySetting};

        Five9LSP__Five9_List__c f9ListLeadNewNew = SM_TestSmartDataFactory.getFive9List(F9_LIST_NAME_LEAD_NEW_NEW, 'Lead');
        Five9LSP__Five9_List__c f9ListLeadNoContactBusy = SM_TestSmartDataFactory.getFive9List(F9_LIST_NAME_LEAD_NO_CONTACT_BUSY, 'Lead');
        Five9LSP__Five9_List__c f9ListLeadOrientedExpensive = SM_TestSmartDataFactory.getFive9List(F9_LIST_NAME_LEAD_ORIENTED_EXPENSIVE, 'Lead');
        insert new List<Five9LSP__Five9_List__c>{f9ListLeadNewNew, f9ListLeadNoContactBusy, f9ListLeadOrientedExpensive};

        // JSPA - SFDCMP-75 - TO DO - Send new record type parameter
        SM_Setup_calls_distribute__c leadNewNewSCD =  SM_TestSmartDataFactory.getSetupCallDistribute(five9SetupCallsRTName, lcsCompanySetting.Id, f9ListLeadNewNew.Id, 'Lead', 'New', 'New');
        leadNewNewSCD.Name = 'Lead New New - Setup Calls Distribute';
        SM_Setup_calls_distribute__c leadNoContactBusySCD =  SM_TestSmartDataFactory.getSetupCallDistribute(five9SetupCallsRTName, lcsCompanySetting.Id, f9ListLeadNoContactBusy.Id, 'Lead', 'No Contact', 'Busy');
        leadNoContactBusySCD.Name = 'Lead No Contact Busy - Setup Calls Distribute';
        SM_Setup_calls_distribute__c leadOrientedExpensiveSCD =  SM_TestSmartDataFactory.getSetupCallDistribute(five9SetupCallsRTName, lcsCompanySetting.Id, f9ListLeadOrientedExpensive.Id, 'Lead', 'Oriented', 'Expensive');
        leadOrientedExpensiveSCD.Name = 'Lead No Contact Busy - Setup Calls Distribute';
        SM_Setup_calls_distribute__c leadNotOrientedCallbackSCD =  SM_TestSmartDataFactory.getReminderSetupCallDistribute(lcsCompanySetting.Id, 'Lead', 'Not Oriented', 'Call Back', 1);
        leadNotOrientedCallbackSCD.Name = 'Lead Not Oriented Call back - Setup Calls Distribute';
        insert new List<SM_Setup_calls_distribute__c>{leadNewNewSCD, leadNoContactBusySCD, leadOrientedExpensiveSCD, leadNotOrientedCallbackSCD};
        /* Data to test five9 list and reminder tasks */

        //Coverage of insert methods, after and before
        User user = SM_TestSmartDataFactory.getUser();
        insert user;

        List<Lead> leads = new List<Lead>();
        Lead newLead = SM_TestSmartDataFactory.getLead().clone();
        // Generate random long number to avoid duplicates
        newLead.Phone = String.valueOf(Crypto.getRandomLong());
        newLead.Email = 'leadToTestF9Assigment@test.com';
        newLead.Status = 'New';
        newLead.SM_Lead_Disposition__c = 'New';
        newLead.SM_Destination_business_unit__c = 'Legal credit solutions';
        newLead.SM_Call_Inbound__c = false;
        leads.add(newLead);
        Lead lead = SM_TestSmartDataFactory.getLead().clone();
        lead.Email = 'first.lead@test.com';
        lead.OwnerId = user.Id;
        leads.add(lead);
        insert leads;
    }

    @IsTest
    static void validateRequiredFieldsError(){
        Test.startTest();
            Lead lead = [SELECT Status FROM Lead WHERE Email = 'first.lead@test.com' LIMIT 1];
            System.assertEquals(SM_LeadHelper.leadStatusEnum.UNQUALIFIED, lead.Status, 'Leads Status don´t valid');
        Test.stopTest();
    }

    @IsTest
    static void validateRequiredFieldsOk(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'Standard User' LIMIT 1];
        Lead lead = SM_TestSmartDataFactory.getLead();
        lead.Phone = '313666777';
        lead.LeadSource = 'Facebook Ads';
        lead.OwnerId = user.Id;
        lead.SM_ManuallyCreated__c = true;
        insert lead;

        Test.startTest();
            lead = [SELECT Status, SM_key_for_duplicates_2__c FROM Lead WHERE Id =: lead.Id LIMIT 1];
            System.assertEquals(SM_LeadHelper.leadStatusEnum.NEW_STATUS, lead.Status, 'Leads Status don´t valid');
            System.assertEquals('313666777', lead.SM_key_for_duplicates_2__c, 'Second key don´t valid');
        Test.stopTest();
    }

    @IsTest
    static void validateKeysChangedOk(){
        Lead lead = [SELECT Phone FROM Lead WHERE Email = 'first.lead@test.com' LIMIT 1];
        Test.startTest();
            lead.Phone = '313666778';
            update lead;
            lead = [SELECT Phone, SM_key_for_duplicates_2__c FROM Lead WHERE Email = 'first.lead@test.com' LIMIT 1];
            system.assertEquals('313666778', lead.Phone, 'The phone was not updated');
            system.assertEquals('313666778', lead.SM_key_for_duplicates_2__c, 'The key was not updated');
        Test.stopTest();
    }

    @IsTest
    static void updateOldDataOk(){
        Lead oldLead = [SELECT Email FROM Lead WHERE Email = 'first.lead@test.com' LIMIT 1];
        oldLead.Email = '';
        oldLead.Phone = '313666777';
        update oldLead;
        Test.startTest();
            Lead lead = SM_TestSmartDataFactory.getLead();
            lead.Phone = '313666777';
            lead.Email = 'newemail@test.com';
            insert lead;
        Test.stopTest();
        oldLead = [SELECT Email FROM Lead WHERE Id =: oldLead.Id LIMIT 1];
        System.assertEquals('newemail@test.com', oldLead.Email, 'The email was not updated in old record');
    }

    @IsTest
    static void assignLeadFromF9ListToAnotherF9List(){

        /** */
        List<SM_Setup_calls_distribute__c> tempLst = [SELECT Id,SM_Administration_Company__r.Name,SM_Object__c,SM_Stage_or_Status__c,SM_Disposition__c FROM SM_Setup_calls_distribute__c];
        System.debug('tempLst: ' + JSON.serialize(tempLst));
        /** */


        Lead oldLead = [SELECT Id, Status, SM_Lead_Disposition__c FROM Lead WHERE Email =: 'leadToTestF9Assigment@test.com' LIMIT 1];

        List<SM_Company_setting__c> companySettingLst = [SELECT Id FROM SM_Company_setting__c WHERE SM_Destination_Bussines_Unit__c = 'Legal credit solutions'];
        System.assertEquals(1, companySettingLst.size(), 'Shoul have only one compay setting record');
        List<SM_Setup_calls_distribute__c> setupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Lead' AND SM_Stage_or_Status__c = 'New' AND SM_Disposition__c = 'New'];
        System.assertEquals(1, setupCallLst.size(), 'Shoul have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> recordsCreated = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Lead__c =: oldLead.Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, recordsCreated.size(), 'Should have only one five9 list item record');

        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        Test.startTest();
            System.runAs(salesUser){
                oldLead.Status = 'No Contact';
                oldLead.SM_Lead_Disposition__c = 'Busy';
                update oldLead;
            }
        Test.stopTest();

        List<SM_Setup_calls_distribute__c> newSetupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Lead' AND SM_Stage_or_Status__c = 'No Contact' AND SM_Disposition__c = 'Busy'];
        System.assertEquals(1, newSetupCallLst.size(), 'Should have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> newF9ListItemRecords = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Lead__c =: oldLead.Id AND Five9LSP__Five9_List__c =: newSetupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, newF9ListItemRecords.size(), 'Should have only one five9 list item record');

    }

    @IsTest
    static void removeLeadFromF9ListAndCreateReminderTask(){

        Lead oldLead = [SELECT Id, Status, SM_Lead_Disposition__c FROM Lead WHERE Email =: 'leadToTestF9Assigment@test.com' LIMIT 1];

        List<SM_Company_setting__c> companySettingLst = [SELECT Id FROM SM_Company_setting__c WHERE SM_Destination_Bussines_Unit__c = 'Legal credit solutions'];
        System.assertEquals(1, companySettingLst.size(), 'Should have only one compay setting record');
        List<SM_Setup_calls_distribute__c> setupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Lead' AND SM_Stage_or_Status__c = 'New' AND SM_Disposition__c = 'New'];
        System.assertEquals(1, setupCallLst.size(), 'Should have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> recordsCreated = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Lead__c =: oldLead.Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, recordsCreated.size(), 'Should have only one five9 list item record');

        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        Test.startTest();
            System.runAs(salesUser){
                oldLead.Status = 'Not Oriented';
                oldLead.SM_Lead_Disposition__c = 'Call Back';
                update oldLead;
            }
        Test.stopTest();

        List<SM_Setup_calls_distribute__c> newSetupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Lead' AND SM_Stage_or_Status__c = 'No Contact' AND SM_Disposition__c = 'Busy'];
        System.assertEquals(1, newSetupCallLst.size(), 'Should have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> newF9ListItemRecords = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Lead__c =: oldLead.Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(0, newF9ListItemRecords.size(), 'Should have zero five9 list item records');
        List<Task> reminders = [SELECT Id, ActivityDate FROM Task WHERE RecordTypeId =: reminderTaskRT AND WhoId =: oldLead.Id AND IsRecurrence = false];
        System.assertEquals(1, reminders.size(), 'Should have only one reminder created');
        System.assertEquals(System.today().addDays(1), reminders.get(0).ActivityDate, 'The result is not the expected');

    }

    @IsTest
    static void removeLeadFromReminderAndAssignF9List(){

        Lead oldLead = [SELECT Id, Status, SM_Lead_Disposition__c FROM Lead WHERE Email =: 'leadToTestF9Assigment@test.com' LIMIT 1];

        List<SM_Company_setting__c> companySettingLst = [SELECT Id FROM SM_Company_setting__c WHERE SM_Destination_Bussines_Unit__c = 'Legal credit solutions'];
        System.assertEquals(1, companySettingLst.size(), 'Should have only one compay setting record');
        List<SM_Setup_calls_distribute__c> oldSetupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Lead' AND SM_Stage_or_Status__c = 'New' AND SM_Disposition__c = 'New'];
        System.assertEquals(1, oldSetupCallLst.size(), 'Should have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> recordsCreated = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Lead__c =: oldLead.Id AND Five9LSP__Five9_List__c =: oldSetupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, recordsCreated.size(), 'Should have only one five9 list item record');

        oldLead.Status = 'Not Oriented';
        oldLead.SM_Lead_Disposition__c = 'Call Back';
        update oldLead;

        List<SM_Setup_calls_distribute__c> setupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Lead' AND SM_Stage_or_Status__c = 'No Contact' AND SM_Disposition__c = 'Busy'];
        System.assertEquals(1, setupCallLst.size(), 'Should have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> newF9ListItemRecords = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Lead__c =: oldLead.Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(0, newF9ListItemRecords.size(), 'Should have zero five9 list item records');
        List<Task> reminders = [SELECT Id FROM Task WHERE RecordTypeId =: reminderTaskRT AND WhoId =: oldLead.Id AND IsRecurrence = false];
        System.assertEquals(1, reminders.size(), 'Should have only one reminder created');

        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        Lead leadToAssignF9List = [SELECT Id, Status, SM_Lead_Disposition__c FROM Lead WHERE Email =: 'leadToTestF9Assigment@test.com' LIMIT 1];
        Test.startTest();
        System.runAs(salesUser){
            leadToAssignF9List.Status = 'Oriented';
            leadToAssignF9List.SM_Lead_Disposition__c = 'Expensive';
            update leadToAssignF9List;
        }
        Test.stopTest();

        List<SM_Setup_calls_distribute__c> newSetupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Lead' AND SM_Stage_or_Status__c = 'Oriented' AND SM_Disposition__c = 'Expensive'];
        System.assertEquals(1, newSetupCallLst.size(), 'Should have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> f9ListRecords = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Lead__c =: leadToAssignF9List.Id AND Five9LSP__Five9_List__c =: newSetupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, f9ListRecords.size(), 'Should have only one five9 list item record');
        reminders = [SELECT Id, Status FROM Task WHERE RecordTypeId =: reminderTaskRT AND WhoId =: oldLead.Id AND IsRecurrence = false];
        System.assertEquals(0, reminders.size(), 'Should have only one reminder created');
    }

    @IsTest
    static void removeLeadFromF9List(){

        Lead oldLead = [SELECT Id, Status, SM_Lead_Disposition__c FROM Lead WHERE Email =: 'leadToTestF9Assigment@test.com' LIMIT 1];

        List<SM_Company_setting__c> companySettingLst = [SELECT Id FROM SM_Company_setting__c WHERE SM_Destination_Bussines_Unit__c = 'Legal credit solutions'];
        System.assertEquals(1, companySettingLst.size(), 'Should have only one compay setting record');
        List<SM_Setup_calls_distribute__c> oldSetupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Lead' AND SM_Stage_or_Status__c = 'New' AND SM_Disposition__c = 'New'];
        System.assertEquals(1, oldSetupCallLst.size(), 'Should have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> recordsCreated = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Lead__c =: oldLead.Id AND Five9LSP__Five9_List__c =: oldSetupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, recordsCreated.size(), 'Should have only one five9 list item record');

        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        Test.startTest();
        System.runAs(salesUser){
            oldLead.Status = 'No Contact';
            oldLead.SM_Lead_Disposition__c = 'Disconnected Number';
            update oldLead;
        }
        Test.stopTest();

        oldSetupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Lead' AND SM_Stage_or_Status__c = 'No Contact' AND SM_Disposition__c = 'Disconnected Number'];
        System.assertEquals(0, oldSetupCallLst.size(), 'Should not have any setup calls distribute record');
        recordsCreated = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Lead__c =: oldLead.Id];
        System.assertEquals(0, recordsCreated.size(), 'Should not have any five9 list item record to this lead');


    }
}