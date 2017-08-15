library(httr)
library(jsonlite)
library(curl)

source("security_info.R")

security_get_token <- function() {
	uri = paste("https://login.windows.net", security_tenant_id, "oauth2/token", sep = "/")
	
	h <- new_handle()
	
	handle_setform(h,
				   "grant_type"="client_credentials",
				   "resource"="https://management.core.windows.net/",
				   "client_id"=security_client_id,
				   "client_secret"=security_client_secret
	)
	
	req <- curl_fetch_memory(uri, handle = h)
	res <- fromJSON(rawToChar(req$content))
	
	token <- res$access_token
	
	return(token)
}
