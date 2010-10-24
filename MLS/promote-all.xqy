xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false"; 

declare variable $scoll := "http://norman.walsh.name/ns/collections/staging";
declare variable $pcoll := "http://norman.walsh.name/ns/collections/production";

let $count := count(collection($scoll))
return
  $count,
  for $node in collection($scoll)[1 to 1000]
  let $uri := xdmp:node-uri($node)
  let $props := xdmp:document-properties($uri)/prop:properties
  let $coll := xdmp:document-get-collections($uri)

  let $newuri  := concat("/production/", substring-after($uri, "/staging/"))
  let $newcoll := ($coll[. != $scoll], $pcoll)
  let $newprop := $props/*[not(self::prop:*)]
  let $readperm := xdmp:permission("weblog-reader", "read")
  return
    if (starts-with($uri, "/staging/"))
    then
      (xdmp:document-insert($newuri, doc($uri), ($readperm), $newcoll),
       xdmp:document-set-properties($newuri, $newprop),
       xdmp:document-delete($uri),
       $newuri)
    else
      concat("Unexpected uri: ", $uri)

