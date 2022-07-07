/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 07-27-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-20-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
public with sharing class SM_LeadDuplicateController {
    
    private Lead[] leads;//Leads for compared
    private Map<String, Lead[]> leadsByDestination;//Map of Leads by destination bussiness
    private Set<String> destinations;//Destinations of new leads
    private Set<String> newLeadsIds;//Ids of new leads
    private Set<String> keysBySearchDuplicates1;//Set of keys to searchs duplicates
    private Set<String> keysBySearchDuplicates2;//Set of second keys to searchs duplicates
    private Set<String> requiredFieldsToQuery;//Required fields to quiery of Leads

    private  Map<String, SM_Company_setting__c> companySettingsByName {
        get {
            if(companySettingsByName == null){
                companySettingsByName = SM_CompanySettingHelper.getMapCompanysSettingsByNames();
            }
            return companySettingsByName;
        }

        set { return; }
    }

    /**
    * @description Constructor
    * @author diego.jacanamijoy@gmail.com | 11-20-2020 
    * @param leads 
    **/
    public SM_LeadDuplicateController(Lead[] leads) {
        this.leads = leads;
    }

    /**
    * @description  Main method
    * @author diego.jacanamijoy@gmail.com | 11-20-2020 
    * @return Map<Lead, Lead[]> 
    **/
    public Map<Lead, Lead[]> initProcessing(){
        Map<Lead, Lead[]> duplicatesByLead;
        try {
            //Call method to prepare data
            prepareData();
            //validate if have keys to search, else if return empty map
            if(keysBySearchDuplicates1.isEmpty() && keysBySearchDuplicates2.isEmpty()){
                return new Map<Lead, Lead[]>();
            }
            //Call method to query Leads to validate duplicates
            Lead[] resultLeads = getLeadsToCompare();
            //call method to build map of leads
            createLeadMapByDestination(resultLeads);
            //call method to validate duplicates
            duplicatesByLead = searchDuplicates();
            //Call method to create inbound record
            //if don´t manually created call method searchDuplicates from ashyncronous context
            Boolean manuallyCreated = this.leads[0].SM_ManuallyCreated__c;
            if(!manuallyCreated){
                SM_DuplicatesHelper.createTrakingInboundLeads(duplicatesByLead);
            }
        } catch (Exception e) {
            throw new SM_CustomException('An error occurred validating duplicate leads '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
        //return map of duplicates leads by new lead
        return duplicatesByLead;
    }

    /**
    * @description this method prepare data to proccess
    * @author diego.jacanamijoy@gmail.com | 11-23-2020 
    **/
    public void prepareData(){
        //Inicialized of variables
        destinations = new Set<String>();
        newLeadsIds = new Set<String>();
        keysBySearchDuplicates1 = new Set<String>();
        keysBySearchDuplicates2 = new Set<String>();
        requiredFieldsToQuery = new Set<String>();
        //Iterate new leads
        for(Lead lead: this.leads){
            //Validate if the Status of lead is New and have keys for search duplicates
            if(lead.Status == SM_LeadHelper.leadStatusEnum.NEW_STATUS && (String.isNotBlank(lead.SM_key_for_duplicates__c) || String.isNotBlank(lead.SM_key_for_duplicates_2__c))){
                destinations.add(lead.SM_Destination_business_unit__c);
                newLeadsIds.add(lead.Id);
                keysBySearchDuplicates1.add(lead.SM_key_for_duplicates__c);
                keysBySearchDuplicates2.add(lead.SM_key_for_duplicates_2__c);
                requiredFieldsToQuery.addAll(companySettingsByName.get(lead.SM_Destination_business_unit__c).SM_Required_fields__c.split(';'));
            }
        }
    }

    /**
    * @description Query leads to compare
    * @author diego.jacanamijoy@gmail.com | 11-20-2020 
    * @param 
    * @return Lead[] 
    **/
    public Lead[] getLeadsToCompare(){
        //Formated sets to strings
        String destinationsFormat = '\'';
        String idsFormat = '\'';
        String keysBySearchDuplicates1Format = '\'';
        String keysBySearchDuplicates2Format = '\'';
        destinationsFormat += String.join(new List<String>(destinations), '\',\'');
        destinationsFormat += '\'';
        idsFormat += String.join(new List<String>(newLeadsIds), '\',\'');
        idsFormat += '\'';
        //Build Strng to dinamic query
        String query = 'SELECT {0}, Name, Owner.Profile.Name, SM_Destination_business_unit__c, SM_key_for_duplicates__c, SM_key_for_duplicates_2__c FROM Lead ';
        //Format query
        query = String.format(query, new List<String>{String.join(new List<String>(requiredFieldsToQuery), ',')});
        query += 'WHERE SM_Destination_business_unit__c IN ( ' + destinationsFormat + ' ) ';
        query += 'AND Id NOT IN ( ' + idsFormat + ' ) ';
        //validate keys1 fields to query
        if(!keysBySearchDuplicates1.isEmpty()){
            keysBySearchDuplicates1Format += String.join(new List<String>(keysBySearchDuplicates1), '\',\'');
            keysBySearchDuplicates1Format += '\'';
            //Add clause to querry
            query += 'AND ( SM_key_for_duplicates__c IN ( ' + keysBySearchDuplicates1Format + ' ) ';
        }
        //validate keys2 fields to query
        if(!keysBySearchDuplicates2.isEmpty()){
            keysBySearchDuplicates2Format += String.join(new List<String>(keysBySearchDuplicates2), '\',\'');
            keysBySearchDuplicates2Format += '\'';
            //Add clause to querry
            if(!keysBySearchDuplicates1.isEmpty()){
                query += 'OR SM_key_for_duplicates_2__c IN ( ' + keysBySearchDuplicates2Format + ' ) )';
            }else {
                query += 'AND SM_key_for_duplicates_2__c IN ( ' + keysBySearchDuplicates2Format + ' ) ';
            }
        }else {
            query += ') ';
        }
        query += ' LIMIT 20000';
        //Execute method of SM_LeadHelper, for return Leads
        Lead[] resultLeads = SM_LeadHelper.getLeasByDinamicQuery(query);
        return resultLeads;
    }

    /**
    * @description Create map of Leads by destination bussiness
    * @author diego.jacanamijoy@gmail.com | 11-20-2020 
    * @param leads 
    **/
    public void createLeadMapByDestination(Lead[] leads){
        leadsByDestination = new Map<String, Lead[]>();
        //Iterate Leads to build map
        for(Lead lead: leads){
            if(!leadsByDestination.containsKey(lead.SM_Destination_business_unit__c)){
                leadsByDestination.put(lead.SM_Destination_business_unit__c, new List<lead>{lead});
            }else {
                leadsByDestination.get(lead.SM_Destination_business_unit__c).add(lead);
            }
        }
    }

    /**
    * @description this metdos compare news leads with stored leads, by fields configurated
    * @author diego.jacanamijoy@gmail.com | 11-20-2020 
    * @return Map<Lead, Lead[]> 
    **/
    public Map<Lead, Lead[]> searchDuplicates(){
        Map<Lead, Lead[]> duplicatesByLead = new Map<Lead, Lead[]>();
        //Iterate leads
        for(Lead lead: this.leads){
            //Init map of current lead
            duplicatesByLead.put(lead, new List<Lead>{});
            //Iterate leads to compare
            if(leadsByDestination.containsKey(lead.SM_Destination_business_unit__c)){
                for(Lead leadToCompare: leadsByDestination.get(lead.SM_Destination_business_unit__c)){
                    if((String.isNotBlank(lead.SM_key_for_duplicates__c) && lead.SM_key_for_duplicates__c == leadToCompare.SM_key_for_duplicates__c) ||
                        (String.isNotBlank(lead.SM_key_for_duplicates_2__c) && lead.SM_key_for_duplicates_2__c == leadToCompare.SM_key_for_duplicates_2__c)){
                        //Add lead to list of duplicates
                        duplicatesByLead.get(lead).add(leadToCompare);
                    }
                }
            }
        }
        return duplicatesByLead;
    }
}