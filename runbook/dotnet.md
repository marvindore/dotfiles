 - 1. Initialize user-secrets (adds UserSecretsId automatically)
 dotnet user-secrets init
 
 - 2. Set your secrets
 dotnet user-secrets set "SomeApi:ApiKey" "your-secret-key"
 dotnet user-secrets set "Database:Password" "your-db-password"
 
 - 3. Verify secrets are stored
 dotnet user-secrets list
 
 - 4. (Optional) Remove a secret
 dotnet user-secrets remove "SomeApi:ApiKey"
 
 - 5. (Optional) Clear all secrets
 dotnet user-secrets clear
