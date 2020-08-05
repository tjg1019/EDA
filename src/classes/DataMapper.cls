public class DataMapper {
    
    public static void testRun() {
        List<Map<String,Object>> jsonObjKey = JSONBuilder.runBuilder('CommonApp', 'Student'); 
        System.debug('DataMapper jsonObjKey -->' + jsonObjKey); 
        main(jsonObjKey); 
    }
    
    public static void main(List<Map<String,Object>> jsonObjByCAID) {
        System.debug('DataMapper main -->'); 
        
        //Retrieves the CA DataMapping Object+Field
        Map<String, CommonApp_DataMapping__c> schemaMapperBySourceAttribute = retrieveDataMappingObj(); 
        System.debug('DataMapper main schemaMapperBySourceAttribute -->' + schemaMapperBySourceAttribute); 
        
        //Check and retrives Common App ID from Custom Setting
        String commonAppIDField = checkCommonAppCustomSetting(); //TODO: check the output 
        System.debug('DataMapper main commonAppIDField -->' + commonAppIDField);
        
        //Check if CommonAppID record as student exist in SFDC
        //checkExistingStudent(jsonObjByCAID, schemaMapperBySourceAttribute, commonAppIDField); 
        
        System.debug('DataMapper main beforeCreateNew -->');
        createNewRecords(jsonObjByCAID, schemaMapperBySourceAttribute, commonAppIDField); 

    }
    
    public static Map<String, CommonApp_DataMapping__c> retrieveDataMappingObj() {
        Map<String, CommonApp_DataMapping__c> commonAppMappingByStructure = new Map<String, CommonApp_DataMapping__c>(); 
        List<CommonApp_DataMapping__c> dataMappingList = [SELECT Id, Name, Structure__c, Final_Object__c, Final_Field__c, Mapped_to__c 
                                                          FROM CommonApp_DataMapping__c]; 
        for (CommonApp_DataMapping__c cd : dataMappingList) {
            commonAppMappingByStructure.put(cd.Structure__c, cd); 
        }
        return commonAppMappingByStructure; 
        
    }
    
    //Method that constructs Map<String,String> where SourceAttribute is Key and Value is a string of Object/Field/Mapper
    public static Map<String,List<String>> constructSchemaMap() {
        List<JSONBuilderSchema__mdt> schema = retrieveJSONSchemaBuilder(); 
        Map<String,List<String>> schemaMapperBySourceAttribute = new Map<String,List<String>>(); 
        for (JSONBuilderSchema__mdt sch : schema) {
            if (String.isNotBlank(sch.Structure__c) && 
                String.isNotBlank(sch.Object__c) && 
               	String.isNotBlank(sch.Mapped_To__c) && 
               	String.isNotBlank(sch.SFDC_Field_Name__c)) 
            {
                	List<String> schemaValues = new List<String>(); 
                	schemaValues.add(sch.Object__c);
                	schemaValues.add(sch.Mapped_To__c);
                	schemaValues.add(sch.SFDC_Field_Name__c);
                    //String valueString = sch.Mapped_To__c + ';' + sch.Object__c + ';' + sch.SFDC_Field_Name__c; 
                   	schemaMapperBySourceAttribute.put(sch.Structure__c, schemaValues); 
            }
        }
        return schemaMapperBySourceAttribute; 
    }
    
    //Retrieves the JSONSchemaBuilder CMT 
    //TODO: This is a potential duplicate since JSONBuilder also does this in getJSONBuilderSchema()
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
    
    //Checks if the Common App ID field in CS is mapped properly
    public static String checkCommonAppCustomSetting() {
        Boolean matchField = False; 
        String caIDFieldToMap = ''; 
        CommonApp_Integration_Setup__c caIDMapping = CommonApp_Integration_Setup__c.getOrgDefaults(); 
        System.debug('caIDMapping -->' + caIDMapping.Common_App_Id__c); 
        Set<String> conFields = Schema.SObjectType.Contact.fields.getMap().keySet();
        System.debug('ConFields -->' + conFields); 
        for (String conField : conFields) {
            System.debug('conField Loop-->' + conField); 
            if (conField == caIDMapping.Common_App_ID__c) {
                matchField = true; 
                caIDFieldToMap = conField;
                System.debug('matchField -->' + matchField); 
                System.debug('caIDFieldToMap -->' + caIDFieldToMap); 
            }
        }
        /*Boolean caIDFieldExist = False; 
        String mappedCAIdField = ''; 
    	
        CommonApp_Integration_Setup__c caIDMapping = CommonApp_Integration_Setup__c.getOrgDefaults(); 		 
       	Set<String> conFields = Schema.SObjectType.Contact.fields.getMap().keySet();
        if (conFields.contains(caIDMapping.Common_App_ID__c )) {
            caIDFieldExist = true; 
            mappedCAIdField = caIDMapping.Common_App_ID__c; 
        }
        System.debug('DataMapper customSetting Field -->' +  mappedCAIdField);*/ 
        return caIDFieldToMap; 
    }
    
    //Method that queries existing Student records 
    public static List<Contact> queryExistingStudents(List<String> caIdList) {
       //TODO: Update CommonApp_Id__c query to the string variable commonAppIdFieldName so that it's dynamic 
       return [SELECT Id, CommonApp_Id__c
       			FROM Contact 
                WHERE CommonApp_Id__c IN :caIdList]; 
        
    }
    
    //Method that queries existing Application records for Students
    public static Map<Id, Application__c> queryStudentApplication(List<Contact> students) {
        Map<Id, Application__c> applicationByStudentCAID = new Map<Id, Application__c>(); 
        List<Application__c> applications = [SELECT Id, Applicant__c 
                                             FROM Application__c 
               								 WHERE Applicant__c  IN :students]; 
        if (!applications.isEmpty()) {
            for (Application__c app : applications) {
                applicationByStudentCAID.put(app.Applicant__c, app); 
            }
        }
        return applicationByStudentCAID; 
    }
    
    public static void checkExistingStudent(List<Map<String,Object>> jsonObjByCAID, Map<String, CommonApp_DataMapping__c> schemaMapperBySourceAttribute, String commonAppIDField) {
        List<String> caIdList = new List<String>(); 
        
        //Retrieve the student CAIDs 
        for (Map<String,Object> students : jsonObjByCAID) {
            for (String caId : students.keySet()) {
                caIdList.add(caId); 
            }
        }
       
        //Query database if Student CAIDs exist 
        List<Contact> studentList = queryExistingStudents(caIdList); 
        if (!studentList.isEmpty()) {
            System.debug('DataMapper checkExistingStudent ExistingStudent-->');
            Map<Id, Application__c> applicationByStudentCAID = queryStudentApplication(studentList); 
        } else {
            System.debug('DataMapper checkExistingStudent NotExistingStudent-->');
            createNewRecords(jsonObjByCAID, schemaMapperBySourceAttribute, commonAppIDField); 
        }
    }
    
    public static void createNewRecords(List<Map<String,Object>> jsonObjByCAID, Map<String, CommonApp_DataMapping__c> schemaMapperBySourceAttribute, String commonAppIDField) {
       	System.debug('DataMapper createNewRecords -->');
        /*List<String> schemaMapperValues = new List<String>();
        for (List<String> values : schemaMapperBySourceAttribute.values()) {
            schemaMapperValues.addAll(values); 
        }*/
        
       	List<String> mapValues = new List<String>(); 
        List<Contact> consToInsert = new List<Contact>(); 
        //Access the list of maps 
        for (Map<String,Object> fakeStud : jsonObjByCAID) {
            String jsonStr = JSON.serialize(fakeStud); 
            System.debug('DataMapper createNewRecords jsonStr -->' + jsonStr);
            Student newFakeStud = Student.parse(jsonStr);
            System.debug('newFakeStud -->' + newFakeStud);   
            consToInsert = constructNewStudents(newFakeStud, schemaMapperBySourceAttribute, commonAppIDField); 
            
            /*for (String key : schemaMapperBySourceAttribute.keySet()) {
                //Loop through the CMT SourceAttribute and check if that key exist in the JSONObject 
                if (student.get(key) != ''){ 
					//group by object - check what object the key is assigned to. ie. FirstName = Contact 
              		mapValues = schemaMapperBySourceAttribute.get(key); 
                    if (mapValues[0] == 'Contact') {
                        //createNewStudents(student); 
                    }
                } 
            }*/ 
        }
        
        if (consToInsert.size() > 0) {
            insertRecords(consToInsert); 
        }
    } 
    
    
    public static List<Contact> constructNewStudents(Student newFakeStud, Map<String, CommonApp_DataMapping__c> schemaMapperBySourceAttribute, String commonAppIDField) {
        List<Contact> consToInsert = new List<Contact>(); 
        
        Contact c = new Contact(
            FirstName = newFakeStud.FirstName,  
            LastName = newFakeStud.LastName
            //CommonApp_Id__c = newFakeStud.CommonAppId
        ); 
		
        String str = 'Contact';
       	SObject conObj = Schema.getGlobalDescribe().get(str).newSObject(); 
        System.debug('obj -->' + conObj);
        
		//commonAppIDField = newFakeStud.CommonAppId;         
        for (String key : schemaMapperBySourceAttribute.keySet()) {
            System.debug('KeyValue -->' + key); //Structure Value 
			System.debug('dynamicProp --->' + newFakeStud.getProperty(key)); //the value of the Key
            
            Set<String> conFields = Schema.SObjectType.Contact.fields.getMap().keySet(); //Retrieves Contact fields 
            System.debug('ConFields -->' + conFields); 
            for (String conField : conFields) { //Loop through the Contact fields 
                System.debug('conField Loop-->' + conField); 
                if (schemaMapperBySourceAttribute.containsKey(key)) { 
                    if (conField == schemaMapperBySourceAttribute.get(key).Final_Field__c) { //Check if the key value matches the current Contact field
                    	System.debug('keyField Value -->' + (schemaMapperBySourceAttribute.get(key).Final_Field__c)); 
                        System.debug('conField Loop-->' + conField); 
                         
                        conObj.put(schemaMapperBySourceAttribute.get(key).Final_Field__c, conField);
						System.debug('Finalobj -->' + conObj); 
                    }
                }
            }
        }
        
        
        /*if (schemaMapperBySourceAttribute.containsKey ('FirstGen.InProgress')) {
        	c.Contact_JSON__c = 'FirstGen-InProgress: ' + (String)newFakeStud.FirstGen.InProgress; 
        } 
        if (schemaMapperBySourceAttribute.containsKey ('FirstGen.Submitted')) {
            c.Contact_JSON__c = 'FirstGen-Submitted: ' + (String)newFakeStud.FirstGen.InProgress; 
        }*/ 
        
        
        consToInsert.add(c); 
        return consToInsert;   
    }
    
    public static void insertRecords(List<Contact> consToInsert) {
        try {
            Database.insert(consToInsert); 
        } catch (DmlException e) {
            System.debug('Fail to insert records -->' + e.getMessage()); 
        }
    }
    
}