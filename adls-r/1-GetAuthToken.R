library(httr)
library(jsonlite)
library(curl)

# Variables
tenant_id <- "<get your own>" # Azure AD directory ID
client_id <- "<get your own>" # From Azure AD app
client_secret <- "<get your own>" # From Azure AD app
localTokenFilePath <- "adls-r/1a-AuthToken.txt" # Save auth token here for other scripts to read from

# Exec
uri = paste("https://login.windows.net", tenant_id, "oauth2/token", sep = "/")

h <- new_handle()

handle_setform(h,
               "grant_type"="client_credentials",
               "resource"="https://management.core.windows.net/",
               "client_id"=client_id,
               "client_secret"=client_secret
)

req <- curl_fetch_memory(uri, handle = h)
res <- fromJSON(rawToChar(req$content))

token <- res$access_token

writeLines(token, localTokenFilePath)