xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $map   := doc(xdmp:get-request-field("map"))/*
let $image := xdmp:get-request-field("image")
let $orig  := xdmp:get-request-field("uri")
let $uri   := string($map/redirect[@name=$image][1]/@uri)
return
  if ($uri = "")
  then
    (xdmp:set-response-code(404, "Not found"),
     concat("404 Not found: ", $orig))
  else
    (xdmp:set-response-code(301, "Moved permanently"),
     xdmp:add-response-header("Location", $uri),
     concat("301 Moved permanently: ", $uri))



