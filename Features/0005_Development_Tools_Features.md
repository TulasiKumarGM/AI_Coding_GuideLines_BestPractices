# Development Tools and Features

## Overview
This document covers the development tools, testing utilities, debugging features, and productivity enhancements demonstrated in the GrpcDemos project.

## 1. Code Generation Tools

### 1.1 dotnet-grpc Tool
**Feature**: Protocol Buffer code generation
**Installation**:
```bash
dotnet tool install -g dotnet-grpc
```

**Usage**:
```bash
# Generate client and server stubs
dotnet grpc add-file SimpleCalc.proto --output-dir Generated

# Add service reference
dotnet grpc add-service-reference https://localhost:5001
```

**Generated Files**:
- Client stubs (`*Client.cs`)
- Server base classes (`*Base.cs`)
- Message types
- Service definitions

### 1.2 Protocol Buffer Compiler (protoc)
**Feature**: Cross-language code generation
**Usage**:
```bash
# Generate C# code
protoc --csharp_out=Generated --grpc_out=Generated --plugin=protoc-gen-grpc SimpleCalc.proto

# Generate multiple languages
protoc --csharp_out=Generated --go_out=Generated --java_out=Generated SimpleCalc.proto
```

**Benefits**:
- Multi-language support
- Version compatibility
- Custom code generation
- Build integration

## 2. Testing Tools

### 2.1 gRPCurl
**Feature**: Command-line gRPC testing tool
**Installation**:
```bash
# Windows (using Chocolatey)
choco install grpcurl

# Linux/macOS
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
```

**Basic Usage**:
```bash
# List all services
grpcurl -plaintext localhost:5001 list

# Describe a service
grpcurl -plaintext localhost:5001 describe SimpleCalc.CalculatorService

# Call a method
grpcurl -plaintext -d '{"n1": 10, "n2": 20}' localhost:5001 SimpleCalc.CalculatorService/Add
```

**Advanced Usage**:
```bash
# With TLS
grpcurl -cacert ca.pem localhost:5001 list

# With metadata
grpcurl -plaintext -H "authorization: Bearer token123" localhost:5001 list

# Server reflection
grpcurl -plaintext localhost:5001 list SimpleCalc.CalculatorService
```

**Example from GrpcDemos**:
```bash
# Call SimpleCalc service
grpcurl -v -plaintext -d '{"n1": 34, "n2": 76}' localhost:5001 SimpleCalc.CalculatorService/Add

# Call AsyncChat service (streaming)
grpcurl -v -plaintext -d '{"user": "Alice", "text": "Hello World"}' localhost:5001 AsyncChat.ChatService/Chat
```

### 2.2 BloomRPC
**Feature**: GUI-based gRPC testing tool
**Features**:
- Visual interface for gRPC calls
- Request/response editing
- Service discovery
- Import/export capabilities

**Usage**:
1. Enter server address (e.g., `localhost:5001`)
2. Import `.proto` files
3. Select service and method
4. Enter request data
5. Execute and view response

**Screenshot Reference**: `grpcurl.png` in the project

### 2.3 gRPCox
**Feature**: Web-based gRPC testing tool
**Features**:
- Browser-based interface
- Docker deployment
- Server reflection support
- Real-time testing

**Docker Usage**:
```bash
docker run -p 8080:8080 gusaul/grpcox
```

## 3. Network Analysis Tools

### 3.1 Wireshark
**Feature**: Network protocol analysis
**Configuration**:
1. Capture on loopback interface
2. Filter: `tcp.port == 5001`
3. Configure HTTP/2 dissection: Edit > Settings > Protocols > http2 > Port = 5001

**Use Cases**:
- Protocol debugging
- Performance analysis
- Security auditing
- Connection troubleshooting

**Screenshot Reference**: `grpcweb.png` in the project

### 3.2 gRPC-Web Analysis
**Feature**: HTTP/1.1 gRPC-Web protocol analysis
**Characteristics**:
- HTTP/1.1 transport
- Browser compatibility
- Limited streaming support
- Web integration

## 4. Development Environment Setup

### 4.1 Visual Studio Integration
**Feature**: Native IDE support for gRPC development
**Capabilities**:
- IntelliSense for generated code
- Debugging support
- Project templates
- Service references

**Project Template Usage**:
1. File > New > Project
2. Select "gRPC Service" template
3. Configure project settings
4. Start development

