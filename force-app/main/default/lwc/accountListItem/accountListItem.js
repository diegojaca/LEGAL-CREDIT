import { LightningElement, api, track, wire } from 'lwc';
// import getFieldsToShow from '@salesforce/apex/SM_AccountListItemController.getFieldsToShow';

export default class AccountListItem extends LightningElement {

    @api item;
    @api fields;
    @track showFields = true;
    @track value = '';
    @track isChecked = false;

    connectedCallback() {
        console.log('accountListItem - item: ', JSON.stringify(this.item));
    }

    // @wire(getFieldsToShow)
    // getFieldsToShow({error, data}) {
    //     if (data) {
    //         console.log('data:', JSON.stringify(data));
    //         this.fields = data;
    //     } else if (error) {
    //         console.log('error:', JSON.stringify(error));
    //     }
    // }

    handleRadioChange() {
        console.log('handleRadioChange: ', JSON.stringify(this.item));
        this.dispatchEvent(
            // To call, use attribute: onreassign (on + reassign).
            new CustomEvent('process', {detail: {selectedItemId: this.item.Id}})
        );
    }
}