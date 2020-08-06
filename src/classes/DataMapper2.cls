public class DataMapper2 {

	public static void testRun() {
        List<Map<String,Object>> jsonObjKey = JSONBuilder.runBuilder('CommonApp', 'Student'); 
        
        main(jsonObjKey); 
    }

    public static void main(List<Map<String,Object>> commonAppValuesByField) {
    	
    	Map<String, CommonApp_DataMapping__c> dataMappingByJSONStructure = retrieveDataMappingObj(); 

    	String commonAppIdField = checkCommonAppCustomSetting(); 

    	Map<String,List<CASFDCMapping>> masterDataMapping = constructMasterMap(commonAppValuesByField, dataMappingByJSONStructure); 
        
        checkObjToCreate (masterDataMapping); 
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

    public static Map<String,List<CASFDCMapping>> constructMasterMap(List<Map<String,Object>> commonAppValuesByField, Map<String, CommonApp_DataMapping__c> dataMappingByJSONStructure) {
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
            System.debug('mappingsByObj -->' + mappingsByObj);      
        }
        
        /*if (!commonAppValuesByField.isEmpty()) {
    		for (Map<String, Object> checkStud : commonAppValuesByField) {
                System.debug('checkStud -->' + checkStud); 
    			
                for (String key : checkStud.keySet()) {
                    System.debug('key -->' + key); 
    				
                    if (dataMappingByJSONStructure.containsKey(key)) {
                        System.debug('keyIsFound on DM -->'); 
                        for (Object caVal : checkStud.values()) {
                            System.debug('caVal -->' + caVal);
                            System.debug('keyCheck2 -->' + key); 
                                CASFDCMapping caMap = new CASFDCMapping();
                                caMap.structure = key; 
                                caMap.fieldName = dataMappingByJSONStructure.get(key).Final_Field__c; 
                                caMap.objectName  = dataMappingByJSONStructure.get(key).Final_Object__c; 
								
                            	String objectName  = dataMappingByJSONStructure.get(key).Final_Object__c; 
                            	List<CASFDCMapping> existingMaps = new List<CASFDCMapping>(); 
                                if (mappingsByObj.containsKey(objectName)) {
                                    existingMaps = mappingsByObj.get(objectName); 
                                } 
                                existingMaps.add(caMap); 
								mappingsByObj.put(dataMappingByJSONStructure.get(key).Final_Object__c, existingMaps);                             
                            
    					} 
                    }    
    			}
    		}
    	}*/ 
        System.debug('mappingsByObj -->' + mappingsByObj.get('Contact')); 
    	return mappingsByObj; 
    }
    
    public static void checkObjToCreate(Map<String,List<CASFDCMapping>> masterMappingMap) {
        Map<String,Map<String,Object>> contactValuesForContact = new Map<String,Map<String,Object>>(); 
        //Group by Object to create
        for (String caKey : masterMappingMap.keySet()) {
            /*for (CASFDCMapping valObj : masterMappingMap.values()) {
                for (String jsonStr : valObj.structures) {
                    if (jsonStr == caKey) {
                        //contactValuesForContact.put(masterMappingMap.get(caKey));
                    }
                }
            }*/ 
        }
        
    }
}