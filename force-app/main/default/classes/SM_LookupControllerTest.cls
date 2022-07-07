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
public without sharing class SM_LookupControllerTest {

    private static final String ADDRESS_TYPE = 'Physical Address';

    @TestSetup
    static void makeData(){
        ContactPointAddress cpa = SM_TestSmartDataFactory.getContactPointAddress('Street 1','NY','NY','00001','USA',ADDRESS_TYPE);
        insert new List<ContactPointAddress>{cpa};
    }

    @IsTest
    static void testSearchAddresses(){

        List<ContactPointAddress> cpaLst;
        Test.startTest();
            cpaLst = SM_LookupController.searchAddresses('NY', ADDRESS_TYPE, '');
        Test.stopTest();
        System.assertEquals(1, cpaLst.size(), 'Shoul have only one contact point address record');
        
    }

}