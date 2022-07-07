trigger SM_DisputeTrigger on SM_Dispute__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Call handler class to execute
    SM_DisputeHandler disputeHandler = new SM_DisputeHandler('SM_DisputeTrigger');
    disputeHandler.run();
}