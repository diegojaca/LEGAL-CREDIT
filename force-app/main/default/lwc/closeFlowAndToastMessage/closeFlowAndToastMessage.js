/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 02-11-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   02-11-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { finishFlow } from 'c/flowHelper';

export default class CloseFlowAndToastMessage extends LightningElement {

    @api title;
    @api message;
    @api variant;
    @api mode;

    connectedCallback() {
        finishFlow(this);
        this.showToast(this.variant, this.message, this.title, this.mode);
    }

    /****************************************
     * Method to show success or error message
     *****************************************/
    showToast(variant, message, title, mode) {
        console.log('variant: ', variant);
        console.log('message: ', message);
        console.log('title: ', title);
        console.log('mode: ', mode);
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
            }),
        );
    }
}