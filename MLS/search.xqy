xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace patom="http://purl.org/atom/ns#";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $search-options
  := <options xmlns="http://marklogic.com/appservices/search">
       <constraint name="c">
         <collection prefix="http://norman.walsh.name/ns/collections/"/>
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
       <page-length>25</page-length>
       <transform-results apply="snippet" ns="http://norman.walsh.name/ns/modules/snippet"
                          at="/modules/snippet.xqy"/>
     </options>;

declare variable $s := xdmp:get-request-field("s");
declare variable $p := xdmp:get-request-field("p");

declare function local:format($nodes as node()*) as node()* {
  for $x in $nodes
  return
    typeswitch ($x)
      case element(search:highlight)
        return
          <b xmlns="http://www.w3.org/1999/xhtml">
            { local:format($x/node()) }
          </b>
      case element()
        return
          element { node-name($x) }
                  { $x/@*, local:format($x/node()) }
      default
        return $x
};

let $incoll   := "(c:production AND (c:essay OR c:comment)"
let $query    := concat($incoll, if ($s) then concat(" AND ", $s) else "")
let $page     := if (empty($p) or not($p castable as xs:decimal))
                 then 1 else $p cast as xs:decimal
let $search   := search:search($query, $search-options, (($page - 1)*25) + 1)
let $max      := min(($search/@start + 25 - 1, $search/@total))
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Search for "{$s}"</title>
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner(concat("/search?s=",$s,"&amp;p=",$page),
                   concat("Search for """, $s, """"), (), ()) }
      <div id="content">
        <h2>Search results</h2>
        { if ($search/@total = 0)
          then
            <p>Sorry, I didn't find anything that matched that query.</p>
          else
            <div>
              <p>Showing {string($search/@start)} to {$max} of {string($search/@total)} results:</p>
              <dl>
                { for $result in $search/search:result
                  let $doc := doc($result/@uri)
                  return
                    (if ($doc/patom:entry)
                     then
                       let $base  := substring-after($result/@uri, "/production/comments")
                       let $url   := substring-before($base, ".")
                       let $eurl  := concat($url, ".xml")
                       let $essay := doc(nwn:docuri($eurl))/db:essay
                       let $title := string($essay/db:info/db:title)
                       let $date  := format-dateTime(xs:dateTime($essay/db:info/mldb:pubdate),
                                                     "[D01] [MNn,*-3] [Y0001]")
                       let $num   := substring-before(substring-after($base, "."), ".")
                       return
                         <dt><a href="{$url}#{$num}">Comment {xs:decimal($num)}</a>
                             on
                             <a href="{$url}">{$title}</a>, {$date}
                         </dt>
                     else
                       let $base  := substring-after($result/@uri, "/production")
                       let $url   := substring-before($base, ".")
                       let $eurl  := concat($url, ".xml")
                       let $essay := doc(nwn:docuri($eurl))/db:essay
                       let $title := string($essay/db:info/db:title)
                       let $date  := format-dateTime(xs:dateTime($essay/db:info/mldb:pubdate),
                                                     "[D01] [MNn,*-3] [Y0001]")
                       let $num   := substring-before(substring-after($base, "."), ".")
                       return
                         <dt><a href="{$url}">{$title}</a>, {$date}</dt>,
                     <dd><p>{local:format($result/search:snippet/search:match[1])}</p></dd>)
                }
              </dl>

              { if ($max < $search/@total)
                then
                  <p>See <a href="/search?s={$s}&amp;p={$page+1}">more</a> results...</p>
                else
                  ()
               }
            </div>
        }
      </div>
      { nwn:footer() }
    </body>
  </html>


