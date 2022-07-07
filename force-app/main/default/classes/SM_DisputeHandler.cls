/**
 * @description       : Dispute Object Handler
 * @author            : cjimenez@legal-credit.com
 * @group             : 
 * @last modified on  : 03-17-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   17-01-2021    cjimenez@legal-credit.com  Initial Version
**/
public with sharing class SM_DisputeHandler extends SM_TriggerHandler{ 
    private static String  integrationToken {get;set;}

    public SM_DisputeHandler(String triggerName) {
        super(triggerName); 
    }
    /************* Overwrite DML methods *************/
    override public void asyncAfterUpdate(){
        try {
            processDisputes(Trigger.new, Trigger.oldMap);
        } catch (Exception e) {
            System.debug('An error occurred in asyncAfterUpdate dispute  '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }
    override public void asyncAfterInsert(){
        try {
            processInsertDisputes(JSON.serialize(Trigger.new));
        } catch (Exception e) {
            System.debug('An error occurred in asyncAfterUpdate dispute  '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }
    /************* Auxiliar methods *************/
    public static void processDisputes(List<SObject> newDisputes, Map<Id, SObject> oldDisputesMap){
        system.debug('servicio disputas--->');
        List<SM_Dispute__c> newDisputesToNative = new List<SM_Dispute__c>();
        List<SM_Dispute__c> updatedDisputesToNative = new List<SM_Dispute__c>();
        for (SM_Dispute__c newDispute : (List<SM_Dispute__c>) newDisputes) {
            SM_Dispute__c oldDispute = (SM_Dispute__c) oldDisputesMap.get(newDispute.Id);
            if (SM_Utils.isChangedField(newDispute, oldDispute, 'SM_Status__c')) {
                 updatedDisputesToNative.add(newDispute);
            }
        }
        // Any other status dispute changes
        if (!updatedDisputesToNative.isEmpty()) {
             processUpdateDisputes(JSON.serialize(updatedDisputesToNative));
        }
    }
    
    /**
    * @description this is the method that processes each of the disputes created
    * @author cjimenez@legal-credit.com | 17-01-2021 
    * @param newDisputeJSON 
    **/
    @Future(callout=true)
    public static void processInsertDisputes(String newDisputesJSON){
        //Deserialze JSON
        SM_Dispute__c[] newDispute = (List<SM_Dispute__c>) JSON.deserialize(newDisputesJSON, List<SM_Dispute__c>.class);
        SM_HelperWS helperWS = new SM_HelperWS();
        String access = '';
        Map<String,SM_Dispute__c> contraByIds = new Map<String,SM_Dispute__c>();
        List<SM_Dispute__c> lstUpdateDispute = new List<SM_Dispute__c>();
        for(SM_Dispute__c dispute: newDispute){ 
            helperWS.idObject = dispute.id;    
            access = getAccess(helperWS);
            notifyDisputesNative(helperWS,dispute.id,access);
            contraByIds.put(dispute.SM_Contract__c,dispute);
        }
        //Update token if it has already expired
        if(helperWS.updateToken){
            helperWS.integration = integrationToken;
            helperWS.updateToken(access.remove('Bearer '));
        }
        //Insert token every time you make a request to the service
        if(!helperWS.lstTransactionLog.isEmpty()){
            insert helperWS.lstTransactionLog;
        }
        for (Contract contr: [SELECT AccountId, Id,SM_Email_to_send_contract__c, SM_Opportunity__r.SM_Company_Setting__r.SM_Abbreviated_Company__c, SM_Dispute_Number__c, (SELECT ID,Status FROM Assets__r ORDER BY CreatedDate DESC) FROM Contract WHERE ID IN :contraByIds.keySet()]) {
            lstUpdateDispute.add(new SM_Dispute__c (id = contraByIds.get(contr.Id).id, SM_Asset__c = contr.Assets__r.get(0).id));
        } 
        if(!lstUpdateDispute.isEmpty()){
           Database.Update(lstUpdateDispute);
        }
    }
    /**
    * @description this is the method that processes each of the disputes update
    * @author cjimenez@legal-credit.com | 17-01-2021 
    * @param updatedDisputesJSON 
    **/
    @Future(callout=true)
    public static void processUpdateDisputes(String updatedDisputesJSON){
        SM_Dispute__c[] newDisputes = (List<SM_Dispute__c>) JSON.deserialize(updatedDisputesJSON, List<SM_Dispute__c>.class);
        SM_HelperWS helperWS = new SM_HelperWS();
      
        String access='';
        for(SM_Dispute__c newDispute: newDisputes){          
            helperWS.idObject = newDispute.id;  
            List<String> notValidstStatus = Label.SM_INITIAL_NATIVE_STATE.split(';');    
            if(!notValidstStatus.contains(newDispute.SM_Status__c)){    
                access = getAccess(helperWS);
                updateStatusDisputeNative(helperWS,newDispute.SM_Dispute_ID__c,newDispute.SM_Status__c,access);
            }
        }
        //Update token if it has already expired
        if(helperWS.updateToken){
            helperWS.integration = integrationToken;
            helperWS.updateToken(access.remove('Bearer '));
        }
        //Insert token every time you make a request to the service
        if(!helperWS.lstTransactionLog.isEmpty()){
            insert helperWS.lstTransactionLog;
        }
    }
  /**
    * @description this method is in charge of notifying the native that a new dispute was created
    * @author  cjimenez@legal-credit.com | 01-16-2021
    * @param helperWS,idDisputa,access
    **/
    public static void notifyDisputesNative(SM_HelperWS helperWS,String idDisputa,String access){
        String endPoint = '';
        String method = '';
        Integer timeOut = 0;

        SM_SetupWebService__mdt setupWebService = helperWS.getSetupWebServices('SM_NoniticateDisputeCreated');
        endPoint = setupWebService.SM_EndPoint__c;
        method = setupWebService.SM_Method__c;
        timeOut = Integer.valueOf(setupWebService.SM_timeOut__c);
        helperWS.integration = setupWebService.SM_Integration__c;
        if(String.isNotBlank(idDisputa))
           endPoint = endPoint.replace('idDispute',idDisputa);
        helperWS.executeService(endPoint,method,'', timeOut,access);
    }
    /**
    * @description this method is in charge of notifying the native that update Status
    * @author  cjimenez@legal-credit.com | 01-16-2021
    * @param helperWS,idDisputa,Status,access
    **/
    public static void updateStatusDisputeNative(SM_HelperWS helperWS,String idDisputa,String status,String access){
        String endPoint = '';
        String method = '';
        Integer timeOut = 0;
        Status statusUpdate = new Status();
        statusUpdate.id = status;
        statusUpdate.name = status;
        StatusDispute statusDispute = new StatusDispute();
        statusDispute.status = statusUpdate;
        String JSONString = JSON.serialize(StatusDispute);
        
        SM_SetupWebService__mdt setupWebService=helperWS.getSetupWebServices('SM_updateStatusDisputeNative');
        endPoint=setupWebService.SM_EndPoint__c;
        method=setupWebService.SM_Method__c;
        timeOut=Integer.valueOf(setupWebService.SM_timeOut__c);
        helperWS.integration=setupWebService.SM_Integration__c;
        if(String.isNotBlank(idDisputa))
           endPoint=endPoint.replace('disputeExternalID',idDisputa);
        helperWS.executeService(endPoint,method,JSONString, timeOut,access);
    }
    /**
    * @description this method is encoded to gain access to consume native notification services
    * @author  cjimenez@legal-credit.com | 01-16-2021
    * @param helperWS
    **/
    public static String  getAccess(SM_HelperWS helperWS){
        String endPoint = '';
        String method = '';
        Integer timeOut = 0;
        String access = '';
        Boolean updateToken = false;
        Token token = null;

        SM_SetupWebService__mdt setupWebService = null;
        setupWebService=helperWS.getSetupWebServices('SM_TokenDispute');
        TokenObtainPair tokenObtainPair = new TokenObtainPair();
        tokenObtainPair.email = setupWebService.SM_UserName__c;
        tokenObtainPair.password = setupWebService.SM_Password__c;
        String JSONString = JSON.serialize(tokenObtainPair);
        endPoint = setupWebService.SM_EndPoint__c;
        method = setupWebService.SM_Method__c;
        timeOut = Integer.valueOf(setupWebService.SM_timeOut__c);
        helperWS.integration = setupWebService.SM_Integration__c;
        integrationToken = setupWebService.SM_Integration__c;
        if(helperWS.validateTokenExpiration()){
            SM_HelperWS.ResponseData responseData = helperWS.getToken(endPoint,method,JSONString, timeOut);
            if(responseData.body != null){
                token = (Token)JSON.deserialize(responseData.body, Token.class);
                access = 'Bearer '+token.access;
            }
        }else {
               access = 'Bearer '+helperWS.getTokenSetup(); 
        }
        return access;
    }
    public class TokenObtainPair{
        public String email{get; set;}
        public String password{get; set;}
    }

    public class Token{
        public String refresh{get; set;}
        public String access{get; set;}
    }
    public class Status{
        public String id{get; set;}
        public String name{get; set;}
    }
    public class StatusDispute{
        Status status {get; set;}
    }
}