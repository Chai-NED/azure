library(httr)

source("security.R")

### User specified
adlsFolderName <- "Samples"

# Security info
auth <- paste("Bearer", security_get_token(), " ")

#Exec
op <- "LISTSTATUS"

adlsUri <- paste("https://", security_adls_account_name, ".azuredatalakestore.net/webhdfs/v1", sep="")

uri = paste(adlsUri, adlsFolderName, paste("?op=", op, sep=""), sep="/")

r <- httr::GET(uri, add_headers(Authorization = auth))

jsonlite::toJSON(jsonlite::fromJSON(content(r, "text")), pretty = TRUE)
