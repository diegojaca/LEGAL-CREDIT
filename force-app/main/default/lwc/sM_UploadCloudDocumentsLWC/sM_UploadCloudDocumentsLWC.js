import { LightningElement, track, wire,api } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

//Apex methods
import  SM_amazonFile from '@salesforce/resourceUrl/SM_amazonFile';
import  createCloudDocument from '@salesforce/apex/SM_UploadCloudDocumentsLWCController.createCloudDocument';
import  getPathParametersS3 from '@salesforce/apex/SM_UploadCloudDocumentsLWCController.getPathParametersS3';
import  getDocumetType from '@salesforce/apex/SM_UploadCloudDocumentsLWCController.getDocumetType';


//Labels 
import SM_API_VERSION_AWS3 from '@salesforce/label/c.SM_API_VERSION_AWS3';
import SM_ACL_AWS3 from '@salesforce/label/c.SM_ACL_AWS3';

export default class SM_UploadCloudDocumentsLWC extends LightningElement {
    @api recordId;
    @api relationshipField;
    //Traking atributes
    @track fileName;
    @track awsSettngRecordId;
    @track showSpinner = false;
    @track optionsTypeDocument = []; 

    //Local variables
    documentType;
    awS3= false; 
    awS3Initialized=false;
    AwS3Path='';
    abbreviatedCompany='';

   connectedCallback() {
   
    this.optionsTypeFile();
    
      Promise.all([loadScript(this, SM_amazonFile)])
        .catch(error => {
          this.showToast('error', 'An error occurred contact your administrator');
        });
    }

      /****************************************
     * method to initialize AWS attributes
     *****************************************/

      initializeAwS3(confData) {
        
        const AWS = window.AWS;
    
        AWS.config.update({
          accessKeyId: confData.awsAccessKeyId, 
          secretAccessKey: confData.awsSecretAccessKey 
        });
        this.awS3 = new AWS.S3({
          apiVersion: SM_API_VERSION_AWS3,
          params: {
            Bucket: confData.s3bucketName 
          }
        });
        this.awS3Initialized = true;
      }

  /****************************************
     * method to get the selected file
     *****************************************/
    
  getSelectedFiles(event) {
   
    if (event.target.files.length > 0) {
        if (event.target.files.length > 0) {
                let file = event.target.files[0];
                this.selectedFilesToUpload=file;
                this.fileName = event.target.files[0].name;
              
              
        }}
  }

  /****************************************
     * Cloud document record creation method
     *****************************************/
   createCloudDocumentLwc(event){
    console.log('createCloudDocumentLwc-->');
    if(this.documentType == undefined){
      this.showToast('warning', 'You must select a document type');
      return;
    }

    if(this.selectedFilesToUpload == undefined){
      this.showToast('warning', 'You must select a file');
      return;
    }
    

     getPathParametersS3({fileName: this.selectedFilesToUpload.name,idObjct:this.recordId,documetType:this.documentType})
        .then(result => { 
        
           if(result != null ) {
            this.AwS3Path=result.path
            this.abbreviatedCompany=result.abbreviatedCompany
            let bucketparameters = {};

          bucketparameters = {
                              s3bucketName: result.bucketName,
                              awsAccessKeyId: result.key,
                              awsSecretAccessKey: result.secret
                              
          };
          this.initializeAwS3(bucketparameters); 
            console.log('bucketparameters-->'+bucketparameters);
            this.uploadToAWS();
          
          }else{
              this.showToast('error', 'There was a problem loading files');
              this.showHideSpinner();
            }
        })
        .catch(error => {
          this.showToast('error', 'There was a problem loading files ');
          this.showHideSpinner();
        });

  }

  /****************************************
     * Amazon file upload method
     *****************************************/
  uploadToAWS() {
   
  if (this.selectedFilesToUpload) {
      
    this.showHideSpinner();
    this.awS3.putObject(
      {
        Key: this.AwS3Path,
        ContentType: this.selectedFilesToUpload.type,
        Body: this.selectedFilesToUpload
      },
      err => {
        
        if (err) {
          this.selectedFilesToUpload=undefined;
          this.showHideSpinner();
          console.log("err"+err);
          this.showToast('error', 'An error occurred contact your administrator');
        } else {
          createCloudDocument({fileName: this.selectedFilesToUpload.name,idObjct:this.recordId,documetType:this.documentType,relationshipField:this.relationshipField,pathS3:this.AwS3Path,abbreviatedCompany:this.abbreviatedCompany})
          .then(result => { 
            if(result != null ) {
                eval("$A.get('e.force:refreshView').fire();");
                this.showHideSpinner();
                this.showToast('Success', 'Files uploaded Successfully');
            }else 
            {
              this.showToast('error', 'There was a problem loading files');
              this.showHideSpinner();
            }
            this.selectedFilesToUpload=undefined;
            this.fileName=undefined;
            this.documentType=undefined;
         })
         .catch(error => {
           this.selectedFilesToUpload=undefined;
           this.showToast('error', 'There was a problem loading files ');
           this.showHideSpinner();
         });
         
          
        }
      }
    );
  }
}



/****************************************
     * Method to show success or error message
     *****************************************/
    showToast(variant, message) {
      this.dispatchEvent(
          new ShowToastEvent({
              message: message,
              variant: variant,
          }),
      );
      this.showSpinner=false;
  }

  
    /****************************************
     * Method to switch value of showSpinner.
     *****************************************/
    showHideSpinner() {
      this.showSpinner = !this.showSpinner;
  }

 /****************************************
     * method that gets the types of documents
     *****************************************/
  optionsTypeFile(){
  
    getDocumetType()
      .then((result) => {
          let data=result;
       for(let i=0; i<data.length; i++)  {
          
           this.optionsTypeDocument = [...this.optionsTypeDocument ,{value: data[i] , label: data[i]} ];                                   
       }                
      })
      .catch((error) => {
        this.showToast('error', 'An error occurred contact your administrator');
      });

  }

 /****************************************
     * method that gets the selected document type
     *****************************************/

  handleChangeDocumentType(event){
    this.documentType=event.target.value;
   }

}