library(httr)

# Security info
token <- readLines("adls-r/1a-AuthToken.txt")
auth <- paste("Bearer", token, " ")

# Variables
adlsAccountName <- "<get your own>"
adlsFolderName <- "Samples/testFolder"
op <- "MKDIRS"

#Exec
adlsUri <- paste("https://", adlsAccountName, ".azuredatalakestore.net/webhdfs/v1/", adlsFolderName, sep="")

uri = paste(adlsUri, paste("?op=", op, sep=""), sep="/")

r <- httr::PUT(uri, add_headers(Authorization = auth))

content(r, "text")