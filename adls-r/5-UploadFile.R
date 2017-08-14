library(httr)

# Security info
token <- readLines("adls-r/1a-AuthToken.txt")
auth <- paste("Bearer", token, " ")

# Variables
adlsAccountName <- "<get your own>"
fileName <- "test1.txt"
localPath <- paste("samples", fileName, sep="/")
adlsPath <- paste("Samples/testDir2", fileName, sep="/")
op <- "CREATE"

# Execute
adlsUri <- paste("https://", adlsAccountName, ".azuredatalakestore.net/webhdfs/v1/", adlsPath, sep="")

uri = paste(adlsUri, "?op=", op, "&overwrite=true&write=true", sep="")

payload <- upload_file(localPath)

r <- httr::PUT(uri, body = payload, add_headers(Authorization = auth, "Transfer-Encoding"="chunked"), verbose(), progress())

r$status_code