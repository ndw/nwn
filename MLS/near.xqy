xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

import module namespace cache="http://norman.walsh.name/ns/modules/cache"
       at "cache.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace c="http://nwalsh.com/rdf/contacts#";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function local:nearby-essays($center as cts:point) {
  let $geoq := cts:element-pair-geospatial-query(
                           xs:QName("mldb:geoloc"),
                           xs:QName("geo:lat"), xs:QName("geo:long"),
                           cts:circle(100, $center))
  let $nearby
    := for $essay in cts:search(collection($nwn:ecoll),
                           cts:and-not-query($geoq, cts:collection-query($nwn:vcoll)))/db:essay
       let $p := cts:point($essay/db:info/mldb:geoloc[1]/geo:lat,
                           $essay/db:info/mldb:geoloc[1]/geo:long)
       order by cts:distance($center, $p) ascending,
                $essay/db:info/mldb:pubdate descending
       return
         <essay>
           <dist>{format-number(cts:distance($center, $p), "0")}</dist>
           <uri>{xdmp:node-uri($essay)}</uri>
         </essay>

   let $groups := xdmp:xslt-invoke("/style/nearby.xsl", document {<doc>{$nearby}</doc>})/essays

   for $dist in $groups/dist
   let $mi := string($dist/@mi)
   let $uris := $dist/uri
   return
     (<dt xmlns="http://www.w3.org/1999/xhtml">Within {$mi} miles...</dt>,
      <dd xmlns="http://www.w3.org/1999/xhtml">
        <ul>
          { for $uri in $uris
            let $essay := doc($uri)/db:essay
            return
              <li><a href="{nwn:httpuri($uri)}">{string($essay/db:info/db:title)}</a></li>
          }
        </ul>
      </dd>)
};

let $lat := xs:decimal(xdmp:get-request-field("lat"))
let $long := xs:decimal(xdmp:get-request-field("long"))
let $center := cts:point($lat, $long)
let $geoq := cts:element-pair-geospatial-query(
                 xs:QName("rdf:Description"),
                 xs:QName("geo:lat"), xs:QName("geo:long"),
                 cts:circle(15, $center))
let $cityq := cts:element-value-query(xs:QName("c:category"), "Cities")
let $airq  := cts:element-value-query(xs:QName("c:category"), "Airports")
let $here  := (for $place in cts:search(/rdf:Description,
                         cts:and-not-query(cts:and-query(($geoq, cts:or-query(($cityq,$airq)))),
                                           cts:collection-query($nwn:vcoll)))
              let $p := cts:point($place/geo:lat, $place/geo:long)
              order by cts:distance($center, $p)
              return
                $place)[1]
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Nearby...</title>
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner(concat("/near?lat=", $lat, ",", $long), "Nearby...", (), ()) }
      <div id="content">
        <div class="abstract">
          <p>Essays near
          { if (empty($here))
            then
              concat($lat, ", ", $long, ".")
            else
              concat(($here/c:associatedTitle, $here/c:associatedName)[1], ".")
          }
          </p>
        </div>
        <dl>
          { local:nearby-essays($center) }
        </dl>
      </div>
      { nwn:footer() }
    </body>
  </html>
