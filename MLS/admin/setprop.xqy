xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "/nwn.xqy";

declare namespace etc="http://norman.walsh.name/ns/etc";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $uri := xdmp:get-request-field("uri");
declare variable $props
  := for $name in xdmp:get-request-field-names()[. != "uri"]
     return
       element { xs:QName(concat("etc:", $name)) } { xdmp:get-request-field($name) };
declare variable $propnames := distinct-values(for $p in $props return node-name($p));

let $isdoc := doc-available($uri)
return
  if ($isdoc)
  then
    (xdmp:document-remove-properties($uri, $propnames),
     xdmp:document-add-properties($uri, $props),
     <updated href="{$uri}">{$props}</updated>)
  else
    error(xs:QName("etc:setprop"), "URI does not identify an existing document!")
