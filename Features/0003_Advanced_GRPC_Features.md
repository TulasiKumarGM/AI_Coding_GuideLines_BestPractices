# Advanced gRPC Features

## Overview
This document covers the advanced gRPC features demonstrated in the GrpcDemos project, including metadata handling, deadline management, server reflection, service lifetime management, and web integration capabilities.

## 1. Metadata Handling

### 1.1 Request/Response Metadata
**Feature**: Custom metadata exchange between client and server
**Location**: `Metadata` project
**Use Cases**:
- Authentication tokens
- Correlation IDs
- Custom headers
- Tracing information

**Client Implementation**:
```csharp
var metadata = new Metadata
{
    { "user-id", "12345" },
    { "correlation-id", Guid.NewGuid().ToString() },
    { "custom-header", "custom-value" }
};

var callOptions = new CallOptions(metadata: metadata);
var response = client.GetMetadata(new MetadataRequest(), callOptions);
```

**Server Implementation**:
```csharp
public override Task<MetadataResponse> GetMetadata(MetadataRequest request, ServerCallContext context)
{
    // Read request metadata
    var userId = context.RequestHeaders.GetValue("user-id");
    var correlationId = context.RequestHeaders.GetValue("correlation-id");
    
    // Set response metadata
    context.ResponseTrailers.Add("server-version", "1.0.0");
    context.ResponseTrailers.Add("processing-time", "150ms");
    
    return Task.FromResult(new MetadataResponse 
    { 
        Message = $"Processed for user {userId} with correlation {correlationId}" 
    });
}
```

### 1.2 Metadata Access Patterns
**Feature**: Various ways to access and manipulate metadata
**Methods**:
- `context.RequestHeaders` - Incoming request metadata
- `context.ResponseTrailers` - Outgoing response metadata
- `context.GetHeaderValue()` - Safe header value retrieval
- `context.AddHeader()` - Adding response headers

**Key Features**:
- Type-safe metadata access
- Header validation
- Custom metadata support
- Bidirectional metadata exchange

## 2. Deadline and Timeout Management

### 2.1 Client-Side Deadlines
**Feature**: Request timeout handling
**Location**: `Deadline` project
**Implementation**:
```csharp
// Calculate deadline based on current time
var deadline = DateTime.UtcNow.AddMilliseconds(clientTimeout);

try
{
    var reply = client.GetDelayedGreeting(
        new DelayedHelloRequest { Name = "Joe", Delay = serverDelay },
        deadline: deadline);
    
    Console.WriteLine($"Response: {reply.Message}");
}
catch (RpcException rpcException)
{
    if (rpcException.StatusCode == StatusCode.DeadlineExceeded)
    {
        Console.WriteLine("Request timed out!");
    }
}
```

### 2.2 Server-Side Deadline Handling
**Feature**: Server-side timeout awareness
**Implementation**:
```csharp
public override async Task<DelayedHelloReply> GetDelayedGreeting(
    DelayedHelloRequest request, ServerCallContext context)
{
    // Check if request has been cancelled due to deadline
    if (context.CancellationToken.IsCancellationRequested)
    {
        throw new RpcException(new Status(StatusCode.Cancelled, "Request cancelled"));
    }
    
    // Simulate work with delay
    await Task.Delay(request.Delay, context.CancellationToken);
    
    return new DelayedHelloReply 
    { 
        Message = $"Hello {request.Name} after {request.Delay}ms delay" 
    };
}
```

### 2.3 Deadline Propagation
**Feature**: Automatic deadline propagation through service calls
**Benefits**:
- Consistent timeout behavior
- Cascading timeout handling
- Resource cleanup
- Performance optimization

## 3. Server Reflection

### 3.1 Server Reflection Setup
**Feature**: Dynamic service discovery
**Location**: `ServerReflection` project
**Configuration**:
```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddGrpc();
    services.AddGrpcReflection();
}

public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    app.UseRouting();
    app.UseEndpoints(endpoints =>
    {
        endpoints.MapGrpcService<GreeterService>();
        endpoints.MapGrpcReflectionService();
    });
}
```

### 3.2 Reflection Usage
**Feature**: Client-side service introspection
**Tools**:
- `grpcurl` for command-line testing
- `BloomRPC` for GUI testing
- Programmatic reflection clients

**Example with grpcurl**:
```bash
# List all services
grpcurl -plaintext localhost:5001 list

# Describe a specific service
grpcurl -plaintext localhost:5001 describe Greeter

# Call a service method
grpcurl -plaintext -d '{"name":"World"}' localhost:5001 Greeter/SayHello
```

### 3.3 Reflection Benefits
**Features**:
- Dynamic service discovery
- Development and debugging
- Tool integration
- API documentation

## 4. Service Lifetime Management

