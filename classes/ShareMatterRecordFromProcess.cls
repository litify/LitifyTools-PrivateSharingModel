public with sharing class ShareMatterRecordFromProcess {
    @InvocableMethod(label='Share Matter Record With Team Members')
    public static void shareMatterRecord(List<InputParam> l_inputParams) {
        String matterobject = litify_pm__Matter__c.getSobjectType().getDescribe().getName();
        Schema.SObjectType matterShareObject = Schema.getGlobalDescribe().get(matterobject.replace('__c', '__Share'));
        if (matterShareObject == null) {
            matterShareObject = Schema.getGlobalDescribe().get(matterobject+'Share');
        }
        if (matterShareObject != null) {
            List<sObject> l_matterSharingRecords = new List<sObject>();
            Set<Id> s_matterIds = new Set<Id>();
            Map<Id,litify_pm__Matter__c> m_matters = new Map<Id, litify_pm__Matter__c>();
            Map<Id, InputParam> m_params = new Map<Id, InputParam>();
            for (InputParam param : l_inputParams) {
                if (param.matter_id != null) {
                    s_matterIds.add(param.matter_id);
                    m_params.put(param.matter_id, param);
                }
            }
            
            m_matters = SharingUtilities.getMatters(s_matterIds);
            String accessLevel = 'Edit';
            Set<Id> s_old_members = new Set<Id>();
            for (InputParam param : l_inputParams) {
                if (String.isNotBlank(param.accessLevel)) {
                    accessLevel = param.accessLevel;
                }
                litify_pm__Matter__c matter = m_matters.get(param.matter_id);
                if (matter != null && matter.litify_pm__Matter_Teams__r.size() > 0) {
                    if (matterShareObject != null) {
                        for (litify_pm__Matter_Team_Member__c member : matter.litify_pm__Matter_Teams__r) {
                            if (member.litify_pm__User__r.isActive && member.litify_pm__User__c != matter.OwnerId && (param.s_new_members == null || param.s_new_members.contains(member.litify_pm__User__c))) {
                                system.debug('member.litify_pm__User__c==='+member.litify_pm__User__c);
                                l_matterSharingRecords.add(
                                    SharingUtilities.fillSharingRecords(
                                        matterShareObject,
                                        matter.Id,
                                        member.litify_pm__User__c,
                                        accessLevel
                                    )
                                );
                            }
                        }
                    }
                }
                if (param.s_old_members != null && param.s_old_members.size() > 0) {
                    s_old_members.addAll(param.s_old_members);
                }
            }
            if (l_matterSharingRecords.size() > 0 ) {
                SharingUtilities.insertSharingRecords(l_matterSharingRecords);
            }
            if (s_old_members.size() > 0) {
                List<sObject> l_delete = Database.query('SELECT ID FROM '+matterShareObject+' WHERE ParentId IN:s_matterIds  AND UserOrGroupId IN :s_old_members');
                SharingUtilities.deleteSharingRecords(l_delete);
            }
            
            
            List<Matter_Sharing_Setting__mdt> l_settings = [SELECT Matter_Field__r.QualifiedApiName, Object_Name__r.QualifiedApiName,Private_Field__r.QualifiedApiName  FROM  Matter_Sharing_Setting__mdt];
            if (l_settings.size() > 0) {
                Map<String, Schema.SObjectType> m_global = Schema.getGlobalDescribe();
                for (Matter_Sharing_Setting__mdt setting : l_settings) {
                    Schema.SObjectType objectType= m_global.get(setting.Object_Name__r.QualifiedApiName);
                    if (objectType != null) {
                        SObjectField matterField = objectType.getDescribe().fields.getMap().get(setting.Matter_Field__r.QualifiedApiName);
                        if (matterField != null) {
                            String objectName = setting.Object_Name__r.QualifiedApiName;
                            Schema.SObjectType shareObject = Schema.getGlobalDescribe().get(objectName.replace('__c', '__Share'));
                            if (shareObject == null) {
                                shareObject = Schema.getGlobalDescribe().get(objectName+'Share');
                            }
                            if (shareObject != null) {
                                system.debug('shareObject==='+shareObject);
                                Map<Id,sObject> m_relatedRecords = new Map<Id,sObject>(Database.query('SELECT ID, OwnerId, '+setting.Matter_Field__r.QualifiedApiName+', '+setting.Private_Field__r.QualifiedApiName+' FROM '+setting.Object_Name__r.QualifiedApiName+' WHERE '+setting.Matter_Field__r.QualifiedApiName+' IN :s_matterIds'));
                                if (m_relatedRecords != null) {
                                    List<sObject> l_recordsForUpdate = new List<sObject>();
                                    for (sObject rec : m_relatedRecords.values()) {
                                        InputParam param = m_params.get((Id)rec.get(setting.Matter_Field__r.QualifiedApiName));
                                        if (param != null && param.isPrivate != rec.get(setting.Private_Field__r.QualifiedApiName)){
                                            rec.put(setting.Private_Field__r.QualifiedApiName, param.isPrivate);
                                            l_recordsForUpdate.add(rec);
                                        }
                                    }
                                    if (l_recordsForUpdate.size() >0 ) {
                                        update l_recordsForUpdate;
                                    }
                                    List<sObject> l_sharingRecords = new List<sObject>();
                                    Set<Id> s_recordIds = m_relatedRecords.keySet();
                                    for (sObject rec : m_relatedRecords.values()) {
                                        litify_pm__Matter__c matter = m_matters.get((Id)rec.get(setting.Matter_Field__r.QualifiedApiName));
                                        InputParam param = m_params.get((Id)rec.get(setting.Matter_Field__r.QualifiedApiName));
                                        if (matter != null && matter.litify_pm__Matter_Teams__r.size() > 0 && param.isPrivate) {
                                            Boolean isOwnerInTeam = false;
                                            
                                            Set<Id> s_userIds = new Set<Id>();
                                            system.debug('s_userIds - before '+s_userIds);
                                            for (litify_pm__Matter_Team_Member__c member : matter.litify_pm__Matter_Teams__r) {
                                                if (member.litify_pm__User__r.isActive && member.litify_pm__User__c != rec.get('OwnerId') && (param.s_new_members == null || param.s_new_members.contains(member.litify_pm__User__c))) {
                                                    s_userIds.add(member.litify_pm__User__c);
                                                }
                                                if (member.litify_pm__User__c == matter.OwnerId) {
                                                    isOwnerInTeam = true;
                                                }
                                            }
                                            if (isOwnerInTeam == false) {
                                                s_userIds.add( matter.OwnerId);
                                            }
                                            system.debug('s_userIds - after '+s_userIds);
                                            for (Id uId : s_userIds) {
                                                l_sharingRecords.add(
                                                    SharingUtilities.fillSharingRecords(
                                                        shareObject,
                                                        rec.Id,
                                                        uId,
                                                        accessLevel
                                                    )
                                                );
                                            }
                                        }
                                    }
                                    system.debug('s_old_members=='+s_old_members);
                                    system.debug('s_recordIds=='+s_recordIds);
                                    if (s_old_members.size() > 0 && s_recordIds.size() >0 )  {
                                        List<sObject> l_delete = Database.query('SELECT ID FROM '+shareObject+' WHERE ParentId IN:s_recordIds  AND UserOrGroupId IN :s_old_members');
                                        SharingUtilities.deleteSharingRecords(l_delete);
                                    }
                                    if (l_sharingRecords.size() > 0 ) {
                                        SharingUtilities.insertSharingRecords(l_sharingRecords);
                                    }
                                } 
                            }
                        }
                    }
                }
            }
        }
    }
    
    //output details which goes from apex to flow
    public class InputParam{
        @InvocableVariable(required=true  label='Matter Record Id')
        public Id matter_id;
        @InvocableVariable(required=true  label='Define if record should be private or not')
        public Boolean isPrivate;
        @InvocableVariable(label='AccessLevel ("Edit". "Read")')
        public String accessLevel; // related object id 
        public Set<Id> s_new_members;
        public Set<Id> s_old_members;
    }
}