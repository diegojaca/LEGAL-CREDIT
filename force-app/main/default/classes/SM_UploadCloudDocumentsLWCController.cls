/**
 * @description       : Controller class lwc sM_UploadCloudDocumentsLWC
 * @author            : Camilo Jimenez
 * @group             : 
 * @last modified on  : 22-11-2020
 * @last modified by  : cjimenez@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   22-11-2020  cjimenez@legal-credit.com   Initial Version
**/


public with sharing class SM_UploadCloudDocumentsLWCController {
 
 /**
 * @description get s3 parameters
 * @author  cjimenez@legal-credit.com |  22-11-2020
 * @param 
  **/
  @AuraEnabled(cacheable=false)
  public static PathParameters getPathParametersS3(String fileName,String idObjct,String documetType){
   
    String pathS3=''; 
    SM_CloudDocumentPath cloudDocumentPath=new SM_CloudDocumentPath();
    String objectName=SM_Utils.getSObjectNameById((ID)idObjct);
    String abbreviatedCompany='';
 
    SM_Setup_Document_Path_By_Company__mdt setupDocumentPathByCompany= [SELECT SM_Label_API_Name__c,SM_Object_API_Name__c
                                                                        FROM SM_Setup_Document_Path_By_Company__mdt  
                                                                        WHERE SM_Object_API_Name__c =: objectName LIMIT 1];
                                                  
    Set<String> fieldsToQuery = new Set<String>();
    String query = 'SELECT {0} FROM ' +objectName+ ' WHERE Id =: idObjct LIMIT 1';      
    if(setupDocumentPathByCompany.SM_Label_API_Name__c <> 'N/V'){
       fieldsToQuery.addAll(setupDocumentPathByCompany.SM_Label_API_Name__c.split(';'));
            //Format query
       query = String.format(query, new List<String>{String.join(new List<String>(fieldsToQuery), ',')});
       System.debug('query-> ' + query);
        sObject obj=Database.query(query);    
        abbreviatedCompany=getFieldObject(obj,setupDocumentPathByCompany.SM_Label_API_Name__c);
     }else {
       abbreviatedCompany=setupDocumentPathByCompany.SM_Label_API_Name__c;
     }  
           
    pathS3=cloudDocumentPath.generatePath(documetType,fileName,idObjct,abbreviatedCompany);
    
    PathParameters pathParameters=new PathParameters();
    pathParameters.bucketName=cloudDocumentPath.bucket.bucketName;
    pathParameters.key=cloudDocumentPath.bucket.key;
    pathParameters.secret=cloudDocumentPath.bucket.secret;
    pathParameters.path=pathS3;
    pathParameters.abbreviatedCompany=abbreviatedCompany;

    return PathParameters;
  }
    
   
   /**
    * @description Create records in Cloud Document
    * @author  cjimenez@legal-credit.com |  22-11-2020
    * @param  fileName , idObjct,documetType,relationshipField
    **/
   
   @AuraEnabled
   public static SM_Cloud_Document__c createCloudDocument(String fileName,String idObjct,String documetType, String relationshipField,String pathS3,String abbreviatedCompany){

        String extFile=fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
        SM_Cloud_Document__c cloudDocumen= new SM_Cloud_Document__c();
        cloudDocumen.Name=fileName;
        cloudDocumen.SM_File_Path__c=pathS3;
        cloudDocumen.SM_Documet_Type__c=documetType;
        cloudDocumen.SM_Extension__c=extFile;
        cloudDocumen.SM_Active__c=true;
        if(abbreviatedCompany <> 'N/V')
        cloudDocumen.SM_Abbreviated_Company__c=abbreviatedCompany;
        cloudDocumen.put(relationshipField,idObjct);
 
        insert cloudDocumen;

        return cloudDocumen;
   }

    /**
        * @description Get the list of document types
        * @author  cjimenez@legal-credit.com |  22-11-2020
        * @param 
        **/
    @AuraEnabled(cacheable=false)
    public static List<String> getDocumetType(){
      List<String> lstDocumetType = new List<String>();
      List<Schema.PicklistEntry> ple = Schema.getGlobalDescribe().get('SM_Cloud_Document__c').getDescribe().fields.getMap().get('SM_Documet_Type__c').getDescribe().getPicklistValues();
      for(Schema.PicklistEntry e:ple){
          lstDocumetType.add(e.getLabel());
        }
        return lstDocumetType;
     }


/**
    * @description Get the query for each of the fields
    * @author  cjimenez@legal-credit.com |  11-01-2021
    * @param  obj,field
**/
public Static String getFieldObject(SObject obj, String field){

  if(field.containsNone('.')){
      return String.valueOf(obj.get(field));
  }
  else{
      String fieldAux=field.replace('.','☼');
      List<String> lstFields = fieldAux.split('☼');
      if(lstFields.size() == 2){
          
          return String.valueOf(obj.getSobject(lstFields[0]).get(lstFields[1]));
      }
      else if(lstFields.size()==3){
        
          return String.valueOf(obj.getSobject(lstFields[0]).getSobject(lstFields[1]).get(lstFields[2]));
      }
      else if(lstFields.size()==4){
        
          return String.valueOf(obj.getSobject(lstFields[0]).getSobject(lstFields[1]).getSobject(lstFields[2]).get(lstFields[3]));
      }
      else if(lstFields.size()==5){
        
          return String.valueOf(obj.getSobject(lstFields[0]).getSobject(lstFields[1]).getSobject(lstFields[2]).getSobject(lstFields[3]).get(lstFields[4]));
      }
      else{
          return null;
      }
  }
}
    

    public class PathParameters{
      @AuraEnabled public String    path {get;set;}
      @AuraEnabled public String    bucketName {get;set;}
      @AuraEnabled public String    key {get;set;}
      @AuraEnabled public String    secret {get;set;}
      @AuraEnabled public String    abbreviatedCompany {get;set;} 
    }



}