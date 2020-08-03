public class ObjectSerializer {
	//Dynamic parseJSON
	//Check whether value needs to be stored in JSON or custom field 
	//Format + Appending multiple JSON values into the Contact JSON field. 

    public static StudentContact parseJSON(List<SObject> records) {
        //JSONBuilder.runBuilder(records); 
        //Mocking JSONBuilder for now
        StudentContact student = new StudentContact(); 
        student.FirstName = 'Kate';
        student.LastName = 'LastName'; 
        student.GenderIdentity = 'Female';
        student.Occupation = 'Student'; 
    
        StudentContact.Races race = new StudentContact.Races();
        race.White = 'Caucasian'; 
        student.Races = race; 
        return student;
    }
    
    public static void main(List<SObject> records) {
      	StudentContact s = parseJSON(records); 
        createStudentContact(s); 
    }
    
    public static void createStudentContact(StudentContact s) {
        Contact c = new Contact(); 
        StudentContact studentCon = s; 
        c.FirstName = studentCon.FirstName; 
        c.LastName = studentCon.LastName; 
        c.Contact_JSON__c = studentCon.GenderIdentity; 
       	
        /*Student.PersonalInfo info = s.PersonalInfo; 
        c.FirstName = (String)info.FirstName; 
        insert c; */ 
    }
}