/**
 * @description       :
 * @author            : Camilo Jimenez
 * @group             :
 * @last modified on  : 06-02-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log
 * Ver   Date         Author                        Modification
 * 1.0   08-01-2021  cjimenez@legal-credit.com   Initial Version
**/

@IsTest
public with sharing class SM_UploadCloudDocumentsLWCControllerTest {

    @TestSetup
    static void makeData(){

        Account account = SM_TestSmartDataFactory.getPersonAccount();
        account.PersonEmail = 'test.monee@test.com';
        account.Phone = '313666777';
        insert account;


    }


    // JSPA - 06/02/2021 - Error in prd
    // @IsTest
    // static void createCloudDocument(){


    //     Test.startTest();
    //         Account acc = [SELECT Id FROM Account LIMIT 1];
    //         SM_UploadCloudDocumentsLWCController.getDocumetType();
    //         SM_UploadCloudDocumentsLWCController.getPathParametersS3('Prueba.jpg',acc.id,'Agreements');
    //         SM_UploadCloudDocumentsLWCController.createCloudDocument('Prueba.jpg',acc.id,'Agreements','SM_Account__c','Test/Account/Pruebas.jpg','LCS');

    //         List<SM_Cloud_Document__c> lstCloudDocument = [SELECT Id FROM SM_Cloud_Document__c ];

    //         system.assertEquals(1, lstCloudDocument.size(), 'Should must create a Cloud Document record');

    //     Test.stopTest();
    // }


    // @IsTest
    // static void generatePath(){
    //     list<SM_SetupDocumentPath__mdt> lstSetupDocumentPath = [SELECT DeveloperName,Label,SM_DocumetType__c,SM_GenerateDate__c,SM_ObjectAPIName__c,SM_RenameName__c,SM_SetupBucketS3__r.SM_BucketName__c,
    //                                                             SM_SetupBucketS3__r.SM_Key__c,SM_SetupBucketS3__r.SM_Secret__c,SM_Abbreviated_Company__c,
    //                                                             (SELECT Label,SM_Folder__c,SM_SearchFieldName__c,SM_SearchQuery__c,SM_Position__c  FROM SM_SetupDocumentPath__r ORDER BY SM_Position__c ASC )
    //                                                             FROM SM_SetupDocumentPath__mdt ];

    //     for(SM_SetupDocumentPath__mdt setupDocumentPath:lstSetupDocumentPath){
    //        if(setupDocumentPath.SM_DocumetType__c=='Agreements'){
    //           for(SM_SetupPathLevel__mdt setupPathLevel:setupDocumentPath.SM_SetupDocumentPath__r){
    //              setupPathLevel.SM_Folder__c=false;
    //           }
    //         }
    //     }


    //     Test.startTest();

    //         Account acc = [SELECT Id FROM Account LIMIT 1];
    //         SM_CloudDocumentPath cloudDocumentPath=new SM_CloudDocumentPath();
    //         cloudDocumentPath.lstSetupDocumentPath=lstSetupDocumentPath;
    //         cloudDocumentPath.generatePath('Agreements','Prueba.jpg',acc.id,'LCS');
    //         System.assert(cloudDocumentPath.bucket != null);


    //     Test.stopTest();
    // }



}