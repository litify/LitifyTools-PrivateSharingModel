trigger MatterTeamTrigger on litify_pm__Matter_Team_Member__c (after insert, after update, after delete) {
    litify_pm__Public_Setup__c  setting = litify_pm__Public_Setup__c.getOrgDefaults();
    if (setting != null && setting.Disable_Matter_Team_Sharing_Rules__c) {
        return;
    }
    MatterTeamTriggerHandler handler = new MatterTeamTriggerHandler(Trigger.isExecuting, Trigger.size);

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