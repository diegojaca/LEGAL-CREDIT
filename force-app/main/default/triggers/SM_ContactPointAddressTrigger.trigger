/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 03-02-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   03-02-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
trigger SM_ContactPointAddressTrigger on ContactPointAddress (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Call handler class to execute
    SM_ContactPointAddressHandler handler = new SM_ContactPointAddressHandler('SM_ContactPointAddressTrigger');
    handler.run();
}