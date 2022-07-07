/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 04-29-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   01-07-2021   diego.jacanamijoy@gmail.com   Initial Version
 * 1.1   01-18-2021   cjimenez@legal-credit.com   Initial Version
**/
@IsTest
public with sharing class SM_TestSmartDataFactoryTest {
    
    private static String five9RTName = SM_SetupCallsDistributeHelper.recordType.five9List;

    @isTest
    static void getData(){
        Test.startTest();
        SM_Company_setting__c cs = SM_TestSmartDataFactory.getCompanySetting();
        insert cs;
        Lead lead = SM_TestSmartDataFactory.getLead();
        User user = SM_TestSmartDataFactory.getUser();
        Account acc = SM_TestSmartDataFactory.getPersonAccount();
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        Account account = SM_TestSmartDataFactory.getPersonAccount();
        SM_Dispute__c dispute=SM_TestSmartDataFactory.getDispute();
        SM_SetupToken__c setupToken=SM_TestSmartDataFactory.getSetupToken();
        insert account;
        echosign_dev1__SIGN_Agreement__c agreementObj = SM_TestSmartDataFactory.getAgreement();
        insert agreementObj;  
        Attachment attachmentObj = SM_TestSmartDataFactory.getAttachment(agreementObj.id);
        insert attachmentObj;
        system.debug('attachmentObj-->'+attachmentObj.id);
        APXTConga4__Conga_Solution__c conga4CongaSolutionObj = SM_TestSmartDataFactory.getConga4CongaSolutionObj();
        insert conga4CongaSolutionObj;
        Process_automation_by_product_family__c processautomationProductfamilyObj = SM_TestSmartDataFactory.getProcessautomationProductfamily(cs.id,conga4CongaSolutionObj.id);
        insert processautomationProductfamilyObj;
        Contract contract = SM_TestSmartDataFactory.getContract(account.Id,processautomationProductfamilyObj.id);
        insert contract;
    
        Attachment attachment = SM_TestSmartDataFactory.getAttachment(contract.Id);
        Insert attachment;
        echosign_dev1__SIGN_Agreement__c Agre=SM_TestSmartDataFactory.getAgreement();	
        
        Five9LSP__Five9_List__c five9L = SM_TestSmartDataFactory.getFive9List('Test class - New Leads', 'Lead');
        insert five9L;
        SM_Setup_calls_distribute__c sc = SM_TestSmartDataFactory.getSetupCallDistribute(five9RTName, cs.Id, five9L.Id, 'Lead', 'New', 'No Contact');
        Five9LSP__Five9_LSP_Settings__c five9Setting = SM_TestSmartDataFactory.getFive9Settings();
        insert SM_TestSmartDataFactory.getProccessAutomation();
        SM_TestSmartDataFactory.getPricebookEntry();
        SM_TestSmartDataFactory.getContactPointAddress('Street 1','NY','NY','00001','USA','Physical Address');
        Asset asset = SM_TestSmartDataFactory.getAsset(acc.Id, contract.Id);
        insert asset;
        SM_TestSmartDataFactory.getTask();
        SM_TestSmartDataFactory.getTrackingInbound('Tracking inbound 1');
        SM_TestSmartDataFactory.getConversionFieldMappingObj(cs.Id, 'Lead', 'FirstName', 'Account','FirstName');
        SM_TestSmartDataFactory.getRequiredFields(cs.Id);
        SM_TestSmartDataFactory.getGateway();
        SM_TestSmartDataFactory.getACHOrder(contract.Id);
        SM_TestSmartDataFactory.getAssetFee(asset.Id);
        Test.stopTest();
    }
}