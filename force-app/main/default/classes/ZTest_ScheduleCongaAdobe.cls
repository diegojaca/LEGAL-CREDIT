/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 04-10-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   04-10-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
global without sharing class ZTest_ScheduleCongaAdobe implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ZTest_BatchCongaAdobe());
    }
}