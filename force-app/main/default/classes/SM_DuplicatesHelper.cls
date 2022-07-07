/**
 * @description       :
 * @author            : diego.jacanamijoy@gmail.com
 * @group             :
 * @last modified on  : 06-09-2022
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                        Modification
 * 1.0   12-11-2020   diego.jacanamijoy@gmail.com   Initial Version
 * 1.1   09-06-2022   jpachon.ariza@gmail.com       SMPII-152
**/
public with sharing class SM_DuplicatesHelper {


    /**
    * @description This method create tracking inbound records
    * @author diego.jacanamijoy@gmail.com | 12-11-2020
    * @param lead
    * @param relatedId
    * @param relatedFieldName
    * @return SM_Tracking_Inbound__c
    **/
    public static SM_Tracking_Inbound__c createTrakingInbound(Lead lead, String relatedId, String relatedFieldName){
        //Create Traking inbound with init data
        String leadSource = String.isNotBlank(lead.LeadSource) ? lead.LeadSource : '';
        // SMPII-152 - SM_Company field added
        SM_Tracking_Inbound__c trakingInbound = new SM_Tracking_Inbound__c(
                                                        SM_Contact_Date__c = System.Now(),
                                                        SM_Email__c = lead.Email,
                                                        SM_Phone__c = lead.phone,
                                                        SM_Company__c = lead.Company
                                                    );
        if(String.isNotBlank(leadSource)){
            trakingInbound.SM_Lead_origin__c = leadSource;
        }
        trakingInbound.put(relatedFieldName, relatedId);
        return trakingInbound;
    }

    /**
    * @description This method create record of traking inbound to leads
    * @author diego.jacanamijoy@gmail.com | 11-27-2020
    * @param duplicatesByLead
    **/
    public static void createTrakingInboundLeads(Map<Lead, Lead[]> duplicatesByLead){
        SM_Tracking_Inbound__c[] trakingInbouns = new List<SM_Tracking_Inbound__c>();
        SM_NotificationHelper.Notification[] notifications = new List<SM_NotificationHelper.Notification>();
        for(Lead lead: duplicatesByLead.keySet()){
            String leadIdAux;
            //validate if have duplicate leads, only send notification and create traking record if then one duplicate
            if(duplicatesByLead.get(lead).size() == 1 || (!lead.SM_ManuallyCreated__c && duplicatesByLead.get(lead).size() > 0)){
                //send notifications to lead owner
                Lead duplicate = duplicatesByLead.get(lead)[0];
                leadIdAux = duplicate.Id;
                //If Owner is not admin, send notification
                if(!duplicate.Owner.Profile.Name.containsIgnoreCase('admin')){
                    notifications.add(sendNotificationByDuplicateRecord(Label.DUPLICATE_LEAD_NOTIFICATION_TITLE,
                                                                        Label.DUPLICATE_LEAD_NOTIFICATION_BODY,
                                                                        duplicate,
                                                                        lead));
                }
            }else if(duplicatesByLead.get(lead).size() == 0){
                leadIdAux = lead.Id;
            }
            //add traking to list
            trakingInbouns.add(createTrakingInbound(lead, leadIdAux, 'SM_LeadId__c'));
        }
        if(!trakingInbouns.isEmpty()){
            Database.insert(trakingInbouns);
        }
        if(!notifications.isEmpty()){
            //Create instance of SM_NotificationHelper
            SM_NotificationHelper notificationhelper = new SM_NotificationHelper(notifications);
            notificationhelper.sendNotification();
        }
    }

    /**
    * @description This method created trackin inbound records to accounts
    * @author diego.jacanamijoy@gmail.com | 12-11-2020
    * @param accountsByLead
    **/
    public static void createTrakingInboundAccount(Map<Lead, Set<Account>> accountsByLead){
        SM_Tracking_Inbound__c[] trakingInbouns = new List<SM_Tracking_Inbound__c>();
        for(Lead lead: accountsByLead.keySet()){
            List<Account> accountsAux = new List<Account>(accountsByLead.get(lead));
            //validate if have duplicate leads, only send notification and create traking record if then one duplicate
            if(accountsAux.size() == 1 || (!lead.SM_ManuallyCreated__c && accountsAux.size() > 0)){
                //add traking to list
                trakingInbouns.add(createTrakingInbound(lead, accountsAux[0].Id, 'SM_AccountId__c'));
            }
        }
        if(!trakingInbouns.isEmpty()){
            Database.insert(trakingInbouns);
        }
    }

    /**
    * @description This method create notifications to duplicates records
    * @author diego.jacanamijoy@gmail.com | 12-11-2020
    * @param title
    * @param body
    * @param duplicate
    * @param newLead
    * @return SM_NotificationHelper.Notification
    **/
    public static SM_NotificationHelper.Notification sendNotificationByDuplicateRecord(String title, String body, SObject duplicate, Lead newLead){
        //Create instance of Notification of SM_NotificationHelper, with init data
        SM_NotificationHelper.Notification notification = new SM_NotificationHelper.Notification(
                                                            title,
                                                            '',
                                                            UserInfo.getUserId(),
                                                            Label.NOTIFICATION_TYPE_NAME,
                                                            '',
                                                            new Set<String>()
                                                        );
        //Params to replace label
        List<Object> params = new List<Object>();
        params.add(newLead.Name);
        if(newLead.LeadSource <> null){
            params.add(newLead.LeadSource);
        }
        notification.body = String.format(body, params);
        notification.targetId = (String) duplicate.get('Id');
        notification.sendIds = new Set<String> { (String) duplicate.get('OwnerId') };

        return notification;
    }
}