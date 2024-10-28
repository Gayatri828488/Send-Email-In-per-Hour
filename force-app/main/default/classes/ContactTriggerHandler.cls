public class ContactTriggerHandler {
    public static void updateAssociatedAccount(List<Contact>contactList){
        Set<Id> accountIds = new Set<Id>();
        if(!contactList.isEmpty()){
            for(Contact con: contactList){
                if(con.AccountId!=null){
                     accountIds.add(con.AccountId);
                }
            }
        }
            if(!accountIds.isEmpty()){
              Map<Id, Account> accountMap= new Map<Id, Account> ([Select Id, Is_Mail_Send__c From Account Where Id IN : accountIds]);
             for(Id accountId : accountMap.keySet()) {
                Account acc = accountMap.get(accountId);
                acc.Is_Mail_Send__c = false;
            }
        // Update the modified Account records
            if(!accountMap.isEmpty()) {
                update accountMap.values();
            }
          }
    }
}