xquery version "1.0-ml";

module namespace snippet="http://norman.walsh.name/ns/modules/snippet";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace atom="http://purl.org/atom/ns#";

declare option xdmp:mapping "false";

declare function snippet:snippet(
  $result as node(),
  $ctsquery as schema-element(cts:query),
  $options as element(search:transform-results)?
) as element(search:snippet)
{
  if ($result/atom:entry)
  then
    search:snippet($result/atom:entry/atom:content, $ctsquery, $options)
  else
    search:snippet($result, $ctsquery, $options)
};
