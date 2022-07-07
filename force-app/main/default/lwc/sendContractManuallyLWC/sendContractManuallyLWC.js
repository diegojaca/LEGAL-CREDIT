/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 02-11-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   02-10-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { finishFlow } from 'c/flowHelper';
import contractSentMessageLabel from '@salesforce/label/c.CONTRACT_SENT_MESSAGE';
import sendContract from '@salesforce/apex/SendContractMannuallyLWCController.sendContract';

/* eslint-disable no-debugger, no-console */
export default class SendContractManuallyLWC extends LightningElement {

    @api recordId;
    @track showSpinner = false;
    contractSentMessageLabel = contractSentMessageLabel;

    connectedCallback(){
        this.showHideSpinner();
        sendContract({
            contractId: this.recordId
        }).then(result => {
            this.showHideSpinner();
            console.log('result: ' + JSON.stringify(result));
            finishFlow(this);
            this.showToast('success', this.contractSentMessageLabel);
            // const closeQA = new CustomEvent('close');
            // this.dispatchEvent(closeQA);
        }).catch(error => {
            this.showHideSpinner();
            console.log('error: ', JSON.stringify(error));
            this.showToast('error', error.body.message);
        });
    }

    /****************************************
     * Method to show success or error message
     *****************************************/
    showToast(variant, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: message,
                variant: variant,
            }),
        );
    }

    /****************************************
     * Method to switch value of showSpinner.
     *****************************************/
    showHideSpinner() {
        this.showSpinner = !this.showSpinner;
    }
}