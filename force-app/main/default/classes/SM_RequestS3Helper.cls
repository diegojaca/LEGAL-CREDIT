/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 04-10-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   04-01-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
public with sharing class SM_RequestS3Helper {

    //Variable con la configuracion para solicitudes a S3
    // public CalloutPanel__mdt uploadS3Cnf;
    public SM_SetupWebService__mdt uploadS3Cnf;

    public SM_RequestS3Helper() {
        // CalloutPanel uploadS3Cnf = new CalloutPanel();
        // uploadS3Cnf = [Select MasterLabel,Token__c,Password__c,Callout__c,Region__c,Service__c,Metodo__c From CalloutPanel__mdt Where DeveloperName = 'UploadFileToS3' Limit 1];
        uploadS3Cnf = [SELECT Id, SM_EndPoint__c, SM_Method__c, SM_Password__c, SM_UserName__c FROM SM_SetupWebService__mdt WHERE SM_Integration__c = 'Upload S3' Limit 1];
    }

    /**
    * @description Generic method to HTTP Requests to S3 API
    * @author jpachon@legal-credit.com | 04-01-2021
    * @param method 
    * @param endPoint 
    * @param headers 
    * @param body 
    * @return HTTPResponse
    **/
    public HTTPResponse getHTTPResponseS3(String method, Url endPoint, Map<String,String> headers, Blob body,SM_CloudDocumentPath.Bucket bucketS3){
        
        // SM_ConnectorToS3 connector = new SM_ConnectorToS3(uploadS3Cnf.Password__c,uploadS3Cnf.Token__c);
        SM_ConnectorToS3 connector = new SM_ConnectorToS3(bucketS3.key, bucketS3.secret);
        // connector.region = uploadS3Cnf.Region__c;
        connector.region = bucketS3.region;
        connector.service = 's3';
        HttpRequest req = connector.signedRequest(method,endPoint,headers,body,false);
        Http http = new Http();
        if(Test.isRunningTest()) return new HTTPResponse();
        HttpResponse response = http.send(req);
        return response;
    }

    /**
    * @description Method to upload documents to S3
    * @author jpachon@legal-credit.com | 04-01-2021
    * @param fileObj 
    * @param fileName 
    * @param destinationRoute 
    * @return HTTPResponse
    **/
    public HTTPResponse uploadFilesToS3(Attachment fileObj, String fileName, String destinationRoute,SM_CloudDocumentPath.Bucket bucketS3){

        String method = 'PUT';

        // String host = 'https://s3.us-east-1.amazonaws.com';
        String host = bucketS3.host;

        Blob pdfBlob = fileObj.Body ;//encryptFile(pdfBlob);
        URL endPoint = new URL(host+destinationRoute);

        Map<String,String> headers = new Map<String,String>();
        headers.put('Content-Length',String.valueOf(pdfBlob.size()));
        headers.put('Content-Type', 'application/'+fileObj.Name.substring(fileObj.Name.lastIndexOf('.') + 1).toLowerCase());
        headers.put('Connection', 'keep-alive');
        //headers.put('x-amz-acl', 'public-read');

        return  getHTTPResponseS3('PUT',endPoint,headers,pdfBlob,bucketS3);
    }

}