library(httr)

source("security.R")

### User specified
fileName <- "test1.txt"
adlsPath <- paste("Data/Analysis/TestFolder", fileName, sep="/")

# Security info
auth <- paste("Bearer", security_get_token(), " ")

# Execute
op <- "DELETE"

adlsUri <- paste(
	"https://",
	security_adls_account_name,
	".azuredatalakestore.net/webhdfs/v1/",
	adlsPath,
	sep=""
)

uri = paste(adlsUri, "?op=", op, sep="")

r <- httr::DELETE(uri, body = payload, add_headers(Authorization = auth))

r$status_code