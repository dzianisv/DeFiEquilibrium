# web3.eth
```
OPTIONS / HTTP/1.1
Host: 127.0.0.1:8545
Connection: keep-alive
Accept: */*
Access-Control-Request-Method: POST
Access-Control-Request-Headers: content-type
Origin: http://localhost:8081
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1
Sec-Fetch-Mode: cors
Sec-Fetch-Site: cross-site
Sec-Fetch-Dest: empty
Referer: http://localhost:8081/
Accept-Encoding: gzip, deflate, br
Accept-Language: en-US,en;q=0.9

HTTP/1.1 200 OK
access-control-allow-origin: *
vary: origin
vary: access-control-request-method
vary: access-control-request-headers
access-control-allow-methods: GET,POST
access-control-allow-headers: content-type
allow: POST,GET,HEAD
content-length: 0
date: Thu, 17 Aug 2023 23:55:28 GMT

POST / HTTP/1.1
Host: 127.0.0.1:8545
Connection: keep-alive
Content-Length: 115
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1
Content-Type: application/json
Accept: */*
Origin: http://localhost:8081
Sec-Fetch-Site: cross-site
Sec-Fetch-Mode: cors
Sec-Fetch-Dest: empty
Referer: http://localhost:8081/
Accept-Encoding: gzip, deflate, br
Accept-Language: en-US,en;q=0.9

{"method":"eth_getBalance","params":["0x28175d9578d498f2d9cebef7c969c0b1f1e2d09f","latest"],"jsonrpc":"2.0","id":3}HTTP/1.1 200 OK
content-type: application/json
content-length: 57
access-control-allow-origin: *
vary: origin
vary: access-control-request-method
vary: access-control-request-headers
date: Thu, 17 Aug 2023 23:55:28 GMT

{"jsonrpc":"2.0","id":3,"result":"0x21e199118942d8e12d0"}POST / HTTP/1.1
Host: 127.0.0.1:8545
Connection: keep-alive
Content-Length: 137
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1
Content-Type: application/json
Accept: */*
Origin: http://localhost:8081
Sec-Fetch-Site: cross-site
Sec-Fetch-Mode: cors
Sec-Fetch-Dest: empty
Referer: http://localhost:8081/
Accept-Encoding: gzip, deflate, br
Accept-Language: en-US,en;q=0.9

{"method":"eth_call","params":[{"to":"0x0bB64a3648FdfA3Cb64EfCFd2f0A10b5399D60f8","input":"0x1f1fcd51"},"latest"],"jsonrpc":"2.0","id":4}HTTP/1.1 200 OK
content-type: application/json
content-length: 230
access-control-allow-origin: *
vary: origin
vary: access-control-request-method
vary: access-control-request-headers
date: Thu, 17 Aug 2023 23:55:28 GMT

{"jsonrpc":"2.0","id":4,"error":{"code":-32602,"message":"unknown field `input`, expected one of `from`, `to`, `gasPrice`, `maxFeePerGas`, `maxPriorityFeePerGas`, `gas`, `value`, `data`, `nonce`, `chainId`, `accessList`, `type`"}}
```


# cast call

```
POST / HTTP/1.1
content-type: application/json
accept: */*
host: 127.0.0.1:8545
content-length: 47

{"id":1,"jsonrpc":"2.0","method":"eth_chainId"}HTTP/1.1 200 OK
content-type: application/json
content-length: 42
access-control-allow-origin: *
vary: origin
vary: access-control-request-method
vary: access-control-request-headers
date: Fri, 18 Aug 2023 00:19:16 GMT

{"jsonrpc":"2.0","id":1,"result":"0x7a69"}POST / HTTP/1.1
content-type: application/json
accept: */*
host: 127.0.0.1:8545
content-length: 218

{"id":2,"jsonrpc":"2.0","method":"eth_call","params":[{"type":"0x02","from":"0x0000000000000000000000000000000000000000","to":"0x0bb64a3648fdfa3cb64efcfd2f0a10b5399d60f8","data":"0x1f1fcd51","accessList":[]},"latest"]}HTTP/1.1 200 OK
content-type: application/json
content-length: 102
access-control-allow-origin: *
vary: origin
vary: access-control-request-method
vary: access-control-request-headers
date: Fri, 18 Aug 2023 00:19:16 GMT

{"jsonrpc":"2.0","id":2,"result":"0x0000000000000000000000004971adfcc61b847be1bb66490dce7b8dee009281"}
```