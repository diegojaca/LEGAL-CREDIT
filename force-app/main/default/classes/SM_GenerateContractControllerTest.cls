/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 19/07/2022
 * @last modified by  : Diego Jacanamijoy -> djacanamijoy@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   02-05-2021   diego.jacanamijoy@gmail.com   Initial Version
**/
@IsTest
public with sharing class SM_GenerateContractControllerTest {
    
    @TestSetup
    static void makeData(){

        insert new SM_SetupToken__c (SM_Active__c = true ,SM_ExpirationDate__c=System.now(), SM_DurationMinutes__c = 15 , Name ='Token Native');
        insert SM_TestSmartDataFactory.getProccessAutomation();
        Account acc = SM_TestSmartDataFactory.getPersonAccount();
        insert acc;

        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        opp.AccountId = acc.Id;
        insert opp;

        //master
        OpportunityLineItem oppLitMaster = SM_TestSmartDataFactory.getOpportunityLineItem();
        oppLitMaster.OpportunityId = opp.Id;
        oppLitMaster.TotalPrice = 1200;
        oppLitMaster.Product_Type__c = SM_OpportunityHelper.contractType.MASTER;
        oppLitMaster.Is_master__c = true;
        insert oppLitMaster;

        Process_automation_by_product_family__c paf = new Process_automation_by_product_family__c();
        paf.Name = 'Depend proccess';
        paf.SM_Type_of_contract__c = 'Legal Credit Solution';
        paf.SM_Generates_dispute__c = true;
        paf.Contract_activation_form__c = 'Future activation with conditions';
        paf.Start_assets_in_fee_number__c = 10;
        insert paf;

        Product2 p2Depend = SM_TestSmartDataFactory.getProduct2().clone(false, false, false, false);
        p2Depend.Name = 'Dependent Laptop X200';
        p2Depend.Family = 'Dependent Hardware';
        p2Depend.Process_automation_by_product_family__c = paf.Id;
        insert p2Depend;

        PricebookEntry pbe = SM_TestSmartDataFactory.getPricebookEntry().clone();
        pbe.Product2Id = p2Depend.Id;
        insert pbe;

        //Dependent 1
        OpportunityLineItem oppLitDependet1 = oppLitMaster.clone(false, false, false, false);
        oppLitDependet1.Product_Type__c = SM_OpportunityHelper.contractType.DEPENDENT;
        oppLitDependet1.Is_master__c = false;
        oppLitDependet1.Product2Id = p2Depend.Id; 
        oppLitDependet1.PricebookEntryId = pbe.Id;
        oppLitDependet1.Principal_Opportunity_Product__c = oppLitMaster.Id;
        insert oppLitDependet1;

        //Dependent 2
        OpportunityLineItem oppLitDependet2 = oppLitMaster.clone(false, false, false, false);
        oppLitDependet2.Product_Type__c = SM_OpportunityHelper.contractType.DEPENDENT;
        oppLitDependet2.Is_master__c = false;
        oppLitDependet2.Product2Id = p2Depend.Id;
        oppLitDependet2.PricebookEntryId = pbe.Id;
        oppLitDependet2.Principal_Opportunity_Product__c = oppLitMaster.Id;
        insert oppLitDependet2;

        ContactPointAddress cpa = SM_TestSmartDataFactory.getContactPointAddress('','','','','',SM_ContactPointAddressHelper.type.POSTAL_ADDRESS);
        cpa.ParentId = acc.Id;
        insert new List<ContactPointAddress>{cpa};

    }

    @IsTest
    static void generateContractsOk(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
            SM_GenerateContractController geerateContract = new SM_GenerateContractController(new List<String>{opp.Id});
            Contract[] contracts = [SELECT SM_Generates_dispute__c, SM_Requires_AC_Payment__c, SM_Total_ac__c, SM_Postal_address__c FROM Contract];
            System.assertEquals(2, contracts.size(), 'Must return 2 contract record');
            System.assertEquals(true, contracts[0].SM_Generates_dispute__c, 'Must return true dispute');
            System.assertEquals(true, contracts[0].SM_Requires_AC_Payment__c, 'Must return true Ac required');
            //System.assertEquals(40000, contract.SM_Total_ac__c, 'Must return 40000');
            System.assertNotEquals(null, contracts[0].SM_Postal_address__c, 'Must be not null');
            //Check related contract
            System.assertEquals(1, [SELECT Count() FROM Contract WHERE Contract_type__c =: SM_ContractHelper.contractType.MASTER], 'Must be return one record');
            //Get master
            Contract master = [SELECT Id FROM Contract WHERE Contract_type__c =: SM_ContractHelper.contractType.MASTER];
            Contract dependent = [SELECT Contract_activation_form__c, Start_assets_in_fee_number__c
                                        , SM_Process_automation_by_product_family__r.Contract_activation_form__c, SM_Process_automation_by_product_family__r.Start_assets_in_fee_number__c
                                    FROM Contract WHERE Contract_type__c =: SM_ContractHelper.contractType.DEPENDENT];

            System.assertEquals(dependent.SM_Process_automation_by_product_family__r.Contract_activation_form__c, dependent.Contract_activation_form__c, 'Must be return the same value');
            System.assertEquals(dependent.SM_Process_automation_by_product_family__r.Start_assets_in_fee_number__c, dependent.Start_assets_in_fee_number__c, 'Must be return the same value');

            System.assertEquals(1, [SELECT Count() FROM Contract WHERE Contract_type__c =: SM_ContractHelper.contractType.DEPENDENT AND Principal_Contract__c =: master.Id], 'Must be return one dependent contract');
            Asset[] dependentAssets = [SELECT Contract_activation_form__c, Start_assets_in_fee_number__c FROM Asset WHERE Principal_Contract__c =: master.Id];
            System.assertEquals(2, dependentAssets.size(), 'Must be return two dependent asset');
            System.assertEquals(dependent.Contract_activation_form__c, dependentAssets[0].Contract_activation_form__c, 'Must be return two dependent asset');
            System.assertEquals(dependent.Start_assets_in_fee_number__c, dependentAssets[0].Start_assets_in_fee_number__c, 'Must be return two dependent asset');
        Test.stopTest();
    }
}