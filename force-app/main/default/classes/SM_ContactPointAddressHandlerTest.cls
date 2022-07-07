/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 03-08-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   03-06-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
@IsTest
public without sharing class SM_ContactPointAddressHandlerTest {

    @TestSetup
    static void makeData(){
        ContactPointAddress cpa = SM_TestSmartDataFactory.getContactPointAddress('Street 1','BOG','CUN','111111','COL', 'Physical Address');
        insert cpa;
    }

    @IsTest
    static void testFillName(){
        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        Test.startTest();
        System.runAs(salesUser){
            ContactPointAddress cpa = SM_TestSmartDataFactory.getContactPointAddress('Street 1','NY','NY','00001','USA', 'Physical Address');
            insert cpa;
            cpa.Street = 'Street 2';
        }
        Test.stopTest();
        ContactPointAddress cpa = [SELECT Name, Street, City, State, PostalCode, Country FROM ContactPointAddress LIMIT 1];
        System.assertEquals(cpa.Street + ' ' + cpa.City + ', ' + cpa.State + ' ' + cpa.PostalCode + ' ' + cpa.Country, cpa.Name, 'The result is not the expected');
    }

    @IsTest
    static void testFillNameUpdate(){
        
        List<ContactPointAddress> cpaLst = [SELECT Id, Street FROM ContactPointAddress WHERE name like '%COL%'];
        System.assertEquals(1, cpaLst.size(), 'Should have only one record');
        Test.startTest();
            cpaLst.get(0).Street = 'Street 2';
            update cpaLst;
        Test.stopTest();
        List<ContactPointAddress> cpaUpdatedLst = [SELECT Id, Name, Street, City, State, PostalCode, Country FROM ContactPointAddress WHERE Id =: cpaLst.get(0).Id];
        System.assertEquals(1, cpaUpdatedLst.size(), 'Should have only one record');
        System.assertEquals(cpaUpdatedLst.get(0).Street + ' ' + cpaUpdatedLst.get(0).City + ', ' + cpaUpdatedLst.get(0).State + ' ' + cpaUpdatedLst.get(0).PostalCode + ' ' + cpaUpdatedLst.get(0).Country, cpaUpdatedLst.get(0).Name, 'The result is not the expected');
    }

}