xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $uri := xdmp:get-request-field('uri');

declare variable $ROOT as xs:string := "/MarkLogic/nwn";

let $doc := xdmp:document-get(concat($ROOT, $uri))
return
  if ($doc)
  then
    (xdmp:log(concat("Local: ", $uri)), $doc)
  else
    xdmp:set-response-code(404, concat("Resource has no representation: ", $uri))
