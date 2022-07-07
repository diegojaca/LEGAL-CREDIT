/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 01-05-2021
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                     Modification
 * 1.0   11-11-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

//Apex methods
import getAllCompanysSettings from '@salesforce/apex/SM_searchLeadLWCController.getAllCompanysSettings';
import validateDuplicates from '@salesforce/apex/SM_searchLeadLWCController.validateDuplicates';
import unifyLeads from '@salesforce/apex/SM_searchLeadLWCController.unifyLeads';
import unifyAccountWithLead from '@salesforce/apex/SM_searchLeadLWCController.unifyAccountWithLead';
import createTrackingInbound from '@salesforce/apex/SM_searchLeadLWCController.createTrackingInbound'

//Labels
import DESTINATION_LABEL from '@salesforce/label/c.DESTINATION_LABEL';
import SELECT_DESTINATION from '@salesforce/label/c.SELECT_DESTINATION';
import SAVE_LEAD_BUTTON from '@salesforce/label/c.SAVE_LEAD_BUTTON';
import CANCEL_BUTTON from '@salesforce/label/c.CANCEL_BUTTON';
import CANCEL_OPTION_TITLE from '@salesforce/label/c.CANCEL_OPTION_TITLE';
import EMAIL_OR_PHONE_MESSAGE from '@salesforce/label/c.EMAIL_OR_PHONE_MESSAGE';
import SELECT_DUPLICATE_TITLE from '@salesforce/label/c.SELECT_DUPLICATE_TITLE';
import NEW_LEAD_SUCCESS from '@salesforce/label/c.NEW_LEAD_SUCCESS';
import MUST_SELECT_RECORD_TITLE from '@salesforce/label/c.MUST_SELECT_RECORD_TITLE';
import UNIFIED_RECORDS_SUCCESS from '@salesforce/label/c.UNIFIED_RECORDS_SUCCESS';

//Lead data
import LEAD_OBJECT from '@salesforce/schema/Lead';

//Enum to toast variants types
const variantsToast = {
    ERROR: 'error',
    WARNING: 'warning',
    SUCCESS: 'success',
    INFO: 'info'
}

export default class SM_searchLeadLWC extends NavigationMixin(LightningElement) {
    
    //Label object
    label = { DESTINATION_LABEL, SELECT_DESTINATION, SAVE_LEAD_BUTTON, CANCEL_BUTTON, CANCEL_OPTION_TITLE }

    leadObject = LEAD_OBJECT;

    @track myLead = { 'sobjectType': 'Account' };

    //Traking atributes
    @track requiredFieldsByCompany = [];

    //Local variables
    @track destinationBusinessOptions = [];
    @track items;

    destinationSelected;
    destinationSelectedAux;
    valueDefaultTrue = true;
    viewDuplicates = false;
    leadFields = ['Name', 'Phone', 'Email', 'LeadSource'];
    accountFields = ['Name', 'Phone', 'PersonEmail'];
    fields;
    titleDuplicates;
    newLeadId;
    duplicateSelected;
    sObjectName;
    showSpinner = false;

    /** Call apex method getAllCompanysSettings */
    @wire(getAllCompanysSettings)
    companySettings;

    /**
    * @description This method set default values to true
    * @author diego.jacanamijoy@gmail.com | 11-14-2020 
    * @param event 
    **/
    handleSubmit (event) {
        event.preventDefault(); // stop the form from submitting
        const fields = event.detail.fields;
        fields.SM_Call_Inbound__c = true;
        fields.SM_ManuallyCreated__c = true;
        //validate if set values in phone or email
        if(fields.Phone || fields.Email){
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }else{
            this.handleToast(variantsToast.ERROR, EMAIL_OR_PHONE_MESSAGE);
        }
    }
    
    /**
    * @description This method validate change in destination select options
    * @author diego.jacanamijoy@gmail.com | 11-14-2020 
    * @param event 
    **/
    handleChange(event){
        this.destinationSelected = event.target.value;
        this.requiredFieldsByCompany = [];
        //call method to get required fields
        if(this.destinationSelected){
            this.destinationSelectedAux = this.destinationSelected;
            this.getRequiredsFieldsByCompany();
        }
    }

    /**
    * @description This method return required fields by company and show fields
    * @author diego.jacanamijoy@gmail.com | 11-14-2020 
    * @param  
    **/
    getRequiredsFieldsByCompany(){
        if(this.companySettings && this.companySettings.data){
            let companySetting = this.companySettings.data.find(element => element.Name === this.destinationSelected);
            if(companySetting.SM_Required_fields__c){
                this.requiredFieldsByCompany = companySetting.SM_Required_fields__c.split(';');
            }
        }
    }

    /**
    * @description This method is executed when success create Lead
    * @author diego.jacanamijoy@gmail.com | 11-26-2020 
    * @param event 
    **/
    handleSuccess(event){
        this.showSpinner = true;
        this.newLeadId = event.detail.id;
        //call method to search duplicates
        this.validateDuplicates(event.detail.id);  
    }

