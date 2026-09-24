FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine3.24 AS build

WORKDIR /src

COPY api-tarjetas/ApiTarjetas.csproj ./
RUN dotnet restore ApiTarjetas.csproj

COPY api-tarjetas/ ./
RUN dotnet publish ApiTarjetas.csproj -c Release -o /out --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine3.24

WORKDIR /app

COPY --from=build /out/ ./

USER app

EXPOSE 8080

ENTRYPOINT ["dotnet", "ApiTarjetas.dll"]