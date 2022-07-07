/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 03-11-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   02-05-2021   diego.jacanamijoy@gmail.com   Initial Version
**/
@IsTest
public with sharing class SM_GenerateContractControllerTest {
    
    @IsTest
    static void makeData(){
        insert new SM_SetupToken__c (SM_Active__c = true ,SM_ExpirationDate__c=System.now(), SM_DurationMinutes__c = 15 , Name ='Token Native');
        insert SM_TestSmartDataFactory.getProccessAutomation();
        Account acc = SM_TestSmartDataFactory.getPersonAccount();
        insert acc;

        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        opp.AccountId = acc.Id;
        insert opp;

        OpportunityLineItem oppLit = SM_TestSmartDataFactory.getOpportunityLineItem();
        oppLit.OpportunityId = opp.Id;
        oppLit.TotalPrice = 1200;
        insert oppLit;

        OpportunityLineItem oppLit2 = oppLit.clone();
        insert oppLit2;

        ContactPointAddress cpa = SM_TestSmartDataFactory.getContactPointAddress('','','','','',SM_ContactPointAddressHelper.type.POSTAL_ADDRESS);
        cpa.ParentId = acc.Id;
        insert new List<ContactPointAddress>{cpa};

    }

    @IsTest(SeeAllData=true)
    static void generateContractsOk(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
            SM_GenerateContractController geerateContract = new SM_GenerateContractController(new List<String>{opp.Id});
            Contract contract = [SELECT SM_Generates_dispute__c, SM_Requires_AC_Payment__c, SM_Total_ac__c, SM_Postal_address__c FROM Contract LIMIT 1];
            System.assertNotEquals(null, contract, 'Must return one contract record');
            System.assertEquals(true, contract.SM_Generates_dispute__c, 'Must return true dispute');
            System.assertEquals(true, contract.SM_Requires_AC_Payment__c, 'Must return true Ac required');
            //System.assertEquals(40000, contract.SM_Total_ac__c, 'Must return 40000');
            System.assertNotEquals(null, contract.SM_Postal_address__c, 'Must be not null');
        Test.stopTest();
    }
}