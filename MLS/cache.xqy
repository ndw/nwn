xquery version "1.0-ml";

module namespace cache="http://norman.walsh.name/ns/modules/cache";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $DEBUG as xs:boolean := false();
declare variable $readperm := xdmp:permission("weblog-reader", "read");
declare variable $updateperm := xdmp:permission("weblog-reader", "update");

declare function cache:uri($uri as xs:string) as xs:string {
  if (starts-with($uri, "/cached/"))
  then
    $uri
  else
    if (starts-with($uri, "/"))
    then
      concat("/cached", $uri)
    else
      concat("/cached/", $uri)
};

declare function cache:ready($uri as xs:string, $date as xs:dateTime) as xs:boolean {
  let $cached := cache:uri($uri)
  return
    if ($DEBUG or not(doc-available($cached)))
    then
      false()
    else
      let $cacheddt := xdmp:document-properties($cached)/prop:properties/prop:last-modified
      return
        xs:dateTime($cacheddt) > $date
};

declare function cache:get($uri as xs:string) as document-node()? {
  let $cached := cache:uri($uri)
  return
    doc($cached)
};

declare function cache:put($uri as xs:string, $doc as document-node()) as document-node() {
  let $cached := cache:uri($uri)
  return
    (xdmp:document-insert($cached, $doc, ($readperm, $updateperm), ($nwn:ccoll)), $doc)
};
