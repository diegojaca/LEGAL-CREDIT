/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 01-27-2021
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   01-07-2021   diego.jacanamijoy@gmail.com   Initial Version
**/
@IsTest
public with sharing class SM_AccountHelperTest {
    
    @TestSetup
    static void makeData(){
        Account account = SM_TestSmartDataFactory.getPersonAccount();
        insert account;
    }

    @IsTest
    static void recordTypeEnum(){
        String rc = SM_AccountHelper.recordType.personAccount;
    }

    @IsTest
    static void getAccountsByDinamicQueryOk(){
        String query = 'SELECT Id FROM Account LIMIT 1';
        Account[] acc = SM_AccountHelper.getAccountsByDinamicQuery(query);
        system.assertEquals(1, acc.size(), 'Must return one record of account');

        acc = SM_AccountHelper.getAccountsByDinamicQuery('');
        system.assertEquals(0, acc.size(), 'Must not return one record of account');
    }
}