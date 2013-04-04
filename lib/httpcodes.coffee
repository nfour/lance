
module.exports = {
	'100': 'Continue' # This means that the server has received the request headers, and that the client should proceed to send the request body (in the case of a request for which a body needs to be sent; for example, a POST request). If the request body is large, sending it to a server when a request has already been rejected based upon inappropriate headers is inefficient. To have a server check if the request could be accepted based on the request's headers alone, a client must send Expect: 100-continue as a header in its initial request and check if a 100 Continue status code is received in response before continuing (or receive 417 Expectation Failed and not continue).
	'101': 'Switching Protocols' # This means the requester has asked the server to switch protocols and the server is acknowledging that it will do so.
	'102': 'Processing' # As a WebDAV request may contain many sub-requests involving file operations, it may take a long time to complete the request. This code indicates that the server has received and is processing the request, but no response is available yet. This prevents the client from timing out and assuming the request was lost.

	# 2xx Success
	# This class of status codes indicates the action requested by the client was received, understood, accepted and processed successfully.

	'200': 'OK' # Standard response for successful HTTP requests. The actual response will depend on the request method used. In a GET request, the response will contain an entity corresponding to the requested resource. In a POST request the response will contain an entity describing or containing the result of the action.
	'201': 'Created' # The request has been fulfilled and resulted in a new resource being created.
	'202': 'Accepted' # The request has been accepted for processing, but the processing has not been completed. The request might or might not eventually be acted upon, as it might be disallowed when processing actually takes place.
	'203': 'Non-Authoritative Information' # The server successfully processed the request, but is returning information that may be from another source.
	'204': 'No Content' # The server successfully processed the request, but is not returning any content.
	'205': 'Reset Content' # The server successfully processed the request, but is not returning any content. Unlike a 204 response, this response requires that the requester reset the document view.
	'206': 'Partial Content' # The server is delivering only part of the resource due to a range header sent by the client. The range header is used by tools like wget to enable resuming of interrupted downloads, or split a download into multiple simultaneous streams.
	'207': 'Multi-Status' # The message body that follows is an XML message and can contain a number of separate response codes, depending on how many sub-requests were made.
	'208': 'Already Reported' # The members of a DAV binding have already been enumerated in a previous reply to this request, and are not being included again.
	'226': 'IM Used' # The server has fulfilled a GET request for the resource, and the response is a representation of the result of one or more instance-manipulations applied to the current instance.
	'250': 'Low on Storage Space' # The server returns this warning after receiving a RECORD request that it may not be able to fulfill completely due to insufficient storage space. If possible, the server should use the Range header to indicate what time period it may still be able to record. Since other processes on the server may be consuming storage space simultaneously, a client should take this only as an estimate.

	# 3xx Redirection
	# The client must take additional action to complete the request. This class of status code indicates that further action needs to be taken by the user agent to fulfill the request. The action required may be carried out by the user agent without interaction with the user if and only if the method used in the second request is GET or HEAD. A user agent should not automatically redirect a request more than five times, since such redirections usually indicate an infinite loop.

	'300': 'Multiple Choices' # Indicates multiple options for the resource that the client may follow. It, for instance, could be used to present different format options for video, list files with different extensions, or word sense disambiguation.
	'301': 'Moved Permanently' # This and all future requests should be directed to the given URI.
	'302': 'Found' # This is an example of industry practice contradicting the standard. The HTTP/1.0 specification (RFC 1945) required the client to perform a temporary redirect (the original describing phrase was "Moved Temporarily"), but popular browsers implemented 302 with the functionality of a 303 See Other. Therefore, HTTP/1.1 added status codes 303 and 307 to distinguish between the two behaviours. However, some Web applications and frameworks use the 302 status code as if it were the 303.
	'303': 'See Other' # The response to the request can be found under another URI using a GET method. When received in response to a POST (or PUT/DELETE), it should be assumed that the server has received the data and the redirect should be issued with a separate GET message.
	'304': 'Not Modified' # Indicates that the resource has not been modified since the version specified by the request headers If-Modified-Since or If-Match. This means that there is no need to retransmit the resource, since the client still has a previously-downloaded copy.
	'305': 'Use Proxy' # The requested resource is only available through a proxy, whose address is provided in the response. Many HTTP clients (such as Mozilla and Internet Explorer) do not correctly handle responses with this status code, primarily for security reasons.
	'307': 'Temporary Redirect' # In this case, the request should be repeated with another URI; however, future requests should still use the original URI. In contrast to how 302 was historically implemented, the request method is not allowed to be changed when reissuing the original request. For instance, a POST request should be repeated using another POST request.
	'308': 'Permanent Redirect' # The request, and all future requests should be repeated using another URI. 307 and 308 (as proposed) parallel the behaviours of 302 and 301, but do not allow the HTTP method to change. So, for example, submitting a form to a permanently redirected resource may continue smoothly.

	# 4xx Client Error
	# The 4xx class of status code is intended for cases in which the client seems to have erred. Except when responding to a HEAD request, the server should include an entity containing an explanation of the error situation, and whether it is a temporary or permanent condition. These status codes are applicable to any request method. User agents should display any included entity to the user.

	'400': 'Bad Request' # The request cannot be fulfilled due to bad syntax.
	'401': 'Unauthorized' # Similar to 403 Forbidden, but specifically for use when authentication is required and has failed or has not yet been provided. The response must include a WWW-Authenticate header field containing a challenge applicable to the requested resource. See Basic access authentication and Digest access authentication.
	'402': 'Payment Required' # Reserved for future use. The original intention was that this code might be used as part of some form of digital cash or micropayment scheme, but that has not happened, and this code is not usually used. As an example of its use, however, Apple's MobileMe service generates a 402 error if the MobileMe account is delinquent. In addition, YouTube uses this status if a particular IP address has made excessive requests, and requires the person to enter a CAPTCHA.
	'403': 'Forbidden' # The request was a valid request, but the server is refusing to respond to it. Unlike a 401 Unauthorized response, authenticating will make no difference. On servers where authentication is required, this commonly means that the provided credentials were successfully authenticated but that the credentials still do not grant the client permission to access the resource (e.g. a recognized user attempting to access restricted content).
	'404': 'Not Found' # The requested resource could not be found but may be available again in the future. Subsequent requests by the client are permissible.
	'405': 'Method Not Allowed' # A request was made of a resource using a request method not supported by that resource; for example, using GET on a form which requires data to be presented via POST, or using PUT on a read-only resource.
	'406': 'Not Acceptable' # The requested resource is only capable of generating content not acceptable according to the Accept headers sent in the request.
	'407': 'Proxy Authentication Required' # The client must first authenticate itself with the proxy.
	'408': 'Request Timeout' # The server timed out waiting for the request. According to W3 HTTP specifications: "The client did not produce a request within the time that the server was prepared to wait. The client MAY repeat the request without modifications at any later time."
	'409': 'Conflict' # Indicates that the request could not be processed because of conflict in the request, such as an edit conflict.
	'410': 'Gone' # Indicates that the resource requested is no longer available and will not be available again. This should be used when a resource has been intentionally removed and the resource should be purged. Upon receiving a 410 status code, the client should not request the resource again in the future. Clients such as search engines should remove the resource from their indices. Most use cases do not require clients and search engines to purge the resource, and a "404 Not Found" may be used instead.
	'411': 'Length Required' # The request did not specify the length of its content, which is required by the requested resource.
	'412': 'Precondition Failed' # The server does not meet one of the preconditions that the requester put on the request.
	'413': 'Request Entity Too Large' # The request is larger than the server is willing or able to process.
	'414': 'Request-URI Too Long' # The URI provided was too long for the server to process.
	'415': 'Unsupported Media Type' # The request entity has a media type which the server or resource does not support. For example, the client uploads an image as image/svg+xml, but the server requires that images use a different format.
	'416': 'Requested Range Not Satisfiable' # The client has asked for a portion of the file, but the server cannot supply that portion. For example, if the client asked for a part of the file that lies beyond the end of the file.
	'417': 'Expectation Failed' # The server cannot meet the requirements of the Expect request-header field.
	'418': 'Im a teapot' # This code was defined in 1998 as one of the traditional IETF April Fools' jokes, in RFC 2324, Hyper Text Coffee Pot Control Protocol, and is not expected to be implemented by actual HTTP servers.
	'420': 'Enhance Your Calm' # Not part of the HTTP standard, but returned by the Twitter Search and Trends API when the client is being rate limited. Other services may wish to implement the 429 Too Many Requests response code instead.
	'422': 'Unprocessable Entity' # The request was well-formed but was unable to be followed due to semantic errors.
	'423': 'Locked' # The resource that is being accessed is locked.
	'424': 'Failed Dependency' # The request failed due to failure of a previous request (e.g. a PROPPATCH).
	'424': 'Method Failure' # Indicates the method was not executed on a particular resource within its scope because some part of the method's execution failed causing the entire method to be aborted.

	'425': 'Unordered Collection' # Defined in drafts of "WebDAV Advanced Collections Protocol", but not present in "Web Distributed Authoring and Versioning (WebDAV) Ordered Collections Protocol".
	'426': 'Upgrade Required' # The client should switch to a different protocol such as TLS/1.0.
	'428': 'Precondition Required' # The origin server requires the request to be conditional. Intended to prevent "the 'lost update' problem, where a client GETs a resource's state, modifies it, and PUTs it back to the server, when meanwhile a third party has modified the state on the server, leading to a conflict."
	'429': 'Too Many Requests' # The user has sent too many requests in a given amount of time. Intended for use with rate limiting schemes.
	'431': 'Request Header Fields Too Large' # The server is unwilling to process the request because either an individual header field, or all the header fields collectively, are too large.
	'444': 'No Response' # Used in Nginx logs to indicate that the server has returned no information to the client and closed the connection (useful as a deterrent for malware).

	'451': 'Parameter Not Understood' # The recipient of the request does not support one or more parameters contained in the request.
	'451': 'Unavailable For Legal Reasons' # Defined in the internet draft "A New HTTP Status Code for Legally-restricted Resources". Intended to be used when resource access is denied for legal reasons, e.g. censorship or government-mandated blocked access. A reference to the 1953 dystopian novel Fahrenheit 451, where books are outlawed.
	'451': 'Redirect' # Used in Exchange ActiveSync if there either is a more efficient server to use or the server can't access the users' mailbox. The client is supposed to re-run the HTTP Autodiscovery protocol to find a better suited server.
	'452': 'Conference Not Found' # The conference indicated by a Conference header field is unknown to the media server.
	'453': 'Not Enough Bandwidth' # The request was refused because there was insufficient bandwidth. This may, for example, be the result of a resource reservation failure.
	'454': 'Session Not Found' # The RTSP session identifier in the Session header is missing, invalid, or has timed out.
	'455': 'Method Not Valid in This State' # The client or server cannot process this request in its current state. The response SHOULD contain an Allow header to make error recovery easier.
	'456': 'Header Field Not Valid for Resource' # The server could not act on a required request header. For example, if PLAY contains the Range header field but the stream does not allow seeking.
	'457': 'Invalid Range' # The Range value given is out of bounds, e.g., beyond the end of the presentation.
	'458': 'Parameter Is Read-Only' # The parameter to be set by SET_PARAMETER can be read but not modified.
	'459': 'Aggregate Operation Not Allowed' # The requested method may not be applied on the URL in question since it is an aggregate (presentation) URL. The method may be applied on a stream URL.
	'460': 'Only Aggregate Operation Allowed' # The requested method may not be applied on the URL in question since it is not an aggregate (presentation) URL. The method may be applied on the presentation URL.
	'461': 'Unsupported Transport' # The Transport field did not contain a supported transport specification.
	'462': 'Destination Unreachable' # The data transmission channel could not be established because the client address could not be reached. This error will most likely be the result of a client attempt to place an invalid Destination parameter in the Transport field.
	'494': 'Request Header Too Large' # Nginx internal code similar to 431 but it was introduced earlier.
	'495': 'Cert Error' # Nginx internal code used when SSL client certificate error occurred to distinguish it from 4XX in a log and an error page redirection.
	'496': 'No Cert' # Nginx internal code used when client didn't provide certificate to distinguish it from 4XX in a log and an error page redirection.
	'497': 'HTTP to HTTPS' # Nginx internal code used for the plain HTTP requests that are sent to HTTPS port to distinguish it from 4XX in a log and an error page redirection.
	'499': 'Client Closed Request' # Used in Nginx logs to indicate when the connection has been closed by client while the server is still processing its request, making server unable to send a status code back.

	# 5xx Server Error
	# The server failed to fulfill an apparently valid request. Response status codes beginning with the digit "5" indicate cases in which the server is aware that it has encountered an error or is otherwise incapable of performing the request. Except when responding to a HEAD request, the server should include an entity containing an explanation of the error situation, and indicate whether it is a temporary or permanent condition. Likewise, user agents should display any included entity to the user. These response codes are applicable to any request method.

	'500': 'Internal Server Error' # A generic error message, given when no more specific message is suitable.
	'501': 'Not Implemented' # The server either does not recognize the request method, or it lacks the ability to fulfill the request.
	'502': 'Bad Gateway' # The server was acting as a gateway or proxy and received an invalid response from the upstream server.
	'503': 'Service Unavailable' # The server is currently unavailable (because it is overloaded or down for maintenance). Generally, this is a temporary state.
	'504': 'Gateway Timeout' # The server was acting as a gateway or proxy and did not receive a timely response from the upstream server.
	'505': 'HTTP Version Not Supported' # The server does not support the HTTP protocol version used in the request.
	'506': 'Variant Also Negotiates' # Transparent content negotiation for the request results in a circular reference.
	'507': 'Insufficient Storage' # The server is unable to store the representation needed to complete the request.
	'508': 'Loop Detected' # The server detected an infinite loop while processing the request (sent in lieu of 208).
	'509': 'Bandwidth Limit Exceeded' # This status code, while used by many servers, is not specified in any RFCs.
	'510': 'Not Extended' # Further extensions to the request are required for the server to fulfill it.
	'511': 'Network Authentication Required' # The client needs to authenticate to gain network access. Intended for use by intercepting proxies used to control access to the network (e.g. "captive portals" used to require agreement to Terms of Service before granting full Internet access via a Wi-Fi hotspot).
	'550': 'Permission denied'
	'551': 'Option not supported' # An option given in the Require or the Proxy-Require fields was not supported. The Unsupported header should be returned stating the option for which there is no support.
	'598': 'Network read timeout error' # This status code is not specified in any RFCs, but is used by Microsoft HTTP proxies to signal a network read timeout behind the proxy to a client in front of the proxy.
	'599': 'Network connect timeout error' # This status code is not specified in any RFCs, but is used by Microsoft HTTP proxies to signal a network connect timeout behind the proxy to a client in front of the proxy. 


}