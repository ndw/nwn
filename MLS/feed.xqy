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
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace flickr="http://norman.walsh.name/ns/flickr";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $feed := xdmp:get-request-field("feed");

declare function local:feedbody($feed as xs:string, $type as xs:string) as document-node() {
  if ($type = "rss")
  then
    local:rssfeed($feed)
  else
    local:atomfeed($feed)
};

declare function local:get-essays($feed as xs:string) as element(db:essay)* {
  let $essays := nwn:get-essays(current-dateTime(), "descending", 30)
  return
    $essays
};

declare function local:z($dt as xs:dateTime) as xs:dateTime {
  adjust-dateTime-to-timezone($dt, xs:dayTimeDuration("PT0H"))
};

declare function local:atomfeed($feed as xs:string) as document-node() {
  let $essays := local:get-essays($feed)
  return
    document {
      <feed xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/"
            xmlns:dcterms="http://purl.org/dc/terms/"
            xml:lang="EN-us">
        <title>Norman.Walsh.name</title>
        <subtitle>
        { "Norm's musings. Make of them what you will." }
        </subtitle>
        <link rel="alternate" type="text/html" href="http://norman.walsh.name/"/>
        <link rel="self" href="http://norman.walsh.name/atom/whatsnew.xml"/>
        <id>http://norman.walsh.name/atom/whatsnew.xml</id>
        <updated>{ local:z(nwn:most-recent-update()) }</updated>
        <author>
          <name>Norman Walsh</name>
        </author>

        { for $essay in $essays
          let $base := nwn:httpuri(xdmp:node-uri($essay))
          return
            <entry>
              <title>{string($essay/db:info/db:title)}</title>
              <link rel="alternate" type="text/html"
                    href="http://norman.walsh.name{$base}"/>
              <id>http://norman.walsh.name{$base}</id>
              <published>{local:z(xs:dateTime($essay/db:info/mldb:pubdate))}</published>
              <updated>{local:z(xs:dateTime($essay/db:info/mldb:updated))}</updated>
              { for $subj in $essay/db:info/mldb:topic
                return
                  <dc:subject>{string($subj)}</dc:subject>
              }
              <summary type="xhtml">
                <div xmlns="http://www.w3.org/1999/xhtml">
                  <p>{string($essay/db:info/db:abstract)}</p>
                </div>
              </summary>
              { (: FIXME: hack! :) }
              { if (contains($feed, "fulltext"))
                then
                  <content type="xhtml" xml:base="http://norman.walsh.name{$base}">
                    <div xmlns="http://www.w3.org/1999/xhtml">
                      { nwn:format-essay(nwn:docuri($base)) }
                    </div>
                  </content>
                else
                  ()
              }
            </entry>
        }

      </feed>
    }
};

declare function local:rssfeed($feed as xs:string) as document-node() {
  let $essays := local:get-essays($feed)
  return
    document {
      <rdf:RDF xmlns="http://purl.org/rss/1.0/"
               xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:dc="http://purl.org/dc/elements/1.1/">
        <channel rdf:about="http://norman.walsh.name/">
          <title>Everything</title>
          <link>http://norman.walsh.name/</link>
          <description> at norman.walsh.name</description>
          <dc:language>en-us</dc:language>
          <dc:publisher>Norman Walsh</dc:publisher>
          <items>
            <rdf:Seq>
              { for $essay in $essays
                let $base := nwn:httpuri(xdmp:node-uri($essay))
                return
                  <rdf:li rdf:resource="http://norman.walsh.name{$base}"/>
              }
            </rdf:Seq>
          </items>
        </channel>

        { for $essay in $essays
          let $base := nwn:httpuri(xdmp:node-uri($essay))
          return
            <item rdf:about="http://norman.walsh.name{$base}">
              <title>{string($essay/db:info/db:title)}</title>
              <link>http://norman.walsh.name/{nwn:httpuri(xdmp:node-uri($essay))}</link>
              <dc:date>{local:z(xs:dateTime($essay/db:info/mldb:updated))}</dc:date>
              { for $subj in $essay/db:info/mldb:topic
                return
                  <dc:subject>{string($subj)}</dc:subject>
              }
              <description>{string($essay/db:info/db:abstract)}</description>
            </item>
        }
      </rdf:RDF>
    }
};

let $type := if (xdmp:get-request-field("type") = "rss") then "rss" else "atom"
return
  if ($feed = "whatsnew" or ($type = "atom" and $feed = "whatsnew-fulltext"))
  then
    let $feeduri  := concat("/", $type, "/", $feed, ".xml")
    let $feeddoc  := if (cache:ready($feeduri, nwn:most-recent-update()))
                     then
                       cache:get($feeduri)
                     else
                       cache:put($feeduri, local:feedbody($feed, $type))
    let $feedbody := $feeddoc/*
    return
      $feedbody
  else
    (xdmp:set-response-code(404, "Not Found."),
     concat("404 resource not found."))
