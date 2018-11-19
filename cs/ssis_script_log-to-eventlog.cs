public void Main()
        {
            // TODO: Add your code here
            bool fireAgain = true;
            Dts.Events.FireInformation(0, "gpg stdout", Dts.Variables["stdout"].Value.ToString(), string.Empty, 0, ref fireAgain);
            Dts.Events.FireInformation(0, "gpg stderr", Dts.Variables["stderr"].Value.ToString(), string.Empty, 0, ref fireAgain);

            System.Diagnostics.EventLog eventLog = new System.Diagnostics.EventLog();
            //eventLog.Source.
            //// If the SSIS event log doesn't exist on the target machine then create it
            //if (!eventLog.SourceExists("SSIS"))
            //{
            //    eventLog.CreateEventSource("SSIS", "Application");
            //}

            // Create an instance of the EventLog class
            eventLog = new System.Diagnostics.EventLog();
            
            // Specify the source as SSIS
            eventLog.Source = "SQLISPackage100";
            // Add an event log message
            eventLog.WriteEntry("This is a message from the Meritain Task!", System.Diagnostics.EventLogEntryType.Information);
            eventLog.WriteEntry("gpg stdout" + Dts.Variables["stdout"].Value.ToString(), System.Diagnostics.EventLogEntryType.Information);
            eventLog.WriteEntry("gpg stderr" + Dts.Variables["stderr"].Value.ToString(), System.Diagnostics.EventLogEntryType.Information);
            eventLog.Dispose();
            Dts.TaskResult = (int)ScriptResults.Success;
        }