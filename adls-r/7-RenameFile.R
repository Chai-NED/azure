library(httr)

source("security.R")

### User specified
adlsFolder <- paste("Samples/testFolder", sep="/")
adlsFileNameCurrent <- "test1.txt"
adlsFileNameNew <- "test2.txt"

# Security info
auth <- paste("Bearer", security_get_token(), " ")

# Execute
op <- "RENAME"

adlsPathCurrent <- paste(adlsFolder, adlsFileNameCurrent, sep="/")
adlsPathNew <- paste(adlsFolder, adlsFileNameNew, sep="/")

adlsUri <- paste("https://", security_adls_account_name, ".azuredatalakestore.net/webhdfs/v1/", adlsPathCurrent, sep="")

uri = paste(adlsUri, "?op=", op, "&destination=", adlsPathNew, sep="")

r <- httr::PUT(uri, add_headers(Authorization = auth))

r$status_code
content(r, "text")