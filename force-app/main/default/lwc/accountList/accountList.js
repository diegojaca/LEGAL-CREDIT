import { LightningElement, api, track, wire } from 'lwc';
import getFieldsToShow from '@salesforce/apex/SM_AccountListItemController.getFieldsToShow';

export default class AccountList extends LightningElement {
    @api items;
    @track fields;

    @wire(getFieldsToShow)
    getFieldsToShow({error, data}) {
        if (data) {
            console.log('data:', JSON.stringify(data));
            this.fields = data;
        } else if (error) {
            console.log('error:', JSON.stringify(error));
        }
    }

    handleProcess(event) {
        console.log('accountList - handleProcess: ', JSON.stringify(event.detail));
        this.dispatchEvent(
            // To call, use attribute: onreassign (on + reassign).
            new CustomEvent('process', {detail: {selectedItemId: event.detail.selectedItemId}})
        );
    }

    handleClick() {
        console.log('accountList - handleClick: ');
    }
}