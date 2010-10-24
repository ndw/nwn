xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $ecoll := "http://norman.walsh.name/ns/collections/essay";
declare variable $scoll := "http://norman.walsh.name/ns/collections/staging";
declare variable $pcoll := "http://norman.walsh.name/ns/collections/production";
declare variable $icoll := "http://norman.walsh.name/ns/collections/itinerary";

let $pubdate := xs:dateTime('2010-09-21T11:16:59-04:00')
let $qcoll   := cts:or-query(
                  (cts:collection-query($scoll), cts:collection-query($pcoll)))
let $icoll   := cts:collection-query($icoll)
let $nrquery := cts:element-range-query(xs:QName("mldb:pubdate"), ">", $pubdate)
let $prquery := cts:element-range-query(xs:QName("mldb:pubdate"), "<", $pubdate)
let $nquery  := cts:and-not-query(cts:and-query(($qcoll, $nrquery)), $icoll)
let $pquery  := cts:and-not-query(cts:and-query(($qcoll, $prquery)), $icoll)
return
  (string(nwn:next-essay($pubdate)/db:info/db:title),
   string(nwn:prev-essay($pubdate)/db:info/db:title))

(:
("Next: ",
   cts:element-values(xs:QName("mldb:pubdate"), $pubdate, ("ascending", "limit=4"), $nquery),
   "Prev: ",
   cts:element-values(xs:QName("mldb:pubdate"), $pubdate, ("descending", "limit=4"), $pquery)
)
:)