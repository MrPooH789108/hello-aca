# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o /app/publish

# Tracer install stage
FROM alpine:latest AS dd-tracer-stage
ADD https://github.com/DataDog/dd-trace-dotnet/releases/download/v2.53.2/datadog-dotnet-apm-2.53.2.tar.gz .
RUN mkdir extracted-tracer
RUN tar -C /extracted-tracer -xzf datadog-dotnet-apm-*.tar.gz
RUN mkdir /empty

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
COPY --from=dd-tracer-stage /extracted-tracer/ /opt/datadog/
COPY --from=dd-tracer-stage /empty/ /var/log/datadog/dotnet/

# APM Config
ENV CORECLR_ENABLE_PROFILING=1 \
    CORECLR_PROFILER={846F5F1C-F9AE-4B07-969E-05C26BC060D8} \
    CORECLR_PROFILER_PATH=/opt/datadog/Datadog.Trace.ClrProfiler.Native.so \
    DD_DOTNET_TRACER_HOME=/opt/datadog \
    DD_RUNTIME_METRICS_ENABLED=true \
    DD_TRACE_EXPAND_ROUTE_TEMPLATES_ENABLED=true \
    DD_LOGS_INJECTION=true

# Service tags (กำหนดใน Azure Container App Environment ก็ได้)
ENV DD_ENV=dev \
    DD_SERVICE=hello-aca \
    DD_VERSION=1.0.0 \
    DD_SERVERLESS_LOG_PATH=/LogFiles/*.log

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "hello-aca.dll"]