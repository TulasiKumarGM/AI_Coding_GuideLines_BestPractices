# C# Development Coding Guidelines and Best Practices

## Table of Contents
1. [Naming Conventions](#naming-conventions)
2. [Code Formatting and Style](#code-formatting-and-style)
3. [Exception Handling](#exception-handling)
4. [Performance and Memory Management](#performance-and-memory-management)
5. [Security Best Practices](#security-best-practices)
6. [Async/Await Patterns](#asyncawait-patterns)
7. [Unit Testing and Documentation](#unit-testing-and-documentation)
8. [Code Organization](#code-organization)
9. [Common Anti-Patterns to Avoid](#common-anti-patterns-to-avoid)

---

## Naming Conventions

### General Principles
- Use PascalCase for public members, types, and methods
- Use camelCase for private fields, local variables, and parameters
- Use descriptive names that clearly indicate purpose
- Avoid abbreviations unless they are widely understood
- Use meaningful names for boolean variables (e.g., `isValid`, `hasPermission`)

### Specific Conventions

#### Classes and Interfaces
```csharp
// ✅ Good
public class CustomerService { }
public interface IRepository<T> { }

// ❌ Bad
public class custSvc { }
public interface repo { }
```

#### Methods and Properties
```csharp
// ✅ Good
public string GetCustomerName(int customerId) { }
public bool IsActive { get; set; }

// ❌ Bad
public string getCustName(int id) { }
public bool active { get; set; }
```

#### Constants and Fields
```csharp
// ✅ Good
public const int MaxRetryAttempts = 3;
private readonly string _connectionString;
private static readonly object _lockObject = new object();

// ❌ Bad
public const int MAX_RETRY_ATTEMPTS = 3;
private readonly string connectionString;
```

#### Enums
```csharp
// ✅ Good
public enum OrderStatus
{
    Pending,
    Processing,
    Shipped,
    Delivered
}

// ❌ Bad
public enum orderStatus
{
    pending,
    processing,
    shipped,
    delivered
}
```

---

## Code Formatting and Style

### Indentation and Spacing
- Use 4 spaces for indentation (not tabs)
- Place opening braces on the same line as the declaration
- Use blank lines to separate logical groups of code
- Maximum line length: 120 characters

```csharp
// ✅ Good
public class CustomerService
{
    private readonly IRepository<Customer> _repository;

    public CustomerService(IRepository<Customer> repository)
    {
        _repository = repository ?? throw new ArgumentNullException(nameof(repository));
    }

    public async Task<Customer> GetCustomerAsync(int customerId)
    {
        if (customerId <= 0)
        {
            throw new ArgumentException("Customer ID must be positive", nameof(customerId));
        }

        return await _repository.GetByIdAsync(customerId);
    }
}
```

### Braces and Control Structures
```csharp
// ✅ Good - Always use braces, even for single statements
if (condition)
{
    DoSomething();
}

// ❌ Bad
if (condition)
    DoSomething();
```

### LINQ Formatting
```csharp
// ✅ Good - Multi-line LINQ with proper indentation
var activeCustomers = customers
    .Where(c => c.IsActive)
    .OrderBy(c => c.LastName)
    .ThenBy(c => c.FirstName)
    .Select(c => new CustomerDto
    {
        Id = c.Id,
        FullName = $"{c.FirstName} {c.LastName}",
        Email = c.Email
    })
    .ToList();
```

---

## Exception Handling

### General Principles
- Use specific exception types when possible
- Don't catch exceptions you can't handle
- Always validate input parameters
- Use `ArgumentNullException` and `ArgumentException` for parameter validation
- Log exceptions appropriately

### Exception Handling Patterns

```csharp
// ✅ Good - Specific exception handling
public async Task<Customer> GetCustomerAsync(int customerId)
{
    try
    {
        if (customerId <= 0)
        {
            throw new ArgumentException("Customer ID must be positive", nameof(customerId));
        }

        return await _repository.GetByIdAsync(customerId);
    }
    catch (EntityNotFoundException ex)
    {
        _logger.LogWarning("Customer with ID {CustomerId} not found", customerId);
        throw;
    }
    catch (DatabaseException ex)
    {
        _logger.LogError(ex, "Database error occurred while retrieving customer {CustomerId}", customerId);
        throw new ServiceException("Unable to retrieve customer", ex);
    }
}

// ❌ Bad - Generic exception catching
public async Task<Customer> GetCustomerAsync(int customerId)
{
    try
    {
        return await _repository.GetByIdAsync(customerId);
    }
    catch (Exception ex)
    {
        // Swallowing the exception - bad practice
        return null;
    }
}
```

### Using Statements and Resource Management
```csharp
// ✅ Good - Using statement for IDisposable
public async Task<string> ReadFileAsync(string filePath)
{
    using var fileStream = new FileStream(filePath, FileMode.Open);
    using var reader = new StreamReader(fileStream);
    return await reader.ReadToEndAsync();
}

// ✅ Good - Multiple using statements
public async Task ProcessDataAsync()
{
    using var httpClient = new HttpClient();
    using var cancellationTokenSource = new CancellationTokenSource(TimeSpan.FromMinutes(5));
    
    var response = await httpClient.GetAsync("https://api.example.com/data", cancellationTokenSource.Token);
    // Process response...
}
```

---

## Performance and Memory Management

### String Handling
```csharp
// ✅ Good - Use StringBuilder for multiple concatenations
public string BuildQueryString(Dictionary<string, string> parameters)
{
    var queryBuilder = new StringBuilder();
    queryBuilder.Append("?");
    
    foreach (var param in parameters)
    {
        queryBuilder.Append($"{param.Key}={param.Value}&");
    }
    
    return queryBuilder.ToString().TrimEnd('&');
}

// ✅ Good - Use string interpolation
var message = $"Hello {firstName} {lastName}, your order #{orderId} is ready.";

// ❌ Bad - String concatenation in loops
string result = "";
foreach (var item in items)
{
    result += item + ","; // Creates new string each iteration
}
```

### Collections and LINQ
```csharp
// ✅ Good - Use appropriate collection types
private readonly List<Customer> _customers = new List<Customer>();
private readonly Dictionary<int, Customer> _customerCache = new Dictionary<int, Customer>();

// ✅ Good - Efficient LINQ usage
public IEnumerable<Customer> GetActiveCustomers()
{
    return _customers
        .Where(c => c.IsActive)
        .OrderBy(c => c.LastName);
}

// ❌ Bad - Inefficient LINQ
public List<Customer> GetActiveCustomers()
{
    return _customers
        .Where(c => c.IsActive)
        .OrderBy(c => c.LastName)
        .ToList() // Unnecessary ToList() if you're just iterating
        .Where(c => c.Email != null) // Multiple enumerations
        .ToList();
}
```

### Memory Management
```csharp
// ✅ Good - Implement IDisposable for unmanaged resources
public class DatabaseConnection : IDisposable
{
    private bool _disposed = false;
    private readonly SqlConnection _connection;

    public DatabaseConnection(string connectionString)
    {
        _connection = new SqlConnection(connectionString);
    }

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    protected virtual void Dispose(bool disposing)
    {
        if (!_disposed)
        {
            if (disposing)
            {
                _connection?.Dispose();
            }
            _disposed = true;
        }
    }
}
```

---

## Security Best Practices

### Input Validation
```csharp
// ✅ Good - Comprehensive input validation
public class UserService
{
    public async Task<User> CreateUserAsync(CreateUserRequest request)
    {
        if (request == null)
            throw new ArgumentNullException(nameof(request));
        
        if (string.IsNullOrWhiteSpace(request.Email))
            throw new ArgumentException("Email is required", nameof(request.Email));
        
        if (!IsValidEmail(request.Email))
            throw new ArgumentException("Invalid email format", nameof(request.Email));
        
        if (string.IsNullOrWhiteSpace(request.Password))
            throw new ArgumentException("Password is required", nameof(request.Password));
        
        if (request.Password.Length < 8)
            throw new ArgumentException("Password must be at least 8 characters", nameof(request.Password));
        
        // Sanitize input
        var sanitizedEmail = request.Email.Trim().ToLowerInvariant();
        
        return await _userRepository.CreateAsync(new User
        {
            Email = sanitizedEmail,
            PasswordHash = HashPassword(request.Password)
        });
    }
    
    private static bool IsValidEmail(string email)
    {
        try
        {
            var addr = new System.Net.Mail.MailAddress(email);
            return addr.Address == email;
        }
        catch
        {
            return false;
        }
    }
}
```

### SQL Injection Prevention
```csharp
// ✅ Good - Use parameterized queries
public async Task<Customer> GetCustomerByEmailAsync(string email)
{
    const string sql = "SELECT * FROM Customers WHERE Email = @Email";
    
    using var connection = new SqlConnection(_connectionString);
    using var command = new SqlCommand(sql, connection);
    command.Parameters.AddWithValue("@Email", email);
    
    await connection.OpenAsync();
    using var reader = await command.ExecuteReaderAsync();
    
    if (await reader.ReadAsync())
    {
        return MapCustomerFromReader(reader);
    }
    
    return null;
}

// ❌ Bad - SQL injection vulnerability
public async Task<Customer> GetCustomerByEmailAsync(string email)
{
    var sql = $"SELECT * FROM Customers WHERE Email = '{email}'"; // Vulnerable!
    // ... rest of the code
}
```

---

## Async/Await Patterns

### General Guidelines
- Use `async`/`await` for I/O operations
- Avoid `async void` except for event handlers
- Use `ConfigureAwait(false)` in library code
- Don't block on async code with `.Result` or `.Wait()`

### Proper Async Patterns
```csharp
// ✅ Good - Proper async method
public async Task<Customer> GetCustomerAsync(int customerId)
{
    if (customerId <= 0)
        throw new ArgumentException("Customer ID must be positive", nameof(customerId));
    
    try
    {
        var customer = await _repository.GetByIdAsync(customerId).ConfigureAwait(false);
        return customer;
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error retrieving customer {CustomerId}", customerId);
        throw;
    }
}

// ✅ Good - Async event handler
private async void OnButtonClick(object sender, EventArgs e)
{
    try
    {
        await ProcessDataAsync();
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error processing data");
        MessageBox.Show("An error occurred while processing data.");
    }
}

// ❌ Bad - Blocking async code
public Customer GetCustomer(int customerId)
{
    return GetCustomerAsync(customerId).Result; // Can cause deadlocks
}

// ❌ Bad - Fire and forget without proper error handling
public void ProcessData()
{
    _ = ProcessDataAsync(); // Exceptions will be lost
}
```

### Cancellation Support
```csharp
// ✅ Good - Support cancellation
public async Task<List<Customer>> GetCustomersAsync(CancellationToken cancellationToken = default)
{
    try
    {
        return await _repository.GetAllAsync(cancellationToken).ConfigureAwait(false);
    }
    catch (OperationCanceledException)
    {
        _logger.LogInformation("Operation was cancelled");
        throw;
    }
}

// Usage with timeout
public async Task<List<Customer>> GetCustomersWithTimeoutAsync()
{
    using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
    return await GetCustomersAsync(cts.Token);
}
```

---

## Unit Testing and Documentation

### Unit Testing Best Practices
```csharp
// ✅ Good - Well-structured unit test
[Test]
public async Task GetCustomerAsync_ValidId_ReturnsCustomer()
{
    // Arrange
    var customerId = 123;
    var expectedCustomer = new Customer { Id = customerId, Name = "John Doe" };
    _mockRepository.Setup(r => r.GetByIdAsync(customerId))
                  .ReturnsAsync(expectedCustomer);
    
    // Act
    var result = await _customerService.GetCustomerAsync(customerId);
    
    // Assert
    Assert.That(result, Is.Not.Null);
    Assert.That(result.Id, Is.EqualTo(customerId));
    Assert.That(result.Name, Is.EqualTo("John Doe"));
    _mockRepository.Verify(r => r.GetByIdAsync(customerId), Times.Once);
}

[Test]
public void GetCustomerAsync_InvalidId_ThrowsArgumentException()
{
    // Arrange
    var invalidId = -1;
    
    // Act & Assert
    var ex = Assert.ThrowsAsync<ArgumentException>(
        () => _customerService.GetCustomerAsync(invalidId));
    
    Assert.That(ex.ParamName, Is.EqualTo("customerId"));
}
```

### XML Documentation
```csharp
/// <summary>
/// Retrieves a customer by their unique identifier.
/// </summary>
/// <param name="customerId">The unique identifier of the customer to retrieve.</param>
/// <param name="cancellationToken">A token to cancel the asynchronous operation.</param>
/// <returns>
/// A task that represents the asynchronous operation. The task result contains
/// the customer if found; otherwise, null.
/// </returns>
/// <exception cref="ArgumentException">
/// Thrown when <paramref name="customerId"/> is less than or equal to zero.
/// </exception>
/// <exception cref="ServiceException">
/// Thrown when an error occurs while retrieving the customer.
/// </exception>
public async Task<Customer> GetCustomerAsync(int customerId, CancellationToken cancellationToken = default)
{
    // Implementation...
}
```

---

## Code Organization

### Project Structure
```
MyProject/
├── src/
│   ├── MyProject.Core/           # Domain models, interfaces
│   ├── MyProject.Infrastructure/ # Data access, external services
│   ├── MyProject.Application/    # Business logic, services
│   └── MyProject.Web/           # Controllers, API endpoints
├── tests/
│   ├── MyProject.UnitTests/
│   └── MyProject.IntegrationTests/
└── docs/
```

### Namespace Organization
```csharp
// ✅ Good - Clear namespace hierarchy
namespace MyProject.Core.Entities
{
    public class Customer { }
}

namespace MyProject.Core.Interfaces
{
    public interface IRepository<T> { }
}

namespace MyProject.Application.Services
{
    public class CustomerService { }
}

namespace MyProject.Infrastructure.Data
{
    public class SqlCustomerRepository : IRepository<Customer> { }
}
```

### Dependency Injection
```csharp
// ✅ Good - Register services in Program.cs or Startup.cs
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<ICustomerService, CustomerService>();
        services.AddScoped<IRepository<Customer>, SqlCustomerRepository>();
        services.AddScoped<IEmailService, SmtpEmailService>();
        
        return services;
    }
}

// Usage in Program.cs
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddApplicationServices();
```

---

## Common Anti-Patterns to Avoid

### 1. God Classes
```csharp
// ❌ Bad - God class doing too much
public class CustomerManager
{
    public void CreateCustomer() { }
    public void UpdateCustomer() { }
    public void DeleteCustomer() { }
    public void SendEmail() { }
    public void GenerateReport() { }
    public void ProcessPayment() { }
    public void ValidateAddress() { }
    // ... 50+ more methods
}

// ✅ Good - Single responsibility classes
public class CustomerService
{
    public async Task<Customer> CreateCustomerAsync(CreateCustomerRequest request) { }
    public async Task<Customer> UpdateCustomerAsync(int id, UpdateCustomerRequest request) { }
    public async Task DeleteCustomerAsync(int id) { }
}

public class EmailService
{
    public async Task SendWelcomeEmailAsync(Customer customer) { }
}

public class ReportService
{
    public async Task<CustomerReport> GenerateCustomerReportAsync() { }
}
```

### 2. Primitive Obsession
```csharp
// ❌ Bad - Using primitives for domain concepts
public class Order
{
    public string CustomerEmail { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; }
}

// ✅ Good - Using value objects
public class Order
{
    public EmailAddress CustomerEmail { get; set; }
    public Money TotalAmount { get; set; }
    public OrderStatus Status { get; set; }
}

public class EmailAddress
{
    public string Value { get; }
    
    public EmailAddress(string value)
    {
        if (!IsValidEmail(value))
            throw new ArgumentException("Invalid email address", nameof(value));
        Value = value;
    }
    
    private static bool IsValidEmail(string email) { /* validation logic */ }
}
```

### 3. Exception Swallowing
```csharp
// ❌ Bad - Swallowing exceptions
public void ProcessFile(string filePath)
{
    try
    {
        var content = File.ReadAllText(filePath);
        ProcessContent(content);
    }
    catch (Exception ex)
    {
        // Silent failure - very bad!
    }
}

// ✅ Good - Proper exception handling
public async Task ProcessFileAsync(string filePath)
{
    try
    {
        var content = await File.ReadAllTextAsync(filePath);
        await ProcessContentAsync(content);
    }
    catch (FileNotFoundException ex)
    {
        _logger.LogError(ex, "File not found: {FilePath}", filePath);
        throw new ProcessingException($"File not found: {filePath}", ex);
    }
    catch (UnauthorizedAccessException ex)
    {
        _logger.LogError(ex, "Access denied to file: {FilePath}", filePath);
        throw new ProcessingException($"Access denied to file: {filePath}", ex);
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Unexpected error processing file: {FilePath}", filePath);
        throw;
    }
}
```

---

## Conclusion

---

## Additional Microsoft-Aligned Best Practices

### Nullable Reference Types
- Enable nullable in all projects and treat warnings as errors where feasible.
- Prefer non-nullable reference types by default; use `?` only when truly optional.
- Validate and guard inputs; use `ArgumentNullException.ThrowIfNull(...)`.
- Avoid `!` (null-forgiving) except at well-justified boundaries.

```xml
<!-- In .csproj -->
<PropertyGroup>
  <Nullable>enable</Nullable>
  <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
</PropertyGroup>
```

### Analyzers and Style Enforcement
- Enable .NET analyzers and include StyleCop.Analyzers for style consistency.
- Use `.editorconfig` to enforce formatting and naming rules.
- Fail builds on analyzer warnings in CI for libraries; consider phased adoption for apps.

```xml
<ItemGroup>
  <PackageReference Include="StyleCop.Analyzers" Version="1.2.0" PrivateAssets="all" />
</ItemGroup>
<PropertyGroup>
  <AnalysisLevel>latest</AnalysisLevel>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <CodeAnalysisTreatWarningsAsErrors>true</CodeAnalysisTreatWarningsAsErrors>
</PropertyGroup>
```

### Source Link and Deterministic Builds
- Enable Source Link, deterministic and reproducible builds for libraries.

```xml
<PropertyGroup>
  <PublishRepositoryUrl>true</PublishRepositoryUrl>
  <EmbedUntrackedSources>true</EmbedUntrackedSources>
  <ContinuousIntegrationBuild>true</ContinuousIntegrationBuild>
  <Deterministic>true</Deterministic>
</PropertyGroup>
<ItemGroup>
  <PackageReference Include="Microsoft.SourceLink.GitHub" Version="8.0.0" PrivateAssets="All" />
</ItemGroup>
```

### Async Naming and ConfigureAwait
- Suffix async methods with `Async`.
- Avoid `async void` except event handlers.
- In libraries, use `ConfigureAwait(false)` on awaits; in applications, prefer default context.

```csharp
public async Task<Data> FetchAsync(CancellationToken ct) =>
    await _client.GetAsync(ct).ConfigureAwait(false);
```

### Thread-Safety and Immutability
- Prefer immutable types and records for value-like data.
- Minimize shared state; when needed, protect with `lock`, `SemaphoreSlim`, or concurrent collections.
- Avoid static mutable state; if required, ensure proper synchronization.

```csharp
private readonly object _gate = new();
public void AddItem(Item item)
{
    lock (_gate)
    {
        _items.Add(item);
    }
}
```

### Logging Standards
- Use `Microsoft.Extensions.Logging` abstractions.
- Choose appropriate log levels; avoid logging secrets/PII. Use event IDs where applicable.
- Prefer structured logging with named placeholders.

```csharp
_logger.LogInformation(EventIds.UserCreated, "User {UserId} created", user.Id);
```

### Configuration and Options
- Bind strongly typed options with validation and fail-fast on invalid configuration.
- Store secrets outside source code (User Secrets, environment variables, Key Vault).

```csharp
builder.Services.AddOptions<MySettings>()
    .Bind(builder.Configuration.GetSection("MySettings"))
    .ValidateDataAnnotations()
    .ValidateOnStart();
```

### Dependency Versioning and Packaging
- Pin versions; avoid floating versions. Keep dependencies updated regularly.
- Verify licenses and transitive dependencies. Minimize dependency surface for libraries.

### Serialization Guidelines
- Prefer `System.Text.Json`; define explicit contracts and casing (camelCase).
- Provide custom converters for complex types and date/time.

```csharp
builder.Services.ConfigureHttpJsonOptions(o =>
{
    o.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    o.SerializerOptions.Converters.Add(new JsonStringEnumConverter());
});
```

### Date and Time
- Use UTC for storage and `DateTimeOffset` for external inputs and timestamps.
- Avoid `DateTime.Now`; prefer `DateTimeOffset.UtcNow`. Centralize clock access via an interface where needed.

### Analyzer Suppression Policy
- Fix warnings rather than suppress. If suppression is necessary:
  - Prefer targeted `#pragma warning disable/restore` scoped to minimal code.
  - Include clear justification and tracking link.
  - Avoid global or project-wide suppressions unless formally approved.

### Style Decisions
- Use file-scoped namespaces.
- Order `using` directives: System first, then third-party, then project, sorted alphabetically.
- Prefer explicit types when it improves clarity; `var` when the type is obvious.
- Consider expression-bodied members for simple properties/methods.

```csharp
namespace MyApp.Models;
public record User(Guid Id, string Email);
```

### Records vs Classes
- Use records for immutable, value-like data and withers; classes for entities with identity and behavior.

```csharp
public record Money(decimal Amount, string Currency)
{
    public Money Convert(decimal rate) => this with { Amount = Amount * rate };
}
```

### Span/Memory for High-Performance Code
- In hot paths, consider `Span<T>`, `ReadOnlySpan<T>`, and pooling to reduce allocations.
- Avoid premature optimization; measure with benchmarks before adopting.

```csharp
public static int ParseLeadingInt(ReadOnlySpan<char> s)
{
    int value = 0;
    foreach (var ch in s)
    {
        if (!char.IsDigit(ch)) break;
        value = checked(value * 10 + (ch - '0'));
    }
    return value;
}
```

### Error Model for Libraries
- Throw meaningful exceptions; avoid returning null for exceptional control flow.
- Design a clear exception taxonomy; document thrown exceptions in XML docs.

### Code Review Policy (Process)
- Definition of done includes: analyzers clean, tests updated, docs updated, and security reviewed.
- Require at least one reviewer; block merging on failing checks.

---

## Conclusion

These guidelines represent Microsoft's recommended best practices for C# development. Following these standards will help ensure:

- **Consistency** across your codebase
- **Maintainability** of your code
- **Performance** optimization
- **Security** best practices
- **Readability** and collaboration

Remember to adapt these guidelines to your specific project requirements while maintaining the core principles of clean, maintainable, and secure code.

---

*This document is based on Microsoft's official C# coding conventions and best practices as of 2024.*


