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

declare function local:nearby-essays($center as cts:point) as element(essay)* {
  let $geoq := cts:element-pair-geospatial-query(
                           xs:QName("mldb:geoloc"),
                           xs:QName("geo:lat"), xs:QName("geo:long"),
                           cts:circle(100, $center))
  return
    for $essay in cts:search(collection($nwn:ecoll),
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
};

declare function local:format-nearby-essays($nearby as element(essay)*) {
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
let $nearby := local:nearby-essays($center)
return
  <html xmlns="http://www.w3.org/1999/xhtml" v="urn:schemas-microsoft-com:vml">
    <head>
      <title>Nearby...</title>
      { nwn:css-links() }
      <script type="text/javascript" src="/js/jquery-1.4.2.min.js">
      </script>
      <script type="text/javascript" src="/js/nwn.js">
      </script>
      <style type="text/css">v\:* {{ behavior:url(#default#VML); }}</style>
      <script type="text/javascript"
              src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=ABQIAAAAO1qAaQsvBqLxt1nDHmVdXRT2NEtcpIGhYQyn6m1C7TS31DAKixTrwZexV8cQaZV92n_CCyWlNd6Mxw">
      </script>
      <script type="text/javascript" src="/js/gmapfunc.js"></script>
      <script type="text/javascript">// Populate map(s)
$(document).ready(function() {{
      addMapMarks()
}});</script>
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

        <div class="artwork" id="map" style="width: 540px; height: 540px;"></div>
        <div class="map-messages" id="map_messages"></div>
        <script type="text/javascript">
if (GBrowserIsCompatible()) {{
   var map = new GMap2(document.getElementById("map"));
   configureMap(map, {$lat}, {$long}, 12);
}}</script>

        { if (empty($nearby))
          then
            <p>There are no nearby essays.</p>
          else
            <dl>
              { local:format-nearby-essays($nearby) }
            </dl>
        }

      </div>
      { nwn:footer() }
    </body>
  </html>
