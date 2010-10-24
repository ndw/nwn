xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

import module namespace cache="http://norman.walsh.name/ns/modules/cache"
       at "cache.xqy";

declare namespace t="http://norman.walsh.name/ns/taxonomy";
declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace tax="http://norman.walsh.name/ns/taxonomy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $subjects := xdmp:xslt-invoke("/style/subjects.xsl", document {<doc/>})/subjects;

declare function local:subjbody($letter as xs:string) as document-node() {
  let $terms    := $subjects/group[@key=$letter]/subject
  return
    document {
      <dl xmlns="http://www.w3.org/1999/xhtml">
        {
          for $t in $terms
          let $q := cts:element-value-query(xs:QName("mldb:subject"), string($t))
          let $r := cts:and-query(($q, cts:collection-query($nwn:pcoll)))
          let $d := cts:search(collection($nwn:ecoll), $r)
          return
            (<dt>{$t}</dt>,
             <dd>
               <ul>
                 { for $e in $d
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
             </dd>)
        }
      </dl>
    }
};

let $lparam   := upper-case(xdmp:get-request-field("letter"))
let $letter   := if (empty($lparam) or empty($subjects/group[@key=$lparam]))
                 then "A"
                 else $lparam

let $subjuri  := concat("/etc/subjects/", $letter, ".html")
let $subjdoc  := if (cache:ready($subjuri, nwn:most-recent-update()))
                then
                  cache:get($subjuri)
                else
                  cache:put($subjuri, local:subjbody($letter))
let $subjbody := $subjdoc/*
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>All subjects: {$letter}</title>
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner("/subjects", concat("All subjects: ", $letter), (), nwn:most-recent-update()) }
      <div id="content">
        <div class="abstract">
          <p>All of the subjects discussed. Or, at least, all the subjects I marked up.</p>
        </div>
        { $subjbody }
      </div>
      <div id="sidebar">
        <div class="nearby">
          <h3>Subject links:</h3>
          <dl>
            { for $l in ("0", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
                         "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",
                         "X", "Y", "Z")
              return
                <dt>
                  { if ($l = "0")
                    then
                      if ($l = $letter) then "Symbols" else <a href="/subjects/0">Symbols</a>
                    else
                      if ($l = $letter)
                      then concat("Starting with ", $l)
                      else <a href="/subjects/{$l}">Starting with {$l}</a>
                  }
                </dt>
            }
          </dl>
        </div>
      </div>
      { nwn:footer() }
    </body>
  </html>

