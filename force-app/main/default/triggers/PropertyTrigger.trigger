trigger PropertyTrigger on Property__c (before insert, after insert, before update, after update, before delete, after undelete) {
    rflib_TriggerManager.dispatch(Property__c.SObjectType);   
}