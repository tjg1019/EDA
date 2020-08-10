public class DataMapper2 {

	public static void testRun() {
        List<Map<String,Object>> rawStudentsData = JSONBuilder.runBuilder('CommonApp', 'Student'); 
        main(rawStudentsData); 
    }

    public static void main(List<Map<String,Object>> rawStudentsData) {
    	
    	Map<String, CommonApp_DataMapping__c> dataMappingByJSONStructure = retrieveDataMappingObj(); 

    	String commonAppIdField = checkCommonAppCustomSetting(); 

    	Map<String,List<CASFDCMapping>> caMappingByObj = constructMasterMap(dataMappingByJSONStructure); 
        
        List<Student> parsedStudents = convertRawJSONStudentDataToStudents(rawStudentsData); 
        
        List<SObject> sObjList = constructObjectsFromMapping('Contact', parsedStudents, caMappingByObj); 
        
        insertNewRecords(sObjList); 
    }

    public static Map<String, CommonApp_DataMapping__c> retrieveDataMappingObj() {
        Map<String, CommonApp_DataMapping__c> dataMappingByJSONStructure = new Map<String, CommonApp_DataMapping__c>(); 
        
        List<CommonApp_DataMapping__c> dataMappingList = [SELECT Id, Name, Structure__c, 
        													Final_Object__c, Final_Field__c, Mapped_to__c,
                                                          	Repeat_Action__c
                                                          	FROM CommonApp_DataMapping__c]; 

        for (CommonApp_DataMapping__c cd : dataMappingList) {
            dataMappingByJSONStructure.put(cd.Structure__c, cd); 
        }

        return dataMappingByJSONStructure; 
        
    }

    public static String checkCommonAppCustomSetting() {
        String commonAppIdField = ''; 

        CommonApp_Integration_Setup__c caIDMapping = CommonApp_Integration_Setup__c.getOrgDefaults(); 
        
        Set<String> conFields = Schema.SObjectType.Contact.fields.getMap().keySet();

        for (String conField : conFields) {
            if (conField == caIDMapping.Common_App_ID__c) {
                commonAppIdField = conField;
            }
        }

        return commonAppIdField; 
    }

    public static Map<String,List<CASFDCMapping>> constructMasterMap(Map<String, CommonApp_DataMapping__c> dataMappingByJSONStructure) {
        Map<String,List<CASFDCMapping>> mappingsByObj = new Map<String,List<CASFDCMapping>>(); 
        
        for (CommonApp_DataMapping__c dm : dataMappingByJSONStructure.values()) {
       		CASFDCMapping caMap = new CASFDCMapping();
            caMap.structure = dm.Structure__c; 
            caMap.fieldName = dm.Final_Field__c; 
            caMap.objectName = dm.Final_Object__c; 
            caMap.repeatAction = dm.Repeat_Action__c; 
								
            String objectName = dm.Final_Object__c; 
            List<CASFDCMapping> existingMaps = new List<CASFDCMapping>(); 
            if (mappingsByObj.containsKey(objectName)) {
            	existingMaps = mappingsByObj.get(objectName); 
           	} 
            existingMaps.add(caMap); 
			mappingsByObj.put(dm.Final_Object__c, existingMaps);                                 
        }
       
        System.debug('mappingsByObj -->' + mappingsByObj.get('Contact')); 
    	return mappingsByObj; 
    }
    
    public static List<Student> convertRawJSONStudentDataToStudents(List<Map<String,Object>> rawStudentsData) {
        List<Student> parsedStudents = new List<Student>(); 
        
        for (Map<String,Object> rawStudent : rawStudentsData) {
            String rawStudSerialized = JSON.serialize(rawStudent); 
            Student parsedStudent = Student.parse(rawStudSerialized); 
            parsedStudents.add(parsedStudent); 
        }
        return parsedStudents; 
    }
    
    
    //TODO: Generic Function to construct objects given a objectname to read out of the Mapping and given the student data to load on to the new obj
    public static List<SObject> constructObjectsFromMapping(String objectName, List<Student> parsedStudents, Map<String,List<CASFDCMapping>> caMappingByObj) {
        List<SObject> constructedListOfObj = new List<SObject>(); 
        
        List<CASFDCMapping> masterMapping = caMappingByObj.get(objectName); 
        for (Student newStud : parsedStudents) {
            SObject newObj = Schema.getGlobalDescribe().get(objectName).newSObject(); //Contact{} Cast into Contact SOBject - ie. Contact c = new Contact(): 
            System.debug('whatObject -->' + newObj); 
            for (CASFDCMapping jsonKey2Field : masterMapping) { //Loop through the masterMapping to retrieve the structure/Field 
           		System.debug('jsonKey2Field -->' + jsonKey2Field); //[fieldName=Contact_JSON__c, objectName=Contact, structure=GenderIdentity]
                
                String keyString = (String)jsonKey2Field.structure; 
                System.debug('keyString -->' + keyString); 
                
                //Check if the Structure does not contain special character 
                if (keyString.containsNone('.') && keyString.containsNone('[')) {
                    System.debug('keyString DoesNotContainSpecialChar -->' + keyString); //FirstName, LastName, GenderIdentity, etc. 
                    Object jsonKeyOnStudentAsString = newStud.getProperty(keyString); //Returns the value of FirstName, LastName, GenderIdentity, etc. 
                    System.debug('jsonKeyOnStudentAsString -->' + jsonKeyOnStudentAsString);
                   	System.debug('checktheFieldName ---> ' + jsonKey2Field.fieldName); //Contact_JSON__c 
                    
                    //Set the Contact fields with the value from jsonKeyOnStudentAsString 
                    if (newObj != NULL) {
                        newObj.put(jsonKey2Field.fieldName, jsonKeyOnStudentAsString); 
                        System.debug('newObj is notnull2 -->' + newObj); 
                    } 
                } else {
                    System.debug('keyString ContainsSpecialChar -->' + keyString);
                } 
            }
            constructedListOfObj.add(newObj); 
        }
       
        return constructedListOfObj; 
    }
	
    public static void insertNewRecords(List<SObject> sObjList) {
        Database.insert(sObjList); 
    }
    
    /*
    TODO: This method should loop through the processed StudentData  
    public static void constructIndividualStudentContact(CASFDCMapping caDataMappingForContact) {
		Loop through the student object to check if the CASFDCMapping exist in the student obj 
		Student checkStudentObj = new Student(); 
        
        for (CASFDCMapping fieldMapping : caDataMappingForContact) {
            System.debug('fieldMapping -->' + fieldMapping.structure); 
            String keyString = (String)fieldMapping.structure; 
            Object valReturn = checkStudentObj.getProperty(keyString);
            System.debug('valReturn -->' + valReturn); 
        }
        
    }
    
 	//TODO: Return a list of in memory constructed contacts. --> Non generic version of constructObjectsFromMapping I think 
    public static List<Contact> buildStudentContacts(List<Student> parsedStudents, Map<String,List<CASFDCMapping>> caMappingByObj){
        for (Student newStud : parsedStudents) {
            
        }
        return constructObjectsFromMapping('Contact', parsedStudents, caMappingByObj);
    }

    //TODO: Potentially delete this method - TBD 
    public static void constructMappingList(Map<String,List<CASFDCMapping>> caMappingByObj) {
		List<CASFDCMapping> caDataMappingForContact = new List<CASFDCMapping>(); 
        
        if (caMappingByObj.containsKey('Contact')) {
            for (List<CASFDCMapping> caMapping : caMappingByObj.values()) {
                System.debug('checkObj caVal -->' + caMapping); 
                caDataMappingForContact.addAll(caMapping); 
                System.debug('checkObj caDataMappingForContact -->' + caDataMappingForContact); 
            }
            //constructStudentContact(caDataMappingForContact); 
        }
        
        if (caMappingByObj.containsKey('Application__c')){}
    }*/ 
    
}