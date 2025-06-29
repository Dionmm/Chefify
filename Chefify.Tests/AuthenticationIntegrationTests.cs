using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Chefify.Core.Interfaces.Services;

namespace Chefify.Tests;

public class AuthenticationIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public AuthenticationIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public void UserService_IsRegistered()
    {
        using var scope = _factory.Services.CreateScope();
        var userService = scope.ServiceProvider.GetService<IUserService>();
        
        Assert.NotNull(userService);
    }

    [Fact]
    public void AuthenticationConfiguration_IsLoaded()
    {
        using var scope = _factory.Services.CreateScope();
        var config = scope.ServiceProvider.GetRequiredService<IConfiguration>();
        
        var authority = config["Authentication:OIDC:Authority"];
        var clientId = config["Authentication:OIDC:ClientId"];

        Assert.NotNull(authority);
        Assert.NotNull(clientId);
    }
}