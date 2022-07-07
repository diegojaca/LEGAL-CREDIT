/**
 * @description       : Helper class of SM_Company_setting__c object
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 01-14-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                     Modification
 * 1.0   11-11-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
public with sharing class SM_CompanySettingHelper {

    public  static Map<String, SM_Company_setting__c> companySettingsByName {
        get {
            if(companySettingsByName == null){
                companySettingsByName = getMapCompanysSettingsByNames();
            }
            return companySettingsByName;
        }

        set { return; }
    }

   /**
    * @description This method return company setting by name
    * @author diego.jacanamijoy@gmail.com | 11-11-2020 
    * @param companyName 
    * @return SM_Company_setting__c 
    **/
    public static SM_Company_setting__c getCompanySettingByName(string companyName){
        return [SELECT  SM_Required_fields__c, SM_Fields_to_validate_duplicates__c, SM_Fields_to_validate_duplicates2__c
                FROM SM_Company_setting__c
                WHERE Name =: companyName LIMIT 1];
    }

    /**
    * @description This method return all companys settings
    * @author diego.jacanamijoy@gmail.com | 11-19-2020 
    * @param companyNames 
    * @return SM_Company_setting__c[] 
    **/
    public static SM_Company_setting__c[] getAllCompanysSettings(){
        return [SELECT  Name, SM_Required_fields__c, SM_Fields_to_validate_duplicates__c, SM_Fields_to_validate_duplicates2__c
                FROM SM_Company_setting__c ];
    }

    /**
    * @description This methos return map of companysettings by name
    * @author diego.jacanamijoy@gmail.com | 11-23-2020 
    * @return SM_Company_setting__c[] 
    **/
    public static Map<String, SM_Company_setting__c> getMapCompanysSettingsByNames(){
        Map<String, SM_Company_setting__c> companySettingsByName = new Map<String, SM_Company_setting__c>();
        for(SM_Company_setting__c companySetting: [SELECT  Name, SM_Required_fields__c, SM_Fields_to_validate_duplicates__c, SM_Fields_to_validate_duplicates2__c
                                                    FROM SM_Company_setting__c]){
            //Iterate for create map
            companySettingsByName.put(companySetting.Name, companySetting);                                            
        }
        return companySettingsByName;
    }
}