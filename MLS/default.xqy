xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

import module namespace cache="http://norman.walsh.name/ns/modules/cache"
       at "cache.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace etc="http://norman.walsh.name/ns/etc";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace t="http://norman.walsh.name/ns/taxonomy";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace flickr="http://norman.walsh.name/ns/flickr";
declare namespace itin="http://nwalsh.com/rdf/itinerary#";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function local:random-image() as xs:string+ {
  local:random-image(
    cts:element-attribute-values(xs:QName("db:imagedata"), xs:QName("fileref"), ())
  )
};

declare function local:random-image($values as xs:string+) as xs:string+ {
  let $ran := xdmp:random(count($values) - 1) + 1
  let $uri := $values[$ran]
  return
    if (contains($uri, "flickr.com"))
    then
      (string($ran), $uri)
    else
      local:random-image($values)
};

declare function local:homepage() as document-node() {
  let $essays := nwn:get-essays(current-dateTime(), "descending", 30)
  return
    document {
      <div class="essay-list" xmlns="http://www.w3.org/1999/xhtml">
        { for $essay in $essays
          let $nodeuri := xdmp:node-uri($essay)
          let $uri := substring-after(substring-after($nodeuri, "/"), "/")

          let $staged := (doc-available(concat("/staging/", $uri))
                          and doc-available(concat("/production/", $uri)))
          let $suppress := $staged and starts-with($nodeuri, "/production/")
          let $pubdate := format-dateTime(xs:dateTime($essay/db:info/db:pubdate),
                                          "[D01] [MNn,*-3] [Y0001]")
          return
            if ($suppress)
            then
              ()
            else
              <div>
                { attribute { QName("", "class") }
                            { if (xdmp:document-get-collections($nodeuri) = $nwn:scoll)
                              then "essay-listitem staging"
                              else "essay-listitem" }
                }
                <h3>
                  <a href="{substring-before($uri, '.xml')}">
                    {string($essay/db:info/db:title)}
                  </a>
                  <span class="essay-listitem-date">, {$pubdate}</span>
                </h3>
                <div class="essay-listitem-topics">
                  { "In " }
                  { let $props := for $prop in $essay/db:info/mldb:topic
                                  order by string($prop)
                                  return
                                    string($prop)
                    return
                      string-join($props, ", ")
                  }
                </div>
                <div class="essay-listitem-abstract">
                  {string($essay/db:info/db:abstract)}
                </div>
              </div>
        }
      </div>
    }
};

declare function local:random-list($max as xs:integer,
                                   $count as xs:integer,
                                   $numbers as xs:integer*) as xs:integer* {
  let $num := xdmp:random($max - 1) + 1
  return
    if ($num = $numbers)
    then
      local:random-list($max, $count, $numbers)
    else
      if (count($numbers) != $count)
      then
        local:random-list($max, $count, ($numbers, $num))
      else
        $numbers
};

declare function local:icons() {
  let $alwayslinks
    := <links xmlns="http://norman.walsh.name/ns/etc">
         <link title="Powered by MarkLogic" alt="[MarkLogic]" href="http://www.marklogic.com/"
               image="icon-marklogic.png"/>
         <link title="nwalsh.com" alt="[nwalsh.com]" href="http://nwalsh.com/"
               image="icon-nwalsh.png"/>
         <link title="docbook.org" alt="[docbook.org]" href="http://docbook.org/"
               image="icon-docbook.png" />
         <link title="{year-from-dateTime(current-dateTime())} Itineraries"
               alt="[Itineraries]" href="/{year-from-dateTime(current-dateTime())}/itinerary/"
               image="icon-itinerary.png"/>
       </links>

  let $randomlinks
    := <links xmlns="http://norman.walsh.name/ns/etc">
         <link title="Flickr photographs" alt="[flickr]" href="http://www.flickr.com/photos/ndw/"
               image="icon-flickr.png"/>
         <link title="Friend of the Guild" alt="[XML Guild]" href="http://www.xmlguild.org/"
               image="icon-xmlguild.png"/>
         <link title="Friend of a Friend" alt="[FOAF]" href="/foaf"
               image="icon-foaf.png"/>
         <link title="Twitter" alt="[Twitter]" href="http://twitter.com/ndw"
               image="icon-twitter.png"/>
         <link title="Identi.ca" alt="[Identi.ca]" href="http://identi.ca/ndw"
               image="icon-identica.png"/>
         <link title="Creative Commons License" alt="[CC License]" rel="license"
               href="http://creativecommons.org/licenses/by-nc/2.0/"
               image="icon-cc.png" />
         <link title="Last.fm profile" alt="[last.fm]" href="http://www.last.fm/user/nwalsh"
               image="icon-lastfm.png"/>
         <link title="Out Campaign" alt="[Out Campaign]" href="http://outcampaign.org"
               image="icon-out.png"/>
       </links>

  let $random := local:random-list(count($randomlinks/etc:link), 3, ())

  let $links := ($alwayslinks/etc:link[1 to 3],
                 for $pos in $random
                 return
                   $randomlinks/etc:link[$pos],
                 $alwayslinks/etc:link[4])

  return
    <div class="icons">
      { for $link in $links
        return
          <a href="{$link/@href}" title="{$link/@title}" class="button">
            { if ($link/@rel) then $link/@rel else () }
            <img src="/graphics/{$link/@image}" alt="{$link/@alt}" border="0" class="icon"/>
          </a>
      }
    </div>
};

