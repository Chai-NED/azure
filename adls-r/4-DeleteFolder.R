library(httr)

# Security info
token <- readLines("adls-r/1a-AuthToken.txt")
auth <- paste("Bearer", token, " ")

# Variables
adlsAccountName <- "<get your own>"
adlsFolderName <- "Samples/testDir1/"
op <- "DELETE"
recursive <- "true"

#Exec
adlsUri <- paste("https://", adlsAccountName, ".azuredatalakestore.net/webhdfs/v1/", adlsFolderName, sep="")

uri = paste(adlsUri, "?op=", op, "&recursive=", recursive, sep="")

r <- httr::DELETE(uri, add_headers(Authorization = auth))

r$status_code