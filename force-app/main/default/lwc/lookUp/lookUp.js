/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 07-24-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   02-27-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
import searchAddresses from '@salesforce/apex/SM_LookupController.searchAddresses';
import { api, LightningElement, track, wire } from 'lwc';


export default class LookUp extends LightningElement {

    @api iconName;
    @api filter = '';
    @api searchPlaceholder='Search';
    @api addressType;

    @api selectedId;
    @api selectedName;
    @api accountId;

    @track selectedName;
    @track records;
    @track isValueSelected;
    @track blurTimeout;

    searchTerm;
    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = '';

    connectedCallback(){
        if (this.selectedId) {
            this.isValueSelected = true;
        }
    }

    @wire(searchAddresses, {searchTerm : '$searchTerm', addressType : '$addressType', accountId: '$accountId'})
    wiredRecords({ error, data }) {
        if (data) {
            this.error = undefined;
            this.records = data;
        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }


    handleClick() {
        this.searchTerm = '';
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
    }

    onBlur() {
        this.blurTimeout = setTimeout(() =>  {this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus'}, 300);
    }

    onSelect(event) {
        this.selectedId = event.currentTarget.dataset.id;
        this.selectedName = event.currentTarget.dataset.name;
        const valueSelectedEvent = new CustomEvent('lookupselected', {detail:  { recordId: this.selectedId, addressType: this.addressType} });
        this.dispatchEvent(valueSelectedEvent);
        this.isValueSelected = true;
        // this.selectedName = selectedName;
        if(this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    }

    handleRemovePill(event) {
        this.isValueSelected = false;
        const removeSelectedEvent = new CustomEvent('removeselected', {detail: {addressType: this.addressType}});
        this.dispatchEvent(removeSelectedEvent);
    }

    onChange(event) {
        console.log('Executing onChange: ' + event.target.value);
        this.searchTerm = event.target.value;
    }

}