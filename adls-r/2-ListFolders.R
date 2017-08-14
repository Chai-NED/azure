library(httr)

# Security info
token <- readLines("adls-r/1a-AuthToken.txt")
auth <- paste("Bearer", token, " ")

# Variables
adlsAccountName <- "<get your own>"
adlsFolderName <- "Samples"
op <- "LISTSTATUS"

#Exec
adlsUri <- paste("https://", adlsAccountName, ".azuredatalakestore.net/webhdfs/v1", sep="")

uri = paste(adlsUri, adlsFolderName, paste("?op=", op, sep=""), sep="/")

r <- httr::GET(uri, add_headers(Authorization = auth))

jsonlite::toJSON(jsonlite::fromJSON(content(r, "text")), pretty = TRUE)
