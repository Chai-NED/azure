library(httr)

# Security info
token <- readLines("adls-r/1a-AuthToken.txt")
auth <- paste("Bearer", token, " ")

# Variables
adlsAccountName <- "<get your own>"
fileName <- "test1.txt"
adlsPath <- paste("", "Samples/testDir2", fileName, sep="/")
localPath <- paste("samples2", fileName, sep="/")
op <- "OPEN"

# Execute
adlsUri <- paste("https://", adlsAccountName, ".azuredatalakestore.net/webhdfs/v1/", adlsPath, sep="")

uri = paste(adlsUri, "?op=", op, "&read=true", sep="")

r <- httr::GET(uri, add_headers(Authorization = auth), write_disk(localPath, overwrite = TRUE), progress())

readLines(localPath)
