/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             :
 * @last modified on  : 07-24-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   03-27-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
@IsTest
public without sharing class SM_PaymentHelperTest {

    @TestSetup
    static void makeData(){
        Account account = SM_TestSmartDataFactory.getPersonAccount();
        account.PersonEmail='legal_credit@gmail.com.invalid';
        insert account;
        ChargentBase__Gateway__c Gt = SM_TestSmartDataFactory.getGateway();
        insert Gt;
        SM_Company_setting__c companySettingObj = SM_TestSmartDataFactory.getCompanySettingPMethod(Gt.Id);
        companySettingObj.SM_Abbreviated_Company__c = 'LCS';
        insert companySettingObj;
        APXTConga4__Conga_Solution__c conga4CongaSolutionObj = SM_TestSmartDataFactory.getConga4CongaSolutionObj();
        insert conga4CongaSolutionObj;
        Process_automation_by_product_family__c processautomationProductfamilyObj = SM_TestSmartDataFactory.getProcessautomationProductfamily(companySettingObj.id,conga4CongaSolutionObj.id);
        processautomationProductfamilyObj.SM_Generates_dispute__c = true;
        insert processautomationProductfamilyObj;
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        opp.SM_Company_Setting__c = companySettingObj.Id;
        insert opp;
        Contract contract = SM_TestSmartDataFactory.getContract(account.Id,processautomationProductfamilyObj.id);
        contract.SM_Email_to_send_contract__c = 'test@yopmail.com';
        contract.SM_Opportunity__c = opp.Id;
        insert contract;
        SM_Payment__c payment  = SM_TestSmartDataFactory.getPayment(contract.Id);
        insert payment;
    }

    @IsTest
    static void testDoNothing(){
        Test.startTest();
        String status = SM_PaymentHelper.status.ACCEPTED;
        Test.stopTest();
    }

    @IsTest
    static void testSendPaymentReceipt(){
        Contract ct = [SELECT Id FROM Contract];
        Test.startTest();
            SM_Payment__c payment  = SM_TestSmartDataFactory.getPayment(ct.Id);
            payment.Payment_Status__c = 'ACCEPTED';
            insert payment;
        Test.stopTest();
    }

    @IsTest
    static void testUpdatePaymentStatus(){
        // Test.startTest();
        //     SM_Payment__c payment = [SELECT Id FROM SM_Payment__c];
        //     payment.Payment_Status__c = SM_PaymentHelper.status.ACH_TRANSMITTED;
        //     update payment;
        //     payment.Payment_Status__c = SM_PaymentHelper.status.ACCEPTED;
        //     update payment;
        //     payment.Payment_Status__c = SM_PaymentHelper.status.REJECTED;
        //     update payment;
        // Test.stopTest();
    }
}