/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 03-18-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   03-06-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONNTRACT_OBJECT from '@salesforce/schema/Contract';
import ACCOUNT_ID_CONTRACT from '@salesforce/schema/Contract.AccountId';
import PHYSICAL_ADDRESS_CONTRACT from '@salesforce/schema/Contract.SM_Physical_address__c';
import PHYSICAL_ADDRESS_NAME_CONTRACT from '@salesforce/schema/Contract.SM_Physical_address__r.Name';
import POSTAL_ADDRESS_CONTRACT from '@salesforce/schema/Contract.SM_Postal_address__c';
import POSTAL_ADDRESS_NAME_CONTRACT from '@salesforce/schema/Contract.SM_Postal_address__r.Name';
import BILLING_ADDRESS_CONTRACT from '@salesforce/schema/Contract.SM_Billing_Address__c';
import BILLING_ADDRESS_NAME_CONTRACT from '@salesforce/schema/Contract.SM_Billing_Address__r.Name';

export default class ContractRelatedAddresses extends LightningElement {

    @api recordId;
    @track fieldsAndValues = [];

    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_ID_CONTRACT, PHYSICAL_ADDRESS_CONTRACT, PHYSICAL_ADDRESS_NAME_CONTRACT, POSTAL_ADDRESS_CONTRACT, POSTAL_ADDRESS_NAME_CONTRACT, BILLING_ADDRESS_CONTRACT, BILLING_ADDRESS_NAME_CONTRACT]})
    contract;

    @wire(getObjectInfo, { objectApiName: CONNTRACT_OBJECT })
    contractInfo({ data, error }) {
        if(data){
            console.log('this.contract.data: ' + JSON.stringify(this.contract.data));
            this.fieldsAndValues.push({
                Id: getFieldValue(this.contract.data, PHYSICAL_ADDRESS_CONTRACT),
                Name: getFieldValue(this.contract.data, PHYSICAL_ADDRESS_NAME_CONTRACT),
                Label: data.fields[PHYSICAL_ADDRESS_CONTRACT.fieldApiName].label,
                ApiName: PHYSICAL_ADDRESS_CONTRACT.fieldApiName,
                AccountId: getFieldValue(this.contract.data, ACCOUNT_ID_CONTRACT)
            });
            this.fieldsAndValues.push({
                Id: getFieldValue(this.contract.data, POSTAL_ADDRESS_CONTRACT),
                Name: getFieldValue(this.contract.data, POSTAL_ADDRESS_NAME_CONTRACT),
                Label: data.fields[POSTAL_ADDRESS_CONTRACT.fieldApiName].label,
                ApiName: POSTAL_ADDRESS_CONTRACT.fieldApiName,
                AccountId: getFieldValue(this.contract.data, ACCOUNT_ID_CONTRACT)
            });
            this.fieldsAndValues.push({
                Id: getFieldValue(this.contract.data, BILLING_ADDRESS_CONTRACT),
                Name: getFieldValue(this.contract.data, BILLING_ADDRESS_NAME_CONTRACT),
                Label: data.fields[BILLING_ADDRESS_CONTRACT.fieldApiName].label,
                ApiName: BILLING_ADDRESS_CONTRACT.fieldApiName,
                AccountId: getFieldValue(this.contract.data, ACCOUNT_ID_CONTRACT)
            });
        }
    }

    handleSelection(event){
        const selectedValue = this.fieldsAndValues.filter(function(val){
            return event.detail.addressType === val.Label;
        });
        const fields = {};
        fields['Id'] = this.recordId
        fields[selectedValue[0].ApiName] = event.detail.recordId;
        const recordInput = { fields };
        updateRecord(recordInput)
        .then( () => {
            console.log('success');
        }).catch( error => {
            console.log('error: ' + JSON.stringify(error));
        })

    }

    handleRemove(event){
        const selectedValue = this.fieldsAndValues.filter(function(val){
            return event.detail.addressType === val.Label;
        });
        const fields = {};
        fields['Id'] = this.recordId
        fields[selectedValue[0].ApiName] = '';
        const recordInput = { fields };
        updateRecord(recordInput)
        .then( () => {
            console.log('success');
        }).catch( error => {
            console.log('error: ' + JSON.stringify(error));
        })
    }

}