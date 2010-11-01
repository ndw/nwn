xquery version "1.0-ml";

declare namespace flickr="http://www.flickr.com/services/api/";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $DELTA := 0.1;

declare function local:field-value($name as xs:string, $default as xs:decimal) as xs:decimal {
  let $value := xdmp:get-request-field($name)
  return
    if (empty($value) or not($value castable as xs:decimal))
    then
      $default
    else
      xs:decimal($value)
};

let $mapid   := xdmp:get-request-field("mapid")
let $clat    := local:field-value("lat", 42.3572945595)
let $clong   := local:field-value("long", -72.484949827)
let $minlat  := local:field-value("minlat", $clat - $DELTA)
let $minlong := local:field-value("minlong", $clong - $DELTA)
let $maxlat  := local:field-value("maxlat", $clat + $DELTA)
let $maxlong := local:field-value("maxlong", $clong + $DELTA)
return
  xdmp:invoke("/modules/mapmarks.xqy",
              (xs:QName("mapid"), if (empty($mapid)) then "map" else $mapid,
               xs:QName("clat"), $clat,
               xs:QName("clong"), $clong,
               xs:QName("minlat"), $minlat,
               xs:QName("minlong"), $minlong,
               xs:QName("maxlat"), $maxlat,
               xs:QName("maxlong"), $maxlong),
               <options xmlns="xdmp:eval">
                 <database>{xdmp:database("Flickr")}</database>
               </options>)
