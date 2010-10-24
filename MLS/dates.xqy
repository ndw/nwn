xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

import module namespace cache="http://norman.walsh.name/ns/modules/cache"
       at "cache.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function local:get-essays($year as xs:int) as element(db:essay)* {
  let $search-options
    := <options xmlns="http://marklogic.com/appservices/search">
         <constraint name="collection">
           <collection prefix="http://norman.walsh.name/ns/collections/"/>
         </constraint>
         <constraint name="dt">
           <range type="xs:dateTime" facet="false">
             <element ns="http://norman.walsh.name/ns/metadata" name="pubdate"/>
             <bucket ge="{$year}-01-01T00:00:00Z" lt="{current-dateTime()}"
                     name="range">range</bucket>
           </range>
         </constraint>
         <search:operator name="sort">
           <search:state name="pubdate">
             <search:sort-order direction="descending" type="xs:dateTime" collation="">
               <search:element ns="http://norman.walsh.name/ns/metadata" name="pubdate"/>
             </search:sort-order>
             <search:sort-order>
               <search:score/>
             </search:sort-order>
           </search:state>
         </search:operator>
         <page-length>400</page-length>
       </options>

  let $incoll   := if (nwn:show-staging())
                   then "collection:production OR collection:staging"
                   else "collection:production"

  let $query    := concat("collection:essay dt:range (", $incoll, ") sort:pubdate")

  let $search   := search:search($query, $search-options)

  let $uris     := $search/search:result/@uri/string()

  let $essays   := for $uri in $uris
                   return doc($uri)/db:essay
  return
    $essays
};

declare function local:datebody($year as xs:int) as document-node() {
  document {
        <dl xmlns="http://www.w3.org/1999/xhtml">
          <dt id="Y{$year}">{$year}</dt>
          <dd>
            <dl>
              { let $year-essays := local:get-essays($year)
                for $month in (12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
                let $month-essays := $year-essays
                                 [month-from-dateTime(xs:dateTime(db:info/mldb:pubdate))=$month]
                return
                  if (empty($month-essays))
                  then
                    ()
                  else
                    (<dt id="YM{concat($year, if ($month < 10) then '0' else '', $month)}">
                       { $nwn:MONTHS[$month] }
                     </dt>,
                     <dd>
                       { for $day in reverse(1 to 31)
                         let $day-essays := $month-essays
                               [day-from-dateTime(xs:dateTime(db:info/mldb:pubdate))=$day]
                         return
                           if (empty($day-essays))
                           then
                             ()
                           else
                             <div class="caldaylist">
                               <span class="calday">
                                 { concat(if ($day < 10) then "&#160;" else "", $day, "&#160;") }
                               </span>
                               { for $essay at $index in $day-essays
                                 return
                                   (if ($index > 1) then <br/> else (),
                                    <a href="{nwn:httpuri(xdmp:node-uri($essay))}">
                                      { string($essay/db:info/db:title) }
                                    </a>)
                                }
                             </div>
                       }
                     </dd>)
              }
            </dl>
          </dd>
        </dl>
  }
};

let $pubdate := nwn:most-recent-update()
let $yparam  := xdmp:get-request-field("year")
let $yint    := if ($yparam castable as xs:integer)
                then $yparam cast as xs:integer
                else year-from-dateTime($pubdate)
let $year    := if ($yint >= 1998 and $yint <= year-from-dateTime($pubdate))
                then $yint
                else year-from-dateTime($pubdate)

let $dateuri  := concat("/etc/dates/", $year, ".html")
let $datedoc  := if (cache:ready($dateuri, nwn:most-recent-update()))
                then
                  cache:get($dateuri)
                else
                  cache:put($dateuri, local:datebody($year))
let $datebody := $datedoc/*
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>All dates</title>
      { nwn:css-links() }
      <style type="text/css">
        .caldaylist {{
          text-indent: -1.5em;
          margin-left: 1.5em;
        }}
      </style>
    </head>
    <body>
      { nwn:banner("/dates", "All dates", (), $pubdate) }
      <div id="content">
        <div class="abstract">
          <p>All essays, by date.</p>
        </div>
        { $datebody }
      </div>
      <div id="sidebar">
        <div class="nearby">
          <h3>Jump to:</h3>
          <dl>
            { for $y in reverse((1998 to year-from-dateTime($pubdate)))
              return
                if ($y = $year)
                then <dt>{$y}</dt>
                else <dt><a href="/dates/{$y}">{$y}</a></dt>
            }
          </dl>
        </div>
      </div>
      { nwn:footer() }
    </body>
  </html>

