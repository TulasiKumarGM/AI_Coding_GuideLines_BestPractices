# Core gRPC Features

## Overview
This document outlines the fundamental gRPC features demonstrated in the GrpcDemos project, covering basic service implementation, client-server communication, and core architectural patterns.

## 1. Basic Service Implementation

### 1.1 Protocol Buffer Service Definition
**Feature**: Service contract definition using Protocol Buffers
**Location**: All `.proto` files in SharedLib projects
**Example**: `SimpleCalc.SharedLib/SimpleCalc.proto`

```protobuf
syntax = "proto3";
option csharp_namespace = "SimpleCalc.SharedLib.Generated";

service CalculatorService {
    rpc Add (CalculatorRequest) returns (CalculatorReply) {}
    rpc Subtract (CalculatorRequest) returns (CalculatorReply) {}
    rpc Multiply (CalculatorRequest) returns (CalculatorReply) {}
    rpc Divide (CalculatorRequest) returns (CalculatorReply) {}
}

message CalculatorRequest {
    double n1 = 1;
    double n2 = 2;
}

message CalculatorReply {
    double result = 1;
}
```

**Key Features**:
- Type-safe service contracts
- Cross-language compatibility
- Automatic code generation
- Version management support

### 1.2 Service Implementation
**Feature**: Server-side service implementation
**Location**: ServiceLib projects
**Example**: `SimpleCalc.ServiceLib/CalculatorService.cs`

```csharp
public class CalculatorService : CalculatorServiceBase
{
    public override Task<CalculatorReply> Add(CalculatorRequest request, ServerCallContext context) =>
        Task.FromResult(new CalculatorReply { Result = request.N1 + request.N2 });

    public override Task<CalculatorReply> Divide(CalculatorRequest request, ServerCallContext context) =>
        Task.FromResult(new CalculatorReply { Result = request.N1 / request.N2 });
}
```

**Key Features**:
- Inheritance from generated base classes
- Async/await pattern support
- ServerCallContext access
- Type-safe request/response handling

### 1.3 Client Implementation
**Feature**: Client-side service consumption
**Location**: Client projects
**Example**: `SimpleCalc.Client/Program.cs`

```csharp
using var channel = GrpcChannel.ForAddress("https://localhost:5001");
var client = new CalculatorService.CalculatorServiceClient(channel);

var sum = client.Add(new CalculatorRequest { N1 = n1, N2 = n2 });
Console.WriteLine($"Called service: {n1} + {n2} = {sum.Result}");
```

**Key Features**:
- Channel-based connection management
- Type-safe client generation
- Synchronous and asynchronous calls
- Automatic connection pooling

## 2. Service Hosting

### 2.1 ASP.NET Core Integration
**Feature**: gRPC service hosting in ASP.NET Core
**Location**: ServiceHost projects
**Example**: `SimpleCalc.ServiceHost/Startup.cs`

```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddGrpc();
}

public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    app.UseRouting();
    app.UseEndpoints(endpoints =>
    {
        endpoints.MapGrpcService<ServiceLib.CalculatorService>();
    });
}
```

**Key Features**:
- Native ASP.NET Core integration
- Dependency injection support
- Middleware pipeline integration
- Configuration management

### 2.2 HTTP/2 Protocol Support
**Feature**: HTTP/2 protocol configuration
**Location**: `appsettings.json` files

```json
{
  "Kestrel": {
    "EndpointDefaults": {
      "Protocols": "Http2"
    }
  }
}
```

**Key Features**:
- HTTP/2 multiplexing
- Binary protocol efficiency
- Connection reuse
- Performance optimization

## 3. Error Handling

### 3.1 RPC Exception Handling
**Feature**: Structured error handling with gRPC status codes
**Location**: Service implementations

```csharp
public override Task<CalculatorReply> Subtract(CalculatorRequest request, ServerCallContext context)
{
    if (request.N2 == 0)
    {
        throw new RpcException(new Status(StatusCode.InvalidArgument, "Division by zero."));
    }
    return Task.FromResult(new CalculatorReply { Result = request.N1 - request.N2 });
}
```

**Key Features**:
- Standardized error codes
- Cross-language error propagation
- Detailed error messages
- Client-side exception handling

### 3.2 Client-Side Error Handling
**Feature**: Client-side error catching and handling
**Location**: Client applications

```csharp
try
{
    var result = client.Divide(new CalculatorRequest { N1 = n1, N2 = 0 });
}
catch (RpcException ex)
{
    Console.WriteLine($"Error: {ex.Status.StatusCode} - {ex.Status.Detail}");
}
```

**Key Features**:
- Exception-based error handling
- Status code inspection
- Error message extraction
- Graceful degradation

