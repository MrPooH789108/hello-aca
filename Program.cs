using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Use Serilog for logging to file
Log.Logger = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File("/LogFiles/app.log", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

var app = builder.Build();
var logger = app.Logger;

logger.LogInformation("Application starting...");

app.MapGet("/", () =>
{
    logger.LogInformation("Root endpoint hit");
    return new { message = "Hello from Azure Container Apps 👋" };
});

app.MapGet("/healthz", () =>
{
    logger.LogDebug("Health check endpoint hit");
    return Results.Ok("ok");
});

app.Run();
