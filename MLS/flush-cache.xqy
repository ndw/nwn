xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $count := count(collection($nwn:ccoll))
return
  (for $node in collection($nwn:ccoll)
   return
    xdmp:document-delete(xdmp:node-uri($node)),
  concat("Removed ", $count, " cached documents."))
