/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 02-26-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   02-26-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
@isTest
public without sharing class SM_AssetHelperTest {

    private static final String EMAIL_1 = 'acc1@test.com';
    private static final String EMAIL_2 = 'acc2@test.com';

    @TestSetup
    static void makeData(){
        Account acc = SM_TestSmartDataFactory.getPersonAccount();
        acc.PersonEmail = EMAIL_1;
        Account acc2 = SM_TestSmartDataFactory.getPersonAccount().clone();
        acc2.PersonEmail = EMAIL_2;
        insert new List<Account>{acc, acc2};

        Contract ct = SM_TestSmartDataFactory.getContract(acc.Id, null);
        Contract ct2 = SM_TestSmartDataFactory.getContract(acc2.Id, null);
        insert new List<Contract>{ct, ct2};

        Asset ast = SM_TestSmartDataFactory.getAsset(acc.Id, ct.Id);
        Asset ast2 = SM_TestSmartDataFactory.getAsset(acc.Id, ct.Id);
        Asset ast3 = SM_TestSmartDataFactory.getAsset(acc2.Id, ct2.Id);
        Asset ast4 = SM_TestSmartDataFactory.getAsset(acc2.Id, ct2.Id);
        Asset ast5 = SM_TestSmartDataFactory.getAsset(acc2.Id, ct2.Id);
        insert new List<Asset>{ast, ast2, ast3, ast4, ast5};
        
    }

    @IsTest
    static void getAssetsByContractIds(){
        
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name =: 'Sales Agent'];
        User salesUser = [SELECT Id FROM User WHERE ProfileId =: salesProfile.Id AND IsActive = TRUE LIMIT 1];

        Contract ct = [SELECT Id FROM Contract WHERE Account.PersonEmail =: EMAIL_1];
        Contract ct2 = [SELECT Id FROM Contract WHERE Account.PersonEmail =: EMAIL_2];

        Map<String, List<Asset>> assetsByContractId;
        Test.startTest();
        System.runAs(salesUser){
            assetsByContractId = SM_AssetHelper.getAssetsByContractIds(new Set<String>{ct.Id, ct2.Id});
        }
        Test.stopTest();
        System.assertEquals(2, assetsByContractId.get(ct.Id).size(), 'The contract must have only two asset records');
        System.assertEquals(3, assetsByContractId.get(ct2.Id).size(), 'The contract must have only three asset records');
        
    }
}