let $homeuri  := if (nwn:admin()) then "/home.admin.html" else "/home.html"
let $homedoc  := if (cache:ready($homeuri, nwn:most-recent-update()))
                then
                  cache:get($homeuri)
                else
                  cache:put($homeuri, local:homepage())
let $homebody := $homedoc/*
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Norman.Walsh.name</title>
      <meta name="DC.title" content="Norman.Walsh.name"/>
      { nwn:css-meta() }
      <link rel="icon" href="/graphics/nwn.png" type="image/png" />
      <link rel="home" href="/" title="NWN" />
      <link rel="contents" title="Contents" href="/dates.html" />
      <link rel="index" title="Index" href="/subjects.html" />
      { nwn:css-links() }
      <link rel="stylesheet" type="text/css" href="/css/home.css" />
    </head>
    <body>
      <div id="banner">
        <div id="hnav"></div>
        { let $base := "http://chart.apis.google.com/chart?chs=125x125&amp;cht=qr"
          let $text := "http://norman.walsh.name/"
          return
            <div id="qrcode">
              { (: alt="" is intentional, if there's no code, there's no point :) }
              <img alt="" src="{$base}&amp;chl={$text}"/>
            </div>
        }
        <h1>Norman<span class="punct">.</span>Walsh<span class="punct">.name</span></h1>
        <div id="dateline">
          {format-dateTime(nwn:most-recent-update(), "[D01] [MNn,*-3] [Y0001]")}
      </div>
    </div>
    { if (nwn:admin())
      then
        <div class="admin" id="admin">
          <span>Welcome admin | </span>
          <a href="/admin/promote">promote</a>
        </div>
      else
        ()
    }
    <div id="content">
      <div class="abstract">
        <p>Norm's musings. Make of them what you will.</p>
      </div>
      <div id="intro">
        <p>This weblog is part experimental playground, part soap box,
        and part pleasant diversion for me. Here you’ll find opinions,
        technical and otherwise, photographs, and whatever interests me
        when I sit down to write. If you'd like to follow along, you can
        <a href="/subscribe">subscribe</a> to one or more of several feeds.
        </p>
      </div>
      { $homebody }

      <p>Consult <a href="/dates">the archives</a> for older essays…</p>
    </div>
    <div id="sidebar">
      <div class="search">
        <h3>Search:</h3>
        <form action="/search" method="get">
        <div><input name="s"/></div>
        </form>
      </div>

      { let $random := local:random-image()
        let $num    := $random[1]
        let $uri    := $random[2]
        let $thumb  := concat(substring-before($uri, ".jpg"), "_m.jpg")
        let $id     := replace($thumb, "^.*/([a-z0-9]+)_.*$", "$1")

        let $eavq   := cts:element-attribute-value-query(
                           xs:QName("flickr:photo"), QName("","id"), $id)
        let $photo  := cts:search(collection($nwn:pcoll), $eavq)[1]/flickr:photo

        let $essay  := cts:search(collection($nwn:ecoll),
                                  cts:and-not-query(
                                    cts:element-attribute-value-query(
                                      xs:QName("db:imagedata"), QName("","fileref"), $uri),
                                    cts:collection-query($nwn:vcoll)))[1]
        return
          if (empty($essay))
          then
            xdmp:log(concat("Failed to find essay for ", $num, ": ", $uri))
          else
            <div class="snapshot">
              <h3>Random image #{$num}:</h3>
              <a href="{nwn:httpuri(xdmp:node-uri($essay))}">
                <img src="{$thumb}" alt="Random photo" border="0" width="200"/>
              </a>
              { if ($photo)
                then
                  <div class="imagetitle">{string($photo/flickr:title)}</div>
                else
                  ()
              }
            </div>
      }

      <div class="navigate">
        <h3>Navigation:</h3>
        <dl>
          <dt><a href="/dates">Archive</a></dt>
          <dt><a href="/topics">Topics</a></dt>
          <dt><a href="/subjects">Subjects</a></dt>
{(:
          <dt><a href="/tags">Tags</a></dt>
:)}
          <dt><a href="/coverage">Geo</a></dt>
        </dl>
      </div>

      { let $sq := cts:element-attribute-range-query(
                       xs:QName("itin:trip"), QName("","startDate"), ">=",
                       current-dateTime())
        let $eq := cts:element-attribute-range-query(
                       xs:QName("itin:trip"), QName("","startDate"), "<=",
                       current-dateTime() + xs:dayTimeDuration("P180D"))
        let $q  := cts:and-not-query(
                       cts:and-query(($sq,$eq)),
                       cts:collection-query($nwn:vcoll))
        let $r  := cts:search(collection($nwn:ecoll), $q)/db:essay
        return
          <div class="itinerary">
            <h3>Upcoming travel:</h3>
            <dl>
            { for $trip in $r
              let $start := $trip/itin:trip/@startDate
              let $title := $trip/db:info/db:title
              return
                (<dt>
                   { if (year-from-dateTime($start) = year-from-dateTime(current-dateTime()))
                     then format-dateTime($start, "[D01] [MNn,*-3]")
                     else format-dateTime($start, "[D01] [MNn,*-3] [Y0001]")
                   }
                 </dt>,
                 <dd><a href="{nwn:httpuri(xdmp:node-uri($trip))}">{string($title)}</a></dd>)
            }
            </dl>
          </div>
      }

      <div class="disclaimer">I work at MarkLogic Corporation. The opinions
        expressed here are my own, and neither MarkLogic nor any other party
        necessarily agrees with them.
      </div>
    </div>
    { local:icons() }
    { nwn:footer() }
    </body>
  </html>

