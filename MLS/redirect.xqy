xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace mldb="http://norman.walsh.name/ns/metadata";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $uri := xdmp:get-request-field("uri")
return
  xdmp:redirect-response($uri)

