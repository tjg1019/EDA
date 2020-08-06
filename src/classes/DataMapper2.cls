public class DataMapper2 {

	public static void testRun() {
        List<Map<String,Object>> rawStudentsData = JSONBuilder.runBuilder('CommonApp', 'Student'); 
        
        main(rawStudentsData); 
    }

    public static void main(List<Map<String,Object>> rawStudentsData) {
    	
    	Map<String, CommonApp_DataMapping__c> dataMappingByJSONStructure = retrieveDataMappingObj(); 

    	String commonAppIdField = checkCommonAppCustomSetting(); 

    	Map<String,List<CASFDCMapping>> caMappingByObj = constructMasterMap(dataMappingByJSONStructure); 
        
        //checkObjToCreate (caMappingByObj); 
    }

    public static Map<String, CommonApp_DataMapping__c> retrieveDataMappingObj() {
        Map<String, CommonApp_DataMapping__c> dataMappingByJSONStructure = new Map<String, CommonApp_DataMapping__c>(); 
        
        List<CommonApp_DataMapping__c> dataMappingList = [SELECT Id, Name, Structure__c, 
        													Final_Object__c, Final_Field__c, Mapped_to__c 
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
    
    //TODO: Create a method that processes the rawStudentData to the Student object(cls) --> This will return a list of students.cls 
    public static void convertRawJSONStudentDataToStudents() {}
    
   
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
    }
    
    //TODO: Return a list of in memory constructed contacts. 
    public static List<Contact> buildStudentContacts(List<Student> processedStudents, Map<String,List<CASFDCMapping>> caMappingByObj){
        return constructObjectsFromMapping('Contact', processedStudents,caMappingByObj);
    }
    
    //TODO: Generic Function to construct objects given a objectname to read out of the Mapping and given the student data to load on to the new obj
    public static List<SObject> constructObjectsFromMapping(String objectName, List<Student> processedStudents, Map<String,List<CASFDCMapping>> caMappingByObj) {
        List<SObject> ttest = new List<SObject>(); 
        
        /*
         * list<CASFDCMapping> mapping = caMappingByObj.get(objectName)
         * for student in processedStudents:
         *    SObject conObj = Schema.getGlobalDescribe().get(objectName).newSObject();  ==> Contact c = new COntact(); 
         *    for (CASFDCMapping str2Field : mapping) {
            	Object strValue = student.getProperty(str2Field.structure__c); 
                //conObj.firstname = student.firstname				
                //conObj.last = student.last
				str2Field.Final_Field__c //figure out how to dynamically set the final_field__c's value as the contact field
               }
         * 
         * 
         */
        
        
        return ttest; 
    }

    //TODO: This method should loop through the processed StudentData  
    public static void constructIndividualStudentContact(CASFDCMapping caDataMappingForContact) {
		//Loop through the student object to check if the CASFDCMapping exist in the student obj 
		Student checkStudentObj = new Student(); 
        
        /*for (CASFDCMapping fieldMapping : caDataMappingForContact) {
            System.debug('fieldMapping -->' + fieldMapping.structure); 
            String keyString = (String)fieldMapping.structure; 
            Object valReturn = checkStudentObj.getProperty(keyString);
            System.debug('valReturn -->' + valReturn); 
        }*/
        
    }
    
    
    
}