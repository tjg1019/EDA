global class SampleBatch implements Database.Batchable<sObject> {
	
    global Database.QueryLocator start(Database.BatchableContext bc) {
       	return Database.getQueryLocator(
            'SELECT Id, FinalJSON__c, JSON__c, Source__c, Type__c FROM ProxyObject__c WHERE Processed__c = False'
        ); 
    }
    
    global void execute(Database.BatchableContext bc, List<ProxyObject__c> records){
        if (records.isEmpty()) {
            return; 
        } 
        
        for (ProxyObject__c po : records) {
            
        }
        
        //Non Bulk 
        /*for (ProxyObject__c po : records) {
            if (String.isNotBlank(po.Type__c) && String.isNotBlank(po.Source__c)) {
                JSONBuilder.saveToProxy(po.Source__c, po.Type__c); 
                //Calls Data Mapper? 
                if (String.isNotBlank(po.FinalJSON__c))  {
                    DataMapper.main(po); 
                }
            } 
        }*/ 
        
        
        //Assuming that this is only for first years 
        /*List<SObject> jsonRecords = new List<SObject>(); 
        for (ContentNote contentNote : records) {
        	jsonRecords.add(contentNote); 
        }
        
        if (!jsonRecords.isEmpty()) {
            ObjectSerializer.main(jsonRecords); 
        }*/ 
       	
    }    
    
    global void finish(Database.BatchableContext bc){
    }    
}