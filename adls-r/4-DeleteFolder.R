library(httr)

source("security.R")

### User specified
adlsFolderName <- "Samples/testFolder/"
recursive <- "true"

# Security info
auth <- paste("Bearer", security_get_token(), " ")

#Exec
op <- "DELETE"

adlsUri <- paste("https://", security_adls_account_name, ".azuredatalakestore.net/webhdfs/v1/", adlsFolderName, sep="")

uri = paste(adlsUri, "?op=", op, "&recursive=", recursive, sep="")

r <- httr::DELETE(uri, add_headers(Authorization = auth))

r$status_code