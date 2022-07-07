/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 01-04-2021
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                     Modification
 * 1.0   11-11-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
public without sharing class SM_searchLeadLWCController {
    
    /**
    * @description This method return required fields by company
    * @author diego.jacanamijoy@gmail.com | 11-11-2020 
    * @param  
    * @return SM_Company_setting__c[]
    **/
    @AuraEnabled(cacheable=true)
    public static SM_Company_setting__c[] getAllCompanysSettings(){
        SM_Company_setting__c[] companySettings;
        try {
            companySettings = SM_CompanySettingHelper.getAllCompanysSettings();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return companySettings;
    }

    /**
    * @description This method validate if new lead have duplicates
    * @author diego.jacanamijoy@gmail.com | 12-09-2020 
    * @param leadId
    * @param companyName 
    * @return DuplicateWraper 
    **/
    @AuraEnabled(cacheable=false)
    public static DuplicateWraper validateDuplicates(String leadId, String companyName){
        DuplicateWraper duplicateWraper = new DuplicateWraper();//Instance of wraper to return
        duplicateWraper.hasDuplicates = false;//Init hasDuplicates = false
        try {
            //Get instance of SM_Company_setting__c by Name
            SM_Company_setting__c companySetting = SM_CompanySettingHelper.getCompanySettingByName(companyName);
            //Query data from Lead by Id
            Lead newLead = SM_LeadHelper.getLeadWithRequiredFieldsById(leadId, companySetting);
            //Call method to search duplicates by Lead
            SM_LeadHandler.searchDuplicates(new List<Lead>{newLead}, true);
            //validate if exist accounts duplicates, or leads duplicates
            if(SM_LeadHandler.accountsDuplicatesByLead.containsKey(newLead) && SM_LeadHandler.accountsDuplicatesByLead.get(newLead).size() > 0){
                duplicateWraper.hasDuplicates = true;
                duplicateWraper.sObjectName = 'Account';
                duplicateWraper.duplicates = new List<Account>(SM_LeadHandler.accountsDuplicatesByLead.get(newLead));
            }else if(SM_LeadHandler.leadsDuplicatesByLead.containsKey(newLead) && SM_LeadHandler.leadsDuplicatesByLead.get(newLead).size() > 0){
                duplicateWraper.hasDuplicates = true;
                duplicateWraper.sObjectName = 'Lead';
                duplicateWraper.duplicates = SM_LeadHandler.leadsDuplicatesByLead.get(newLead);
            }else{
                //If not exist duplicates, create tracking record
                SM_DuplicatesHelper.createTrakingInboundLeads(new Map<Lead, Lead[]>{ newLead => new List<Lead>()});
            }    
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return duplicateWraper;
    }

    /**
    * @description This method create trackin, when click in cancel button
    * @author diego.jacanamijoy@gmail.com | 01-04-2021 
    * @param leadId 
    * @param companyName 
    **/
    @AuraEnabled(cacheable=false)
    public static void createTrackingInbound(String leadId, String companyName){
        try {
            //Get instance of SM_Company_setting__c by Name
            SM_Company_setting__c companySetting = SM_CompanySettingHelper.getCompanySettingByName(companyName);
            //Query data from Lead by Id
            Lead newLead = SM_LeadHelper.getLeadWithRequiredFieldsById(leadId, companySetting);
            SM_DuplicatesHelper.createTrakingInboundLeads(new Map<Lead, Lead[]>{ newLead => new List<Lead>()});
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description This method unify leads
    * @author diego.jacanamijoy@gmail.com | 12-09-2020 
    * @param lead 
    * @param duplicate 
    * @return string 
    **/
    @AuraEnabled
    public static string unifyLeads(String newLeadId, Lead duplicate, String companyName){
        Lead lead;
        try {
            lead = getLeadData(newLeadId, companyName);
            SM_DuplicatesHelper.createTrakingInboundLeads(new Map<Lead, Lead[]>{ lead => new List<Lead>{(Lead) duplicate} });
            finallyActions(lead, duplicate);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return duplicate.Id;
    }

    /**
    * @description This method unify lead with account
    * @author diego.jacanamijoy@gmail.com | 12-09-2020 
    * @param lead 
    * @param duplicate 
    * @return string 
    **/
    @AuraEnabled
    public static string unifyAccountWithLead(String newLeadId, Account duplicate, Opportunity[] opportunities, String companyName){
        String opportunityId;
        Lead lead;
        try {
            lead = getLeadData(newLeadId, companyName);
            SM_AccountDuplicateController accountDuplicateController = new SM_AccountDuplicateController();
            opportunityId = accountDuplicateController.getOpportunityByDuplicateAccount(opportunities, lead, duplicate);
            SM_DuplicatesHelper.createTrakingInboundAccount(new Map<Lead, Set<Account>>{ lead => new Set<Account>{(Account) duplicate}});
            finallyActions(lead, duplicate);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return opportunityId;
    }

    /**
    * @description return lead data
    * @author diego.jacanamijoy@gmail.com | 12-11-2020 
    * @param newLeadId 
    * @param companyName 
    * @return Lead 
    **/
    public static Lead getLeadData(String newLeadId, String companyName){
        //Get instance of SM_Company_setting__c by Name
        SM_Company_setting__c companySetting = SM_CompanySettingHelper.getCompanySettingByName(companyName);
        return SM_LeadHelper.getLeadWithRequiredFieldsById(newLeadId, companySetting);
    }

    /**
    * @description 
    * @author diego.jacanamijoy@gmail.com | 12-11-2020 
    * @param lead 
    * @param duplicate 
    **/
    public static void finallyActions(Lead lead, SObject duplicate){
        //Update old data
        SM_LeadHelper.updateOldRecord(lead, duplicate);
        //Delete new lead
        Database.delete(lead);
        Database.update(duplicate);
    }

    /** Wraper to manage duplicates return */
    public class DuplicateWraper{
        @AuraEnabled public SObject[] duplicates;
        @AuraEnabled public String sObjectName;
        @AuraEnabled public Boolean hasDuplicates;
    }
    
}