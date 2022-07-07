/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 12-02-2020
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-17-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
public without sharing class SM_TakeRecordLWCController {
    
    private static String currentUsereId = UserInfo.getUserId();

    @AuraEnabled
    public static string changeRecordOwner(String recordId){
        try {
            validateDataBySObjectType(recordId);
            //Update owner
            sObject sObj = Schema.getGlobalDescribe().get(SM_Utils.getSObjectNameById(recordId)).newSObject() ;
            sObj.put('Id',recordId);
            sObj.put('OwnerId',currentUsereId);
            update sObj;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return 'OK';
    }

    public static void validateDataBySObjectType(String recordId){

        switch on SM_Utils.getSObjectNameById(recordId) {
            when  'Lead'{
                validateLeadData(recordId);
            }
            when 'Opportunity'{
                validateOpportunityData(recordId);
            }
            when else {
                throw new SM_CustomException('don´t valid object');
            }
        }
    }

    /**
    * @description 
    * @author diego.jacanamijoy@gmail.com | 11-17-2020 
    * @param leadId 
    **/
    public static void validateLeadData(String leadId){
        //get lead record
        Lead lead = SM_LeadHelper.getLeadById(leadId);
        if(lead <> null){
            if(lead.OwnerId == currentUsereId){
                throw new SM_CustomException(Label.IS_OWNER_ERROR);
            }
            if(lead.SM_Company_setting__c <> null && lead.SM_Company_setting__r.SM_Lead_Stage__c <> null){
                List<String> notValidstStatus = lead.SM_Company_setting__r.SM_Lead_Stage__c.split(';');
                if(notValidstStatus.contains(lead.status)){
                    throw new SM_CustomException(String.format(Label.RECORD_STATUS_ERROR, new List<Object>{lead.status}));
                }
            }
        }
    }

    /**
    * @description 
    * @author diego.jacanamijoy@gmail.com | 12-02-2020 
    * @param opportunityId 
    **/
    public static void validateOpportunityData(String opportunityId){
        //get Opportunity record
        Opportunity opp = SM_OpportunityHelper.getOpportunityId(opportunityId);
        if(opp <> null){
            if(opp.OwnerId == currentUsereId){
                throw new SM_CustomException(Label.IS_OWNER_ERROR);
            }
            if(opp.SM_Company_Setting__c <> null && opp.SM_Company_Setting__r.SM_Opportunity_Stage_not_accessible__c <> null){
                List<String> notValidstStatus = opp.SM_Company_Setting__r.SM_Opportunity_Stage_not_accessible__c.split(';');
                if(notValidstStatus.contains(opp.StageName)){
                    throw new SM_CustomException(String.format(Label.RECORD_STATUS_ERROR, new List<Object>{opp.StageName}));
                }
            }
        }
    }
}