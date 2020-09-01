public with sharing class ShareRecordWithTeamFromProcess {
    @InvocableMethod(label='Share Record With Team Members')
    public static void shareRecord(List<InputParam> l_inputParams) {
        List<sObject> l_sharingRecords = new List<sObject>();
        Set<Id> s_matterIds = new Set<Id>();
        Set<Id> s_recordIds = new Set<Id>();
        Map<Id, sObject> m_objects = new Map<Id, sObject>();
        Map<Id,litify_pm__Matter__c> m_matters = new Map<Id, litify_pm__Matter__c>();
        String accessLevel = 'Edit';
        Schema.SObjectType objectType = null;
        Set<Id> s_old = new Set<Id>();
        for (InputParam param : l_inputParams) {
            if (param.matter_id != null) {
                s_matterIds.add(param.matter_id);
            }
            if (param.matter_id != null) {
                s_recordIds.add(param.record_id);
                objectType = param.record_id.getSobjectType();
            }
            if (String.isNotBlank(param.accessLevel)) {
                accessLevel = param.accessLevel;
            }
            Id previsouId = null;
            try {
                previsouId = param.old_matter_id;
            }catch (Exception ex) {}
            if (previsouId != null) {
                s_matterIds.add(previsouId);
                s_old.add(previsouId);
            }
        }
        String objectName = objectType.getDescribe().getName();
        Schema.SObjectType shareObject = Schema.getGlobalDescribe().get(objectName.replace('__c', '__Share'));
        if (shareObject == null) {
            shareObject = Schema.getGlobalDescribe().get(objectName+'Share');
        }
        if (shareObject != null) {
            m_matters = SharingUtilities.getMatters(s_matterIds);
            Set<Id> s_old_members = new Set<Id>();
            Set<Id> s_recordsForDelete = new Set<Id>();
            Map<Id, sObject> m_relatedRecords = new Map<Id, sObject> (Database.query('SELECT ID, OwnerId FROM '+objectName+' WHERE Id IN :s_recordIds'));
            for (InputParam param : l_inputParams) {
                sObject record = m_relatedRecords.get(param.record_id);
                litify_pm__Matter__c matter = m_matters.get(param.matter_id);
                if (matter != null && record != null && matter.litify_pm__Matter_Teams__r.size() > 0) {
                    Boolean isOwnerInTeam = false;
                    for (litify_pm__Matter_Team_Member__c member : matter.litify_pm__Matter_Teams__r) {
                        if (member.litify_pm__User__r.isActive && member.litify_pm__User__c != record.get('OwnerId')) {
                            l_sharingRecords.add(
                                SharingUtilities.fillSharingRecords(
                                    shareObject,
                                    record.Id,
                                    member.litify_pm__User__c,
                                    accessLevel
                                )
                            );
                            if (member.litify_pm__User__c == matter.OwnerId) {
                                isOwnerInTeam = true;
                            }
                        }
                    }
                    if (isOwnerInTeam == false) {
                        l_sharingRecords.add(
                            SharingUtilities.fillSharingRecords(
                                shareObject,
                                record.Id,
                                matter.OwnerId,
                                accessLevel
                            )
                        );
                    }
                }
                Id previsouId = null;
                try {
                    previsouId = param.old_matter_id;
                    system.debug('param.old_matter_id ---'+param.old_matter_id);
                }catch (Exception ex) {}
                if (previsouId != null) {
                    litify_pm__Matter__c matterOld = m_matters.get(previsouId);
                    if (matterOld != null && record != null && matterOld.litify_pm__Matter_Teams__r.size() > 0) {
                        for (litify_pm__Matter_Team_Member__c member : matterOld.litify_pm__Matter_Teams__r) {
                            if (member.litify_pm__User__r.isActive && member.litify_pm__User__c != record.get('OwnerId')) {
                                s_old_members.add(member.litify_pm__User__c);
                                s_recordsForDelete.add(record.Id);
                            }
                        }
                        
                    }
                }
            }
           	system.debug('s_recordsForDelete==='+s_recordsForDelete);
            system.debug('s_old_members==='+s_old_members);
            if (s_recordsForDelete.size() > 0 && s_old_members.size() > 0) {
                List<sObject> l_delete = Database.query('SELECT ID FROM '+shareObject+' WHERE ParentId IN:s_recordsForDelete  AND UserOrGroupId IN :s_old_members');
                SharingUtilities.deleteSharingRecords(l_delete);
            }
             if (l_sharingRecords.size() > 0 ) {
                SharingUtilities.insertSharingRecords(l_sharingRecords);
            }
        }
    }

    //output details which goes from apex to flow
    public class InputParam{
        @InvocableVariable(required=true  label='Matter Record Id')
        public Id matter_id;
        @InvocableVariable(required=true  label='Record Id')
        public Id record_id;
        @InvocableVariable(label='AccessLevel ("Edit". "Read")')
        public String accessLevel; // related object id 
        @InvocableVariable( label='Old Matter Record Id')
        public String old_matter_id;
    }
}