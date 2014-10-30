trigger UserTrigger on User (before insert, after insert,
                             before delete, after delete,
                             before update, after update,
                             after undelete) {

    UserTriggerHandler handler = new UserTriggerHandler();

    if (Trigger.isInsert && Trigger.isBefore) {
        //Handler for before insert
        handler.OnBeforeInsert(Trigger.new);
    }
    else if (Trigger.isInsert && Trigger.isAfter) {
        //Handler for after insert
        handler.OnAfterInsert(Trigger.new);
    }
    else if (Trigger.isUpdate && Trigger.isAfter) {
        //Handler for after update trigger
        handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }
    else if (Trigger.isUpdate && Trigger.isBefore) {
        //Handler for before update trigger
        handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
}