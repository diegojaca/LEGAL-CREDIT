/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 03-11-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   03-11-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
@IsTest
public without sharing class SM_ContactPointAddressHelperTest {


    @TestSetup
    static void makeData(){
        Account acc = SM_TestSmartDataFactory.getPersonAccount();
        insert new List<Account>{acc};

        ContactPointAddress cpa = SM_TestSmartDataFactory.getContactPointAddress('St. 1','FL','FL','00001','USA',SM_ContactPointAddressHelper.type.POSTAL_ADDRESS);
        cpa.ParentId = acc.Id;
        ContactPointAddress cpa2 = SM_TestSmartDataFactory.getContactPointAddress('St. 1','FL','FL','00001','USA',SM_ContactPointAddressHelper.type.PHYSICAL_ADDRESS);
        cpa2.ParentId = acc.Id;
        insert new List<ContactPointAddress>{cpa, cpa2};
    }

    @IsTest
    static void testGetAddressesByParentIds(){

        Account acc = [SELECT Id FROM ACCOUNT LIMIT 1];
        List<ContactPointAddress> addresses;
        Test.startTest();
        // System.runAs(contextuser){
            addresses = SM_ContactPointAddressHelper.getAddressesByParentIds(new Set<String>{acc.Id}); 
        // }
        Test.stopTest();
        System.assertEquals(2, addresses.size(), 'The result is not the expected.');
        
    }
}