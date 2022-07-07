/**
 * @description       : Test class of SM_ErrorDescription_Helper
 * @author            : Manuel Mendez
 * @group             : 
 * @last modified on  : 09/10/2021
 * @last modified by  : mmendez@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                     Modification
 * 1.0   09/10/2021   Manuel Mendez              Initial Version
**/
@IsTest
public with sharing class SM_ErrorDescription_HelperTest {

    @IsTest
    static void createTestErrorDescription(){
        insert new SM_Bypasser__c(SM_Disable_Validation_Rules__c = false, SetupOwnerId = UserInfo.getProfileId());
        insert new SM_SetupToken__c (SM_Active__c = true ,SM_ExpirationDate__c=System.now(), SM_DurationMinutes__c = 15 , Name ='Token Native');
        Account account = SM_TestSmartDataFactory.getPersonAccount();
        account.PersonEmail='legal_credit@gmail.com.invalid';
        insert account;
        ChargentBase__Gateway__c Gt = SM_TestSmartDataFactory.getGateway();
        insert Gt;
        SM_Company_setting__c companySettingObj = SM_TestSmartDataFactory.getCompanySettingPMethod(Gt.Id);
        insert companySettingObj;
        List<SM_Required_Field_Info__c> requiredFields = SM_TestSmartDataFactory.getRequiredFields(companySettingObj.Id);
        insert requiredFields;
        echosign_dev1__SIGN_Agreement__c agreementObj = SM_TestSmartDataFactory.getAgreement();
        insert agreementObj;
        Attachment attachmentObj = SM_TestSmartDataFactory.getAttachment(agreementObj.id);
        insert attachmentObj;
        system.debug('attachmentObj-->'+attachmentObj.id);
        APXTConga4__Conga_Solution__c conga4CongaSolutionObj = SM_TestSmartDataFactory.getConga4CongaSolutionObj();
        insert conga4CongaSolutionObj;
        Process_automation_by_product_family__c processautomationProductfamilyObj = SM_TestSmartDataFactory.getProcessautomationProductfamily(companySettingObj.id,conga4CongaSolutionObj.id);
        processautomationProductfamilyObj.SM_Generates_dispute__c = true;
        insert processautomationProductfamilyObj;
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        opp.AccountId = account.Id;
        opp.SM_Company_Setting__c = companySettingObj.Id;
        insert opp;
        Contract contract = SM_TestSmartDataFactory.getContract(account.Id,processautomationProductfamilyObj.id);
        contract.SM_Generates_dispute__c = true;
        contract.SM_Opportunity__c = opp.Id;
        contract.SM_Email_to_send_contract__c = 'test@yopmail.com';
        insert contract;
        Asset objAsset = SM_TestSmartDataFactory.getAsset(account.Id,contract.Id);
        agreementObj.echosign_dev1__Contract__c = contract.Id;
        insert objAsset;
        update agreementObj;
        ChargentOrders__ChargentOrder__c cO = SM_TestSmartDataFactory.getChargentorder(Account.Id,contract,companySettingObj,'AC');
        co.ChargentOrders__Status__c = 'Initiated';
        co.ChargentOrders__Payment_Status__c = 'Recurring';
        co.ChargentOrders__Card_Type__c = 'Discover';
        co.ChargentOrders__Card_Month_Indicator__c = '01';
        co.ChargentOrders__Card_Last_4__c = '9999';
        co.ChargentOrders__Card_Year_Indicator__c = '2050';
        co.ChargentOrders__Billing_First_Name__c = 'John';
        co.ChargentOrders__Tokenization__c = '998877';
        co.Contract__c = contract.Id;
        co.ChargentOrders__Payment_Start_Date__c = System.today();
        insert cO;
        SM_GatewayErrors__c GtEr100 = SM_TestSmartDataFactory.getGatewayError100(Gt.Id);
        insert GtEr100;
        SM_GatewayErrors__c GtEr101 = SM_TestSmartDataFactory.getGatewayError101(Gt.Id);
        insert GtEr101;

        ChargentOrders__Transaction__c ctr = new ChargentOrders__Transaction__c(
            ChargentOrders__Type__c='Authorization',
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Tokenization__c ='091-29382-298292829229',
            ChargentOrders__Order__c = cO.Id,
            ChargentOrders__Reason_Code__c = 100,
            Contract__c = cO.Contract__C,
            ChargentOrders__Gateway__c =Gt.Id
        );
        Test.startTest();
            insert ctr;
        Test.stopTest();
    }

}