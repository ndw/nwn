xquery version "1.0-ml";

declare namespace flickr="http://www.flickr.com/services/api/";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

<dl>
  { for $country in cts:element-values(xs:QName("flickr:country"))
    let $cq := cts:element-value-query(xs:QName("flickr:country"), $country)
    let $localities := cts:element-values(xs:QName("flickr:locality"), (), (), $cq)
    return
      (<dt>{$country}</dt>,
       <dd>
         <dl>
           { if (empty($localities))
             then
               let $cq := cts:element-value-query(xs:QName("flickr:country"), $country)
               let $count := xdmp:estimate(cts:search(collection(), $cq))
               let $photo := cts:search(collection(), $cq)[1]
               let $lat := xs:decimal($photo/flickr:photo/flickr:location/@latitude)
               let $long := xs:decimal($photo/flickr:photo/flickr:location/@longitude)
               return
                 <dt>{$count} photographs in <a href="/near/{$lat},{$long}">{$country}</a></dt>
             else
               for $locality in $localities
               let $cq := cts:and-query((cts:element-value-query(xs:QName("flickr:country"), $country),
                              cts:element-value-query(xs:QName("flickr:locality"), $locality)))
               let $count := xdmp:estimate(cts:search(collection(), $cq))
               let $photo := cts:search(collection(), $cq)[1]
               let $region := string($photo/flickr:photo/flickr:location/flickr:region)
               let $lat := xs:decimal($photo/flickr:photo/flickr:location/@latitude)
               let $long := xs:decimal($photo/flickr:photo/flickr:location/@longitude)
               return
                 <dt>{$count} photographs
                   <a href="/near/{$lat},{$long}">near {$locality}</a>
                   { if ($region = "") then () else concat(", ", $region) }
                 </dt>
           }
         </dl>
       </dd>)
  }
</dl>
