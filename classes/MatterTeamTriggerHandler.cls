public class MatterTeamTriggerHandler {
    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
    
    public MatterTeamTriggerHandler(boolean isExecuting, integer size) {
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    /*
        this method will disable trigger 
    */
    public static Boolean isDisabled(){
        litify_pm__Public_Setup__c  setting = litify_pm__Public_Setup__c.getOrgDefaults();
        return (setting != null && (setting.litify_pm__Run_Triggers__c == false));
    }
    
    public void OnAfterInsert(List<litify_pm__Matter_Team_Member__c> l_new)  {
       
        List<sObject> l_sharingRecords = new List<sObject>();
        for(litify_pm__Matter_Team_Member__c item : l_new){
            if(item.litify_pm__Matter__c  != null && item.litify_pm__User__c != null) {
                String objectName = 'litify_pm__Matter__Share';
                Schema.SObjectType shareObject = Schema.getGlobalDescribe().get(objectName);
                if (shareObject != null) {
                    SObject newSharing = shareObject.newSObject();
                    newSharing.put('ParentId', item.litify_pm__Matter__c);
                    newSharing.put('UserOrGroupId', item.litify_pm__User__c);
                    newSharing.put('AccessLevel', item.Sharing_Access__c);
                    newSharing.put('RowCause', 'Manual');
                    l_sharingRecords.add(newSharing);                    
                }
            }
        }
        
        if (l_sharingRecords.size() > 0 ) {
            List<Database.saveresult> l_srt = Database.insert(l_sharingRecords, false);
            for (Database.SaveResult sr : l_srt) {
                if (sr.isSuccess()) {
                    System.debug('Successfully created sharing rule. Sharing ID: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Sharing rule that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
    
    public void OnAfterUpdate(List<litify_pm__Matter_Team_Member__c > l_old, List<litify_pm__Matter_Team_Member__c > l_new, Map<Id, litify_pm__Matter_Team_Member__c > m_old,  Map<Id, litify_pm__Matter_Team_Member__c > m_new)  {
        List<sObject> l_sharingRecords = new List<sObject>();
        Map<Id, Set<Id>>  m_user = new Map<Id, Set<Id>> ();
        Set<Id> s_userIds = new Set<Id>();
        for(litify_pm__Matter_Team_Member__c item : l_new){
            if(item.litify_pm__Matter__c  != null && item.litify_pm__User__c != null && (
                item.litify_pm__User__c != m_old.get(item.Id).litify_pm__User__c || 
                item.litify_pm__Matter__c != m_old.get(item.Id).litify_pm__Matter__c ) )   {
                String objectName = 'litify_pm__Matter__Share';
                Schema.SObjectType shareObject = Schema.getGlobalDescribe().get(objectName);
                if (shareObject != null) {
                    SObject newSharing = shareObject.newSObject();
                    newSharing.put('ParentId', item.litify_pm__Matter__c);
                    newSharing.put('UserOrGroupId', item.litify_pm__User__c);
                    newSharing.put('AccessLevel', item.Sharing_Access__c);
                    newSharing.put('RowCause', 'Manual');
                    l_sharingRecords.add(newSharing);                    
                }
                s_userIds.add(m_old.get(item.Id).litify_pm__User__c);
                Set<Id> s_temp = m_user.get(m_old.get(item.Id).litify_pm__Matter__c);
                if (s_temp == null) {
                    s_temp = new Set<Id>();
                }
                s_temp.add(m_old.get(item.Id).litify_pm__User__c);
                m_user.put(m_old.get(item.Id).litify_pm__Matter__c, s_temp);
            }
        }
        if (l_sharingRecords.size() > 0 ) {
            List<Database.saveresult> l_srt = Database.insert(l_sharingRecords, false);
            for (Database.SaveResult sr : l_srt) {
                if (sr.isSuccess()) {
                    System.debug('Successfully created sharing rule. Sharing ID: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Sharing rule that affected this error: ' + err.getFields());
                    }
                }
            }
        }
        if (s_userIds.size() > 0) {
            List<litify_pm__Matter__Share> l_recordTodelete = new List<litify_pm__Matter__Share>();
            for (litify_pm__Matter__Share item : [SELECT ID, ParentId,UserOrGroupId  FROM litify_pm__Matter__Share WHERE ParentId IN : m_user.keySet() AND UserOrGroupId IN : s_userIds]) {
                Set<Id> s_temp = m_user.get(item.ParentId);
                for (Id userId : s_temp) {
                    if (item.UserOrGroupId  == userId){
                        l_recordTodelete.add(item);
                    } 
                }
            }
            delete l_recordTodelete;      
        }
    }
    
    public void OnAfterDelete(List<litify_pm__Matter_Team_Member__c> l_old, Map<ID, litify_pm__Matter_Team_Member__c> m_old){ 
        Map<Id, Set<Id>>  m_user = new Map<Id, Set<Id>> ();
        Set<Id> s_userIds = new Set<Id>();
        for(litify_pm__Matter_Team_Member__c item : l_old){
            s_userIds.add(item.litify_pm__User__c);
            Set<Id> s_temp = m_user.get(item.litify_pm__Matter__c);
            if (s_temp == null) {
                s_temp = new Set<Id>();
            }
            s_temp.add(item.litify_pm__User__c);
            m_user.put(item.litify_pm__Matter__c, s_temp);
            
        }
        List<litify_pm__Matter__Share> l_recordTodelete = new List<litify_pm__Matter__Share>();
        Map<Id, litify_pm__Matter__c> m_matters = new Map<Id, litify_pm__Matter__c> ([SELECT ID, OwnerId FROM litify_pm__Matter__c WHERE Id IN: m_user.keySet()]);
        for (litify_pm__Matter__Share item : [SELECT ID, ParentId,UserOrGroupId FROM litify_pm__Matter__Share WHERE ParentId IN : m_user.keySet() AND UserOrGroupId IN : s_userIds]) {
            Set<Id> s_temp = m_user.get(item.ParentId);
            litify_pm__Matter__c matter = m_matters.get(item.ParentId);
            for (Id userId : s_temp) {
                if (item.UserOrGroupId  == userId && matter.OwnerId != userId){
                    l_recordTodelete.add(item);
                } 
            }
        }
        delete l_recordTodelete;                              
    }
    
}