/**
 * @description       : Helper class of Lead object
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 06-10-2022
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-17-2020   diego.jacanamijoy@gmail.com   Initial Version
 * 1.1   09-06-2022   jpachon.ariza@gmail.com       SMPII-152
**/
@SuppressWarnings('PMD.VariableNamingConventions')
public with sharing class SM_LeadHelper {
    
    //Instances of enums
    public static LeadStatusEnum leadStatusEnum = new LeadStatusEnum();
    public static DispositionEnum dispositionEnum = new DispositionEnum();
    
    /** This class represents Enum to attribute LeadStatus (Developer name) */
    public class LeadStatusEnum {
        public String UNQUALIFIED = 'Unqualified';
        public String NEW_STATUS = 'New';
        public String CONVERTED = 'Converted';
        public String FOLLOW_UP = 'Follow up';
        public String NO_INTERESTING = 'No interesting';
        public String NO_CONTACT = 'No Contact';
        public String NOT_ORIENTED = 'Not Oriented';        
    }

    public class DispositionEnum {
        public String BUSY = 'Busy';
        public String CALL_BACK = 'Call Back';
    }

    /* Queries */

    /**
    * @description 
    * @author diego.jacanamijoy@gmail.com | 11-17-2020 
    * @param leadId 
    * @return Lead 
    **/
    public static Lead getLeadById(String leadId){
        Lead lead;
        try {
            lead = [SELECT Address, City__c, SM_Campaign_id__c, SM_Company_Setting__c, SM_Company_Setting__r.SM_Lead_Stage__c, OwnerId,
                            SM_ChannelAcceptanceTerms_and_conditions__c, SM_Destination_business_unit__c, Status 
                    FROM Lead 
                    WHERE Id =: leadId 
                    LIMIT 1
                    ];
        } catch (QueryException e) {
            lead = null;
        }
        return lead;
    }

    /**
    * @description return leads by dinamic SOQL
    * @author diego.jacanamijoy@gmail.com | 11-20-2020 
    * @param query 
    * @return Lead[] 
    **/
    public static Lead[] getLeasByDinamicQuery(String query){
        Lead[] leads;
        try{
            leads = Database.query(query);
        }catch(QueryException e){
            leads = new List<Lead>();
        }
        return leads;
    }

    /**
    * @description This method update old duplicate record
    * @author diego.jacanamijoy@gmail.com | 12-07-2020 
    * @param newLead 
    * @param oldRecord 
    **/
    public static SObject updateOldRecord(Lead newLead, SObject oldRecord){
        String sObjectName = SM_Utils.getSObjectNameById(oldRecord.Id);
        SM_Company_setting__c companySetting = SM_CompanySettingHelper.companySettingsByName.get(newLead.SM_Destination_business_unit__c);
        List<String> requiredfields = companySetting.SM_Required_fields__c.split(';');
        for(String requiredField: companySetting.SM_Required_fields__c.split(';')){
            //Add exception to email field, because there names are diferents
            String auxField = sObjectName == 'Account' && requiredField == 'Email' ? 'PersonEmail' : requiredField;
            Boolean fieldvalid = sObjectName == 'Account' ? SM_Utils.validateIfExistFieldBySObject('Account', auxField) : true;
            if(fieldvalid && oldRecord.get(auxField) == null && newLead.get(requiredField) <> null){
                oldRecord.put(auxField, newLead.get(requiredField));
            }
        }
        return oldRecord;
    }

    /**
    * @description This method update old data with fields mapping
    * @author diego.jacanamijoy@gmail.com | 01-26-2021 
    * @param newRecord 
    * @param oldRecord 
    * @param oldFieldBynewField 
    * @return SObject 
    **/
    public static SObject updateOldRecord(SObject newRecord, SObject oldRecord, Map<String, String> oldFieldBynewField){
        //Iterate map of fields
        for(String newField: oldFieldBynewField.keySet()){
            Object oldFieldValue = oldRecord.get(oldFieldBynewField.get(newField));
            if(newRecord.get(newField) != null && ( oldFieldValue == null || oldFieldValue == '' || oldFieldValue == false)){
                oldRecord.put(oldFieldBynewField.get(newField), newRecord.get(newField));
            }
        }
        return oldRecord;
    }

    /**
    * @description This method return lead with required fields by Id
    * @author diego.jacanamijoy@gmail.com | 12-09-2020 
    * @param leadId 
    * @param companySetting 
    * @return Lead 
    **/
    public static Lead getLeadWithRequiredFieldsById(String leadId, SM_Company_setting__c companySetting){
        // SMPII-152
        Set<String> fieldsToQuery = new Set<String>{'Name', 'Owner.Profile.Name', 'Status', 'SM_Destination_business_unit__c', 'SM_key_for_duplicates__c', 
                                                    'SM_key_for_duplicates_2__c', 'SM_ManuallyCreated__c', 'LeadSource', 'Email', 'Phone', 'SM_Company_Setting__c', 'Company'};

        String query = 'SELECT {0} FROM Lead WHERE Id =: leadId LIMIT 1';

        if(companySetting.SM_Required_fields__c <> null){
            fieldsToQuery.addAll(companySetting.SM_Required_fields__c.split(';'));
        }
        if(companySetting.SM_Fields_to_validate_duplicates__c <> null){
            fieldsToQuery.addAll(companySetting.SM_Fields_to_validate_duplicates__c.split(';'));
        }
        if(companySetting.SM_Fields_to_validate_duplicates2__c <> null){
            fieldsToQuery.addAll(companySetting.SM_Fields_to_validate_duplicates2__c.split(';'));
        }
        //Format query
        query = String.format(query, new List<String>{String.join(new List<String>(fieldsToQuery), ',')});
        System.debug('query-> ' + query);
        return Database.query(query);
    }

}