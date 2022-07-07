/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * @group             :
 * @last modified on  : 08-05-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
**/
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, LightningElement, wire } from 'lwc';

//Labels
import CHARGUE_BUTTON_TITTLE from '@salesforce/label/c.CHARGUE_BUTTON_TITTLE';
import ACH_ORDER_COMPLEETED_STATUS from '@salesforce/label/c.ACH_ORDER_COMPLEETED_STATUS';
import ACH_ORDER_CANCELED_STATUS from '@salesforce/label/c.ACH_ORDER_CANCELED_STATUS';
import CANCELED_MESSAGE from '@salesforce/label/c.CANCELED_MESSAGE';
import ACH_ORDER_STOPED_STATUS from '@salesforce/label/c.ACH_ORDER_STOPED_STATUS';
import ACH_ORDER_TYPE_LATE_PAYMENT_FEE from '@salesforce/label/c.ACH_ORDER_TYPE_LATE_PAYMENT_FEE';
import STOPED_MESSAGE from '@salesforce/label/c.STOPED_MESSAGE';
import ACH_ORDER_INITIATED_STATUS from '@salesforce/label/c.ACH_ORDER_INITIATED_STATUS';
import ACH_ORDER_CREATED_STATUS from '@salesforce/label/c.ACH_ORDER_CREATED_STATUS';
import ACH_ORDER_PAYMENT_STATUS from '@salesforce/label/c.ACH_ORDER_PAYMENT_STATUS';
import ACH_ORDER_PENDING_STATUS from '@salesforce/label/c.ACH_ORDER_PENDING_STATUS';
import CREATED_PAYMENT_SUCCESS from '@salesforce/label/c.CREATED_PAYMENT_SUCCESS';
import STATUS_INVALID_MESSAGE from '@salesforce/label/c.STATUS_INVALID_MESSAGE';

//ACH Order fields
import ACH_OR_PAYMENT_STATUS from '@salesforce/schema/SM_ACH_Order__c.SM_Payment_Status__c';
import ACH_OR_PAYMENT_TYPE from '@salesforce/schema/SM_ACH_Order__c.SM_Payment_Type__c';
import CONTRACT_STATUS from '@salesforce/schema/SM_ACH_Order__c.SM_Contract__r.Status';
import APPROVAL_STATUS_ACH_ORDER from '@salesforce/schema/SM_ACH_Order__c.SM_Approval_status__c';

//APEX METHODS
import getAllCompanysSettings from '@salesforce/apex/SM_PaymentHelper.createPayment';

//Enum to toast variants types
const variantsToast = {
    ERROR: 'error',
    WARNING: 'warning',
    SUCCESS: 'success',
    INFO: 'info'
}

//ACH Fields
const ACH_OR_FIELDS = [
    ACH_OR_PAYMENT_STATUS, ACH_OR_PAYMENT_TYPE, APPROVAL_STATUS_ACH_ORDER, CONTRACT_STATUS
];

export default class SM_ChargueAchOrderLWC extends LightningElement {

    //labels to view
    label = { CHARGUE_BUTTON_TITTLE }

    @api
    recordId;

    showSpinner = false;

    //Get Ach order data
    @wire(getRecord,{recordId: '$recordId', fields: ACH_OR_FIELDS})
    achOrder;

    /**
    * @description This method handle onclik event
    * @author diego.jacanamijoy@gmail.com | 21-06-2021
    **/
    validationChargeAction(){
        this.showHideSpinner();
        this.validateStatus();
    }

    /**
    * @description This method return ach order status
    * @author diego.jacanamijoy@gmail.com | 21-06-2021
    **/
    status() {
        return getFieldValue(this.achOrder.data, ACH_OR_PAYMENT_STATUS);
    }

    /**
    * @description This method return ach order type
    * @author diego.jacanamijoy@gmail.com | 21-06-2021
    **/
    type() {
        return getFieldValue(this.achOrder.data, ACH_OR_PAYMENT_TYPE);
    }

    /**
    * @description This method return ach order type
    * @author diego.jacanamijoy@gmail.com | 21-06-2021
    **/
    approvalStatus() {
        return getFieldValue(this.achOrder.data, APPROVAL_STATUS_ACH_ORDER);
    }

    /**
    * @description This method return the contract status
    * @author jpachon.ariza@gmail.com | 07-22-2021
    **/
     contractStatus() {
        return getFieldValue(this.achOrder.data, CONTRACT_STATUS);
    }

    /**
    * @description This method validate actions depending of ach order data
    * @author diego.jacanamijoy@gmail.com | 21-06-2021
    **/
    validateStatus(){

        console.log('approval: ' + this.approvalStatus());

        const statusToCreatePayment = [ACH_ORDER_INITIATED_STATUS, ACH_ORDER_CREATED_STATUS, ACH_ORDER_PAYMENT_STATUS, ACH_ORDER_PENDING_STATUS];

        if (this.status() === ACH_ORDER_COMPLEETED_STATUS || this.status() === ACH_ORDER_CANCELED_STATUS){
            this.handleToast(variantsToast.WARNING, CANCELED_MESSAGE);
            this.showHideSpinner();
            return;
        }

        if (this.status() === ACH_ORDER_STOPED_STATUS && this.type() !== ACH_ORDER_TYPE_LATE_PAYMENT_FEE){
            this.handleToast(variantsToast.WARNING, STOPED_MESSAGE);
            this.showHideSpinner();
            return;
        }

        if (this.contractStatus() === 'Finalized' || this.contractStatus() === 'Cancelled' || this.contractStatus() === 'Payment Rejection') {
            this.handleToast(variantsToast.WARNING, 'It\'s not possible to execute the charge because the Contract is Finalized/Canceled/Payment Rejection');
            this.showHideSpinner();
            return;
        }

        if(this.approvalStatus() === 'Pending approval') {
            this.handleToast(variantsToast.WARNING, 'Order pending approval cannot be charged');
            this.showHideSpinner();
            return;
        }

        if(statusToCreatePayment.includes(this.status()) || (this.status() === ACH_ORDER_STOPED_STATUS && this.type() === ACH_ORDER_TYPE_LATE_PAYMENT_FEE)){
            this.createPayment();
            return;
        }

        //Not match before validations
        this.handleToast(variantsToast.WARNING, STATUS_INVALID_MESSAGE.replace('{0}', this.status()));

    }

    /**
    * @description This method create payment
    * @author diego.jacanamijoy@gmail.com | 23-06-2021
    **/
    createPayment(){
        //Call apex method to create payment
        getAllCompanysSettings({
            achOrderId: this.recordId
        })
        .then((data) => {
            this.showHideSpinner();
            if (data.Id){
                this.handleToast(variantsToast.SUCCESS, CREATED_PAYMENT_SUCCESS);
                this.dispatchEvent(
                    // Event to update record page
                    new CustomEvent('refreshview', {detail: {selectedItemId: this.destinationSelected}})
                );
            }
        })
        .catch((error) => {
            this.showHideSpinner();
            this.handleToast(variantsToast.ERROR, error.message);
        });
    }

    /**
    * @description This method show toast event
    * @author diego.jacanamijoy@gmail.com | 21-06-2021
    **/
    handleToast(variant, message){
    this.dispatchEvent(
        new ShowToastEvent({
            title: CHARGUE_BUTTON_TITTLE,
            message: message,
            variant: variant,
            }),
        );
    }

    /**
    * @description This method switch value of spinner
    * @author jpachon.ariza@gmail.com | 07-22-2021
    **/
     showHideSpinner() {
        this.showSpinner = !this.showSpinner;
    }

}