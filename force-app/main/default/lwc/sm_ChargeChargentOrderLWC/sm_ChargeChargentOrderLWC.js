/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * @group             :
 * @last modified on  : 07-24-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                Modification
 * 1.0   07-01-2021   Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com   Initial Version
 * 1.1   20-10-2021   Camilo A. Jimenez B -> cjimenez@legal-credit.com      Initial Version
**/
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, LightningElement, wire } from 'lwc';

//Labels
import CHARGUE_BUTTON_TITTLE from '@salesforce/label/c.CHARGUE_BUTTON_TITTLE';

//Chargent Order fields
import STATUS_CHARGENT_ORDER from '@salesforce/schema/ChargentOrders__ChargentOrder__c.ChargentOrders__Payment_Status__c';
import PAYMENT_TYPE_CHARGENT_ORDER from '@salesforce/schema/ChargentOrders__ChargentOrder__c.SM_Payment_Type__c';
import NEXT_TRANSACTION_DATE_CHARGENT_ORDER from '@salesforce/schema/ChargentOrders__ChargentOrder__c.ChargentOrders__Next_Transaction_Date__c';
import CONTRACT_STATUS from '@salesforce/schema/ChargentOrders__ChargentOrder__c.Contract__r.Status';
import APPROVAL_STATUS_CHARGENT_ORDER from '@salesforce/schema/ChargentOrders__ChargentOrder__c.SM_Approval_status__c';

//APEX METHODS
import chargeChargentOrder from '@salesforce/apex/SM_ChargentOrderHelper.chargeChargentOrder';

//Enum to toast variants types
const variantsToast = {
    ERROR: 'error',
    WARNING: 'warning',
    SUCCESS: 'success',
    INFO: 'info'
}

//Chargent Fields
const CHARGENT_ORDER_FIELDS = [
    STATUS_CHARGENT_ORDER, PAYMENT_TYPE_CHARGENT_ORDER, NEXT_TRANSACTION_DATE_CHARGENT_ORDER, APPROVAL_STATUS_CHARGENT_ORDER, CONTRACT_STATUS
];

export default class SM_ChargeChargentOrderLWC extends LightningElement {

    //labels to view
    label = { CHARGUE_BUTTON_TITTLE }

    @api
    recordId;

    showSpinner = false;

    //Get Chargent order data
    @wire(getRecord,{recordId: '$recordId', fields: CHARGENT_ORDER_FIELDS})
    chargentOrder;

    /**
    * @description This method handle onclik event
    * @author jpachon.ariza@gmail.com | 07-01-2021
    **/
    chargeOrderHandle(){
        console.log('Executing chargeOrder');
        this.showHideSpinner();
        console.log(this.chargentOrder.data);
        this.chargeOrder();
    }

    /**
    * @description This method return chargent order status
    * @author jpachon.ariza@gmail.com | 07-01-2021
    **/
    status() {
        return getFieldValue(this.chargentOrder.data, STATUS_CHARGENT_ORDER);
    }

    /**
    * @description This method return chargent order payment type
    * @author jpachon.ariza@gmail.com | 07-01-2021
    **/
    paymentType() {
        return getFieldValue(this.chargentOrder.data, PAYMENT_TYPE_CHARGENT_ORDER);
    }

    /**
    * @description This method return chargent order next transaction date
    * @author jpachon.ariza@gmail.com | 07-14-2021
    **/
    nextTransactionDate() {
        return getFieldValue(this.chargentOrder.data, NEXT_TRANSACTION_DATE_CHARGENT_ORDER);
    }

    /**
    * @description This method return chargent order approval status
    * @author jpachon.ariza@gmail.com | 07-24-2021
    **/
    approvalStatus() {
        return getFieldValue(this.chargentOrder.data, APPROVAL_STATUS_CHARGENT_ORDER);
    }

    /**
    * @description This method return the contract status
    * @author jpachon.ariza@gmail.com | 07-22-2021
    **/
    contractStatus() {
        return getFieldValue(this.chargentOrder.data, CONTRACT_STATUS);
    }

    /**
    * @description This method validate actions depending of chargent order data
    * @author jpachon.ariza@gmail.com | 07-01-2021
    **/
    chargeOrder(){
        console.log('contract status: ', this.contractStatus());
        // CJ 20-10-2021 SMPII-39
        if (this.status() === 'Canceled') {
            this.handleToast(variantsToast.WARNING, 'It\'s not possible to execute the payment because the Chargent Order is Canceled.');
            this.showHideSpinner();
            return;
        }
        if (this.status() === 'Complete') {
            this.handleToast(variantsToast.WARNING, 'It\'s not possible to execute the payment because the Chargent Order is completed.');
            this.showHideSpinner();
            return;
        }
        if (this.status() === 'Stopped' && this.paymentType() !== 'Late payment fee') {
            this.handleToast(variantsToast.WARNING, 'It\'s not possible to execute the collection because the Chargent Order is Stopped.');
            this.showHideSpinner();
            return;
        }
        if (this.contractStatus() === 'Finalized' || this.contractStatus() === 'Cancelled' || this.contractStatus() === 'Payment Rejection') {
            this.handleToast(variantsToast.WARNING, 'It\'s not possible to execute the charge because the Contract is Finalized/Canceled/Payment Rejection');
            this.showHideSpinner();
            return;
        }
        if (this.approvalStatus() === 'Pending approval') {
            this.handleToast(variantsToast.WARNING, 'Order pending approval cannot be charged');
            this.showHideSpinner();
            return;
        }
        this.createTransaction();
    }

    /**
    * @description This method create transaction
    * @author jpachon.ariza@gmail.com | 07-01-2021
    **/
    createTransaction(){
        const nextTransactionDate = this.nextTransactionDate();
        console.log('--->  ', nextTransactionDate);
        //Call apex method to create payment
        chargeChargentOrder({
            chargentOrderId: this.recordId,
            nextTransactionDate: nextTransactionDate
        })
        .then((data) => {
            this.showHideSpinner();
            console.log(data);
            console.log(JSON.stringify(data));
            if (data.success) {
                this.handleToast(variantsToast.SUCCESS, data.message);
                // updateRecord({fields: this.recordId});
            } else {
                this.handleToast(variantsToast.WARNING, data.message);
            }
            this.dispatchEvent(
                // Event to update record page
                new CustomEvent('refreshview', {detail: {selectedItemId: this.destinationSelected}})
            );
        })
        .catch((error) => {
            this.showHideSpinner();
            console.log(error);
            console.log(JSON.stringify(error));
            this.handleToast(variantsToast.WARNING, error);
        });

    }

    /**
    * @description This method show toast event
    * @author jpachon.ariza@gmail.com | 07-01-2021
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
    * @author jpachon.ariza@gmail.com | 07-01-2021
    **/
    showHideSpinner() {
        this.showSpinner = !this.showSpinner;
    }

}