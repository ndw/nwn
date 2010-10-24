xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace mldb="http://norman.walsh.name/ns/metadata";

(: N.B. The 4.2-1 server and previous releases always send a Content-Length header.
   This is misleading in the case of HEAD, so instead we assert that HEAD is not
   allowed.

let $uri  := xdmp:get-request-field("uri")
let $duri := nwn:docuri($uri)
let $prop := xdmp:document-get-properties($duri, xs:QName("prop:last-modified"))[1]
let $dt   := if ($prop castable as xs:dateTime)
             then adjust-dateTime-to-timezone(xs:dateTime($prop), xs:dayTimeDuration("PT0H"))
             else ()
return
  if (empty($dt))
  then
    ()
  else
    xdmp:add-response-header("Last-Modified",
                             format-dateTime($dt,
                                   "[FNn,*-3], [D01] [MNn,*-3] [Y0001] [H01]:[m01]:[s01] GMT"))
:)

(xdmp:set-response-code(405, "Method Not Allowed"),
xdmp:add-response-header("Allow", "GET"))
