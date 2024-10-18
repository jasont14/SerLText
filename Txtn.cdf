Summary: Implementing Serilog in .NET 8 WebAPI and Blazor Applications with SQL Server Sink

This document provides an overview of integrating Serilog logging into .NET 8 WebAPI and Blazor applications. It also includes configuration for logging to SQL Server, along with best practices and code examples.

1. Overview of Serilog

Serilog is a structured logging library that provides powerful and customizable logging features. It supports various sinks, including SQL Server, and enables detailed logging (e.g., correlation IDs, request durations, exceptions) in both WebAPI and Blazor Server applications.

Why Use Serilog?

	•	Structured logging (JSON-like structure) for easy querying and analysis
	•	Multiple sinks (SQL Server, Console, Files, etc.)
	•	Highly configurable and supports enrichment (e.g., request IDs)
	•	Simplifies filtering and organizing logs by levels (Info, Warning, Error)

2. Installing Serilog in .NET 8 WebAPI and Blazor Applications

To implement Serilog in .NET 8, follow these steps:

Step 1: Install Required Packages

Use the following commands in your project directory:

dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.MSSqlServer
dotnet add package Serilog.Enrichers.Environment
dotnet add package Serilog.Enrichers.Process
dotnet add package Serilog.Enrichers.Thread

Step 2: Configure SQL Server Sink

In both WebAPI and Blazor applications, you’ll configure Serilog to log into SQL Server.

Modify the appsettings.json:

{
  "Serilog": {
    "Using": ["Serilog.Sinks.MSSqlServer"],
    "MinimumLevel": "Information",
    "WriteTo": [
      {
        "Name": "MSSqlServer",
        "Args": {
          "connectionString": "Server=localhost;Database=LogDb;Integrated Security=True;",
          "tableName": "Logs",
          "autoCreateSqlTable": true
        }
      },
      { "Name": "Console" }
    ],
    "Enrich": [
      "WithEnvironmentName",
      "WithMachineName",
      "WithProcessId",
      "WithThreadId"
    ],
    "Properties": {
      "Application": "MyApp"
    }
  }
}

Step 3: Configure Serilog in Program.cs

Modify the Program.cs in both WebAPI and Blazor applications:

using Serilog;
using Microsoft.AspNetCore.Builder;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
builder.Host.UseSerilog((context, services, configuration) => 
    configuration
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.FromLogContext()
        .WriteTo.Console()
        .WriteTo.MSSqlServer(
            connectionString: context.Configuration.GetConnectionString("DefaultConnection"),
            sinkOptions: new Serilog.Sinks.MSSqlServer.MSSqlServerSinkOptions
            {
                TableName = "Logs",
                AutoCreateSqlTable = true
            }));

var app = builder.Build();

// Use Serilog middleware to log HTTP requests
app.UseSerilogRequestLogging();

app.UseRouting();
app.MapControllers(); // For WebAPI
app.MapBlazorHub(); // For Blazor

app.Run();

Step 4: Create the Logs Table in SQL Server

If AutoCreateSqlTable is disabled, manually create the Logs table:

CREATE TABLE Logs (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Timestamp DATETIME2,
    Level NVARCHAR(128),
    Message NVARCHAR(MAX),
    Exception NVARCHAR(MAX),
    Properties NVARCHAR(MAX),
    Application NVARCHAR(128)
);

3. Best Practices for Using Serilog

	1.	Log at Appropriate Levels:
	•	Use Information for general logging, Warning for potential issues, and Error for failures.
	•	Example:

Log.Information("User {UserId} logged in", userId);
Log.Warning("High memory usage detected");
Log.Error("Failed to save order {OrderId}", orderId);


	2.	Use Enrichers:
	•	Add contextual information (like thread ID, machine name, or user identity) for better analysis.
	•	Example:

Log.ForContext("UserId", userId).Information("Operation started");


	3.	Filter Sensitive Information:
	•	Avoid logging sensitive data like passwords or personal data.
	•	Use conditional logging or masking:

Log.Information("User {UserId} logged in with email: {Email}", userId, MaskEmail(email));


	4.	Enable Request Logging for HTTP Calls:
	•	Use Serilog middleware to automatically log incoming HTTP requests:

app.UseSerilogRequestLogging();


	5.	Handle Logging Failures Gracefully:
	•	Use SelfLog to capture internal Serilog errors:

Serilog.Debugging.SelfLog.Enable(Console.Error);


	6.	Use Asynchronous Logging for Performance:
	•	Offload logging to a background thread to improve performance using WriteTo.Async():

.WriteTo.Async(a => a.MSSqlServer(connectionString, sinkOptions));


	7.	Rotate Logs for Performance and Storage Management:
	•	Configure SQL Server or other sinks (like file) to archive or delete older logs periodically.
	8.	Centralize Configuration:
	•	Use appsettings.json or environment variables to manage Serilog settings for consistency across applications.

4. Example Implementation: WebAPI Logging in Controller

Below is an example of a WebAPI controller using Serilog:

using Microsoft.AspNetCore.Mvc;
using Serilog;

[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    [HttpPost]
    public IActionResult CreateOrder([FromBody] Order order)
    {
        Log.Information("Received order {OrderId} for customer {CustomerId}", order.Id, order.CustomerId);

        try
        {
            // Business logic to save order
            return Ok("Order created successfully");
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Failed to create order {OrderId}", order.Id);
            return StatusCode(500, "Internal server error");
        }
    }
}

5. Example Implementation: Logging in Blazor Components

Below is an example of Blazor component logging:

@inject ILogger<FetchData> Logger

<h3>Fetch Data</h3>

<button @onclick="LoadData">Load Data</button>

@code {
    private async Task LoadData()
    {
        Logger.LogInformation("Data load initiated at {Time}", DateTime.Now);

        try
        {
            // Simulate data load
            await Task.Delay(1000);
            Logger.LogInformation("Data load successful");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Data load failed");
        }
    }
}

6. Summary

By following these steps, you can seamlessly integrate Serilog with SQL Server sinks in your .NET 8 WebAPI and Blazor applications. Serilog ensures that your logs are structured, contextual, and stored efficiently for analysis. Following best practices like enriching logs, filtering sensitive data, and using appropriate log levels will help you maintain high-quality, insightful logging throughout your applications.

Let me know if you need any additional sections or modifications to this document!
