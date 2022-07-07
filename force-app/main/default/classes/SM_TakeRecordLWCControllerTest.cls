/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 01-08-2021
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-23-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
@IsTest
public with sharing class SM_TakeRecordLWCControllerTest {
   
    @TestSetup
    static void makeData(){
        insert SM_TestSmartDataFactory.getCompanySetting();
        Lead lead = SM_TestSmartDataFactory.getLead();
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        User user = SM_TestSmartDataFactory.getUser();
        insert user;

        lead.OwnerId = user.Id;
        insert lead;

        opp.OwnerId = user.Id;
        insert opp;
    }

    @IsTest
    static void changeRecordOwnerOk(){
        SM_Company_setting__c cs = [SELECT SM_Lead_Stage__c FROM SM_Company_setting__c LIMIT 1];
        cs.SM_Lead_Stage__c = SM_OpportunityHelper.stageName.noContact;
        update cs;
        Test.startTest();
            Lead lead = [SELECT Id FROM Lead LIMIT 1];
            SM_TakeRecordLWCController.changeRecordOwner(lead.Id);
            lead = [SELECT OwnerId FROM Lead LIMIT 1];
        Test.stopTest();

        system.assertEquals(UserInfo.getUserId(), lead.OwnerId, 'The owner of lead must be ' + UserInfo.getUserId());
    }

    @IsTest
    static void changeRecordOwnerError(){

        Test.startTest();
            Lead lead = [SELECT Id FROM Lead LIMIT 1];
            lead.OwnerId = UserInfo.getUserId();
            update lead;
            try {
                SM_TakeRecordLWCController.changeRecordOwner(lead.Id);    
            } catch (Exception e) {
                system.assertEquals('Script-thrown exception', e.getMessage(), 'Unexpected message');        
            }
            lead = [SELECT OwnerId FROM Lead LIMIT 1];
        Test.stopTest();

        system.assertEquals(UserInfo.getUserId(), lead.OwnerId, 'The owner of lead must be ' + UserInfo.getUserId());
    }

    @IsTest
    static void changeRecordOwnerOppOk(){

        Test.startTest();
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            SM_TakeRecordLWCController.changeRecordOwner(opp.Id);
            opp = [SELECT OwnerId FROM Opportunity LIMIT 1];
        Test.stopTest();

        system.assertEquals(UserInfo.getUserId(), opp.OwnerId, 'The owner of Opportunity must be ' + UserInfo.getUserId());
    }

    @IsTest
    static void changeRecordOwnerOppError(){
        SM_Company_setting__c cs = [SELECT SM_Opportunity_Stage_not_accessible__c FROM SM_Company_setting__c LIMIT 1];
        cs.SM_Opportunity_Stage_not_accessible__c = SM_OpportunityHelper.stageName.noContact;
        update cs;
        
        Test.startTest();
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            SM_TakeRecordLWCController.changeRecordOwner(opp.Id);
            opp = [SELECT OwnerId FROM Opportunity LIMIT 1];
        Test.stopTest();

        system.assertEquals(UserInfo.getUserId(), opp.OwnerId, 'The owner of Opportunity must be ' + UserInfo.getUserId());
    }
}