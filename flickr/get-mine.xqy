xquery version "1.0-ml";

import module namespace flickr="http://www.flickr.com/services/api/"
       at "/flickr.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $me := "24401095@N00";

xdmp:invoke("/get-my-photos.xqy", (fn:QName("","me"), $me, fn:QName("","photos"), <empty/>))
