public without sharing class MatterTeamMemberHandler {
    
    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
    public static Boolean dontInvokeTrigger = false;
    public MatterTeamMemberHandler (boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    /*
        this method will disable trigger 
    */
    public static Boolean isDisabled(){
        litify_pm__Public_Setup__c  setting = litify_pm__Public_Setup__c.getOrgDefaults();
        return (setting != null && (setting.litify_pm__Run_Triggers__c == false || setting.Disable_Matter_Team_Sharing__c));
    }
    
   
    public void OnAfterInsert(List<litify_pm__Matter_Team_Member__c> l_new)  {
        Map<Id, Set<Id>> m_new_members = new Map<Id, Set<Id>>();
        for(litify_pm__Matter_Team_Member__c item : l_new){
            if(item.litify_pm__Matter__c != null && item.litify_pm__User__c != null) {
                Set<Id> s_new = m_new_members.get(item.litify_pm__Matter__c);
                if (s_new == null) {
                    s_new = new Set<Id>();
                }
                if (item.litify_pm__User__c != null) {
                    s_new.add(item.litify_pm__User__c);
                    m_new_members.put(item.litify_pm__Matter__c, s_new);    
                }
            }
        }
        if (m_new_members.size() > 0 ) {
            updateMatters(m_new_members, new Map<Id, Set<Id>>());
        }
    }
    
    public void OnAfterUpdate(List<litify_pm__Matter_Team_Member__c > l_old, List<litify_pm__Matter_Team_Member__c > l_new, Map<Id, litify_pm__Matter_Team_Member__c > m_old,  Map<Id, litify_pm__Matter_Team_Member__c > m_new)  {
        Map<Id, Set<Id>> m_new_members = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> m_old_members = new Map<Id, Set<Id>>();
        for(litify_pm__Matter_Team_Member__c item : l_new){
            if(item.litify_pm__Matter__c != null && 
                (item.litify_pm__User__c != m_old.get(item.Id).litify_pm__User__c )) {
                Set<Id> s_new = m_new_members.get(item.litify_pm__Matter__c);
                if (s_new == null) {
                    s_new = new Set<Id>();
                }
                if (item.litify_pm__User__c != null) {
                    s_new.add(item.litify_pm__User__c);
                    m_new_members.put(item.litify_pm__Matter__c, s_new);    
                }
                Set<Id> s_old = m_old_members.get(item.litify_pm__Matter__c);
                if (s_old == null) {
                    s_old = new Set<Id>();
                }
                if (m_old.get(item.Id).litify_pm__User__c  != null) {
                    s_old.add(m_old.get(item.Id).litify_pm__User__c );
                    m_old_members.put(item.litify_pm__Matter__c, s_old);    
                }                                      
            }
        }
        if (m_new_members.size() > 0 || m_old_members.size() > 0) {
            updateMatters(m_new_members , m_old_members);
        }
    }
    
    public void OnAfterDelete(List<litify_pm__Matter_Team_Member__c > l_old, Map<ID, litify_pm__Matter_Team_Member__c > m_old){ 
        
        Map<Id, Set<Id>> m_old_members = new Map<Id, Set<Id>>();
        for(litify_pm__Matter_Team_Member__c item : l_old){
            Set<Id> s_old = m_old_members.get(item.litify_pm__Matter__c);
            if (s_old == null) {
                s_old = new Set<Id>();
            }
            if (item.litify_pm__User__c  != null) {
                s_old.add(item.litify_pm__User__c );
                m_old_members.put(item.litify_pm__Matter__c, s_old);    
            }
        }
        if (m_old_members.size() > 0) {
            updateMatters(new Map<Id, Set<Id>>() , m_old_members);
        }
    }
    
    /*
        Update set matter team members on matter record 
    */
    public static void updateMatters(Map<Id, Set<Id>> m_new,  Map<Id, Set<Id>>  m_old) {
        if (m_new.size() > 0 ||  m_old.size() > 0) {
            Set<Id> s_mainSet = new Set<Id>();
            if (m_new.size() > 0 ) {
                s_mainSet.addAll(m_new.keySet());
            }
            if (m_old.size() > 0 ) {
                s_mainSet.addAll(m_old.keySet());
            }
            Map<Id, litify_pm__Matter__c> m_matters = new Map<Id, litify_pm__Matter__c>([SELECT ID, Private__c FROM litify_pm__Matter__c WHERE Id IN: s_mainSet]);
            if (s_mainSet.size() > 0) {
                List<ShareMatterRecordFromProcess.InputParam> l_params = new List<ShareMatterRecordFromProcess.InputParam> ();
                for (Id mId : s_mainSet) {
                    litify_pm__Matter__c matter = m_matters.get(mId);
                    Set<Id> s_new = m_new.get(mId);
                    Set<Id> s_old = m_old.get(mId);
                    if (
                        (s_new != null && s_new.size() > 0) 
                        || 
                        (s_old != null && s_old.size() > 0) 
                        ){
                        ShareMatterRecordFromProcess.InputParam param = new ShareMatterRecordFromProcess.InputParam();
                        param.matter_id = mId;
                        param.accessLevel = SharingUtilities.EDIT_LEVEL;
                        param.s_new_members = s_new;
                        param.s_old_members = s_old;
                        param.isPrivate = matter.Private__c;
                        l_params.add(param);
                    }
                }   
                if (l_params.size() > 0) {
                    ShareMatterRecordFromProcess.shareMatterRecord(l_params);
                }
            }
        }
    }
}