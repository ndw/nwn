xquery version "1.0-ml";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $uri  := xdmp:get-request-field('uri')
let $doc  := doc($uri)
let $time := if ($doc/db:essay/db:info/mldb:updated)
             then string($doc/db:essay/db:info/mldb:updated)
             else string(current-dateTime())
return
  (xdmp:set-response-content-type("application/json"),
   concat("{ ""uri"": """, $uri, """, ""lm"": """, $time, """ }"))

