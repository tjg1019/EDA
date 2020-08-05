public class Student extends DynamicProperty{
    /*public Object getValueForProperty(String property){
        String json_instance = Json.serialize(this); //"this" is the instance of the student class
        Map<String, Object> untyped_instance;
        untyped_instance= (Map<String, Object>)JSON.deserializeUntyped(json_instance);
        return untyped_instance.get(property);  
    }*/ 
    
    
    public String CommonAppID {get;set;}
	public String FirstName {get;set;}
	public String LastName {get;set;}
	public String GenderIdentity {get;set;}
	public String StudentType {get;set;}
    public FirstGen FirstGen {get;set;}
	public List<Sibling> Sibling {get;set;}
	public Counselor Counselor {get;set;}
	public Races Races {get;set;}
	
    
    
    public class Counselor {
        public String FirstName;  
        public String LastName; 
    }
    
	public class FirstGen {
		public String InProgress;
		public String Submitted;
	}

	public class Races {
		public String AmericanIndian;
		public String Asian;
	}

    public class Sibling {
		public String FirstName;
		public String LastName;
	}

	public static Student parse(String json) {
		return (Student) System.JSON.deserialize(json, Student.class);
	}
}