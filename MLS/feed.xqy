xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

import module namespace cache="http://norman.walsh.name/ns/modules/cache"
       at "cache.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace tax="http://norman.walsh.name/ns/taxonomy";
declare namespace skos="http://www.w3.org/2004/02/skos/core#";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace flickr="http://norman.walsh.name/ns/flickr";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $feed := xdmp:get-request-field("feed");

declare function local:feedbody(
  $feed as xs:string,
  $type as xs:string,
  $topic as xs:string?)
as document-node()
{
  if ($type = "rss")
  then
    local:rssfeed($feed, $topic)
  else
    local:atomfeed($feed, $topic)
};

declare function local:get-essays($feed as xs:string, $topic as xs:string?) as element(db:essay)* {
  let $essays
    := if (empty($topic))
       then
         nwn:get-essays(current-dateTime(), "descending", 30)
       else
         nwn:get-topic-essays(current-dateTime(), "descending", 30, $topic)
  return
    $essays
};

declare function local:z($dt as xs:dateTime) as xs:dateTime {
  adjust-dateTime-to-timezone($dt, xs:dayTimeDuration("PT0H"))
};

declare function local:atomfeed($feed as xs:string, $topic as xs:string?) as document-node() {
  let $essays := local:get-essays($feed, $topic)
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

declare function local:rssfeed($feed as xs:string, $topic as xs:string?) as document-node() {
  let $essays := local:get-essays($feed, $topic)
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

declare function local:sonnet() as element(html:div) {
  let $sonnets := doc("/etc/sonnets.xml")
  let $today   := current-date()
  let $start   := xs:date("2004-09-11")
  let $mod     := days-from-duration($today - $start) mod 154
  let $number  := if ($mod = 0) then 154 else $mod
  let $sonnet := $sonnets/sonnets/sonnet[$number]
  let $lines := tokenize(string($sonnet), "&#10;")
  return
    <div xmlns="http://www.w3.org/1999/xhtml" class="sonnet">
      <h1>Sonnet Number {$number}</h1>
      <h3>By William Shakespeare</h3>
      <div class="sonnet-body">
        { for $line in $lines
          return
            ($line, <br/>)
        }
      </div>
    </div>
};

declare function local:sonnet-feed() {
  let $today   := current-date()
  let $start   := xs:date("2004-09-11")
  let $mod     := days-from-duration($today - $start) mod 154
  let $number  := if ($mod = 0) then 154 else $mod
  let $nowZ    := adjust-dateTime-to-timezone(current-dateTime(), xs:dayTimeDuration("PT0H"))
  return
    <feed xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/"
          xmlns:dcterms="http://purl.org/dc/terms/"
          xml:lang="EN-us">
      <title>The Sonnets of William Shakespeare</title>
      <link rel="alternate" type="text/html" href="http://norman.walsh.name/2004/09/11/sonnets"/>
      <link rel="self" href="http://norman.walsh.name/atom/sonnets-of-shakespeare.xml"/>
      <id>http://norman.walsh.name/atom/sonnets-of-shakespeare.xml</id>
      <updated>{ $nowZ }</updated>
      <author>
        <name>William Shakespeare</name>
      </author>
      <dc:language>en-us</dc:language>
      <entry>
        <title>Sonnet Number {$number}</title>
        <id>http://norman.walsh.name/atom/sonnets-of-shakespeare.xml?number={$number}</id>
        <published>{$nowZ}</published>
        <updated>{$nowZ}</updated>
        <summary type="xhtml">
          <div xmlns="http://www.w3.org/1999/xhtml">
            <p>Sonnet Number {$number}</p>
          </div>
        </summary>
        <content type="xhtml" xml:base="http://norman.walsh.name/2004/09/11/sonnets">
          { local:sonnet() }
        </content>
      </entry>
    </feed>
};

declare function local:topic-feed($type as xs:string, $topic as xs:string) {
  let $taxonomy := doc("/production/etc/taxonomy.xml")
  let $topic := $taxonomy//tax:*[@feed=$topic]
  return
    if (count($topic) != 1)
    then
      (xdmp:log(concat("404 on feed=", $feed)),
       xdmp:set-response-code(404, "Not Found."),
       concat("404 resource not found."))
    else
      let $feeduri  := concat("/", $type, "/", $feed, ".xml")
      let $feeddoc  := if (cache:ready($feeduri, nwn:most-recent-update()))
                       then
                         cache:get($feeduri)
                       else
                         cache:put($feeduri, local:feedbody($feed, $type,local-name($topic)))
      let $feedbody := $feeddoc/*
      return
        $feedbody
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
                       cache:put($feeduri, local:feedbody($feed, $type, ()))
    let $feedbody := $feeddoc/*
    return
      $feedbody
  else
    if ($feed = "sonnets-of-shakespeare")
    then
      local:sonnet-feed()
    else
      local:topic-feed($type, $feed)
