xquery version "1.0-ml";

declare namespace flickr="http://www.flickr.com/services/api/";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $photoid as xs:string external;

let $q := cts:element-attribute-value-query(xs:QName("flickr:photo"), fn:QName("", "id"), $photoid)
let $r := cts:search(collection(), $q)
return
  if (count($r/*) = 1 and $r/*/self::flickr:photo)
  then
    $r
  else
    ()

