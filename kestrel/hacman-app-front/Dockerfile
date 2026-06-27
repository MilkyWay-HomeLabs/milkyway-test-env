FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

# This will now work because 'latest' is a clean folder with no nested 'latest'
COPY latest/ .

ENTRYPOINT ["dotnet", "hacman-app-front.dll"]
