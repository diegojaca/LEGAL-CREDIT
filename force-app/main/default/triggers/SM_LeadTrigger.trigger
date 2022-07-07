/**
 * @description       : Trigger of Lead Object
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 11-19-2020
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-19-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
trigger SM_LeadTrigger on Lead (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Call handler class to execute
    SM_LeadHandler leadHd = new SM_LeadHandler('SM_LeadTrigger');
    leadHd.run();
}