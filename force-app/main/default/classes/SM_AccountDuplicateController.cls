/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 02-22-2021
 * @last modified by  : Camilo J. Camilo Jimenez -> cjimenez@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   12-04-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
public with sharing class SM_AccountDuplicateController {
    
    private  SM_FieldsForAccountSearch__mdt[] fieldsForAccountSearch {
        get {
            if(fieldsForAccountSearch == null){
                fieldsForAccountSearch = [SELECT SM_Lead_field__c, SM_Account_field__c FROM SM_FieldsForAccountSearch__mdt];
            }
            return fieldsForAccountSearch;
        }

        set { return; }
    }

    private static SM_NotificationHelper.Notification[] notifications;

    private Map<String, Set<String>> keysByLead;//Map of keys to search accounts by Lead
    
    /**
    * @description This method, search and return accounts by Leads
    * @author diego.jacanamijoy@gmail.com | 12-04-2020 
    * @param leads 
    * @return Map<Lead, List<Account>>
    **/
    public Map<Lead, Set<Account>> getDuplicatesAccountsByLead(Lead[] leads){
        boolean executeQuery = false;//Indicate if is execute the query
        String query = 'SELECT {0}, Id, (SELECT Name, StageName, SM_Contract_Stage__c,Account.Name,Account.SM_Customer_Number__pc,RecordType.DeveloperName, RecordType.Name, Owner.Profile.Name, OwnerId FROM Opportunities) FROM Account WHERE ( ';
        //Call method prepareLeadData
        Map<String, Set<String>> valuesByField = prepareLeadData(leads);
        //Call method to get required fields
        getRequiredFieldsByDestination(leads, valuesByField);
        // JSPA 12-06-2020 - Add account fields to query
        query = String.format(query, new List<String>{String.join(new List<String>(valuesByField.keySet()), ',')});
        //Iterate result map
        for(String accountField: valuesByField.keySet()){
            if(!valuesByField.get(accountField).isEmpty()){
                String valuesFormat = '\'';
                Set<String> values = valuesByField.get(accountField);
                valuesFormat += String.join(new List<String>(values), '\',\'');
                valuesFormat += '\'';
                executeQuery = true;
                query += accountField + ' IN ( ' + valuesFormat + ' ) OR ';
            }
        }
        // JSPA - 12-06-2020
        query = query.removeEnd(' OR ');
        query += ' )';
        //If don´t exist fields to search, return null
        if(!executeQuery){
            return new Map<Lead, Set<Account>>();
        }
        //Call method createAccountsByFieldvalue
        System.debug('Query -> ' + query);
        Map<String, List<Account>> accountsByFieldValue = createAccountsByFieldvalue(Database.query(query));
        //Call method validateAccountRecords
        return validateAccountRecords(accountsByFieldValue, leads);
    }

    /**
    * @description This methos validate records for send notifications and create tracking records
    * from manually creation
    * @author diego.jacanamijoy@gmail.com | 12-15-2020 
    * @param accountsByLead 
    **/
    public void actionsForDuplicates(Map<Lead, Set<Account>> accountsByLead){
        //Call method to validate duplicate accounts
        validateAccountsByLead(accountsByLead);
        //call method to create trackin inbound
        SM_DuplicatesHelper.createTrakingInboundAccount(accountsByLead);
    }

    /**
    * @description This method create map of accounts by field name + field value
    * @author diego.jacanamijoy@gmail.com | 12-04-2020 
    * @param accounts 
    * @return Map<String, List<Account>> 
    **/
    public Map<String, List<Account>> createAccountsByFieldvalue(Account[] accounts){
        Map<String, List<Account>> accountsByFieldValue = new Map<String, List<Account>>();
        //Iterate SM_FieldsForAccountSearch__mdt records
        for(SM_FieldsForAccountSearch__mdt mtd: fieldsForAccountSearch){
            //Iterate account records
            for(Account account: accounts){
                if(account.get(mtd.SM_Account_field__c) <> null){
                    //Build key aux
                    String keyAux = mtd.SM_Account_field__c + '-' + account.get(mtd.SM_Account_field__c);
                    if(accountsByFieldValue.containsKey(keyAux)){
                        accountsByFieldValue.get(keyAux).add(account);    
                    }else{
                        accountsByFieldValue.put(keyAux, new List<Account>{account});    
                    }
                }
            }
        }
        return accountsByFieldValue;
    }

    /**
    * @description This method create map of values by field name, and map of keys field name + field value by lead
    * @author diego.jacanamijoy@gmail.com | 12-04-2020 
    * @param leads 
    * @return Map<String, Set<String>> 
    **/
    public Map<String, Set<String>> prepareLeadData(Lead[] leads){
        keysByLead = new Map<String, Set<String>>();
        Map<String, Set<String>> valuesByField = new Map<String, Set<String>>();
        //Iterate fields from SM_FieldsForAccountSearch__mdt
        for(SM_FieldsForAccountSearch__mdt mtd: fieldsForAccountSearch){
            //validate if Leads contains data in fields
            valuesByField.put(mtd.SM_Account_field__c, new Set<String>());
            for(Lead lead: leads){
                if(lead.get(mtd.SM_Lead_field__c) <> null){
                    valuesByField.get(mtd.SM_Account_field__c).add((String)lead.get(mtd.SM_Lead_field__c));
                    //Set values in map ok keys
                    String keyAux = mtd.SM_Account_field__c + '-' + lead.get(mtd.SM_Lead_field__c);
                    if(keysByLead.containsKey(lead.Id)){
                        keysByLead.get(lead.Id).add(keyAux);
                    }else{
                        keysByLead.put(lead.Id, new Set<String>{keyAux});
                    }
                }
            }
        }  
        return valuesByField;
    }

    /**
    * @description This method add required fields to map
    * @author diego.jacanamijoy@gmail.com | 12-07-2020 
    * @param leads 
    * @param valuesByField 
    **/
    public void getRequiredFieldsByDestination(Lead[] leads, Map<String, Set<String>> valuesByField){
        Set<String> requiredFields = new Set<String>();
        Map<String, SM_Company_setting__c> companySettingsByName = SM_CompanySettingHelper.getMapCompanysSettingsByNames();
        //Iterate leads
        for(Lead lead: leads){
            requiredFields.addAll(companySettingsByName.get(lead.SM_Destination_business_unit__c).SM_Required_fields__c.split(';'));
        }
        //validate required fields by add to map
        for(String field: requiredFields){
            //Add exception to email field, because there names are diferents
            if(!valuesByField.containsKey(field) &&  SM_Utils.validateIfExistFieldBySObject('Account', field)){
                valuesByField.put(field, new Set<String>());
            }
        }
    }

    /**
    * @description This method validate and create map of accounts by lead
    * @author diego.jacanamijoy@gmail.com | 12-04-2020 
    * @param accountsByFieldValue 
    * @param leads 
    * @return Map<Lead, Set<Account>> 
    **/
    public Map<Lead, Set<Account>> validateAccountRecords(Map<String, List<Account>> accountsByFieldValue, Lead[] leads){
        System.debug('keysByLead: ' + keysByLead);
        Map<Lead, Set<Account>> accountsByLead = new Map<lead, Set<Account>>(); 
        //Iterate Leads
        for(Lead lead: leads){
            if(keysByLead.containsKey(lead.Id)){
                accountsByLead.put(lead, new Set<Account>());
                for(String key: keysByLead.get(lead.Id)){
                    if(accountsByFieldValue.containsKey(key)){
                        accountsByLead.get(Lead).addAll(accountsByFieldValue.get(key));
                    }
                }
            }
        }
        
        return accountsByLead;
    }

    /**
    * @description this method return opp by duplicate account
    * @author diego.jacanamijoy@gmail.com | 12-11-2020 
    * @param opportuniies 
    * @param lead 
    * @param account 
    * @return String 
    **/
    public String getOpportunityByDuplicateAccount(Opportunity[] opportuniies, Lead lead, Account account){
        notifications = new List<SM_NotificationHelper.Notification>();
        Opportunity opp = validateOpportunitiesByAccount(opportuniies, lead, account);
        if(opp.Id <> null){
            return opp.Id;
        }
        Database.insert(opp);
        //validate send notifications
        if(!notifications.isEmpty()){
            //Create instance of SM_NotificationHelper
            SM_NotificationHelper notificationhelper = new SM_NotificationHelper(notifications);
            notificationhelper.sendNotification();
        }
        return opp.Id;
    }

    /**
    * @description this methid validate opp by accounts
    * @author diego.jacanamijoy@gmail.com | 12-11-2020 
    * @param opportuniies 
    * @param lead 
    * @param account 
    * @return Opportunity 
    **/
    public Opportunity validateOpportunitiesByAccount(Opportunity[] opportuniies, Lead lead, Account account){
        Opportunity oppResult;
        Boolean createOpp = true;
        List<String> statusDonTCreateOpp = new List<String>{SM_OpportunityHelper.stageName.closedWon, SM_OpportunityHelper.stageName.closedLost,SM_OpportunityHelper.stageName.paymentProcess};
        /* The opportunity must by created in the next terms
        * 1 No opportunity found with RecordType.Name == lead.SM_Destination_business_unit__c
        * 2 The opportunity found, have stagename == closedLost
        * 3 The opportunity found, have stagename == closedWon and contractStage == camcel */
        if(opportuniies <> null){
            for(Opportunity opp: opportuniies){
                if(!validateOpportunityData(opp, lead, statusDonTCreateOpp)){
                    createOpp = false;
                    if(!opp.Owner.Profile.Name.containsIgnoreCase('admin')){
                        notifications.add(SM_DuplicatesHelper.sendNotificationByDuplicateRecord(Label.DUPLICATE_LEAD_NOTIFICATION_TITLE, 
                                                                                                Label.DUPLICATE_LEAD_NOTIFICATION_BODY,
                                                                                                opp, 
                                                                                                lead));
                    }
                    oppResult = opp;
                    break;
                }
            }
        }
          // Cjimenez 21-02-2021 SFDCMP-175
        if(createOpp){
            oppResult = createOpportunities(lead, account);
        }
        return oppResult;    
    }

    /**
    * @description This method validate account duplicate by Lead
    * @author diego.jacanamijoy@gmail.com | 12-09-2020 
    * @param accountsByLead 
    * @return String 
    **/
    public void validateAccountsByLead(Map<Lead, Set<Account>> accountsByLead){
        //Validate size of duplicates, if size == 1 send notification
        notifications = new List<SM_NotificationHelper.Notification>();
        List<Opportunity> opportunitiesToCreate = new List<Opportunity>();
        for(Lead lead: accountsByLead.keySet()){
            if(accountsByLead.get(lead).size() == 1 || (!lead.SM_ManuallyCreated__c && accountsByLead.get(lead).size() > 0)){
                Account acc = new List<Account>(accountsByLead.get(lead))[0];
                Opportunity oppAux = validateOpportunitiesByAccount(acc.Opportunities, lead, acc);
                if(oppAux.Id == null){
                    opportunitiesToCreate.add(oppAux);
                }
            }
        }
        //Insert opportunities
        if(!opportunitiesToCreate.isEmpty()){
            Database.insert(opportunitiesToCreate, true);
        }
        //validate send notifications
        if(!notifications.isEmpty()){
            //Create instance of SM_NotificationHelper
            SM_NotificationHelper notificationhelper = new SM_NotificationHelper(notifications);
            notificationhelper.sendNotification();
        }
    }

    /**
    * @description This method validate data from opportunity
    * @author diego.jacanamijoy@gmail.com | 12-09-2020 
    * @param opportunity 
    * @param lead 
    * @param statusDonTCreateOpp 
    * @return Boolean 
    **/
    public Boolean validateOpportunityData(Opportunity opportunity, Lead lead, List<String> statusDonTCreateOpp){
        if(opportunity.RecordType.Name == lead.SM_Destination_business_unit__c){
            if(!statusDonTCreateOpp.contains(opportunity.StageName))
                return false;
            
        }
        return true;
    }

    /**
    * @description This method create instance of Opportunity object
    * @author diego.jacanamijoy@gmail.com | 12-09-2020 
    * @param lead 
    * @param account 
    * @return Opportunity 
    **/
    public Opportunity createOpportunities(Lead lead, Account account){
        return new Opportunity(
            RecordTypeId = SM_Utils.getRecordTypeIdByDeveloperName('Opportunity', lead.SM_Destination_business_unit__c),
            SM_Call_Inbound__c = true,
            AccountId = account.Id,
            Name = 'New Opportunity',
            CloseDate = System.today().addMonths(1),
            StageName = SM_OpportunityHelper.stageName.newSage,
            SM_Company_Setting__c = lead.SM_Company_Setting__c
        );
    }
}