### 4.2 Visual Studio Code
**Feature**: Cross-platform gRPC development
**Extensions**:
- Protocol Buffer support
- gRPC syntax highlighting
- Code generation tools
- Debugging capabilities

**Configuration**:
```json
{
  "grpc.protoc": "/usr/local/bin/protoc",
  "grpc.protoc-gen-grpc": "/usr/local/bin/grpc_csharp_plugin"
}
```

## 5. Build and Deployment Tools

### 5.1 MSBuild Integration
**Feature**: Automated code generation during build
**Configuration**:
```xml
<ItemGroup>
  <Protobuf Include="**/*.proto" GrpcServices="Client,Server" />
</ItemGroup>
```

**Benefits**:
- Automatic code generation
- Build-time validation
- Incremental builds
- CI/CD integration

### 5.2 Docker Support
**Feature**: Containerized gRPC services
**Dockerfile Example**:
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["GrpcDemos.sln", "."]
COPY ["SimpleCalc/SimpleCalc.ServiceHost/SimpleCalc.ServiceHost.csproj", "SimpleCalc/SimpleCalc.ServiceHost/"]
RUN dotnet restore "SimpleCalc/SimpleCalc.ServiceHost/SimpleCalc.ServiceHost.csproj"
COPY . .
WORKDIR "/src/SimpleCalc/SimpleCalc.ServiceHost"
RUN dotnet build "SimpleCalc.ServiceHost.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "SimpleCalc.ServiceHost.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SimpleCalc.ServiceHost.dll"]
```

### 5.3 Kubernetes Deployment
**Feature**: Container orchestration for gRPC services
**Manifest Example**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grpc-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: grpc-service
  template:
    metadata:
      labels:
        app: grpc-service
    spec:
      containers:
      - name: grpc-service
        image: grpc-service:latest
        ports:
        - containerPort: 80
        - containerPort: 443
---
apiVersion: v1
kind: Service
metadata:
  name: grpc-service
spec:
  selector:
    app: grpc-service
  ports:
  - port: 80
    targetPort: 80
  - port: 443
    targetPort: 443
  type: LoadBalancer
```

## 6. Debugging and Diagnostics

### 6.1 gRPC Logging
**Feature**: Comprehensive logging for debugging
**Microsoft gRPC Logging**:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Grpc": "Debug",
      "Microsoft": "Debug"
    }
  }
}
```

**Google gRPC Logging**:
```csharp
Environment.SetEnvironmentVariable("GRPC_TRACE", "all");
Environment.SetEnvironmentVariable("GRPC_VERBOSITY", "debug");
Grpc.Core.GrpcEnvironment.SetLogger(new Grpc.Core.Logging.ConsoleLogger());
```

### 6.2 Performance Profiling
**Feature**: Performance analysis and optimization
**Tools**:
- Visual Studio Diagnostic Tools
- dotTrace Profiler
- PerfView
- Application Insights

**Metrics to Monitor**:
- Request/response times
- Memory usage
- CPU utilization
- Network throughput
- Connection counts

### 6.3 Distributed Tracing
**Feature**: Request tracing across services
**Implementation**:
```csharp
public class TracingInterceptor : Interceptor
{
    public override async Task<TResponse> UnaryServerHandler<TRequest, TResponse>(
        TRequest request,
        ServerCallContext context,
        UnaryServerMethod<TRequest, TResponse> continuation)
    {
        using var activity = ActivitySource.StartActivity("grpc.server");
        activity?.SetTag("grpc.method", context.Method);
        activity?.SetTag("grpc.service", context.Host);
        
        return await continuation(request, context);
    }
}
```

## 7. Code Quality Tools

### 7.1 Static Analysis
**Feature**: Code quality and security analysis
**Tools**:
- SonarQube
- CodeQL
- Security Code Scan
- StyleCop

**Configuration**:
```xml
<PackageReference Include="StyleCop.Analyzers" Version="1.1.118" PrivateAssets="all" />
<PackageReference Include="Microsoft.CodeAnalysis.FxCopAnalyzers" Version="3.3.2" PrivateAssets="all" />
```

### 7.2 Unit Testing
**Feature**: Automated testing framework
**Tools**:
- xUnit
- NUnit
- MSTest
- Moq (for mocking)

**Example Test**:
```csharp
[Test]
public async Task Add_ValidNumbers_ReturnsCorrectSum()
{
    // Arrange
    var service = new CalculatorService();
    var request = new CalculatorRequest { N1 = 5, N2 = 3 };
    var context = Mock.Of<ServerCallContext>();
    
    // Act
    var result = await service.Add(request, context);
    
    // Assert
    Assert.AreEqual(8, result.Result);
}
```

### 7.3 Integration Testing
**Feature**: End-to-end testing with test server
**Implementation**:
```csharp
public class GrpcIntegrationTests : IClassFixture<WebApplicationFactory<Startup>>
{
    private readonly WebApplicationFactory<Startup> _factory;
    
