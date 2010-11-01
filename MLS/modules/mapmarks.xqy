xquery version "1.0-ml";

declare namespace flickr="http://www.flickr.com/services/api/";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $mapid external;
declare variable $clat external;
declare variable $clong external;
declare variable $minlat external;
declare variable $minlong external;
declare variable $maxlat external;
declare variable $maxlong external;

declare variable $MAXPT := 25;
declare variable $EPOCH := xs:dateTime("1970-01-01T00:00:00");

declare function local:show($photo as element(flickr:photo)) {
  let $age   := xs:dayTimeDuration(concat("PT", $photo/flickr:dates/@posted, "S"))
  let $dt    := xs:dateTime($EPOCH + $age)
  let $date  := concat(format-dateTime($dt, "[D01] [MNn,*-3] [Y0001]"),
                       " by ", $photo/flickr:owner/@realname)
  let $id    := string($photo/@id)
  let $lat   := xs:decimal($photo/flickr:location/@latitude)
  let $long  := xs:decimal($photo/flickr:location/@longitude)
  let $nsid  := string($photo/flickr:owner/@nsid)
  let $thumb := concat("http://farm", $photo/@farm, ".static.flickr.com/", $photo/@server, "/",
                       $photo/@id, "_", $photo/@secret, "_s.jpg")
  let $title := replace(string($photo/flickr:title), """", "\\""")
  let $url   := concat("http://www.flickr.com/photos/", $photo/flickr:owner/@username, "/", $id, "/")
  return
    <json latlong="{$lat},{$long}">
      { concat("""date"": """, $date, """, ""id"": """, $id, """, ""lat"": ", $lat, ", ""lon"": ", $long,
               ",&#10;  ""nsid"": """, $nsid, """, ""thumb"": """, $thumb, """,&#10;  ""title"": """, $title,
               """,&#10;  ""url"": """, $url, """ }") }
    </json>
};

let $center  := cts:point($clat, $clong)
let $box     := cts:box($minlat, $minlong, $maxlat, $maxlong)
let $gq      := cts:element-attribute-pair-geospatial-query(
                    xs:QName("flickr:location"),
                    fn:QName("", "latitude"), fn:QName("", "longitude"),

                    $box)
let $search  := cts:search(collection(), $gq)
let $results
  := for $count in (1 to count($search))
     let $pt := cts:point(xs:decimal($search[$count]/flickr:photo/flickr:location/@latitude),
                          xs:decimal($search[$count]/flickr:photo/flickr:location/@longitude))
     order by cts:distance($center, $pt) descending
     return
       if (empty($search[$count])) then () else local:show($search[$count]/*)

return
  (xdmp:set-response-content-type("application/json"),
  (concat("{ ""mapid"": """, $mapid, """, ""localMarkers"": ["),
   for $result at $index in $results
   let $latlong := string($result/@latlong)
   let $more    := ($index = 1 or $results[$index - 1]/@latlong != $latlong)
   let $count   := count($results[@latlong = $latlong]) - 1
   return
     concat(if ($more) then concat("{ ""more"": ", $count, ", ") else "{ ",
            $result,
            if ($index < count($results)) then "," else ""),
   "] }")
  )
