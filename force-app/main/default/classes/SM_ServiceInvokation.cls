/**
 * @description       :  Service Invokation
 * @author            : cjimenez@legal-credit.com
 * @group             : 
 * @last modified on  : 02-11-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   16-01-2021    cjimenez@legal-credit.com  Initial Version
**/
public with sharing class SM_ServiceInvokation {
    public String method {get;set;}
    public String endPoint {get;set;}
    public String response {get;set;}
    public String request {get;set;}
    public Integer statusCode {get;set;}
    public Integer timeout {get;set;}
    public String integrationName {get;set;}
    public String status {get;set;}
    public Boolean isSucces {get;set;}    
    public HttpResponse responsetHttp {get;set;}
    public Map<String, String> headers {get; set;}
    public static Map<String, String> fieldNameBySObjectReference;

    public SM_ServiceInvokation(Boolean loadFieldsConf) {
        if (loadFieldsConf) {
            getFieldsBySOBjectType();            
        }
    }
    /**
    * @description this method execute rest services that are requested
    * @author cjimenez@legal-credit.com | 17-01-2021 
    * @param endPoint,method,headers,request,request,timeOut
    **/
    public SM_ServiceInvokation callService(String endPoint, String method, Map<String, String> headers, String request, Integer timeOut) {
        SM_ServiceInvokation result = null;
        Http htp = new Http();
        HttpRequest htpRequest = new HttpRequest();
        HttpResponse htpResponse = new HttpResponse();
        try {
             if(String.isNotEmpty(request))
                htpRequest.setBody(request);
             htpRequest.setMethod(method);
             htpRequest.setEndpoint(endPoint);
             htpRequest = addHeaders(headers, htpRequest);
             if(timeOut != null)
                htpRequest.setTimeout(timeOut);
             htpResponse = htp.send(htpRequest);
             result = initializeTrace(htpResponse, htpRequest);
             result.isSucces = true;
        }catch(Exception e) {
               result = initializeTrace(null, htpRequest);
               result.isSucces = false;
        }
        return result;
    }

    /**
    * @description This method obtains services Headers 
    * @author cjimenez@legal-credit.com | 17-01-2021 
    * @param headers,addTo
    **/
    public HttpRequest addHeaders(Map<String, String> headers, HttpRequest addTo) {
        HttpRequest result = new HttpRequest();
        try {
             if(addTo != null)
                result = addTo;
            if(headers == null)
               headers = new Map<String, String>();
            for(String item : headers.keySet()) {
                result.setHeader(item, headers.get(item));
            }
         }catch(Exception e) {
                System.debug(e.getMessage());
         }
        return result;
    }
   /**
    * @description This method initializes the class variables
    * @author cjimenez@legal-credit.com | 17-01-2021 
    * @param headers,addTo
    **/
    @TestVisible
    private SM_ServiceInvokation initializeTrace(HttpResponse responseService, HttpRequest requestService) {
        SM_ServiceInvokation result = new SM_ServiceInvokation(false);
        try {
             if(responseService != null) {
                result.response = responseService.getBody();
                result.request = requestService.getBody();
                result.statusCode = responseService.getStatusCode();
                result.status = responseService.getStatus();
                result.responsetHttp = responseService;
            }
            if(requestService != null) {
                result.method = requestService.getMethod();
                result.endPoint = requestService.getEndpoint();
                result.request = requestService.getBody();
            }
        }catch(Exception e){
                System.debug(e.getMessage());
        }
        return result;
    }
    /**
    * @description This method creates the transaction log instance for each request
    * @author cjimenez@legal-credit.com | 17-01-2021 
    * @param idObject,integration
    **/
    public SM_TransactionLog__c crateTransactionLog(String idObject,String integration){
        SM_TransactionLog__c transactionLog = new SM_TransactionLog__c();
        transactionLog.put(fieldNameBySObjectReference.get(SM_Utils.getSObjectNameById(idObject)), idObject);
        transactionLog.SM_EndPoint__c = this.endPoint;
        transactionLog.SM_Method__c = this.method;
        transactionLog.SM_Request__c = this.request;
        transactionLog.SM_Response__c = this.response;
        transactionLog.SM_Integration__c = integration;
        transactionLog.SM_StatusCode__c = this.statusCode;
        return transactionLog;
    }
    /**
    * @description this method allows getting fields name from five list item object
    * @author jpachon@legal-credit.com | 02-04-2021
    **/
    public static void getFieldsBySOBjectType(){
        fieldNameBySObjectReference = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('SM_TransactionLog__c').getDescribe().fields.getMap();
        for (String fieldName: fieldMap.keySet()) {
            Schema.DisplayType fieldDataType = fieldMap.get(fieldName).getDescribe().getType();
            if(fieldDataType == Schema.DisplayType.REFERENCE){
                String fieldLabel = fieldMap.get(fieldName).getDescribe().getLabel();
                String fieldReferenceTo =  String.valueOf(fieldMap.get(fieldName).getDescribe().getReferenceTo()[0]);
                if (fieldReferenceTo != 'User') {
                    fieldNameBySObjectReference.put(fieldReferenceTo, fieldName);
                }
            }
        }
    }
}