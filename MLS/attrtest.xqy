xquery version "1.0-ml";

let $type := xdmp:get-request-header('Content-Type')
let $format
  := if ($type = 'application/xml' or ends-with($type, '+xml'))
     then "xml"
     else if (contains($type, "text/"))
          then "text"
          else "binary"
let $body := xdmp:get-request-body($format)
return
  $body
