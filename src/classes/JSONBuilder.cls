public class JSONBuilder {
    
    //Kim Version: 
    public static void runBuilder(List<ProxyObject__c> pos){
        System.debug('JSONBuilder Kim V -->');
		List<JSONBuilderSchema__mdt> schema = getJSONBuilderSchema('CommonApp', 'Student');
        List<Map<String, Object>> newObjectList = new List<Map<String, Object>>();

        if(!pos.isEmpty() && !schema.isEmpty()){
            newObjectList = buildJSONSchema(pos, schema);
        }

        //return newObjectList; //This is deserialized. 
    
        //Updating the FinalJSON__c for POC
        List<ProxyObject__c> poToUpdate = new List<ProxyObject__c>();

        Map<Id, Map<String,Object>> JSONObjectByProxyId = new Map<Id, Map<String,Object>>();

        for(Map<String,Object> newObject : newObjectList){
            Map<String, Object> IntegrationSystemFields = (Map<String,Object>)newObject.get('IntegrationSystemFields');
            Map<String, Object> proxyObject = (Map<String,Object>)IntegrationSystemFields.get('ProxyObject');
            JSONObjectByProxyId.put((Id)proxyObject.get('Id'), newObject);
        }

        Map<Id, ProxyObject__c> pos2 = new Map<Id, ProxyObject__c>(
            											[Select Id, FinalJSON__c 
             												from ProxyObject__c 
                                                         	WHERE Id IN :JSONObjectByProxyId.keySet()]);

        for(Id poId : JSONObjectByProxyId.keySet()){
            if(pos2.containsKey(poId)){

                ProxyObject__c po = pos2.get(poId);
                po.FinalJSON__c = JSON.serialize(JSONObjectByProxyId.get(poId)); //Converts it from Object to String
                System.debug('saveToProxy finalFieldValueCheck -->' + po); 
                poToUpdate.add(po);

            }
        }
	    System.debug('saveToProxy poToUpdate -->' + poToUpdate); 
        if(!poToUpdate.isEmpty()){
            update poToUpdate;
        }

    }
    
    /******************************************************************************************
     ******************************************************************************************/ 
    //Method does the following:
    //1. Calls runBuilder() to retrieve JSONSchemaBuilder CMT recorrds 
    public static void saveToProxy(String sourceApp, String sourceType){
        List<Map<String, Object>> newObjectList = runBuilder(sourceApp, sourceType);
        List<ProxyObject__c> poToUpdate = new List<ProxyObject__c>();
        Map<Id, Map<String,Object>> JSONObjectByProxyId = new Map<Id, Map<String,Object>>();

        for(Map<String,Object> newObject : newObjectList){
            Map<String, Object> IntegrationSystemFields = (Map<String,Object>)newObject.get('IntegrationSystemFields');
            Map<String, Object> proxyObject = (Map<String,Object>)IntegrationSystemFields.get('ProxyObject');
            JSONObjectByProxyId.put((Id)proxyObject.get('Id'), newObject);
        }

        Map<Id, ProxyObject__c> pos = new Map<Id, ProxyObject__c>([Select Id, FinalJSON__c from ProxyObject__c WHERE Id in :JSONObjectByProxyId.keySet()]);

        for(Id poId : JSONObjectByProxyId.keySet()){
            if(pos.containsKey(poId)){
                ProxyObject__c po = pos.get(poId);
                po.FinalJSON__c = JSON.serialize(JSONObjectByProxyId.get(poId));
                System.debug('saveToProxy finalFieldValueCheck -->' + po); 
                poToUpdate.add(po);

            }
        }
		
        System.debug('saveToProxy poToUpdate -->' + poToUpdate); 
        if(!poToUpdate.isEmpty()){
            update poToUpdate;
        }
    }
	
    /******************************************************************************************
     ******************************************************************************************/ 
    //Method that:
    //1. Retrieves the JSONSchemaBuilder CMT recorrds 
    //2. Retrieves the proxy object records where Source = CA and Type = Student
    public static List<Map<String, Object>> runBuilder(String sourceApp, String sourceType){
        List<Map<String, Object>> newObjectList = new List<Map<String, Object>>();
        List<ProxyObject__c> pos = getProxyObjects(sourceApp, sourceType);

        if(!pos.isEmpty()){
            List<JSONBuilderSchema__mdt> schema = getJSONBuilderSchema(sourceApp, sourceType);
            if(!schema.isEmpty()){
				//We're calling the 2nd runBuilder method 
                newObjectList = runBuilder(pos, schema);
            }
        }
		System.debug('runBuilder returnListMap -->' + newObjectList); 
        for (Map<String,Object> students : newObjectList) {
           	for (String key : students.keySet()) {
            	System.debug('runBuilder returnListMapKey -->' + key); 
            }
            for (Object objValue : students.values()) {
                System.debug('runBuilder returnListMapValue -->' + objValue); 
            }
            
        }
        
     
        return newObjectList;
    }
	
    /******************************************************************************************
     ******************************************************************************************/ 
    //Method that calls buildJSONSchema() 
    public static List<Map<String, Object>> runBuilder(List<ProxyObject__c> pos, List<JSONBuilderSchema__mdt> schema) {
        List<Map<String, Object>> newObjectList = new List<Map<String, Object>>();
        if(!pos.isEmpty() && !schema.isEmpty()){
            newObjectList = buildJSONSchema(pos, schema);
        }

        return newObjectList;
    }
	
    /******************************************************************************************
     ******************************************************************************************/ 
    //Method to retrieve the JSONbuilderSchema CMT
    public static List<JSONBuilderSchema__mdt> getJSONBuilderSchema(String sourceApp, String sourceType){
        List<JSONBuilderSchema__mdt> schema = [SELECT SourceType__c, SourceAttribute__c, Structure__c, Order__c 
                                               FROM JSONBuilderSchema__mdt 
                                               WHERE SourceType__c =: sourceType AND
                                                     Source__c =: sourceApp
                                               ORDER BY Order__c ASC
                                               ];
       
        return schema;
    }
    
    /******************************************************************************************
     ******************************************************************************************/ 
    //Method to retrieve the Proxy records 
    public static List<ProxyObject__c> getProxyObjects(String sourceApp, String sourceType){

        List<ProxyObject__c> pos = [SELECT Id, BatchId__c, JSON__c, Parent__c, Source__c, Type__c, Processed__c 
                                    FROM ProxyObject__c
                                    WHERE Type__c =: sourceType AND
                                          Source__c =: sourceApp AND 
                                    	  Processed__c = False 
                                    ];

        return pos;
    }

    /******************************************************************************************
     ******************************************************************************************/ 
    //Method does the following: 
    //1. Retrieves the JSON flat structure and deserializes it 
    //2. Sets up integration fields 
    //3. For each CMT record, it splits the JSON value in the Structure by period and checks to see if that string exist in the
    // deserialized json flat structure 
    //4. Calls addSchemaItem() 
    //5. Returns a Map<String,Obect> //Contains the integration System fields 
    public static List<Map<String, Object>> buildJSONSchema(List<ProxyObject__c> pos, List<JSONBuilderSchema__mdt> schema){
        system.debug('Received proxy objects: ' + pos.size() );
        system.debug('Received schema records: ' + schema.size() );
        
        List<Map<String, Object>> newObjectList = new List<Map<String, Object>>();

        for(ProxyObject__c po : pos){
            //Retrieve the JSON from the proxy object
            String poJSON = po.JSON__c; 
            //Deserialize the json to a map so that we can access the values easier
            Map<String, Object> poJSONMap = (Map<String, Object>)JSON.deserializeUntyped(poJSON);
            system.debug('The proxy object attributes: ' + poJSONMap.keySet().size());

            Map<String, Object> newObject = new Map<String, Object>();

            //Add the integration system fields to the object
            addIntegrationSystemFields(newObject, po);

            for(JSONBuilderSchema__mdt sch : schema){
                List<String> structure = sch.Structure__c.split('\\.');
                //Check if the schema attribute to assess exists in the po json attribute
                if(poJSONMap.containsKey(sch.SourceAttribute__c)){
                    //For now we treat everything as String...we might need to add a attribute type to cast the object to a specific primitive
                    system.debug('Adding structure: ' + structure + ' with value: ' + poJSONMap.get(sch.SourceAttribute__c));
                    addSchemaItem(newObject, structure, poJSONMap.get(sch.SourceAttribute__c));
                }else{
                    //For now we insert the item with null value if we don't find a source attribute match in the provided proxy object
                    //We could store in the JSONBuilderSchema if this field should inserted with empty value or just ignored while building the structure.
                    system.debug('Adding structure: ' + structure + ' with value: null');
                    addSchemaItem(newObject, structure, null);
                }
            }
            system.debug('JSON structure created: ' + JSON.serialize(newObject));
            newObjectList.add(newObject);
        }
        return newObjectList;
    }

    //Method does the following:
    //Parameters: newObject(system integration fields), 
    //structure(list of the string values stored in structure__c on cmt), 
    //object(value for sourceAttributekeys)
    //Logic Check:
    //Calls the following based on criteria it meets handleArrayField(), handleSimpleField(), or handleSpecialField() 
    public static void addSchemaItem(Map<String, Object> newObject, List<String> structure, Object value){
        
        //Assess if it's the last element or the only one :)
        if(structure.size() == 1){
			System.debug('addSchemaItem Structure == 1 -->'); 
            system.debug('Handling final field: ' + structure.get(0) + ' with value: ' + value);
            
            //Special handling for special field structure
            if(structure.get(0).contains(':')){
				System.debug('addSchemaItem Structure == 1 contains : -->'); 
                // New special handling needed -  Example - A.B[0].C:X(D)
                // C:X is really using a JSON notation so that would go directly to the object and 
                // (D) is a field that needs to be inserted with the passed value
                system.debug('Handling a special field: ' + structure);
                handleSpecialField(newObject, structure.get(0), value);

            }else{
                System.debug('addSchemaItem Structure == 1 Not contains : -->'); 
                //A regular field structure
                system.debug('Adding field: ' + structure + ' Value: ' + value);
                newObject.put(structure.get(0), value);
            }
            
        }else{
			System.debug('addSchemaItem Structure !== 1 -->'); 
            
            String field = structure.remove(0);
            
            Map<String, Object> newNode;

            //Check if the field contains the brackets convention
            
            if(field.contains('[') && field.contains(']')){
                System.debug('addSchemaItem Structure !== 1 contains [] -->'); 
                system.debug('Handling an array: ' + field);
                newNode = handleArrayField(newObject, newNode, field);
            }else{
                System.debug('addSchemaItem Structure !== 1 NOT contains [] -->'); 
                system.debug('Handling a simple field: ' + field);
                newNode = handleSimpleField(newObject, newNode, field);
            }

            //recursive call to calculate now for the new node
            addSchemaItem(newNode, structure, value);
        }

    }
    
	/******************************************************************************************
     ******************************************************************************************/ 
    public static Map<String,Object> handleArrayField(Map<String, Object> newObject, Map<String, Object> newNode, String field){

        //Get the real name for the array without the square brackets
        String arrayField = field.substring(0, field.indexOf('['));
        system.debug('Array Name: ' + arrayField);

        Integer arrayIndex = Integer.valueOf(field.substringBetween('[', ']'));
        system.debug('Array Index: ' + arrayIndex);

        List<Map<String,Object>> nodeList;

        //Find the field in the current node
        if(newObject.containsKey(arrayField)){
			
            //Get the existing list of Nodes (or JSON objects)
            nodeList = (List<Map<String,Object>>)newObject.get(arrayField);
        }else{
            //not found, then create a new List of Nodes
            nodeList = new List<Map<String,Object>>();

            newObject.put(arrayField, nodeList);
        }

        //Check if the array index exists in the nodeList
        if(nodeList.size() > arrayIndex){

            //It was found, then it becomes the new Node to assess
            newNode = nodeList[arrayIndex];
        }else{
            //it wasnt found, then we need to create a new Node and add it to the list
            newNode = new Map<String, Object>();
            nodeList.add(newNode);
        }
		
        System.debug('handleArrayField newNode -->' + newNode); 
        return newNode;
    }
	
    /******************************************************************************************
     ******************************************************************************************/ 
    public static Map<String,Object> handleSimpleField(Map<String, Object> newObject, Map<String, Object> newNode, String field){

        if(newObject.containsKey(field)){

            //Get the existing node
            newNode = (Map<String,Object>)newObject.get(field);

        }else{
            //Build a new node in the object
            newNode = new Map<String, Object>();
            newObject.put(field, newNode);
        }
        System.debug('handleSimpleField newNode -->' + newNode); 
        return newNode;
    }
    
    /******************************************************************************************
     ******************************************************************************************/ 
    public static void handleSpecialField(Map<String, Object> newObject, String structure, Object value){

        /* Handles the Column : x, Value : y style -- not used anymore...
        List<String> substructure = structure.get(0).split('\\:');
        newObject.put(substructure.get(0), substructure.get(1));
        newObject.put('Value', value);
        */

        List<String> pairs = structure.split('\\:');

        String firstField = pairs.get(0);
        String secondPiece = pairs.get(1);

        String firstFieldValue = secondPiece.substring(0, secondPiece.indexOf('('));
        String secondField = secondPiece.substringBetween('(', ')');
        
        system.debug('Adding special field: ' + firstField + ' Value: ' + firstFieldValue);
        newObject.put(firstField, firstFieldValue);

        system.debug('Adding special field: ' + secondField + ' Value: ' + value);
        newObject.put(secondField, value);

    }
	
    /******************************************************************************************
     ******************************************************************************************/ 
    //Method that sets system fields - ie. createdDateTime, etc
    public static void addIntegrationSystemFields(Map<String, Object> newObject, ProxyObject__c po){

        Map<String, Object> integrationSystemField = new Map<String, Object>();
        integrationSystemField.put('CreatedDateTime', system.now());
        integrationSystemField.put('ProxyObject', new Map<String,Object>{'Id' => po.Id, 'Type' => po.Type__c});
        newObject.put('IntegrationSystemFields', integrationSystemField);

    }
}