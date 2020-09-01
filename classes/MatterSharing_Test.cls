@isTest(SeeAllData=false)
private class  MatterSharing_Test {
    @testSetup static void initData() {
        litify_pm__Public_Setup__c setting = new litify_pm__Public_Setup__c();
        setting.litify_pm__Run_Triggers__c = true;
        insert setting;
        List<Account> l_accounts = new List<Account>();
        Account acc1 = new Account(litify_pm__First_Name__c ='Account 1', litify_pm__Last_Name__c ='Last Name 1');
        acc1.BillingCity = 'New York';
        acc1.BillingCountry = 'United States';
        acc1.BillingStreet = 'Avenue';
        acc1.BillingPostalCode = '12412';
        acc1.Phone  = '1241242';
        l_accounts.add(acc1);
        insert l_accounts;
        List<litify_pm__Matter__c> l_matters = new List<litify_pm__Matter__c>();
        litify_pm__Matter__c matter1 = new litify_pm__Matter__c();
        matter1.litify_pm__Client__c = acc1.Id;
        l_matters.add(matter1);
        insert l_matters;
        litify_pm__lit_Note__c note = new litify_pm__lit_Note__c();
        note.Name = 'TEST';
        note.litify_pm__lit_Note__c = 'TEST';
        note.litify_pm__lit_Matter__c = matter1.Id;
        insert note;
        List<User> l_users = new List<User>();
        Profile standardUserProfile = [SELECT Id, Name 
                                       FROM Profile
                                       WHERE Name = 'Standard User'
                                       LIMIT 1];
        String uniqueUserName = 'standardUser1' + DateTime.now().getTime() + '@testorg.com';
        User testUser1 = new User(Alias = 'standt', Email='standarduser1@testorg.com',
                                  EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                                  LocaleSidKey='en_US', ProfileId = standardUserProfile.Id,
                                  TimeZoneSidKey='America/Los_Angeles',
                                  UserName=uniqueUserName);
        
        l_users.add(testUser1); 
        uniqueUserName = 'standardUser2' + DateTime.now().getTime() + '@testorg.com';
        User testUser2 = new User(Alias = 'standt', Email='standarduser2@testorg.com',
                                  EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US',
                                  LocaleSidKey='en_US', ProfileId = standardUserProfile.Id,
                                  TimeZoneSidKey='America/Los_Angeles',
                                  UserName=uniqueUserName);
        
        l_users.add(testUser2); 
        uniqueUserName = 'standardUser3' + DateTime.now().getTime() + '@testorg.com';
        User testUser3 = new User(Alias = 'standt', Email='standarduser3@testorg.com',
                                  EmailEncodingKey='UTF-8', LastName='Testing3', LanguageLocaleKey='en_US',
                                  LocaleSidKey='en_US', ProfileId = standardUserProfile.Id,
                                  TimeZoneSidKey='America/Los_Angeles',
                                  UserName=uniqueUserName);
        
        l_users.add(testUser3); 
        insert l_users;  
        
        litify_pm__Matter_Team_Member__c mtm1 = new litify_pm__Matter_Team_Member__c();
        mtm1.name = 'test team member 1';
        mtm1.litify_pm__Matter__c = matter1.id;
        mtm1.litify_pm__User__c = testUser1.id;
        insert mtm1;
        
        
    }
    
    static testmethod void test_MatterSharing() {
        litify_pm__Matter__c matter = [SELECT ID,Private__c FROM litify_pm__Matter__c LIMIT 1];
        matter.Private__c = true;
        update matter;
        Test.startTest();
        List<ShareMatterRecordFromProcess.InputParam> l_inputParams = new List<ShareMatterRecordFromProcess.InputParam>();
        ShareMatterRecordFromProcess.InputParam param = new ShareMatterRecordFromProcess.InputParam();
        param.matter_id = matter.Id;
        param.isPrivate = true;
        param.accessLevel = 'Edit';
        l_inputParams.add(param);
        ShareMatterRecordFromProcess.shareMatterRecord(l_inputParams);
        
        User usernew2 = [SELECT ID FROM User WHERE LastName = 'Testing2'];
        litify_pm__Matter_Team_Member__c mtm1 = new litify_pm__Matter_Team_Member__c();
        mtm1.name = 'test team member 1';
        mtm1.litify_pm__Matter__c = matter.id;
        mtm1.litify_pm__User__c = usernew2.id;
        insert mtm1;
        User usernew3 = [SELECT ID FROM User WHERE LastName = 'Testing3'];
        mtm1.litify_pm__User__c = usernew3.id;
        update mtm1;
        delete mtm1;
        litify_pm__lit_Note__c note = new litify_pm__lit_Note__c();
        note.Name = 'TEST';
        note.Private__c = true;
        note.litify_pm__lit_Note__c = 'TEST';
        note.litify_pm__lit_Matter__c = matter.Id;
        insert note;
        List<ShareRecordWithTeamFromProcess.InputParam> l_inputParams2 = new List<ShareRecordWithTeamFromProcess.InputParam>();
        ShareRecordWithTeamFromProcess.InputParam param2 = new ShareRecordWithTeamFromProcess.InputParam();
        param2.matter_id = matter.Id;
        param2.record_id = note.Id;
        param2.accessLevel = 'Edit';
        l_inputParams2.add(param2);
        ShareRecordWithTeamFromProcess.shareRecord(l_inputParams2);
        Test.stopTest();
    }
}