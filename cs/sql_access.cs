using (var conn = new SqlConnection(connectionString))
using (var command = new SqlCommand("ProcedureName", conn) { 
                           CommandType = CommandType.StoredProcedure }) {
   conn.Open();
   command.ExecuteNonQuery();
   conn.Close();
}

private static void CreateCommand(string queryString,
    string connectionString)
{
    using (SqlConnection connection = new SqlConnection(
               connectionString))
    {
        SqlCommand command = new SqlCommand(queryString, connection);
        command.Connection.Open();
        command.ExecuteNonQuery();
    }
}

string connectionString = ConsoleApplication1.Properties.Settings.Default.ConnectionString;
	//
	// In a using statement, acquire the SqlConnection as a resource.
	//
	using (SqlConnection con = new SqlConnection(connectionString))
	{
	    //
	    // Open the SqlConnection.
	    //
	    con.Open();
	    //
	    // The following code uses an SqlCommand based on the SqlConnection.
	    //
	    using (SqlCommand command = new SqlCommand("SELECT TOP 2 * FROM Dogs1", con))
	    using (SqlDataReader reader = command.ExecuteReader())
	    {
		while (reader.Read())
		{
		    Console.WriteLine("{0} {1} {2}",
			reader.GetInt32(0), reader.GetString(1), reader.GetString(2));
		}
	    }
	}