public class DataMapper2 {

	public static void testRun() {
        List<Map<String,Object>> jsonObjKey = JSONBuilder.runBuilder('CommonApp', 'Student'); 
        
        main(jsonObjKey); 
    }

    public static void main(List<Map<String,Object>> commonAppValuesByField) {
    	
    	Map<String, CommonApp_DataMapping__c> dataMappingByJSONStructure = retrieveDataMappingObj(); 

    	String commonAppIdField = checkCommonAppCustomSetting(); 

    	Map<String, CASFDCMapping> masterDataMapping = constructMasterMap(commonAppValuesByField, dataMappingByJSONStructure); 
        
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

    public static Map<String, CASFDCMapping> constructMasterMap(List<Map<String,Object>> commonAppValuesByField, Map<String, CommonApp_DataMapping__c> dataMappingByJSONStructure) {
        Map<String, CASFDCMapping> masterMappingMap = new Map<String, CASFDCMapping>(); 
        CASFDCMapping caMap = new CASFDCMapping(); 
        caMap.structures = new List<String>(); 
        caMap.objectNames = new List<String>(); 
        caMap.fieldNames = new List<String>();
        caMap.caValues = new List<Object>(); 
        
    	if (!commonAppValuesByField.isEmpty()) {
    		for (Map<String, Object> checkStud : commonAppValuesByField) {
                System.debug('checkStud -->' + checkStud); 
    			
                for (String key : checkStud.keySet()) {
                    System.debug('key -->' + key); 
    				
                    if (dataMappingByJSONStructure.containsKey(key)) {
                        System.debug('keyIsFound on DM -->'); 
                        for (Object caVal : checkStud.values()) {
                            System.debug('caVal -->' + caVal);
                            System.debug('keyCheck2 -->' + key); 
                            try{
                                caMap.structures.add(key); 
                                if (dataMappingByJSONStructure.get(key).Final_Object__c != Null) {
                                    System.debug('objectCheck -->');
                                    caMap.objectNames.add(dataMappingByJSONStructure.get(key).Final_Object__c); 
                            	}
                                if (dataMappingByJSONStructure.get(key).Final_Field__c != Null) {
                                    System.debug('FieldCheck -->');
                                    caMap.fieldNames.add(dataMappingByJSONStructure.get(key).Final_Field__c);
                                }
                                caMap.caValues.add(caVal);
                                masterMappingMap.put(key, caMap); 
                            } catch (Exception e) {
                                System.debug('exception Error -->' + e.getMessage() + ' = ' + e.getLineNumber()); 
                            }
    					} 
                    }    
    			}
    		}
    	}
        System.debug('caMap -->' + caMap); 
    	return masterMappingMap; 
    }
    
    public static void checkObjToCreate(Map<String, CASFDCMapping> masterMappingMap) {
        //Group by Object to create
        for (String caKey : masterMappingMap.keySet()) {

        }
        
    }
}