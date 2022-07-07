/**
 * @description       : 
 * @author            : jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 01/06/2021
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@gmail.es
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   12-01-2020   jpachon@legal-credit.com   Initial Version
 * 1.1   02-14-2021   cjimenez@legal-credit.com   Initial Version
**/
@IsTest
public with sharing class SM_OpportunityHandlerTest {

    private static final String OPP_NAME_TO_SEND = 'Opp Name - New';
    private static final String OPP_NAME_TO_SEND_2 = 'Opp Name - New - Admin';
    private static final String OPP_NAME_DONT_SEND = 'Opp Name - Converted';
    private static final String FIVE9_LIST_NAME_OPP_NEW_NEW = 'Opportunity New New';
    private static final String FIVE9_LIST_NAME_OPP_NO_CONTACT_BUSY = 'Opportunity No Contact Busy';
    private static final String FIVE9_LIST_NAME_OPP_ORIENTED_EXPENSIVE = 'Opportunity Oriented Expensive';
    private static String five9RTName = SM_SetupCallsDistributeHelper.recordType.five9List;
    private static String reminderTaskRT = SM_Utils.getRecordTypeIdByDeveloperName('Task', SM_TaskHelper.recordType.reminder);

    @TestSetup
    static void makeData(){

        Five9LSP__Five9_LSP_Settings__c f9Settings = SM_TestSmartDataFactory.getFive9Settings();
        insert f9Settings;

        SM_Company_setting__c lcsCompanySetting = SM_TestSmartDataFactory.getCompanySetting();
        String pricebookId=SM_TestSmartDataFactory.getPricebookId();
        lcsCompanySetting.SM_Pricebook2Id__c=pricebookId;
        lcsCompanySetting.SM_Destination_Bussines_Unit__c = 'Legal credit solutions';
        insert new List<SM_Company_setting__c>{lcsCompanySetting};
   
        Five9LSP__Five9_List__c f9ListOppNewNew = SM_TestSmartDataFactory.getFive9List(FIVE9_LIST_NAME_OPP_NEW_NEW, 'Opportunity');
        Five9LSP__Five9_List__c f9ListOppNoContactBusy = SM_TestSmartDataFactory.getFive9List(FIVE9_LIST_NAME_OPP_NO_CONTACT_BUSY, 'Opportunity');
        Five9LSP__Five9_List__c f9ListOppOrientedExpensive = SM_TestSmartDataFactory.getFive9List(FIVE9_LIST_NAME_OPP_ORIENTED_EXPENSIVE, 'Opportunity');
        insert new List<Five9LSP__Five9_List__c>{f9ListOppNewNew, f9ListOppNoContactBusy, f9ListOppOrientedExpensive};

        SM_Setup_calls_distribute__c oppNewNewSCD =  SM_TestSmartDataFactory.getSetupCallDistribute(five9RTName, lcsCompanySetting.Id, f9ListOppNewNew.Id, 'Opportunity', 'New', 'New');
        oppNewNewSCD.Name = 'Opportunity New New - Setup Calls Distribute';
        SM_Setup_calls_distribute__c oppNoContactBusySCD =  SM_TestSmartDataFactory.getSetupCallDistribute(five9RTName, lcsCompanySetting.Id, f9ListOppNoContactBusy.Id, 'Opportunity', 'No Contact', 'Busy');
        oppNoContactBusySCD.Name = 'Opportunity No Contact Busy - Setup Calls Distribute';
        SM_Setup_calls_distribute__c oppOrientedExpensiveSCD =  SM_TestSmartDataFactory.getSetupCallDistribute(five9RTName, lcsCompanySetting.Id, f9ListOppOrientedExpensive.Id, 'Opportunity', 'Oriented', 'Expensive');
        oppOrientedExpensiveSCD.Name = 'Lead No Contact Busy - Setup Calls Distribute';
        SM_Setup_calls_distribute__c oppNotOrientedCallbackSCD =  SM_TestSmartDataFactory.getReminderSetupCallDistribute(lcsCompanySetting.Id, 'Opportunity', 'Not Oriented', 'Call Back', 1);
        oppNotOrientedCallbackSCD.Name = 'Lead Not Oriented Call back - Setup Calls Distribute';
        insert new List<SM_Setup_calls_distribute__c>{oppNewNewSCD, oppNoContactBusySCD, oppOrientedExpensiveSCD, oppNotOrientedCallbackSCD};

        List<Opportunity> opps = new List<Opportunity>();
        Opportunity oppToSend = new Opportunity(
            Name = OPP_NAME_TO_SEND_2,
            CloseDate = System.today().addMonths(1),
            SM_Company_Setting__c = lcsCompanySetting.Id,
            StageName = 'New',
            SM_Opportunity_Disposition__c = 'New'
        );
        opps.add(oppToSend);
        insert opps;

    }

    /* Mar 12 - To Deploy in PRD
    @IsTest
    static void testDontSendOppsWhenThoseComeFromLeads(){

        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        List<SM_Company_setting__c> companySettingLst = [SELECT Id FROM SM_Company_setting__c WHERE SM_Destination_Bussines_Unit__c = 'Legal credit solutions'];
        System.assertEquals(1, companySettingLst.size(), 'Shoul have only one compay setting record');

        Opportunity oppToSend = SM_TestSmartDataFactory.getOpportunity();
        oppToSend.Name = OPP_NAME_TO_SEND;
        oppToSend.SM_Company_Setting__c = companySettingLst.get(0).Id;
        oppToSend.StageName = 'New';
        oppToSend.SM_Opportunity_Disposition__c = 'New';
        Opportunity oppFromLead = SM_TestSmartDataFactory.getOpportunity();
        oppFromLead.SM_Conversion_opportunity__c = true;
        oppFromLead.Name = OPP_NAME_DONT_SEND;
        oppFromLead.SM_Company_Setting__c = companySettingLst.get(0).Id;
        oppFromLead.StageName = 'New';
        oppFromLead.SM_Opportunity_Disposition__c = 'New';
        
        Test.startTest();
            System.runAs(salesUser){
                insert new List<Opportunity>{oppToSend, oppFromLead};
            }
        Test.stopTest();

        List<SM_Setup_calls_distribute__c> setupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Opportunity' AND SM_Stage_or_Status__c = 'New' AND SM_Disposition__c = 'New'];
        System.assertEquals(1, setupCallLst.size(), 'Shoul have only one setup calls distribute record');

        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Name =: OPP_NAME_TO_SEND];
        System.assertEquals(1, opps.size(), 'Should have only one record');

        List<Five9LSP__Five9_List_Item__c> five9ListItems = [SELECT Id, Five9LSP__Five9_List__c FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Opportunity__c =: opps.get(0).Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, five9ListItems.size(), 'Should have only one five9 list item record');

        List<Opportunity> oppNotSent = [SELECT Id FROM Opportunity WHERE Name =: OPP_NAME_DONT_SEND];
        System.assertEquals(1, oppNotSent.size(), 'Should have only one record');

        five9ListItems = [SELECT Id, Five9LSP__Five9_List__c FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Opportunity__c =: oppNotSent.get(0).Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(0, five9ListItems.size(), 'Should not have any five9 list item record');


    }*/

    @IsTest
    static void assignOppFromF9ListToAnotherF9List(){

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        List<SM_Company_setting__c> companySettingLst = [SELECT Id FROM SM_Company_setting__c WHERE SM_Destination_Bussines_Unit__c = 'Legal credit solutions'];
        System.assertEquals(1, companySettingLst.size(), 'Shoul have only one compay setting record');
        List<SM_Setup_calls_distribute__c> setupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Opportunity' AND SM_Stage_or_Status__c = 'New' AND SM_Disposition__c = 'New'];
        System.assertEquals(1, setupCallLst.size(), 'Shoul have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> oldRecordCreated = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Opportunity__c =: opp.Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, oldRecordCreated.size(), 'Should have only one five9 list item record');
        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        opp.OwnerId = salesUser.Id;
        update opp;

        Test.startTest();
            System.runAs(salesUser){
                opp.StageName = 'No Contact';
                opp.SM_Opportunity_Disposition__c = 'Busy';
                update opp;
            }
        Test.stopTest();

        setupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Opportunity' AND SM_Stage_or_Status__c = 'No Contact' AND SM_Disposition__c = 'Busy'];
        System.assertEquals(1, setupCallLst.size(), 'Shoul have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> newRecordCreated = [SELECT Id, Five9LSP__Five9_List__c FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Opportunity__c =: opp.Id];
        System.assertEquals(1, newRecordCreated.size(), 'Should have only one five9 list item record');
        System.assertEquals(setupCallLst.get(0).SM_Five9_List__c, newRecordCreated.get(0).Five9LSP__Five9_List__c, 'The five9 list record is not expected.');
                
    }

    @IsTest
    static void removeOppFromF9ListAndCreateReminderTask(){

        Opportunity oldOpp = [SELECT Id FROM Opportunity LIMIT 1];

        List<SM_Company_setting__c> companySettingLst = [SELECT Id FROM SM_Company_setting__c WHERE SM_Destination_Bussines_Unit__c = 'Legal credit solutions'];
        System.assertEquals(1, companySettingLst.size(), 'Shoul have only one compay setting record');
        List<SM_Setup_calls_distribute__c> setupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Opportunity' AND SM_Stage_or_Status__c = 'New' AND SM_Disposition__c = 'New'];
        System.assertEquals(1, setupCallLst.size(), 'Shoul have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> oldRecordCreated = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Opportunity__c =: oldOpp.Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, oldRecordCreated.size(), 'Should have only one five9 list item record');
        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        oldOpp.OwnerId = salesUser.Id;
        update oldOpp;

        Test.startTest();
            System.runAs(salesUser){
                oldOpp.StageName = 'Not Oriented';
                oldOpp.SM_Opportunity_Disposition__c = 'Call Back';
                update oldOpp;                
            }
        Test.stopTest();

        List<Five9LSP__Five9_List_Item__c> newF9ListItemRecords = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Opportunity__c =: oldOpp.Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(0, newF9ListItemRecords.size(), 'Should have zero five9 list item records');
        List<Task> reminders = [SELECT Id, ActivityDate FROM Task WHERE RecordTypeId =: reminderTaskRT AND WhatId =: oldOpp.Id AND IsRecurrence = false];
        System.assertEquals(1, reminders.size(), 'Should have only one reminder created');
        System.assertEquals(System.today().addDays(1), reminders.get(0).ActivityDate, 'The result is not the expected');        
    }

    @IsTest
    static void removeLeadFromReminderAndAssignF9List(){

        Opportunity oldOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<SM_Company_setting__c> companySettingLst = [SELECT Id FROM SM_Company_setting__c WHERE SM_Destination_Bussines_Unit__c = 'Legal credit solutions'];
        System.assertEquals(1, companySettingLst.size(), 'Should have only one compay setting record');
        List<SM_Setup_calls_distribute__c> oldSetupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Opportunity' AND SM_Stage_or_Status__c = 'New' AND SM_Disposition__c = 'New'];
        System.assertEquals(1, oldSetupCallLst.size(), 'Should have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> recordsCreated = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Opportunity__c =: oldOpp.Id AND Five9LSP__Five9_List__c =: oldSetupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, recordsCreated.size(), 'Should have only one five9 list item record');
        
        oldOpp.StageName = 'Not Oriented';
        oldOpp.SM_Opportunity_Disposition__c = 'Call Back';
        update oldOpp;

        List<SM_Setup_calls_distribute__c> setupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Opportunity' AND SM_Stage_or_Status__c = 'No Contact' AND SM_Disposition__c = 'Busy'];
        System.assertEquals(1, setupCallLst.size(), 'Should have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> newF9ListItemRecords = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Opportunity__c =: oldOpp.Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(0, newF9ListItemRecords.size(), 'Should have zero five9 list item records');
        List<Task> reminders = [SELECT Id FROM Task WHERE RecordTypeId =: reminderTaskRT AND WhatId =: oldOpp.Id AND IsRecurrence = false];
        System.assertEquals(1, reminders.size(), 'Should have only one reminder created');

        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        Opportunity oppToAssignF9List = [SELECT Id, StageName, SM_Opportunity_Disposition__c  FROM Opportunity LIMIT 1];
        Test.startTest();
        System.runAs(salesUser){
            oldOpp.StageName = 'Oriented';
            oldOpp.SM_Opportunity_Disposition__c = 'Expensive';
            update oldOpp;        
        }
        Test.stopTest();
        
        List<SM_Setup_calls_distribute__c> newSetupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Opportunity' AND SM_Stage_or_Status__c = 'Oriented' AND SM_Disposition__c = 'Expensive'];
        System.assertEquals(1, newSetupCallLst.size(), 'Should have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> f9ListRecords = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Opportunity__c =: oppToAssignF9List.Id AND Five9LSP__Five9_List__c =: newSetupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, f9ListRecords.size(), 'Should have only one five9 list item record');
        reminders = [SELECT Id, Subject, ActivityDate, CreatedDate, Status FROM Task WHERE RecordTypeId =: reminderTaskRT AND WhatId =: oldOpp.Id AND IsRecurrence = false];
        System.debug('reminders: ' + JSON.serialize(reminders));
        System.assertEquals(0, reminders.size(), 'Should not have any reminder created'); 
        
    }

    @IsTest
    static void removeOppFromF9List(){
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        List<SM_Company_setting__c> companySettingLst = [SELECT Id FROM SM_Company_setting__c WHERE SM_Destination_Bussines_Unit__c = 'Legal credit solutions'];
        System.assertEquals(1, companySettingLst.size(), 'Should have only one compay setting record');
        List<SM_Setup_calls_distribute__c> setupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Opportunity' AND SM_Stage_or_Status__c = 'New' AND SM_Disposition__c = 'New'];
        System.assertEquals(1, setupCallLst.size(), 'Should have only one setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> oldRecordCreated = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Opportunity__c =: opp.Id AND Five9LSP__Five9_List__c =: setupCallLst.get(0).SM_Five9_List__c];
        System.assertEquals(1, oldRecordCreated.size(), 'Should have only one five9 list item record');
        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        opp.OwnerId = salesUser.Id;
        update opp;

        Test.startTest();
            System.runAs(salesUser){
                opp.StageName = 'No Contact';
                opp.SM_Opportunity_Disposition__c = 'Disconnected Number';
                update opp;
            }
        Test.stopTest();

        setupCallLst = [SELECT Id, SM_Five9_List__c FROM SM_Setup_calls_distribute__c WHERE SM_Administration_Company__c =: companySettingLst.get(0).Id AND SM_Object__c = 'Opportunity' AND SM_Stage_or_Status__c = 'No Contact' AND SM_Disposition__c = 'BuDisconnected Number'];
        System.assertEquals(0, setupCallLst.size(), 'Should not have any setup calls distribute record');
        List<Five9LSP__Five9_List_Item__c> newRecordCreated = [SELECT Id FROM Five9LSP__Five9_List_Item__c WHERE Five9LSP__Opportunity__c =: opp.Id];
        System.assertEquals(0, newRecordCreated.size(), 'Should not have any five9 list item record to this opportunity');
             
    }

    @IsTest
    static void createContractsOk(){

        Product2 prd2 = SM_TestSmartDataFactory.getproduct2NoInsert();
        insert prd2;
        
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        insert opp;
        
        OpportunityLineItem oppLit = SM_TestSmartDataFactory.getOpportunityLineItem();
        oppLit.OpportunityId = opp.Id;
        oppLit.TotalPrice = 1200;
        oppLit.Product2Id = prd2.id;
        insert oppLit;

        Test.startTest();
            opp.StageName = SM_OpportunityHelper.stageName.oriented;
            opp.SM_Opportunity_Disposition__c = SM_OpportunityHelper.dispositions.sale;
            update opp;

            opp = [SELECT SM_Opportunity_Disposition__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
            System.assertEquals(SM_OpportunityHelper.dispositions.sale, opp.SM_Opportunity_Disposition__c, 'Disposition is not valid');
        Test.stopTest();
    }

}