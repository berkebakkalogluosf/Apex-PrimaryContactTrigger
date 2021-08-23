trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        ContactTriggerHandler.handleBefore(Trigger.New, Trigger.oldMap);
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ContactTriggerHandler.handleAfterInsert(Trigger.New);
        }
        
        if (Trigger.isUpdate) {
            ContactTriggerHandler.handleAfterUpdate(Trigger.New, Trigger.oldMap);
        }
    }
}