library(httr)

# Security info
token <- readLines("adls-r/1a-AuthToken.txt")
auth <- paste("Bearer", token, " ")

# Variables
adlsAccountName <- "<get your own>"
adlsFolder <- paste("Samples/testDir2", sep="/")
adlsFileNameCurrent <- "test1A.txt"
adlsFileNameNew <- "test1.txt"
op <- "RENAME"

# Execute
adlsPathCurrent <- paste(adlsFolder, adlsFileNameCurrent, sep="/")
adlsPathNew <- paste(adlsFolder, adlsFileNameNew, sep="/")

adlsUri <- paste("https://", adlsAccountName, ".azuredatalakestore.net/webhdfs/v1/", adlsPathCurrent, sep="")

uri = paste(adlsUri, "?op=", op, "&destination=", adlsPathNew, sep="")

r <- httr::PUT(uri, add_headers(Authorization = auth))

r$status_code
content(r, "text")