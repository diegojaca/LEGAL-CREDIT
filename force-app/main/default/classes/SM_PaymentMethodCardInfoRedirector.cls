public with sharing class SM_PaymentMethodCardInfoRedirector {
    public String Id {get;set;}
    public SM_PaymentMethodCardInfoRedirector(ApexPages.StandardController ctr) {        
        System.debug(ctr.getId());
        Id = [SELECT SM_Chargent_Order__c FROM SM_Payment_Method__c WHERE Id=:ctr.getId()].SM_Chargent_Order__c;
        redirect();
    }


    public PageReference redirect() {
        PageReference requestPage = new pagereference('/apex/ChargentOrders__CardStatusIndicator');
        requestPage.getParameters().put('Id', Id);
        requestPage.setRedirect(true);
        return requestPage;
    }
}