/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 11-18-2020
 * @last modified by  : diego.jacanamijoy@gmail
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-17-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';

//Lead data
import LEAD_ID_FIELD from '@salesforce/schema/Lead.Id';

//Labels 
import TAKE_RECORD_TITLE from '@salesforce/label/c.TAKE_RECORD_TITLE';
import TAKE_RECORD_SUCCESS from '@salesforce/label/c.TAKE_RECORD_SUCCESS';

//Apex methods
import changeRecordOwner from '@salesforce/apex/SM_TakeRecordLWCController.changeRecordOwner';

//Enum to toast variants types
const variantsToast = {
    ERROR: 'error',
    WARNING: 'warning',
    SUCCESS: 'success',
    INFO: 'info'
}

export default class SM_takeRecordLWC extends LightningElement {
    
    //Label object by view
    Label = {
        TAKE_RECORD_TITLE
    }
    
    showSpinner = false;

    //Apis variables
    @api recordId;

    /**
    * @description This method call apex method by change record owner
    * @author diego.jacanamijoy@gmail.com | 11-17-2020 
    **/
    changeRecordOwner(){
        changeRecordOwner({
            recordId : this.recordId
        })
        .then(() => {
            this.showSpinner = false;
            this.handleToast(variantsToast.SUCCESS, TAKE_RECORD_SUCCESS);
            //Update Lead, to execute refresh apex
            const fields = {};
            fields[LEAD_ID_FIELD.fieldApiName] = this.recordId;
            const recordInput = { fields };
            updateRecord(recordInput)
            //Refresh Lead record page
            return refreshApex(this.recordId);
        })
        .catch((error) => {
            this.showSpinner = false;
            this.handleToast(variantsToast.ERROR, error.body.message);
        })
    }

    /**
    * @description This method show toast event
    * @author diego.jacanamijoy@gmail.com | 11-17-2020 
    **/
    handleToast(variant, message){
        this.dispatchEvent(
            new ShowToastEvent({
                title: TAKE_RECORD_TITLE,
                message: message,
                variant: variant,
            }),
        );
    }

}