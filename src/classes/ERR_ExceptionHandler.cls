/*
    Copyright (c) 2017, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2017
* @group Error Handling
* @description Exception handler for intercepting and modifying exception messages to be more user friendly,
* and to remove cruft.
*/
public with sharing class ERR_ExceptionHandler {
    /** @description Map of exception STATUS codes to friendly error message.
    */
    private static final Map<String, String> EXCEPTION_MESSAGES = new Map<String, String>{
        'FIELD_CUSTOM_VALIDATION_EXCEPTION' => Label.exceptionValidationRule,
        'REQUIRED_FIELD_MISSING' => Label.exceptionRequiredField,
        'AfflNullPointerException' => Label.afflNullPointerError,
        'AfflAccountNoRecordTypeException' => Label.afflAccountNoRecordType,
        'AffAccountRecordTypeMappingsException' => Label.afflAccoutMappingError
    };

    /** @description Map of exception STATUS codes to the string that defines the start and end of the useful part of the message
    */
    private static final Map<String, List<String>> SUBSTRINGS = new Map<String, List<String>>{
        'FIELD_CUSTOM_VALIDATION_EXCEPTION' => new List<String>{'FIELD_CUSTOM_VALIDATION_EXCEPTION,',':'},
        'REQUIRED_FIELD_MISSING' => new List<String>{': [',']'}
    };

    /** @description Map of custom exception STATUS codes to the friendly error message
    */
    private static final Map<String, String> CUSTOMS_EXCEPTION_MESSAGES = new Map<String, String>{
        'AfflAccountNoRecordTypeException' => EXCEPTION_MESSAGES.get('FIELD_CUSTOM_VALIDATION_EXCEPTION') + EXCEPTION_MESSAGES.get('AfflAccountNoRecordTypeException'),
        'AffAccountRecordTypeMappingsException' => EXCEPTION_MESSAGES.get('FIELD_CUSTOM_VALIDATION_EXCEPTION') + EXCEPTION_MESSAGES.get('AffAccountRecordTypeMappingsException'),
        'AfflNullPointerException' => EXCEPTION_MESSAGES.get('FIELD_CUSTOM_VALIDATION_EXCEPTION') + EXCEPTION_MESSAGES.get('AfflNullPointerException')
    };

    /*******************************************************************************************************
    * @description Updates an exception's message to a more friendly format.
    * @param ex Exception to update.
    * @return void This method modifies the exception message directly and has no return.
    */
    public static void beautifyExceptionMessage(Exception ex) {
        String message = ex.getMessage();
        String typeName = ex.getTypeName();
        for (String STATUS : EXCEPTION_MESSAGES.keySet()) {
            if (message.contains(STATUS)) {
                if (SUBSTRINGS.keySet().contains(STATUS)) {
                    message = EXCEPTION_MESSAGES.get(STATUS) + message.substringBetween(SUBSTRINGS.get(STATUS)[0], SUBSTRINGS.get(STATUS)[1]);
                } else if (CUSTOMS_EXCEPTION_MESSAGES.keySet().contains(STATUS)) {
                    message = CUSTOMS_EXCEPTION_MESSAGES.get(STATUS);
                }
                ex.setMessage(message);
                break;
            } else if ((typeName.contains(STATUS))){
                ex.setMessage(message);
                break;                
            }
        }
    }

    /*******************************************************************************************************
    * @description Returns whether an exception has a message type that we can or already have modified.
    * @param ex Exception to verify.
    * @return Boolean Whether the exception's message can or has been modified.
    */
    public static Boolean isHandledException(Exception ex) {
        for (String STATUS : EXCEPTION_MESSAGES.keySet()) {
            if (ex.getMessage().contains(STATUS) || ex.getMessage().contains(EXCEPTION_MESSAGES.get(STATUS)) || ex.getTypeName().contains(STATUS)) {
                return true;
            }
        }
        return false;
    }

    public static void handleAfflNullRecordTypeException(Affiliation__c affl, List<String> validRecordTypes) {
        if (affl.Account__c != null) {
            // Get related Account's Record Type Name from 'Affiliation_Type__c' field
            String afflAccRecTypeName;
            if (affl.Affiliation_Type__c != null) {
                AFFL_MultiRecordTypeMapper affilMapper = new AFFL_MultiRecordTypeMapper();
                afflAccRecTypeName = affilMapper.accRecTypeLabelToAPI.get(affl.Affiliation_Type__c);
            }
            //If parent account exists for affiliation and account has no record type
            //display the error message
            if ((affl.Affiliation_Type__c != null && !validRecordTypes.contains(affl.Affiliation_Type__c)) && 
                (String.isNotBlank(afflAccRecTypeName) &&  !validRecordTypes.contains(afflAccRecTypeName))) {
                throw new ERR_ExceptionHandler.AffAccountRecordTypeMappingsException(Label.afflAccoutMappingError);
            } else if (affl.Affiliation_Type__c == null) {
                throw new ERR_ExceptionHandler.AfflAccountNoRecordTypeException(Label.afflAccountNoRecordType);
            }
        }
    }

    public class AfflAccountNoRecordTypeException extends Exception {}
    public class AffAccountRecordTypeMappingsException extends Exception {}
}