## 4. Service Lifetime Management

### 4.1 Per-Call Lifetime (Default)
**Feature**: New service instance per request
**Location**: Microsoft gRPC implementations
**Characteristics**:
- Stateless service design
- Automatic cleanup
- Thread-safe by design
- Memory efficient

### 4.2 Singleton Lifetime
**Feature**: Single service instance for all requests
**Location**: `LifeTime.ServiceHostSingleton`
**Configuration**:
```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddGrpc();
    services.AddSingleton(new GreeterService());
}
```

**Key Features**:
- Stateful service support
- Performance optimization
- Manual lifetime management
- Shared state handling

## 5. Logging and Diagnostics

### 5.1 Microsoft gRPC Logging
**Feature**: Comprehensive logging support
**Location**: Service and client configurations

**Server Configuration**:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Grpc": "Debug"
    }
  }
}
```

**Client Configuration**:
```csharp
var loggerFactory = LoggerFactory.Create(logging =>
{
    logging.AddConsole();
    logging.SetMinimumLevel(LogLevel.Debug);
});

using var channel = GrpcChannel.ForAddress("https://localhost:5001",
    new GrpcChannelOptions { LoggerFactory = loggerFactory });
```

**Key Features**:
- Structured logging
- Performance monitoring
- Debug information
- Production diagnostics

### 5.2 Google gRPC Logging
**Feature**: Google gRPC.Core logging
**Location**: Google gRPC implementations

```csharp
Environment.SetEnvironmentVariable("GRPC_TRACE", "all");
Environment.SetEnvironmentVariable("GRPC_VERBOSITY", "debug");
Grpc.Core.GrpcEnvironment.SetLogger(new Grpc.Core.Logging.ConsoleLogger());
```

**Key Features**:
- Environment variable configuration
- Console output
- Debug tracing
- Performance analysis

## 6. Code Generation

### 6.1 Automatic Stub Generation
**Feature**: Client and server code generation
**Tool**: `dotnet-grpc`
**Process**:
1. Define `.proto` files
2. Generate C# stubs
3. Implement service logic
4. Create client applications

**Key Features**:
- Type-safe code generation
- Cross-platform compatibility
- Version management
- Build-time validation

### 6.2 Project Structure
**Feature**: Consistent project organization
**Pattern**: SharedLib → ServiceLib → ServiceHost → Client

**Benefits**:
- Clear separation of concerns
- Reusable components
- Easy testing
- Maintainable architecture

## 7. Security Features

### 7.1 TLS/SSL Support
**Feature**: Encrypted communication
**Configuration**: HTTPS endpoints
**Implementation**: Automatic TLS handling

### 7.2 Authentication Support
**Feature**: Token-based authentication
**Location**: ServerCallContext access
**Capabilities**:
- User identity extraction
- Authorization checks
- Custom authentication
- Security context management

## 8. Performance Features

### 8.1 Connection Management
**Feature**: Efficient connection handling
**Characteristics**:
- HTTP/2 multiplexing
- Connection pooling
- Load balancing support
- Resource optimization

### 8.2 Binary Serialization
**Feature**: Efficient data serialization
**Benefits**:
- Compact message format
- Fast serialization/deserialization
- Cross-language compatibility
- Version evolution support

## 9. Development Tools Integration

### 9.1 Visual Studio Integration
**Feature**: Native IDE support
**Capabilities**:
- IntelliSense support
- Debugging capabilities
- Project templates
- Service references

### 9.2 Command Line Tools
**Feature**: CLI-based development
**Tools**:
- `dotnet-grpc` for code generation
- `grpcurl` for testing
- `protoc` for protocol buffer compilation

## 10. Cross-Platform Support

### 10.1 .NET Core Compatibility
**Feature**: Cross-platform gRPC support
**Platforms**:
- Windows
- Linux
- macOS
- Docker containers

### 10.2 Language Interoperability
**Feature**: Multi-language support
**Benefits**:
- Polyglot microservices
- Technology diversity
- Team flexibility
- Integration capabilities

## Summary

The core gRPC features demonstrated in the GrpcDemos project provide a solid foundation for building distributed systems with:

- **Type Safety**: Protocol buffer contracts ensure compile-time safety
- **Performance**: HTTP/2 and binary serialization optimize communication
- **Reliability**: Structured error handling and connection management
- **Scalability**: Service lifetime management and connection pooling
- **Observability**: Comprehensive logging and diagnostics
- **Security**: TLS support and authentication capabilities
- **Developer Experience**: Rich tooling and IDE integration

These features make gRPC an excellent choice for modern microservices architectures, providing both the performance and reliability needed for production systems while maintaining developer productivity through excellent tooling and clear patterns.
