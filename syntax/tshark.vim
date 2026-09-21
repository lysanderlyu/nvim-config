" tshark -V (verbose dissection) output.
"
" Layout: each protocol section is a TITLE at column 0 with its fields indented
" (4 spaces per level, nesting). Two traps:
"   1. the Data payload dump is ALSO flush-left ("0000  60 c8 5b ..."), so the
"      hexdump rule has to keep it apart from the titles;
"   2. in this setup `\zs` / `\@<=` produce no highlight, and when two rules start
"      at the same column the LAST defined one wins and Vim does NOT continue the
"      earlier rule past its end. So each colour is produced by a rule that starts
"      where the colour starts: name rules carry `nextgroup=` for their tail.
"
" Only the section titles matter when skimming a capture; the field/value colours
" are deliberately calm so the titles stand out.
if exists('b:current_syntax')
  finish
endif

" --- indented fields: name + colon, then the rest of the line as the value -----
syntax match TsharkFieldName /^\s\+[A-Za-z][^:]*:/ nextgroup=TsharkFieldValue
syntax match TsharkFieldName /^\s\+\[[^]]*\]/       nextgroup=TsharkFieldValue
syntax match TsharkFieldValue /.*$/ contained

" protocol summary line tshark adds inside the Frame section
syntax match TsharkProtocols /^\s*\[Protocols in frame:.*\]$/

" --- section titles: name up to the first comma, detail from that comma on -----
syntax match TsharkSectionName   /^\S[^,]*/ nextgroup=TsharkSectionDetail
syntax match TsharkSectionDetail /.*$/ contained

" --- flush-left exceptions (must stay after the title rules) ------------------
syntax match TsharkFrame   /^Frame \d\+:/  nextgroup=TsharkSectionDetail
syntax match TsharkHexDump /^[0-9a-f]\{4,8\}\s\{2}.*$/

highlight default link TsharkSectionName   Function
highlight default link TsharkSectionDetail Comment
highlight default link TsharkFrame         Identifier
highlight default link TsharkHexDump       Comment
highlight default link TsharkFieldName     Keyword
highlight default link TsharkFieldValue    String
highlight default link TsharkProtocols     Special

let b:current_syntax = 'tshark'
