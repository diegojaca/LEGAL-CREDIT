/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 12-10-2020
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   12-10-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
import { LightningElement, api, track } from 'lwc';

export default class SM_sObjectListLWC extends LightningElement {
    /** api variables **/
    @api sObjectName;
    @api items;
    @api fields;

    renderedCallback(){
        console.log('Nombre Object-> ' + this.sObjectName + ' items-> ' + this.items);
    }

    handleProcess(event) {
        this.dispatchEvent(
            // To call, use attribute: onreassign (on + reassign).
            new CustomEvent('process', {detail: {selectedItemId: event.detail.selectedItemId}})
        );
    }
}