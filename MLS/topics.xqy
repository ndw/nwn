xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

import module namespace cache="http://norman.walsh.name/ns/modules/cache"
       at "cache.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace tax="http://norman.walsh.name/ns/taxonomy";
declare namespace skos="http://www.w3.org/2004/02/skos/core#";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $taxonomy := doc("/production/etc/taxonomy.xml");

declare function local:dump($nodes as element()+) as element()+ {
  for $node in $nodes
  let $topic := local-name($node)
  let $q := cts:element-value-query(xs:QName("mldb:topic"), $topic)
  let $d := cts:search(collection($nwn:pcoll), $q)
  return
    (<dt xmlns="http://www.w3.org/1999/xhtml" id="{local-name($node)}">
       { if ($node/skos:prefLabel)
         then string($node/skos:prefLabel)
         else local-name($node)
       }
     </dt>,
     <dd xmlns="http://www.w3.org/1999/xhtml">
       { if (empty($d)) then ()
         else
           <ul>
             { for $e in $d
               order by xdmp:node-uri($e) descending
               return
                 <li>
                   <a href="{nwn:httpuri(xdmp:node-uri($e))}">
                     { string($e/db:essay/db:info/db:title) }
                   </a>
                   { concat(", ", format-dateTime(xs:dateTime($e/db:essay/db:info/mldb:pubdate),
                                                  "[D01] [MNn,*-3] [Y0001]")) }
                 </li>
             }
           </ul>
       }
       { if ($node/tax:*[not(self::tax:Omit) and not(self::tax:Sticky)])
         then
           <dl>
             { local:dump($node/tax:*[not(self::tax:Omit) and not(self::tax:Sticky)]) }
           </dl>
         else
           ()
       }
     </dd>)
};

declare function local:taxbody() as document-node() {
  document {
    <dl xmlns="http://www.w3.org/1999/xhtml">
      { local:dump($taxonomy/tax:Everything) }
    </dl>
  }
};

let $taxuri  := "/etc/taxonomy.html"
let $taxdoc  := if (cache:ready($taxuri, nwn:most-recent-update()))
                then
                  cache:get($taxuri)
                else
                  cache:put($taxuri, local:taxbody())
let $taxbody := $taxdoc/*
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>All topics</title>
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner("/topics", "All topics", (), ()) }
      <div id="content">
        <div class="abstract">
          <p>All of the topics discussed, as defined by the current taxonomy.</p>
        </div>
        { $taxbody }
      </div>
      <div id="sidebar">
        <div class="nearby">
          <h3>Jump to:</h3>
          <dl>
            { for $t in $taxonomy/tax:Everything/tax:*
                            [not(self::tax:Omit) and not(self::tax:Sticky)]
              return
                <dt>
                  <a href="#{local-name($t)}">
                    { if ($t/skos:prefLabel)
                      then string($t/skos:prefLabel)
                      else local-name($t) }
                  </a>
                </dt>
            }
          </dl>
        </div>
      </div>
      { nwn:footer() }
    </body>
  </html>
