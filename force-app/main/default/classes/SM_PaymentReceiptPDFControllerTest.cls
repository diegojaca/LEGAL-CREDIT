/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * @group             :
 * @last modified on  : 06-09-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                Modification
 * 1.0   06-09-2021   Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com   Initial Version
**/
@IsTest
public without sharing class SM_PaymentReceiptPDFControllerTest {

    @TestSetup
    static void makeData(){
        Account account = SM_TestSmartDataFactory.getPersonAccount();
        account.PersonEmail='legal_credit@gmail.com.invalid';
        insert account;
        ChargentBase__Gateway__c Gt = SM_TestSmartDataFactory.getGateway();
        insert Gt;
        SM_Company_setting__c companySettingObj = SM_TestSmartDataFactory.getCompanySettingPMethod(Gt.Id);
        insert companySettingObj;
        APXTConga4__Conga_Solution__c conga4CongaSolutionObj = SM_TestSmartDataFactory.getConga4CongaSolutionObj();
        insert conga4CongaSolutionObj;
        Process_automation_by_product_family__c processautomationProductfamilyObj = SM_TestSmartDataFactory.getProcessautomationProductfamily(companySettingObj.id,conga4CongaSolutionObj.id);
        processautomationProductfamilyObj.SM_Generates_dispute__c = true;
        insert processautomationProductfamilyObj;
        Contract contract = SM_TestSmartDataFactory.getContract(account.Id,processautomationProductfamilyObj.id);
        // contract.SM_Generates_dispute__c = true;
        // contract.SM_Opportunity__c = opp.Id;
        insert contract;
        SM_Payment__c payment  = SM_TestSmartDataFactory.getPayment(contract.Id);
        insert payment;
    }

    @IsTest
    static void testPaymentReceiptPDF(){
        SM_Payment__c payment = [SELECT Id FROM SM_Payment__c LIMIT 1];
        Test.startTest();
            PageReference paymentReceiptPDF = Page.SM_PaymentReceiptPDF;
            Test.setCurrentPage(paymentReceiptPDF);
            paymentReceiptPDF.getParameters().put('id', String.valueOf(payment.Id));
            SM_PaymentReceiptPDFController controller = new SM_PaymentReceiptPDFController();
        Test.stopTest();
    }
}