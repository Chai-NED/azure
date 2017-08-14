library(httr)

# Security info
token <- readLines("adls-r/1a-AuthToken.txt")
auth <- paste("Bearer", token, " ")

# Variables
adlsAccountName <- "<get your own>"
fileName <- "test1.txt"
adlsPath <- paste("Samples/testDir2", fileName, sep="/")
op <- "DELETE"

# Execute
adlsUri <- paste("https://", adlsAccountName, ".azuredatalakestore.net/webhdfs/v1/", adlsPath, sep="")

uri = paste(adlsUri, "?op=", op, sep="")

r <- httr::DELETE(uri, body = payload, add_headers(Authorization = auth))

r$status_code