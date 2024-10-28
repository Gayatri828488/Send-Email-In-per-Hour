trigger ContactTrigger on Contact (after insert) {
    if(trigger.isAfter && trigger.isInsert){
        ContactTriggerHandler.updateAssociatedAccount(trigger.new);
    }
}