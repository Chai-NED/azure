library(httr)

source("security.R")

### User specified
fileName <- "test1.txt"
adlsPath <- paste("", "Data/Analysis/TestFolder", fileName, sep="/")
localPath <- paste("d:/test", fileName, sep="/")

# Security info
auth <- paste("Bearer", security_get_token(), " ")

# Execute
op <- "OPEN"

adlsUri <- paste(
	"https://",
	security_adls_account_name,
	".azuredatalakestore.net/webhdfs/v1/",
	adlsPath,
	sep=""
)

uri = paste(adlsUri, "?op=", op, "&read=true", sep="")

r <- httr::GET(
	uri,
	add_headers(Authorization = auth),
	write_disk(
		localPath,
		overwrite = TRUE),
	progress()
)

readLines(localPath)