    public GrpcIntegrationTests(WebApplicationFactory<Startup> factory)
    {
        _factory = factory;
    }
    
    [Test]
    public async Task CalculatorService_Add_ReturnsCorrectResult()
    {
        // Arrange
        var client = _factory.CreateClient();
        
        // Act
        var response = await client.PostAsJsonAsync("/api/calculator/add", 
            new { n1 = 10, n2 = 20 });
        
        // Assert
        response.EnsureSuccessStatusCode();
        var result = await response.Content.ReadAsAsync<CalculatorReply>();
        Assert.AreEqual(30, result.Result);
    }
}
```

## 8. Monitoring and Observability

### 8.1 Application Insights
**Feature**: Application performance monitoring
**Configuration**:
```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddApplicationInsightsTelemetry();
    services.AddGrpc();
}
```

**Custom Metrics**:
```csharp
public class MetricsService
{
    private readonly TelemetryClient _telemetryClient;
    
    public void TrackGrpcRequest(string method, double duration, bool success)
    {
        _telemetryClient.TrackDependency("gRPC", method, DateTime.UtcNow, 
            TimeSpan.FromMilliseconds(duration), success);
    }
}
```

### 8.2 Prometheus Integration
**Feature**: Metrics collection and monitoring
**Implementation**:
```csharp
public class PrometheusMetrics
{
    private readonly Counter _requestCounter;
    private readonly Histogram _requestDuration;
    
    public PrometheusMetrics()
    {
        _requestCounter = Metrics.CreateCounter("grpc_requests_total", 
            "Total gRPC requests", new[] { "method", "status" });
        _requestDuration = Metrics.CreateHistogram("grpc_request_duration_seconds", 
            "gRPC request duration", new[] { "method" });
    }
}
```

## 9. Security Tools

### 9.1 Certificate Management
**Feature**: TLS/SSL certificate handling
**Tools**:
- OpenSSL
- Let's Encrypt
- Azure Key Vault
- HashiCorp Vault

**Certificate Generation**:
```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# Generate certificate signing request
openssl req -new -newkey rsa:4096 -keyout key.pem -out csr.pem
```

### 9.2 Security Scanning
**Feature**: Security vulnerability detection
**Tools**:
- OWASP Dependency Check
- Snyk
- WhiteSource
- GitHub Security Advisories

## 10. Documentation Tools

### 10.1 API Documentation
**Feature**: Automatic API documentation generation
**Tools**:
- Swagger/OpenAPI
- gRPC-Gateway
- protoc-gen-doc
- DocFX

**Swagger Integration**:
```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddGrpc();
    services.AddGrpcSwagger();
    services.AddSwaggerGen();
}
```

### 10.2 Code Documentation
**Feature**: Code documentation generation
**Tools**:
- XML Documentation Comments
- DocFX
- Sandcastle
- GitBook

**Example**:
```csharp
/// <summary>
/// Performs addition of two numbers
/// </summary>
/// <param name="request">The calculator request containing two numbers</param>
/// <param name="context">The server call context</param>
/// <returns>A calculator reply containing the sum</returns>
public override Task<CalculatorReply> Add(CalculatorRequest request, ServerCallContext context)
{
    return Task.FromResult(new CalculatorReply { Result = request.N1 + request.N2 });
}
```

## Summary

The development tools and features in the GrpcDemos project provide a comprehensive development ecosystem:

- **Code Generation**: Automated stub generation and build integration
- **Testing Tools**: Command-line and GUI testing utilities
- **Network Analysis**: Protocol debugging and performance analysis
- **IDE Integration**: Native development environment support
- **Build and Deployment**: Containerization and orchestration
- **Debugging**: Comprehensive logging and profiling tools
- **Code Quality**: Static analysis and testing frameworks
- **Monitoring**: Application performance and metrics collection
- **Security**: Certificate management and vulnerability scanning
- **Documentation**: API and code documentation generation

These tools enable developers to build, test, debug, deploy, and maintain gRPC services efficiently in production environments.