### 4.1 Per-Call Lifetime (Default)
**Feature**: New service instance per request
**Characteristics**:
- Stateless design
- Thread-safe by default
- Automatic cleanup
- Memory efficient

**Implementation**:
```csharp
// Default behavior - no special configuration needed
public class CalculatorService : CalculatorServiceBase
{
    // New instance created for each request
    public override Task<CalculatorReply> Add(CalculatorRequest request, ServerCallContext context)
    {
        return Task.FromResult(new CalculatorReply { Result = request.N1 + request.N2 });
    }
}
```

### 4.2 Singleton Lifetime
**Feature**: Single service instance for all requests
**Location**: `LifeTime.ServiceHostSingleton`
**Configuration**:
```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddGrpc();
    services.AddSingleton<LifeTimeService>();
}
```

**Use Cases**:
- Stateful services
- Shared resources
- Performance optimization
- Caching scenarios

### 4.3 Google gRPC Lifetime
**Feature**: Google gRPC.Core lifetime behavior
**Location**: `LifeTime.ServiceHostGoogleGrpc`
**Characteristics**:
- Different lifetime model
- Native library integration
- Performance considerations
- Legacy compatibility

## 5. gRPC-Web Integration

### 5.1 gRPC-Web Setup
**Feature**: Browser-compatible gRPC communication
**Location**: `GrpcWeb` project
**Configuration**:
```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddGrpc();
    services.AddGrpcWeb();
}

public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    app.UseRouting();
    app.UseGrpcWeb();
    app.UseEndpoints(endpoints =>
    {
        endpoints.MapGrpcService<GreeterService>().EnableGrpcWeb();
    });
}
```

### 5.2 Browser Client Implementation
**Feature**: JavaScript client for gRPC-Web
**Implementation**:
```javascript
// gRPC-Web client example
const client = new GreeterClient('https://localhost:5001');
const request = new HelloRequest();
request.setName('World');

client.sayHello(request, {}, (err, response) => {
    if (err) {
        console.error('Error:', err);
    } else {
        console.log('Response:', response.getMessage());
    }
});
```

### 5.3 gRPC-Web Limitations
**Restrictions**:
- No client streaming
- No bidirectional streaming
- HTTP/1.1 transport
- Browser compatibility requirements

## 6. Interceptors and Middleware

### 6.1 Server Interceptors
**Feature**: Server-side request/response interception
**Use Cases**:
- Logging
- Authentication
- Authorization
- Performance monitoring

**Implementation**:
```csharp
public class LoggingInterceptor : Interceptor
{
    public override async Task<TResponse> UnaryServerHandler<TRequest, TResponse>(
        TRequest request,
        ServerCallContext context,
        UnaryServerMethod<TRequest, TResponse> continuation)
    {
        Console.WriteLine($"Received request: {typeof(TRequest).Name}");
        
        var response = await continuation(request, context);
        
        Console.WriteLine($"Sending response: {typeof(TResponse).Name}");
        
        return response;
    }
}
```

### 6.2 Client Interceptors
**Feature**: Client-side request/response interception
**Implementation**:
```csharp
public class LoggingInterceptor : Interceptor
{
    public override AsyncUnaryCall<TResponse> AsyncUnaryCall<TRequest, TResponse>(
        TRequest request,
        ClientInterceptorContext<TRequest, TResponse> context,
        AsyncUnaryCallContinuation<TRequest, TResponse> continuation)
    {
        Console.WriteLine($"Sending request: {typeof(TRequest).Name}");
        
        var call = continuation(request, context);
        
        return new AsyncUnaryCall<TResponse>(
            call.ResponseAsync,
            call.ResponseHeadersAsync,
            call.GetStatus,
            call.GetTrailers,
            call.Dispose);
    }
}
```

## 7. Health Checks

### 7.1 gRPC Health Checking
**Feature**: Service health monitoring
**Implementation**:
```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddGrpc();
    services.AddGrpcHealthChecks();
}

public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    app.UseRouting();
    app.UseEndpoints(endpoints =>
    {
        endpoints.MapGrpcService<GreeterService>();
        endpoints.MapGrpcHealthChecksService();
    });
}
```

### 7.2 Health Check Usage
**Feature**: Client-side health checking
**Implementation**:
```csharp
var healthClient = new Health.HealthClient(channel);
var healthCheckRequest = new HealthCheckRequest { Service = "Greeter" };

var healthResponse = healthClient.Check(healthCheckRequest);
Console.WriteLine($"Service status: {healthResponse.Status}");
```

## 8. Authentication and Authorization

### 8.1 Token-Based Authentication
**Feature**: JWT token authentication
**Implementation**:
```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddGrpc();
    services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = "your-issuer",
                ValidAudience = "your-audience",
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes("your-secret-key"))
            };
        });
}
```

