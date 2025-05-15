public class BulkJobFailureNotifier {
    @future(callout=true)
    public static void checkBulkJobFailures() {
        try {
            String BULK_API_VERSION = '58.0'; // Use latest API version
            String baseUrl = System.Url.getSalesforceBaseUrl().toExternalForm();
            String endpoint = baseUrl + '/services/data/v' + BULK_API_VERSION + '/jobs/ingest';
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            request.setHeader('Content-Type', 'application/json');
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                processFailedJobs(response.getBody());
            } else {
                System.debug('Error checking jobs: ' + response.getStatusCode() + ' - ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' at ' + e.getLineNumber());
        }
    }
    
    private static void processFailedJobs(String jsonResponse) {
        List<String> failedJobDetails = new List<String>();
        Set<String> affectedObjects = new Set<String>();
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        List<Object> jobRecords = (List<Object>) responseMap.get('records');
        
        for (Object job : jobRecords) {
            Map<String, Object> jobData = (Map<String, Object>) job;
            String status = (String) jobData.get('state');
            Integer failed = (Integer) jobData.get('numberRecordsFailed');
            
            // Key Fix: Check for failed records in completed jobs
            if (status == 'Failed' || (status == 'JobComplete' && failed > 0)) {
                String jobId = (String) jobData.get('id');
                String objectName = (String) jobData.get('object');
                Integer processed = (Integer) jobData.get('numberRecordsProcessed');
                String failureReason = (String) jobData.get('errorMessage');
                
                affectedObjects.add(objectName);
                
                failedJobDetails.add(
                    'Job ID: ' + jobId + '\n' +
                    'Object: ' + objectName + '\n' +
                    'Processed Records: ' + processed + '\n' +
                    'Failed Records: ' + failed + '\n' +
                    'Error Message: ' + (failureReason != null ? failureReason : 'No error message') + '\n'
                );
            }
        }
        
        if (!failedJobDetails.isEmpty()) {
            sendFailureNotification(failedJobDetails, affectedObjects);
        }
    }
    
    private static void sendFailureNotification(List<String> failedJobDetails, Set<String> affectedObjects) {
        String recipientEmail = getRecipientEmail(affectedObjects);
        if (recipientEmail == null) return;
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { recipientEmail });
        email.setSubject('Bulk Data Load Failure Alert');
        
        String body = 'IMPORTANT: Bulk Data Load Failures Detected\n\n';
        body += 'Failed Job Details:\n' + String.join(failedJobDetails, '\n------------------\n');
        body += '\n\nPlease investigate immediately.';
        
        email.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    
    private static String getRecipientEmail(Set<String> objectNames) {
        try {
            // Query custom metadata for email settings
            List<Email_Notification_Setting__mdt> settings = [
                SELECT DeveloperName, Email_Recipient__c, Object_Name__c
                FROM Email_Notification_Setting__mdt
            ];
            
            String defaultEmail;
            Map<String, String> objectToEmail = new Map<String, String>();
            
            for (Email_Notification_Setting__mdt setting : settings) {
                if (setting.Object_Name__c == '*') {
                    defaultEmail = setting.Email_Recipient__c;
                } else {
                    objectToEmail.put(setting.Object_Name__c, setting.Email_Recipient__c);
                }
            }
            
            // Check for object-specific email first
            for (String obj : objectNames) {
                if (objectToEmail.containsKey(obj)) {
                    return objectToEmail.get(obj);
                }
            }
            
            return defaultEmail;
        } catch (Exception e) {
            System.debug('Error getting recipient: ' + e.getMessage());
            return null;
        }
    }
}