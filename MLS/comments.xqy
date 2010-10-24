xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

import module namespace cache="http://norman.walsh.name/ns/modules/cache"
       at "cache.xqy";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace db="http://docbook.org/ns/docbook";
declare namespace etc="http://norman.walsh.name/ns/etc";
declare namespace flickr="http://norman.walsh.name/ns/flickr";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace purl="http://purl.org/atom/ns#";
declare namespace t="http://norman.walsh.name/ns/taxonomy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function local:sha1($s as xs:string) as xs:string {
  let $escs    := encode-for-uri($s)
  let $uri     := concat(/etc:host-config/etc:sha1-calculator, "?s=mailto:", $escs)
  let $results := xdmp:http-get($uri)
  let $hash    := if (contains($results[2], "&#10;"))
                  then tokenize($results[2], "&#10;")[1]
                  else $results[2]
  return
    $hash
};

declare function local:tohtml($nodes as node()*) as node()* {
  for $x in $nodes
  return
    typeswitch ($x)
      case element()
        return
          if (namespace-uri($x) = "")
          then
            element { QName("http://www.w3.org/1999/xhtml", local-name($x)) }
                    { $x/@*, local:tohtml($x/node()) }
          else
            element { node-name($x) }
                    { $x/@*, local:tohtml($x/node()) }
      default
        return $x
};

let $uri := xdmp:get-request-field("uri")
let $comments := cts:uris()[starts-with(.,concat("/production/comments", $uri, "."))]
return
  <feed xmlns="http://www.w3.org/2005/Atom"
        xmlns:foaf="http://xmlns.com/foaf/0.1/">
    <title>norman.walsh.name: Comments on {$uri}</title>
    <link rel="alternate" type="text/html" href="http://norman.walsh.name{$uri}"/>
    <id>http://norman.walsh.name{$uri}/comments.atom</id>
    <updated>{adjust-dateTime-to-timezone(current-dateTime(), xs:dayTimeDuration("PT0H"))}</updated>
    { for $curi at $index in $comments
      let $cnum := format-number($index, "0000")
      let $comment := doc($curi)/*
      return
        <entry>
          <title>Comment {$index} on {$uri}</title>
          <link rel="alternate" type="text/html"
                href="http://norman.walsh.name{$uri}#comment{$cnum}"/>
          <id>http://norman.walsh.name/2010/09/25/oauth#comment{$cnum}</id>
          <published>{string($comment/purl:issued)}</published>
          <updated>{string($comment/purl:modified)}</updated>
          <author>
            <name>{string($comment/purl:author/purl:name)}</name>
            { if ($comment/purl:author/purl:email)
              then
                <foaf:mbox_sha1sum>{local:sha1($comment/purl:author/purl:email)}</foaf:mbox_sha1sum>
              else
                ()
            }
          </author>
          <content type="xhtml">
            <div xmlns="http://www.w3.org/1999/xhtml">
              { local:tohtml($comment/purl:content/node()) }
            </div>
          </content>
        </entry>
    }
  </feed>
