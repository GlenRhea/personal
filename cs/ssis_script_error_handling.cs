/*
   Microsoft SQL Server Integration Services Script Task
   Write scripts using Microsoft Visual C# 2008.
   The ScriptMain is the entry point class of the script.
*/

using System;
using System.Data;
using Microsoft.SqlServer.Dts.Runtime;
using System.Windows.Forms;

namespace ST_596dabba1c094a90a8b17d4767b50a31.csproj
{
    [System.AddIn.AddIn("ScriptMain", Version = "1.0", Publisher = "", Description = "")]
    public partial class ScriptMain : Microsoft.SqlServer.Dts.Tasks.ScriptTask.VSTARTScriptObjectModelBase
    {

        #region VSTA generated code
        enum ScriptResults
        {
            Success = Microsoft.SqlServer.Dts.Runtime.DTSExecResult.Success,
            Failure = Microsoft.SqlServer.Dts.Runtime.DTSExecResult.Failure
        };
        #endregion

 
        public void Main()
        {

            System.Data.SqlClient.SqlConnection sqlConn;
            System.Data.SqlClient.SqlCommand sqlComm;

            sqlConn = new System.Data.SqlClient.SqlConnection();

            sqlConn.ConnectionString = "Data Source=sqlserver;Initial Catalog=msdb;Integrated Security=True;";
            sqlConn.Open();

            string fileName = "";

            try
            {
                fileName = ("ImportFileName: " + Dts.Variables["ImportFileName"].Value.ToString()).Trim();
            }
            catch
            {
            }

            if (fileName.Replace("ImportFileName:", "").Trim() != "")
                fileName = fileName + Environment.NewLine + Environment.NewLine;
            else
                fileName = "";

            string to = Dts.Variables["SupportEmail"].Value.ToString();
            string subject = "SSIS Failed: " + Dts.Variables["PackageName"].Value.ToString() + " at " + DateTime.Now.ToString();

            string body = 
                "Package: " + Dts.Variables["PackageName"].Value.ToString() + Environment.NewLine +
                "User: " + Dts.Variables["UserName"].Value.ToString() + Environment.NewLine +
                "Machine: " + Dts.Variables["MachineName"].Value.ToString() + Environment.NewLine + Environment.NewLine +
                "Failed At: " + DateTime.Now.ToString() + Environment.NewLine + 
                fileName + 
                "Error Code: " + Dts.Variables["ErrorCode"].Value.ToString() + Environment.NewLine +
                "Error Message: " + Dts.Variables["ErrorDescription"].Value.ToString();

            sqlComm = new System.Data.SqlClient.SqlCommand("sp_send_dbmail @recipients = '" + to + "', @subject = '" + subject.Replace("'", "''") + "', @body = '" + body.Replace("'", "''") + "'", sqlConn);
            sqlComm.ExecuteNonQuery();

            sqlComm.Dispose();
            sqlConn.Close();
            sqlConn.Dispose();
            
            Dts.TaskResult = (int)ScriptResults.Success;
        }
    }
}