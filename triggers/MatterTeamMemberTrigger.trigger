trigger MatterTeamMemberTrigger on litify_pm__Matter_Team_Member__c (after insert, after update, after delete) {
    if(MatterTeamMemberHandler.isDisabled()) {
        return;
    }
    if(MatterTeamMemberHandler.dontInvokeTrigger){
        System.debug('Trigger was stopped with Boolean variable');
        return;
    } 
    MatterTeamMemberHandler handler = new MatterTeamMemberHandler(Trigger.isExecuting, Trigger.size);
    if(Trigger.isInsert&& Trigger.isAfter){
        handler.OnAfterInsert(Trigger.new);
    }  
    else if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }   
    else if(Trigger.isAfter && Trigger.isDelete){
        handler.OnAfterDelete(Trigger.old,Trigger.oldMap);
    } 
}