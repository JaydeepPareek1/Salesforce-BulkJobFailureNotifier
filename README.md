# Salesforce-BulkJobFailureNotifier
Automate Salesforce Bulk API job monitoring with this Apex class! 📡 Detects failed or partially failed jobs and sends email alerts using custom metadata. Save time and catch issues fast. 🚀 #Salesforce #Apex #BulkAPI

Automate Salesforce Bulk API job monitoring! This Apex class detects failed or partially failed ingest jobs and sends email alerts to configured recipients using custom metadata. Save time, catch issues fast, and keep your data operations running smoothly. 🚀

✨ Features:
  📡 Queries the Salesforce Bulk API (/jobs/ingest) to check job statuses.
  🔍 Identifies jobs with state = 'Failed' or numberRecordsFailed > 0.
  📧 Sends detailed email notifications with failure details (job ID, object, error message).
  ⚙️ Uses Email_Notification_Setting__mdt for flexible recipient configuration.
  ⚡️ Runs asynchronously with @future to handle HTTP callouts.

🛠️ Prerequisites
  Salesforce org with Bulk API enabled.
  Permissions for HTTP callouts (HttpRequest) and email sending (Messaging).
  Custom metadata type Email_Notification_Setting__mdt configured.
  Apex execution context (e.g., scheduled job or manual trigger).
