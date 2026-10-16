# ─────────────────────────────────────────────────────────────────
# Stage 1: BUILD  (SDK image – compiles the app)
# ─────────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy project file and restore dependencies first (layer caching)
COPY ["AuthApp.csproj", "./"]
RUN dotnet restore "AuthApp.csproj"

# Copy all source files and publish a release build
COPY . .
RUN dotnet publish "AuthApp.csproj" \
    -c Release \
    -o /app/publish \
    --no-restore

# ─────────────────────────────────────────────────────────────────
# Stage 2: RUNTIME  (small runtime-only image)
# ─────────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# Create a non-root user for security
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Copy published output from build stage
COPY --from=build /app/publish .

# Create directory for SQLite database with proper permissions
RUN mkdir -p /app/data && chown -R appuser:appgroup /app/data

# Switch to non-root user
USER appuser

# Expose port 80
EXPOSE 80

# Environment variables
ENV ASPNETCORE_URLS=http://+:80
ENV ASPNETCORE_ENVIRONMENT=Production

# Set SQLite DB path to the persistent data volume
ENV ConnectionStrings__DefaultConnection="Data Source=/app/data/authapp.db"

ENTRYPOINT ["dotnet", "AuthApp.dll"]
