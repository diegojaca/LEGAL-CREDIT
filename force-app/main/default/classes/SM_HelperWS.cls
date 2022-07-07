/**
 * @description       :  WS REST Object Helper
 * @author            : cjimenez@legal-credit.com
 * @group             :
 * @last modified on  : 06-12-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                        Modification
 * 1.0   16-01-2021    cjimenez@legal-credit.com  Initial Version
**/
public with sharing class SM_HelperWS {
    public String idObject {get;set;}
    public String integration {get;set;}
    public Boolean updateToken {get;set;}
    public List<SM_TransactionLog__c> lstTransactionLog {get;set;}
    
    public SM_HelperWS(){
        lstTransactionLog=new List<SM_TransactionLog__c>();
        this.updateToken=false;
    }
    /**
    * @description this method obtains the security token of the services that request it
    * @author cjimenez@legal-credit.com | 17-01-2021
    * @param url, method,body,timeOut
    **/
    public ResponseData getToken(String url, String method, String body, Integer timeOut){
        SM_HelperWS.ResponseData responseData = new SM_HelperWS.ResponseData();
        Map<String, String> headers = new Map<String, String>();
        SM_ServiceInvokation trace = new SM_ServiceInvokation(true);
        headers = getHeadersToke();
        try{
            trace = trace.callService(url, method, headers, body, timeOut);
            lstTransactionLog.add(trace.crateTransactionLog(this.idObject,integration));
        }catch(CalloutException e){
                responseData.Success = true;
                return responseData;
        }
        //responseData.traceService = trace;
        responseData.Success = true;
        responseData.Body = trace.response;
        responseData.StatusCode = trace.statusCode;
        return responseData;
    }
    /**
    * @description this method gets the token configuration stored in Salesforce
    * @author cjimenez@legal-credit.com | 17-01-2021
    * @param
    **/
    public String getTokenSetup(){
       SM_SetupToken__c setupToken=SM_SetupToken__c.getAll().get(integration);
       return setupToken.SM_Token__c;
    }
    /**
    * @description this method valid if the token configuration already expired
    * @author cjimenez@legal-credit.com | 17-01-2021
    * @param
    **/
    public Boolean validateTokenExpiration(){
        SM_SetupToken__c setupToken=SM_SetupToken__c.getAll().get(integration);
        if(setupToken.SM_ExpirationDate__c != null) {
            DateTime newExpirationDate =  setupToken.SM_ExpirationDate__c.addHours(-5).addMinutes(Integer.valueOf(setupToken.SM_DurationMinutes__c));
            DateTime CurrentDate=System.now().addHours(-5);
            if(newExpirationDate <= CurrentDate  ) {
                this.updateToken=true;
                return true;
            }else {
                   return false;
            }
         }
        return true;
    }
    /**
    * @description this method updates the token in the configuration if it already expires this this
    * @author cjimenez@legal-credit.com | 17-01-2021
    * @param token
    **/
    public Boolean updateToken(String token){
        SM_SetupToken__c setupToken =SM_SetupToken__c.getAll().get(integration);
        DateTime newExpiationDate =System.now().addMinutes(Integer.valueOf(setupToken.SM_DurationMinutes__c));
        setupToken.SM_ExpirationDate__c=newExpiationDate;
        setupToken.SM_Token__c=token;
        update setupToken;
        return null;
    }
    /**
    * @description this method execute rest services that are requested
    * @author cjimenez@legal-credit.com | 17-01-2021
    * @param url,method,body,timeOut,token
    **/
    public ResponseData executeService(String url, String method, String body, Integer timeOut,String token){
        SM_HelperWS.ResponseData responseData = new SM_HelperWS.ResponseData();
        Map<String, String> headers = new Map<String, String>();
        SM_ServiceInvokation trace = new SM_ServiceInvokation(true);
        headers = getHeadersToke();
        headers.put('Authorization', token);
        try{
            trace = trace.callService(url, method, headers, body, timeOut);
            lstTransactionLog.add(trace.crateTransactionLog(this.idObject,integration));
        }catch(CalloutException e){
               responseData.Success = true;
                return responseData;
        }
        responseData.Success = true;
        responseData.Body = trace.response;
        responseData.StatusCode = trace.statusCode;
        return responseData;
    }
    /**
    * @description This method obtains services Headers
    * @author cjimenez@legal-credit.com | 17-01-2021
    * @param
    **/
    private Map<String, String> getHeadersToke(){
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        headers.put('Accept', 'application/json');
        return headers;
    }
    /**
    * @description This method obtains the configuration of the services
    * @author cjimenez@legal-credit.com | 17-01-2021
    * @param webServicesName
    **/
    public SM_SetupWebService__mdt getSetupWebServices(String webServicesName){
        return [SELECT  SM_EndPoint__c,SM_Method__c,SM_timeOut__c,SM_UserName__c,SM_Password__c,SM_Integration__c
                FROM SM_SetupWebService__mdt
                WHERE DeveloperName =: webServicesName LIMIT 1];
    }
    public class ResponseData{
        public Boolean Success{get; set;}
        public String Body{get; set;}
        public Integer StatusCode{get; set;}
    }

}