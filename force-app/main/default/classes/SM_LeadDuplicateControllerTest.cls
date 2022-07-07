/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 12-23-2020
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-26-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
@IsTest
public with sharing class SM_LeadDuplicateControllerTest {
    
    @TestSetup
    static void makeData(){
        //Insert company setting
        insert SM_TestSmartDataFactory.getCompanySetting();
        //Coverage of insert methods, after and before
        Lead lead = SM_TestSmartDataFactory.getLead();
        lead.Phone = '313666777';
        lead.LeadSource = 'Facebook Ads';
        User user = SM_TestSmartDataFactory.getUser();
        insert user;
        lead.OwnerId = user.Id;
        insert lead;
    }

    @IsTest
    static void foundDuplicatesOk(){
        Lead lead = SM_TestSmartDataFactory.getLead();
        lead.Phone = '313666777';
        lead.LeadSource = 'Facebook Ads';
        lead.SM_key_for_duplicates__c = '';
        lead.SM_key_for_duplicates_2__c = '313666777';
        lead.status = SM_LeadHelper.leadStatusEnum.NEW_STATUS;

        Test.startTest();
        SM_LeadDuplicateController duplicateController = new SM_LeadDuplicateController(new List<Lead>{lead});
        Map<Lead, Lead[]> duplicatesByLead = duplicateController.initProcessing();
        //validate quanity of leads with duplicates
        System.assertEquals(1, duplicatesByLead.values().size(), 'Quantity of Leads with duplicateswrong');
        //validate quanity of leads duplicates
        System.assertEquals(1, duplicatesByLead.values()[0].size(), 'Quantity of duplicates leads wrong');
        Lead[] leadsresult = new List<Lead>(duplicatesByLead.keySet());
        System.assertEquals(lead.Id, leadsresult[0].Id, 'Id of duplicate validation wrong');
        System.assertEquals(lead.SM_key_for_duplicates_2__c, duplicatesByLead.values()[0][0].SM_key_for_duplicates_2__c, 'Key of duplicate wrong');
        //validate quantity of traking inbounds record were created
        System.assertEquals(2, [SELECT Count() FROM SM_Tracking_Inbound__c WHERE SM_Lead_origin__c = 'Facebook Ads'], 'Quantity of traking inbounds wrong');
        Test.stopTest();
    }

    @IsTest
    static void notFoundDuplicatesOk(){
        Lead lead = SM_TestSmartDataFactory.getLead();
        lead.Phone = '313666777';
        lead.LeadSource = 'Google ads';
        lead.SM_key_for_duplicates__c = '';
        lead.SM_key_for_duplicates_2__c = '313666777-Google ads';
        lead.status = SM_LeadHelper.leadStatusEnum.NEW_STATUS;

        Test.startTest();
        SM_LeadDuplicateController duplicateController = new SM_LeadDuplicateController(new List<Lead>{lead});
        Map<Lead, Lead[]> duplicatesByLead = duplicateController.initProcessing();
        //validate quanity of leads with duplicates
        System.assertEquals(1, duplicatesByLead.values().size(), 'Quantity of duplicates leads wrong');
        //validate quanity of leads duplicates
        System.assertEquals(0, duplicatesByLead.values()[0].size(), 'Quantity of duplicates leads wrong');
        //validate quantity of traking inbounds record were created
        System.assertEquals(1, [SELECT Count() FROM SM_Tracking_Inbound__c WHERE SM_Lead_origin__c = 'Google ads'], 'Quantity of traking inbounds wrong');
        Test.stopTest();
    }
}