public class DataMapper {
    
    public static void main(ProxyObject__c po) {
   		Map<String, String> schemaMapper = retrieveKeyField(); 
        checkObject(po, schemaMapper); 
        //Check which object and call the method that handles per object creation
    }
    
    //Retrieves the JSONSchemaBuilder CMT 
    public static List<JSONBuilderSchema__mdt> retrieveJSONSchemaBuilder() {
        String sourceType = 'Student';
        String sourceApp = 'CommonApp';
        List<JSONBuilderSchema__mdt> schema = [SELECT SourceType__c, SourceAttribute__c, Structure__c, Order__c,
                                               Object__c, Mapped_To__c, SFDC_Field_Name__c
                                               FROM JSONBuilderSchema__mdt 
                                               WHERE SourceType__c =: sourceType AND
                                                     Source__c =: sourceApp
                                               ORDER BY Order__c ASC
                                               ];
       
        return schema;
    }
    
    //Method that constructs Map<String,String> where SourceAttribute is Key and Value is a string of Object/Field/Mapper
    public static Map<String,String> retrieveKeyField() {
        List<JSONBuilderSchema__mdt> schema = retrieveJSONSchemaBuilder(); 
        Map<String,String> schemaMapper = new Map<String,String>(); 
        for (JSONBuilderSchema__mdt sch : schema) {
            if (String.isNotBlank(sch.SourceAttribute__c) &&
                String.isNotBlank(sch.Object__c) && 
               	String.isNotBlank(sch.Mapped_To__c) && 
               	String.isNotBlank(sch.SFDC_Field_Name__c)) 
            {
                    String valueString = sch.Mapped_To__c + ';' + sch.Object__c + ';' + sch.SFDC_Field_Name__c; 
                   	schemaMapper.put(sch.SourceAttribute__c, valueString); 
            }
        }
        return schemaMapper; 
    }
    
    public static void checkObject(ProxyObject__c po, Map<String,String> schemaMapper) {
        String mapType = ''; 
        
        if (String.isNotBlank(po.FinalJSON__c)) {
            if (schemaMapper.containsKey(po.FinalJSON__c)) {
                mapType = schemaMapper.get(po.FinalJSON__c); 
                //Split the string and remove the 1st value
                //Check if that value = JSON or FIeld 
                
            }
        }
    }
    
}