### 8.2 Authorization in Services
**Feature**: Service-level authorization
**Implementation**:
```csharp
[Authorize]
public class SecureService : SecureServiceBase
{
    public override Task<SecureResponse> GetSecureData(SecureRequest request, ServerCallContext context)
    {
        var user = context.GetHttpContext().User;
        var userId = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        
        return Task.FromResult(new SecureResponse 
        { 
            Data = $"Secure data for user {userId}" 
        });
    }
}
```

## 9. Performance Monitoring

### 9.1 Metrics Collection
**Feature**: Performance metrics gathering
**Implementation**:
```csharp
public class MetricsInterceptor : Interceptor
{
    private readonly IMetrics _metrics;
    
    public override async Task<TResponse> UnaryServerHandler<TRequest, TResponse>(
        TRequest request,
        ServerCallContext context,
        UnaryServerMethod<TRequest, TResponse> continuation)
    {
        var stopwatch = Stopwatch.StartNew();
        
        try
        {
            var response = await continuation(request, context);
            _metrics.IncrementCounter("grpc_requests_total", new[] { "success" });
            return response;
        }
        catch (Exception ex)
        {
            _metrics.IncrementCounter("grpc_requests_total", new[] { "error" });
            throw;
        }
        finally
        {
            stopwatch.Stop();
            _metrics.RecordHistogram("grpc_request_duration_ms", stopwatch.ElapsedMilliseconds);
        }
    }
}
```

### 9.2 Distributed Tracing
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

## 10. Error Handling and Status Codes

### 10.1 gRPC Status Codes
**Feature**: Standardized error reporting
**Status Codes**:
- `OK` - Success
- `CANCELLED` - Request cancelled
- `UNKNOWN` - Unknown error
- `INVALID_ARGUMENT` - Invalid request
- `DEADLINE_EXCEEDED` - Timeout
- `NOT_FOUND` - Resource not found
- `ALREADY_EXISTS` - Resource already exists
- `PERMISSION_DENIED` - Access denied
- `UNAUTHENTICATED` - Authentication required
- `RESOURCE_EXHAUSTED` - Resource limits exceeded
- `FAILED_PRECONDITION` - Precondition failed
- `ABORTED` - Operation aborted
- `OUT_OF_RANGE` - Value out of range
- `UNIMPLEMENTED` - Method not implemented
- `INTERNAL` - Internal server error
- `UNAVAILABLE` - Service unavailable
- `DATA_LOSS` - Data corruption

### 10.2 Custom Error Handling
**Feature**: Application-specific error handling
**Implementation**:
```csharp
public override Task<CalculatorReply> Divide(CalculatorRequest request, ServerCallContext context)
{
    if (request.N2 == 0)
    {
        throw new RpcException(new Status(StatusCode.InvalidArgument, "Division by zero is not allowed"));
    }
    
    if (request.N1 < 0 || request.N2 < 0)
    {
        throw new RpcException(new Status(StatusCode.InvalidArgument, "Negative numbers not supported"));
    }
    
    return Task.FromResult(new CalculatorReply { Result = request.N1 / request.N2 });
}
```

## 11. Configuration Management

### 11.1 Service Configuration
**Feature**: Flexible service configuration
**Implementation**:
```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddGrpc(options =>
    {
        options.EnableDetailedErrors = true;
        options.MaxReceiveMessageSize = 4 * 1024 * 1024; // 4MB
        options.MaxSendMessageSize = 4 * 1024 * 1024; // 4MB
    });
}
```

### 11.2 Client Configuration
**Feature**: Client-side configuration options
**Implementation**:
```csharp
var channel = GrpcChannel.ForAddress("https://localhost:5001", new GrpcChannelOptions
{
    MaxReceiveMessageSize = 4 * 1024 * 1024, // 4MB
    MaxSendMessageSize = 4 * 1024 * 1024, // 4MB
    Credentials = ChannelCredentials.SecureSsl
});
```

## Summary

The advanced gRPC features demonstrated in the GrpcDemos project provide enterprise-grade capabilities for building production-ready distributed systems:

- **Metadata Handling**: Custom data exchange and context propagation
- **Deadline Management**: Robust timeout and cancellation support
- **Server Reflection**: Dynamic service discovery and tooling integration
- **Service Lifetime**: Flexible instance management patterns
- **gRPC-Web**: Browser compatibility and web integration
- **Interceptors**: Cross-cutting concerns and middleware support
- **Health Checks**: Service monitoring and reliability
- **Authentication**: Security and access control
- **Performance Monitoring**: Metrics, tracing, and observability
- **Error Handling**: Comprehensive error management and status reporting
- **Configuration**: Flexible service and client configuration

These advanced features make gRPC suitable for complex, enterprise-scale applications requiring high performance, reliability, security, and observability.
