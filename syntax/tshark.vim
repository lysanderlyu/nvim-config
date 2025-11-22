syntax match TsharkFrame "^Frame [0-9]\+:.*$"
syntax match TsharkProtocol "^\s*\(Ethernet II\|Internet Protocol Version 4\|Transmission Control Protocol\).*"
syntax match TsharkField "\s*\zs\(\w\+\s*\):"
syntax match TsharkValue ":\s\zs.*$"

highlight link TsharkFrame Identifier
highlight link TsharkProtocol Type
highlight link TsharkField Keyword
highlight link TsharkValue String
