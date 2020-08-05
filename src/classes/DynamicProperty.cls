public virtual class DynamicProperty {	
    public virtual Object getProperty(String property) {
        String json_instance = Json.serialize(this); //"this" is the instance of the student class
        Map<String, Object> untyped_instance = (Map<String, Object>)JSON.deserializeUntyped(json_instance);
        return untyped_instance.get(property);          
    }
}