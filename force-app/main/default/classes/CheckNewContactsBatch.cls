public class CheckNewContactsBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [SELECT Id, Name, Is_Mail_Send__c, Mail_Send_User__c, Mail_Send_User__r.Email, Mail_Send_User__r.Name 
            FROM Account WHERE Is_Mail_Send__c = false AND Mail_Send_User__c != null]
        );
    }
    public void execute(Database.BatchableContext bc, List<Account> accountList) {
        Set<Id> accountIds = new Set<Id>();
         List<Account> updateAccount =  new List<Account>();
        Map<Id, Map<String, String>> accountUserMap = new Map<Id, Map<String, String>>();

        for (Account acc : accountList) {
            if (acc.Mail_Send_User__c != null) {
                Map<String, String> userInfo = new Map<String, String>();
                userInfo.put('userName', acc.Mail_Send_User__r.Name);
                userInfo.put('userMail', acc.Mail_Send_User__r.Email);
                accountUserMap.put(acc.Id, userInfo); // Add account and Its accsociated user datail
                accountIds.add(acc.Id); // Add account Ids to the set
            }
        }
        
        String htmlBody = generateHtmlTable(accountIds);

        
        Boolean isSendMail = sendEmails(accountUserMap, htmlBody);
        if(isSendMail){
            for(Account acc : accountList){
                acc.Is_Mail_Send__c = true;
                updateAccount.add(acc);
            }
        }
        if(!accountList.isEmpty()){
            update updateAccount;
        }
    }

    
    private String generateHtmlTable(Set<Id> accountIds) {
        List<Contact> contactDetails = [SELECT Id, AccountId, Account.Name, Name, Email FROM Contact 
                                        WHERE AccountId IN :accountIds];
        
       /* String htmlBody = '<table border="1" style="border-collapse: collapse;"><caption>Account and Contact Details</caption>' +
                          '<tr><th>Account</th><th>Contact</th><th>Email</th></tr>';*/
    String htmlBody = '<table border="2" style="border-collapse: collapse; width: 100%; border: 2px solid black;">' +
                  '<caption style="font-size: 1em; margin-bottom: 10px;">Below are the details of your Account and its newly added related Contacts: </caption>' +
                  '<tr><th style="border: 2px solid black; padding: 8px;">Account</th>' +
                  '<th style="border: 2px solid black; padding: 8px;">Contact</th>' +
                  '<th style="border: 2px solid black; padding: 8px; background-color: #f2f2f2;">Email</th></tr>';
String lastAccountName = '';
        for (Contact con : contactDetails) {
            String myAccountName = con.Account.Name != null ? con.Account.Name : '[Not Provided]';
            String myName = con.Name != null ? con.Name : '[Not Provided]';
            String myEmail = con.Email != null ? con.Email : '[Not Provided]';
            
             if (myAccountName == lastAccountName) {
        myAccountName = ''; 
    } else {
        lastAccountName = con.Account.Name; 
    }
            htmlBody += '<tr><td>' + myAccountName + '</td><td>' + myName + '</td><td>' + myEmail + '</td></tr>';
        }
        
        htmlBody += '</table>'; 
        return htmlBody;
    }

   
    private Boolean sendEmails(Map<Id, Map<String, String>> accountUserInfo, String dataTable) {
        EmailTemplate template = [SELECT Id, Body FROM EmailTemplate WHERE DeveloperName = 'Account_Contact_Details'];
        Boolean isSuccess = false;
        try{
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Id accId : accountUserInfo.keySet()) {
            Map<String, String> userInfo = accountUserInfo.get(accId);

            // Replace Place Holder in the  Email Template
            String body = template.Body;
            String userName = userInfo.get('userName') != null ? userInfo.get('userName') : '[Name Not Provided]';
            body = body.replace('##User##', userName);
            body = body.replace('##Account##', dataTable);

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { userInfo.get('userMail') });
            email.setSaveAsActivity(false);
            email.setSubject('Account and Contact Details');
            email.setHtmlBody(body);

            emails.add(email);
        }
            if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
            isSuccess = true;
            } 
        }
         catch (Exception e) {
        System.debug('Error sending emails: ' + e.getMessage());
    }         
        return  isSuccess;
    }

    public void finish(Database.BatchableContext bc) {
        
    }
}