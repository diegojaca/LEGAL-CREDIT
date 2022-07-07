/**
 * @description       : 
 * @author            : Camilo J. Camilo Jimenez -> cjimenez@legal-credit.com
 * @group             : 
 * @last modified on  : 03-26-2021
 * @last modified by  : Camilo J. Camilo Jimenez -> cjimenez@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   07-21-2021   Camilo J. Camilo Jimenez -> cjimenez@legal-credit.com   Initial Version
**/
public with sharing class SM_DisputeBatch implements Database.Batchable<SObject>,Database.AllowsCallouts, Database.Stateful,Schedulable {
    private static Set<String> disputeStatus = new Set<String>{SM_DisputeHelper.status.PENDING};
    private List<SM_TransactionLog__c> lstTransactionLog=new List<SM_TransactionLog__c>();
    private static SM_HelperWS helperWS;
    private static String  integrationToken;
    private static String query;
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        query = 'SELECT Id, SM_Status__c '+
                'FROM SM_Dispute__c '+
                'WHERE SM_Status__c IN :disputeStatus LIMIT 20 ';
         return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        helperWS=new SM_HelperWS();
        for (SM_Dispute__c dispute : (List<SM_Dispute__c>) scope) {
             processDisputes(dispute.id);
         }
         lstTransactionLog.addAll(helperWS.lstTransactionLog);
    }
    public static void processDisputes(String idDispute){
       String access = '';
       helperWS.idObject = idDispute;    
       access = getAccess();
       notifyDisputesNative(idDispute,access);
   }
   /**
   * @description this method is in charge of notifying the native that a new dispute was created
   * @author  cjimenez@legal-credit.com | 01-16-2021
   * @param helperWS,idDisputa,access
   **/
   public static void notifyDisputesNative(String idDisputa,String access){
       String endPoint = '';
       String method = '';
       Integer timeOut = 0;
       SM_SetupWebService__mdt setupWebService = helperWS.getSetupWebServices('SM_NoniticateDisputeCreated');
       endPoint = setupWebService.SM_EndPoint__c;
       method = setupWebService.SM_Method__c;
       timeOut = Integer.valueOf(setupWebService.SM_timeOut__c);
       helperWS.integration=setupWebService.SM_Integration__c;
      
       if(String.isNotBlank(idDisputa))
          endPoint = endPoint.replace('idDispute',idDisputa);
       helperWS.executeService(endPoint,method,'', timeOut,access);
   }
   /**
   * @description this method is encoded to gain access to consume native notification services
   * @author  cjimenez@legal-credit.com | 01-16-2021
   * @param helperWS
   **/
   public static String  getAccess(){
       String endPoint = '';
       String method = '';
       Integer timeOut = 0;
       String access = '';
       Boolean updateToken = false;
       SM_DisputeHelper.Token token = null;
       SM_SetupWebService__mdt setupWebService = null;

       setupWebService = helperWS.getSetupWebServices('SM_TokenDispute');
       SM_DisputeHelper.TokenObtainPair tokenObtainPair = new SM_DisputeHelper.TokenObtainPair();
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
           token=(SM_DisputeHelper.Token)JSON.deserialize(responseData.body, SM_DisputeHelper.Token.class);
           access='Bearer '+token.access;
       }else {
           access='Bearer '+helperWS.getTokenSetup(); 
       }
       return access;

   }
   public void finish(Database.BatchableContext bc){
      //Insert token every time you make a request to the service
      if(!lstTransactionLog.isEmpty()){
          Database.Insert(lstTransactionLog);
        }
   }
   /**
   * @description Method to program batch
   * @author  cjimenez@legal-credit.com | 01-16-2021
   * @param sc 
   **/
   public void execute(SchedulableContext sc) {
      Database.executeBatch(new SM_DisputeBatch());
    }
}