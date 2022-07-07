/**
* @description       : Test Class SM_DisputeHandler,SM_ServiceInvokation,SM_HelperWS,SM_DisputeHandler
* @author            : cjimenez@legal-credit.com 
* @group             : 
* Modifications Log 
* Ver   Date         Author                        Modification
* 1.0   17-01-2021   cjimenez@legal-credit.com    Initial Version
**/
@IsTest
public with sharing class SM_DisputeHandlerTest {
    
    @IsTest
    static void insertNewDisputeOk(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        SM_Dispute__c dispute=SM_TestSmartDataFactory.getDispute();
        SM_SetupToken__c setupToken=SM_TestSmartDataFactory.getSetupToken();
        insert setupToken;
        dispute.SM_Status__c = SM_DisputeHelper.status.DRAFT;
        insert dispute;
        dispute.SM_Status__c = SM_DisputeHelper.status.PENDING;
        update dispute;
        Test.stopTest();
    }


    @IsTest
    static void insertOldDataOk(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        SM_Dispute__c dispute=SM_TestSmartDataFactory.getDispute();
        SM_SetupToken__c setupToken=SM_TestSmartDataFactory.getSetupToken();
        insert setupToken;
        insert dispute;
        dispute.SM_Status__c = SM_DisputeHelper.status.CANCELLED;
        update dispute;
        Test.stopTest();
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Success":"true","errorMessage":"","ErrorDispute":""}');
            res.setStatusCode(200);
            return res;
        }
    }
}