xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

import module namespace audit="http://norman.walsh.name/ns/modules/audit"
       at "/audit/audit.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $docuri := format-dateTime(current-dateTime(), "/audit/[Y0001]-[M01]-[D01]/[H01].xml")
let $log    := (xdmp:get-request-field("log"), $docuri)[1]
return
  $log