    /**
    * @description This method validate duplicates
    * @author diego.jacanamijoy@gmail.com | 11-26-2020 
    * @param event 
    **/
    validateDuplicates(leadId){
        validateDuplicates({
            leadId: leadId,
            companyName: this.destinationSelected
        })
        .then((data) => {
            this.validateDuplicateType(data);
        });
    }

    /**
    * @description This validate if has Leads or Accounts duplicates
    * @author diego.jacanamijoy@gmail.com | 11-14-2020 
    * @param event 
    **/
    validateDuplicateType(data){
        this.showSpinner = false;
        if(data && data.hasDuplicates === true){
            this.items = data.duplicates;
            this.viewDuplicates = true;
            this.sObjectName = data.sObjectName;
            if(data.sObjectName === 'Lead'){
                this.fields = this.leadFields;
                this.titleDuplicates = SELECT_DUPLICATE_TITLE.replace('{0}', 'Lead');
            }else if(data.sObjectName === 'Account'){
                this.fields = this.accountFields;
                this.titleDuplicates = SELECT_DUPLICATE_TITLE.replace('{0}', 'Account');
            }
        }else {
            this.showNewLeadSuccess(true);
        }
    }

    /**
    * @description This redirect to new lead record
    * @author diego.jacanamijoy@gmail.com | 11-14-2020 
    * @param event 
    **/
    showNewLeadSuccess(hasTracking){
        //Call apex method to create trackin record, if has not
        if(hasTracking === undefined || hasTracking !== true){
            createTrackingInbound({
                leadId: this.newLeadId,
                companyName: this.destinationSelected
            });
        }
        
        this.resetValues();
        //Show toas message
        this.handleToast(variantsToast.SUCCESS, NEW_LEAD_SUCCESS);
        //Navigate new Lead
        this.navigateToRecord(this.newLeadId);
    }

    /**
    * @description This method reset values of form
    * @author diego.jacanamijoy@gmail.com | 11-26-2020 
    * @param  
    **/
    resetValues(){
        this.showSpinner = false;
        this.viewDuplicates = false;
        this.destinationSelected = '';
        this.requiredFieldsByCompany = [];
        //reset all fields of form
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
        this.closeUtilBar();
    }

    /**
    * @description This method close utilbar new lead
    * @author diego.jacanamijoy@gmail.com | 12-21-2020 
    * @param  
    **/
    closeUtilBar() {
        this.dispatchEvent(
            // To call, use attribute: onreassign (on + reassign).
            new CustomEvent('closeUtilBar', {detail: {selectedItemId: this.destinationSelected}})
        );
    }

    /**
    * @description This method if executed when check a duplicate
    * @author diego.jacanamijoy@gmail.com | 11-26-2020 
    * @param event 
    **/
    handleProcess(event){
        this.duplicateSelected = event.detail.selectedItemId;
    }

    /**
    * @description This method call apex method to unify records
    * @author diego.jacanamijoy@gmail.com | 11-26-2020 
    * @param event 
    **/
    unifyRecords(){
        this.showSpinner = true;
        if(this.duplicateSelected){
            if(this.sObjectName === 'Lead'){
                this.unifyLeads();
            }else if(this.sObjectName === 'Account'){
                this.unifyLeadWithAccount();
            }
        }else{
            this.showSpinner = false;
            this.handleToast(variantsToast.ERROR, MUST_SELECT_RECORD_TITLE);
        }
    }

    /**
    * @description This method call apex method to unify Leads
    * @author diego.jacanamijoy@gmail.com | 11-26-2020 
    * @param event 
    **/
    unifyLeads(){
        const duplicate = this.items.find(element => element.Id === this.duplicateSelected);
        unifyLeads({
            newLeadId: this.newLeadId,
            duplicate: duplicate,
            companyName: this.destinationSelectedAux
        })
        .then((data) => {
            this.resetValues();
            this.handleToast(variantsToast.SUCCESS, UNIFIED_RECORDS_SUCCESS);
            this.navigateToRecord(data);
        });
    }

    /**
    * @description This method call apex method to unify Lead with Account
    * @author diego.jacanamijoy@gmail.com | 11-26-2020 
    * @param event 
    **/
    unifyLeadWithAccount(){
        const duplicate = this.items.find(element => element.Id === this.duplicateSelected);
        unifyAccountWithLead({
            newLeadId: this.newLeadId,
            duplicate: duplicate,
            opportunities: duplicate.Opportunities,
            companyName: this.destinationSelectedAux
        })
        .then((data) => {
            this.resetValues();
            this.handleToast(variantsToast.SUCCESS, UNIFIED_RECORDS_SUCCESS);
            this.navigateToRecord(data);
        });
    }

    /**
    * @description This method dispached event to navegate
    * @author diego.jacanamijoy@gmail.com | 11-26-2020 
    * @param event 
    **/
    navigateToRecord(recordId){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
            },
        });
    }

    /**
    * @description This method show toast event
    * @author diego.jacanamijoy@gmail.com | 11-17-2020 
    **/
    handleToast(variant, message){
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'New Lead',
            message: message,
            variant: variant,
            }),
        );
    }
}