/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 02-05-2021
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   12-07-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
@IsTest
public with sharing class SM_OpportunityHelperTest {
    
    @TestSetup
    static void makeData(){
        insert SM_TestSmartDataFactory.getOpportunity();
    }
    
    @IsTest
    static void getOpportunityIdOk(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
            Opportunity oppResult = SM_OpportunityHelper.getOpportunityId(opp.Id);
            System.assertEquals(oppResult.Id, opp.Id, 'The ids do not match');
        Test.stopTest();

    }

    @IsTest
    static void getOpportunityIdError(){
        Test.startTest();
            Opportunity oppResult = SM_OpportunityHelper.getOpportunityId('123456789');
            System.assertEquals(null, oppResult, 'The result must be null');
        Test.stopTest();

    }

    @IsTest
    static void getOpportunitiesByDinamicQueryOk(){
        Test.startTest();
            String query = 'SELECT Id FROM Opportunity LIMIT 1';
            List<Opportunity> opps = SM_OpportunityHelper.getOpportunitiesByDinamicQuery(query);
            System.assertEquals(1, opps.size(), 'Must return one record');
        Test.stopTest();
    }
}