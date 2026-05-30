FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
EXPOSE 8080
EXPOSE 8081
ENV ASPNETCORE_URLS=http://+:8080

# Copy pre-built binaries from the 'latest' folder
COPY latest/ .

ENTRYPOINT ["dotnet", "hacman-app-back.dll"]
