/**
 * @description       : Class for dynamic path generation
 * @author            : Camilo Jimenez
 * @group             : 
 * @last modified on  : 10-01-2021
 * @last modified by  : cjimenez@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   10-01-2021  cjimenez@legal-credit.com   Initial Version
**/
public with sharing class SM_CloudDocumentPath {
     public List<SM_SetupDocumentPath__mdt> lstSetupDocumentPath{get;set;}
     private  Organization organization{get;set;}
     public SM_CloudDocumentPath.Bucket bucket {get;set;}
     
    public SM_CloudDocumentPath(){
        lstSetupDocumentPath=getSetupDocumentPath();
        organization=getOganization();
    }
  /**
    * @description Generate dynamic document path for storage in aws3
    * @author  cjimenez@legal-credit.com |  10-01-2021
    * @param  
    **/
    public String generatePath(String documetType,String nameDocument,String idObject,String abbreviatedCompany){
        String path='';
        String dynamicName='';
        Boolean generateDate=false;

        Id url = (Id)idObject;
        String nameObject=url.getSObjectType().getDescribe().getName();

        List<SObject> lstSObject=new List<SObject>();
        lstSObject=createQueryObject(documetType,idObject,nameObject,abbreviatedCompany);
        String extFile=nameDocument.substring(nameDocument.lastIndexOf('.') + 1).toLowerCase();
         
        path+=isSandbox();
        for(SM_SetupDocumentPath__mdt setupDocumentPath:this.lstSetupDocumentPath){
         
            if(setupDocumentPath.SM_DocumetType__c==documetType && setupDocumentPath.SM_ObjectAPIName__c==nameObject && setupDocumentPath.SM_Abbreviated_Company__c == abbreviatedCompany){  
                
                bucket=new SM_CloudDocumentPath.Bucket();
                bucket.bucketName=setupDocumentPath.SM_SetupBucketS3__r.SM_BucketName__c;
                bucket.key=setupDocumentPath.SM_SetupBucketS3__r.SM_Key__c;
                bucket.secret=setupDocumentPath.SM_SetupBucketS3__r.SM_Secret__c;
                bucket.host=setupDocumentPath.SM_SetupBucketS3__r.SM_Host_S3__c;
                bucket.region=setupDocumentPath.SM_SetupBucketS3__r.SM_Region_S3__c;
                
                list<SM_SetupPathLevel__mdt> lstSetupPathLevel = sortListLevel(setupDocumentPath);

                for(SM_SetupPathLevel__mdt setupPathLevel:lstSetupPathLevel){
                    generateDate=setupDocumentPath.SM_GenerateDate__c;
                    if(setupPathLevel.SM_SearchQuery__c){ 
                      if(setupPathLevel.SM_Folder__c){
                       path+=getFieldObject(lstSObject.get(0),SetupPathLevel.SM_SearchFieldName__c)+'/';
                    }else {
                       dynamicName+=SetupPathLevel.SM_SearchFieldName__c+'_';
                    }
                }else {
                    if(setupPathLevel.SM_Folder__c){
                        path+=SetupPathLevel.SM_SearchFieldName__c+'/';
                     }else {
                       dynamicName+=SetupPathLevel.SM_SearchFieldName__c+'_';
                     }
                }

             }
            

          }
       }
         
       
       path+=generateNameDocument(nameDocument,dynamicName,extFile,generateDate);

       return path;
        
     }
/**
    * @description Generate dynamic document name for storage in path
    * @author  cjimenez@legal-credit.com |  11-01-2021
    * @param  nameDocument,dynamicName,extFile,generateDate
    **/
     public String generateNameDocument(String nameDocument,String dynamicName,String extFile,Boolean generateDate){
        String finalName='';

         Datetime datetime1 = Datetime.valueOfGMT(String.valueOf(System.now()));

        if(String.isNotBlank(dynamicName)){
           
            dynamicName = dynamicName.removeEnd('_');
            
            if(generateDate){
                finalName=dynamicName;
                finalName+='_'+datetime1;
                finalName=finalName.replace(':','-');
                finalName+='.'+extFile;
                
            }else{
                finalName+=dynamicName+'.'+extFile;
              
            }
               

        }else {
            if(generateDate){
                nameDocument = nameDocument.replace('.'+extFile,'');
                finalName=nameDocument;
                finalName+='_'+datetime1;
                finalName=finalName.replace(':','-');
                finalName+='.'+extFile;
            }else{
                finalName+=nameDocument;
            }
          
        }
        return finalName;
     }
        
/**
    * @description Crea query dinámico 
    * @author  cjimenez@legal-credit.com |  11-01-2021
    * @param  documetType,idObject,nameObject
    **/
     public List<SObject> createQueryObject(String documetType,String idObject,String nameObject,String abbreviatedCompany){
        List<SObject> lstSObject=new List<SObject>();
        String query='SELECT ';
        Boolean searchQuery=false;
        List<String> lstIdObjeto=new  List<String>();
        lstIdObjeto.add(idObject);
 
        for(SM_SetupDocumentPath__mdt setupDocumentPath:this.lstSetupDocumentPath){
          
            if(setupDocumentPath.SM_DocumetType__c==documetType && setupDocumentPath.SM_ObjectAPIName__c==nameObject && setupDocumentPath.SM_Abbreviated_Company__c==abbreviatedCompany){  
              
                for(SM_SetupPathLevel__mdt setupPathLevel:setupDocumentPath.SM_SetupDocumentPath__r){
                    if(setupPathLevel.SM_SearchQuery__c){ 
                      query+=SetupPathLevel.SM_SearchFieldName__c+',';
                      searchQuery=true;
                    }
               }
               query = query.removeEnd(',');
               query+=' FROM '+setupDocumentPath.SM_ObjectAPIName__c;
               query+=' WHERE Id in (\''+string.join(lstIdObjeto,'\',\'')+'\')';
            }

        }

        system.debug('query-->'+query);
        if(searchQuery)
        lstSObject=getFieldsObject(query);

        return lstSObject;

     }
     
     /**
    * @description Get first level of path if it is sandbox
    * @author  cjimenez@legal-credit.com |  11-01-2021
    * @param  
    **/
     public  string isSandbox(){
        String firstLevel='';

        if(this.organization.IsSandbox){
            firstLevel=Label.SM_FIRST_LEVEL_PATH;
            return firstLevel+'/';
        }
        return firstLevel;
    }

   /**
    * @description Get the query for each of the fields
    * @author  cjimenez@legal-credit.com |  11-01-2021
    * @param  obj,field
    **/
    public  String getFieldObject(SObject obj, String field){

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

  /**
    * @description Order levels Path, Name
    * @author  cjimenez@legal-credit.com |  10-01-2021
    * @param  
    **/
    public list<SM_SetupPathLevel__mdt> sortListLevel(SM_SetupDocumentPath__mdt setupDocumentPath){
        list<SM_SetupPathLevel__mdt> sortLevels = new list<SM_SetupPathLevel__mdt>();
        integer levl = setupDocumentPath.SM_SetupDocumentPath__r.size();
        for(Integer i=1;i<=levl;i++){
            for(SM_SetupPathLevel__mdt setupPathLevel:setupDocumentPath.SM_SetupDocumentPath__r){
                if(i==setupPathLevel.SM_Position__c){
                    sortLevels.add(setupPathLevel);
                }
            }
        }
        return sortLevels;
    }

    /**
    * @description Get the configuration for the generation of dynamic paths
    * @author  cjimenez@legal-credit.com |  11-01-2021
    * @param  
    **/
     public  list<SM_SetupDocumentPath__mdt> getSetupDocumentPath(){
        try{
			
            list<SM_SetupDocumentPath__mdt> lstSetupDocumentPath = [SELECT DeveloperName,Label,SM_DocumetType__c,SM_GenerateDate__c,SM_ObjectAPIName__c,SM_RenameName__c,SM_SetupBucketS3__r.SM_BucketName__c,
                                                                   SM_SetupBucketS3__r.SM_Key__c,SM_SetupBucketS3__r.SM_Secret__c,SM_Abbreviated_Company__c,SM_SetupBucketS3__r.SM_Host_S3__c,SM_SetupBucketS3__r.SM_Region_S3__c,           
                                                                   (SELECT Label,SM_Folder__c,SM_SearchFieldName__c,SM_SearchQuery__c,SM_Position__c  FROM SM_SetupDocumentPath__r) 
                                                                   FROM SM_SetupDocumentPath__mdt ];
            return lstSetupDocumentPath;

        }catch(QueryException e){
            return null;
        }
    }  
   /**
    * @description Get the settings of the organization where the user is located
    * @author  cjimenez@legal-credit.com |  11-01-2021
    * @param  
    **/
    public  Organization getOganization(){
        
        try{
            Organization organization = [SELECT IsSandbox FROM Organization];
            return organization;
            
        }catch(QueryException qe){
            return null;
        }
        
    }

       /**
    * @description Get object
    * @author  cjimenez@legal-credit.com |  11-01-2021
    * @param  query
    **/
    public  List<SObject> getFieldsObject(String query){
        try{
            
            List<SObject> ListObj = Database.query(query);
            return ListObj;

        }catch(QueryException e){
            return null;
        }
    }
    
    /**
    * @description Class to store bucket parameters
    * @author  cjimenez@legal-credit.com |  11-01-2021
    * @param  query
    **/
    public class Bucket{
         public String    bucketName {get;set;}
         public String    key {get;set;}
         public String    secret {get;set;}
         public String    host {get;set;}
         public String    region {get;set;}
       
       
      }

}