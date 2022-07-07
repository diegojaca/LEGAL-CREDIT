/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 12-23-2020
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                     Modification
 * 1.0   11-11-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
@IsTest
public with sharing class SM_CompanySettingHelperTest {
    
    @TestSetup
    static void makeData(){
        insert SM_TestSmartDataFactory.getCompanySetting();
    }

    @IsTest
    static void getRequiredsFieldsByCompanyOk(){
        Test.startTest();
        SM_Company_setting__c companySetting = [SELECT Name FROM SM_Company_setting__c LIMIT 1];
            System.assertEquals(companySetting.Id, SM_CompanySettingHelper.getCompanySettingByName(companySetting.Name).Id, 'should return a record');
        Test.stopTest();
    }
    
    @IsTest
    static void getAllCompanysSettingsOk(){
        Test.startTest();
            System.assertEquals(1, SM_CompanySettingHelper.getAllCompanysSettings().size(), 'A record was expected');
        Test.stopTest();
    }

    @IsTest
    static void companySettingsByNameOk(){
        Test.startTest();
        Map<String, SM_Company_setting__c> companySettingsByName = SM_CompanySettingHelper.companySettingsByName;
            System.assertEquals(1, companySettingsByName.size(), 'A record was expected');
        Test.stopTest();
    }

    @IsTest
    static void getRequiredsFieldsByCompanyError(){
        Test.startTest();
            String companySettingName = 'Test';
            SM_Company_setting__c companySetting;
            try {
                companySetting = SM_CompanySettingHelper.getCompanySettingByName(companySettingName);
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
            System.assertEquals(null, companySetting, 'should not return a record');
        Test.stopTest();
    } 
    
}