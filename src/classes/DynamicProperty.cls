public virtual class DynamicProperty {	
    public virtual Object getProperty(String property) {
        System.debug('DynamicProp -->' + property); 
        
        String json_instance = Json.serialize(this); //"this" is the instance of the student class
        System.debug('DynamicProp json_instance -->' + json_instance); 
        
        Map<String, Object> untyped_instance = (Map<String, Object>)JSON.deserializeUntyped(json_instance);
        
        return untyped_instance.get(property);          
    }
}