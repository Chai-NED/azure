library(httr)

source("security.R")

### User specified
fileName <- "test1.txt"
localPath <- paste("d:/test", fileName, sep="/")
adlsPath <- paste("Data/Analysis", fileName, sep="/")

# Security info
auth <- paste("Bearer", security_get_token(), " ")

# Execute
op <- "CREATE"

adlsUri <- paste(
	"https://",
	security_adls_account_name,
	".azuredatalakestore.net/webhdfs/v1/",
	adlsPath,
	sep=""
)

uri = paste(adlsUri, "?op=", op, "&overwrite=true&write=true", sep="")

payload <- upload_file(localPath)

r <- httr::PUT(
	uri,
	body = payload,
	add_headers(
		Authorization = auth,
		"Transfer-Encoding"="chunked"
	),
	verbose(),
	progress()
)

r$status_code