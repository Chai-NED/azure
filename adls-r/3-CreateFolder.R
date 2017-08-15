library(httr)

source("security.R")

### User specified
adlsFolderName <- "Samples/testFolder"

# Security info
auth <- paste("Bearer", security_get_token(), " ")

#Exec
op <- "MKDIRS"

adlsUri <- paste("https://", security_adls_account_name, ".azuredatalakestore.net/webhdfs/v1/", adlsFolderName, sep="")

uri = paste(adlsUri, paste("?op=", op, sep=""), sep="/")

r <- httr::PUT(uri, add_headers(Authorization = auth))

content(r, "text")