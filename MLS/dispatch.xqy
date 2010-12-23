xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace c="http://nwalsh.com/rdf/contacts#";
declare namespace db="http://docbook.org/ns/docbook";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace itin="http://nwalsh.com/rdf/itinerary#";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace patom="http://purl.org/atom/ns#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace t="http://norman.walsh.name/ns/taxonomy";
declare namespace ttag="http://developers.technorati.com/wiki/RelTag#";
declare namespace xlink="http://www.w3.org/1999/xlink";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";
declare option xdmp:output "indent=no";

declare variable $uri := xdmp:get-request-field('uri');

declare variable $readperm := xdmp:permission("weblog-reader", "read");
declare variable $updateperm := xdmp:permission("weblog-reader", "update");

declare function local:cookie-value($param as xs:string) as xs:string? {
  let $cookie := string-join(xdmp:get-request-header("Cookie"), ";")
  let $value  := substring-after($cookie, "remember-me=")
  let $cookie := if (contains($value, ";")) then substring-before($value,";") else $value
  let $params := for $p in tokenize($cookie, ",")
                 return
                   try {
                     xdmp:base64-decode($p)
                   } catch ($e) {
                     ""
                   }
  let $value  := for $p in $params
                 return
                   if (starts-with($p, concat($param,"=")))
                   then
                     substring-after($p, "=")
                   else
                     ()
  return
    $value[1]
};

declare function local:comment-form() {
  <form method="post" action="/cgi-bin/talkback" xmlns="http://www.w3.org/1999/xhtml">
    <input value="1" name="sawform" type="hidden"/>
    <input value="{$uri}" name="page" type="hidden"/>
    <input value="" name="okcomment" type="hidden"/>
    <input value="1" name="inline" type="hidden"/>
    <table summary="Form design" class="commentform" border="0">
      <tbody>
        <tr>
          <td>Name:</td>
          <td>
            <input value="{local:cookie-value('name')}"
                   maxlength="80" size="40" name="name" type="text"/>
          </td>
        </tr>
        <tr>
          <td>
            <span>Email<sup>*</sup>:</span>
          </td>
          <td>
            <input value="{local:cookie-value('email')}"
                   maxlength="80" size="40" name="email" type="text"/>
          </td>
        </tr>
        <tr>
          <td>&#160;</td>
          <td>
          <sup>*</sup>Please provide your real email address;
          it will not be displayed as part of the comment.</td>
        </tr>
        <tr>
          <td>Homepage:</td>
          <td>
            <input value="{local:cookie-value('homepage')}"
                   maxlength="128" size="62" name="homepage" type="text"/>
          </td>
        </tr>
        <tr>
          <td>Comment<sup>**</sup>:</td>
          <td>
            <textarea cols="55" rows="12" name="comment">&lt;p&gt;</textarea>
          </td>
        </tr>
        <tr>
          <td>&#160;</td>
          <td>
            <sup>**</sup>The following markup may be used in the body of the comment:
            a, abbr, b, br, code, em, i, p, pre, strong, and var. You
            can also use character entities. Any other markup will be
            discarded, including all attributes (except
            <code>href</code> on <code>a</code>). Your tag soup will
            be sanitized...
          </td>
        </tr>
      </tbody>
    </table>
    <p>
      <input value="Preview comment" type="submit"/>
    </p>
  </form>
};

declare function local:decorate($uri as xs:string, $body as document-node()?) {
  let $essay   := doc($uri)/db:essay
  let $pubdate := xs:dateTime($essay/db:info/mldb:pubdate)

  let $gmap as xs:boolean := ($essay//itin:trip/itin:itinerary/itin:leg[@class='flight']
                              or $essay//itin:trip/itin:itinerary/itin:leg[@class='train'])
                             or $essay//db:para[@xlink:actuate='onLoad']

  let $prop := xdmp:document-get-properties($uri, xs:QName("prop:last-modified"))[1]
  let $dt   := if ($prop castable as xs:dateTime)
               then adjust-dateTime-to-timezone(xs:dateTime($prop), xs:dayTimeDuration("PT0H"))
               else ()
  let $lm
    := if (empty($dt) or nwn:admin())
       then
         ()
       else
         xdmp:add-response-header("Last-Modified",
                                  format-dateTime($dt,
                                        "[FNn,*-3], [D01] [MNn,*-3] [Y0001] [H01]:[m01]:[s01] GMT"))


  let $expdur
    := if (contains($uri, "/popular/popular"))
       then xs:dayTimeDuration("PT4H")
       else if (contains($uri, "/2004/09/11/sonnets"))
            then xs:dayTimeDuration("PT12H")
            else xs:dayTimeDuration("P7D")

  let $expires
    := if (nwn:admin())
       then
         ()
       else
         xdmp:add-response-header("Expires",
                                  format-dateTime(current-dateTime()+$expdur,
                                     "[FNn,*-3], [D01] [MNn,*-3] [Y0001] [H01]:[m01]:[s01] GMT"))

  return
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>{string($essay/db:info/db:title)}</title>
        <meta name="DC.title" content="{string($essay/db:info/db:title)}"/>
        { nwn:css-meta() }

        { for $loc in $essay/db:info/mldb:geoloc
          return
            <meta name="ICBM" content="{$loc/geo:lat},{$loc/geo:long}"/>
        }

        <link rel="alternate" type="application/rdf+xml" title="Essay metadata"
              href="{nwn:httpuri(xdmp:node-uri($essay))}.rdf" />
        <link rel="alternate" type="application/docbook+xml" title="XML"
              href="{nwn:httpuri(xdmp:node-uri($essay))}.xml" />
        <link rel="icon" href="/graphics/nwn.png" type="image/png" />
        <link rel="home" href="/" title="NWN" />
        <link rel="contents" title="Contents" href="/dates.html" />
        <link rel="index" title="Index" href="/subjects.html" />
        { nwn:css-links() }
        <script type="text/javascript" src="/js/jquery-1.4.2.min.js">
        </script>
        <script type="text/javascript" src="/js/nwn.js">
        </script>

        { if (starts-with($uri, "/staging/"))
          then
            (<meta name="lastmodified.time" content="{$essay/db:info/mldb:updated}"/>,
             <meta name="document.uri" content="{$uri}"/>,
             <script type="text/javascript" src="/js/jquery.timers-1.2.js">
             </script>,
             <script type="text/javascript" src="/local/js/staging.js">
             </script>)
          else
            ()
        }
        { if (contains($uri, "/itinerary"))
          then
            <link rel="stylesheet" type="text/css" href="/css/itin.css" />
          else
            ()
        }
        { $essay/db:info/html:* }

        { if ($gmap)
          then
            (<style type="text/css">v\:* {{ behavior:url(#default#VML); }}</style>,
             <script type="text/javascript"
                     src="http://maps.google.com/maps/api/js?sensor=false">
             </script>)
           else
             ()
        }
        { if ($essay//itin:trip/itin:itinerary/itin:leg[@class='flight']
	      or $essay//itin:trip/itin:itinerary/itin:leg[@class='train'])
          then
	    <script src="/js/FlightMap.js" type="text/javascript"/>
          else
            ()
        }
        { if ($essay//db:para[@xlink:actuate='onLoad'])
          then
            (<script type="text/javascript" src="/js/gmapfunc.js"></script>,
             <script type="text/javascript" src="/js/jquery.timers-1.2.js">
             </script>,
             <script type="text/javascript">// Populate map(s)
$(document).ready(function() {{
  { for $id in $essay//db:para[@xlink:actuate='onLoad']/@xml:id
    return
      concat("plotTracks(mapdata, '", $id, "');&#10;")
  }
}});</script>)
          else
            ()
        }
      </head>
      <body>
        { if (starts-with($uri, "/staging/"))
          then attribute { QName("", "class") } { "staging" }
          else ()
        }

        { nwn:banner($essay) }

        { if (nwn:admin())
          then
            <div id="admin" class="admin">
              { if (starts-with(xdmp:node-uri($essay), "/staging/"))
                then
                  (<a href="/admin/promote?post=post&amp;{$uri}=1">promote</a>,
                   <span>&#160;|&#160;</span>)
                 else
                   ()
              }
              <a href="/admin/taxonomy?uri={nwn:httpuri($uri)}">taxonomy</a>
              <span>&#160;|&#160;</span>
              <a href="/admin/flush-cache?uri={nwn:httpuri($uri)}">flush cache</a>
              <span>&#160;</span>
            </div>
          else
            ()
        }

        { let $this  := concat("http://norman.walsh.name", nwn:httpuri($uri))
          let $replq := cts:element-value-query(QName("http://purl.org/dc/terms/", "replaces"),
                                                $this, ("exact"))
          let $repl  := cts:search(collection($nwn:pcoll), $replq)
          return
            if (empty($repl))
            then
              ()
            else
              <div class="replaced">
                { "Attention: this essay is no longer current. It has been replaced by " }
                { if (count($repl) = 1)
                  then
                    let $essay := doc(xdmp:node-uri($repl))/db:essay
                    return
                      <span>
                        <a href="{nwn:httpuri(xdmp:node-uri($repl))}">
                          <cite>{string($essay/db:info/db:title)}</cite>
                        </a>
                        { " from " }
                        { format-dateTime(xs:dateTime($essay/db:info/mldb:pubdate), 
                                          "[D01] [MNn,*-3] [Y0001].")
                        }
                      </span>
                  else
                    <ul>
                      { for $essay in $repl/db:essay
                        order by $essay/db:info/mldb:pubdate descending
                        return
                          <li>
                            <a href="{nwn:httpuri(xdmp:node-uri($essay))}">
                              <cite>{string($essay/db:info/db:title)}</cite>
                            </a>
                            { ", " }
                            { format-dateTime(xs:dateTime($essay/db:info/mldb:pubdate), 
                                              "[D01] [MNn,*-3] [Y0001]")
                            }
                          </li>
                      }
                    </ul>
                }
              </div>
        }

        { local:walk($body/html:div) }

        { if (xdmp:document-get-collections(xdmp:node-uri($essay)) = $nwn:icoll)
          then ()
          else local:comments($essay)
        }

        <div id="sidebar">
          { let $coverage := for $place in $essay/db:info/dc:coverage/@rdf:resource
                             let $rdf := /rdf:Description[@rdf:about=$place
                                         and (starts-with(xdmp:node-uri(.), "/production/"))]
                             return
                               <a href="{substring-after($place,'.name')}">
                                 { if ($rdf/c:associatedTitle)
                                   then
                                     string($rdf/c:associatedTitle)
                                   else
                                     string($rdf/c:associatedName)
                                 }
                               </a>
            return
              if ($coverage)
              then
                <div class="coverage">
                  <h3>Covers:</h3>
                  <dl>
                    { for $a in $coverage
                      return
                        <dt>{$a}</dt>
                    }
                  </dl>
                </div>
              else
                ()
          }

          <div class="nearby">
            <h3>Nearby:</h3>
            { let $prev  := nwn:get-essays(xs:dateTime($essay/db:info/mldb:pubdate), "descending", 3)
              let $next  := nwn:get-essays(xs:dateTime($essay/db:info/mldb:pubdate), "ascending", 3)
              let $lat   := string($essay/db:info/mldb:geoloc[1]/geo:lat)
              let $long  := string($essay/db:info/mldb:geoloc[1]/geo:long)
              let $xnear := if ($essay/db:info/mldb:geoloc)
                            then
                              nwn:get-essays-near(xs:decimal($lat), xs:decimal($long), 6)
                            else
                              ()
              let $miles := $xnear[1]
              let $near  := $xnear[position() > 1] except $essay
              return
                <div>
                  { if (empty($prev))
                    then
                      ()
                    else
                      (<em>Previously: </em>,
                       for $near at $index in $prev
                       return
                         (if ($index > 1) then "&#160;&#x2766;&#160;" else "",
                          <a href="{nwn:httpuri(xdmp:node-uri($near))}">
                            { string($near/db:info/db:title) }
                          </a>))
                  }
                  { if (empty($next))
                    then
                      ()
                    else
                      (" ", <em>Soon after: </em>,
                       for $near at $index in $next
                       return
                         (if ($index > 1) then "&#160;&#x2766;&#160;" else "",
                          <a href="{nwn:httpuri(xdmp:node-uri($near))}">
                            { string($near/db:info/db:title) }
                          </a>))
                  }
                  { if (empty($near))
                    then
                      ()
                    else
                      (" ", <em>Within&#160;{$miles}mi: </em>,
                       for $near at $index in $near[1 to 3]
                       return
                         (if ($index > 1) then "&#160;&#x2766;&#160;" else "",
                          <a href="{nwn:httpuri(xdmp:node-uri($near))}">
                            { string($near/db:info/db:title) }
                          </a>),
                       if (count($near) > 3)
                       then (" ", <a href="/near/{$lat},{$long}">...</a>)
                       else "")
                  }
                </div>

          }
          </div>

          <div class="seealso">
            <h3>Maybe related:</h3>
            <dl>
              { for $sim in nwn:similar($essay)
                return
                  <dt><a href="{nwn:httpuri(xdmp:node-uri($sim))}">{string($sim/db:info/db:title)}</a></dt>
              }
            </dl>
          </div>

          { let $props := $essay/db:info/mldb:topic
            return
              (<div class="tagged">
                 <h3>Tagged:</h3>
                 <dl>
                   { for $prop in $props[string(.) != "Omit" and string(.) != "Sticky"]
                     return
                       <dt><a href="/topics#{string($prop)}">{string($prop)}</a></dt>
                   }
                 </dl>
               </div>,

               <div class="topics">
                 <h3>Topics:</h3>
                 <dl>
                   { let $tax   := doc("/production/etc/taxonomy.xml")
                     let $all
                       := for $prop in $props
                          let $spot := $tax//*[local-name(.) = string($prop)]
                          return
                            $spot/ancestor-or-self::*
                     return
                       for $prop in ($all)/self::*[not(self::t:Omit) and not(self::t:Sticky)]
                       return
                         <dt><a href="/topics#{local-name($prop)}">{local-name($prop)}</a></dt>
                   }
                 </dl>
               </div>)
          }

          { if (nwn:admin())
            then
              <div class="stats">
                 <h3>Stats:</h3>
                 { xdmp:invoke("/admin/stats.xqy", (QName("","uri"), nwn:httpuri($uri)),
                  <options xmlns="xdmp:eval">
                    <database>{xdmp:database("nwn-audit")}</database>
                  </options>)
                 }
              </div>
            else
              ()
          }
        </div>
        { nwn:footer() }
      </body>
    </html>
};

(: ============================================================ :)

declare function local:walk($body as element(html:div)) as element(html:div) {
  local:dispatch($body)
};

declare function local:passthru($x as node()) as element()* {
  for $z in $x/node() return local:dispatch($z)
};

declare function local:dispatch($x as node()) as node()* {
  typeswitch ($x)
    case element()
      return
        element { node-name($x) }
                { $x/@*, local:passthru($x) }
    case processing-instruction('include')
      return local:include($x)
    default return $x
};

declare function local:include($pi as processing-instruction()) as element()? {
  if (contains(string($pi), "/cgi-bin/sonnet-include"))
  then
    local:sonnet()
  else
    if (contains(string($pi), "/dynamic/popular"))
    then
      xdmp:invoke("/popular.xqy", (),
                  <options xmlns="xdmp:eval">
                    <database>{xdmp:database("nwn-audit")}</database>
                  </options>)
    else
      if (contains(string($pi), "/2008/03/31/places.html"))
      then
        xdmp:invoke("/modules/nearbyphotos.xqy", (),
                    <options xmlns="xdmp:eval">
                      <database>{xdmp:database("Flickr")}</database>
                    </options>)
      else
        xdmp:log(concat("Unexpected include: ", $pi))
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

(: ============================================================ :)

declare function local:comments($essay as element(db:essay)) as element() {
  let $baseuri := nwn:httpuri(xdmp:node-uri($essay))
  let $staged  := cts:uri-match(concat("/staging/comments", $baseuri, ".*"))
  let $uris    := (cts:uri-match(concat("/production/comments", $baseuri, ".*")),
                   if (nwn:show-staging()) then $staged else ())
  return
    <div xmlns="http://www.w3.org/1999/xhtml" id="comments">
      { if (empty($uris))
        then
          <div>There are no comments on this essay.</div>
        else
          <div xmlns="http://www.w3.org/1999/xhtml">
            <h2>Comments:</h2>
              { for $uri in $uris
                let $comment := doc($uri)/patom:entry
                let $hash := if ($comment/patom:author/patom:email)
                             then xdmp:md5($comment/patom:author/patom:email)
                             else ""
                order by $uri
                return
                  <div id="{substring-after($comment/patom:id, '#')}">
                    { attribute { QName("","class") }
                                { if (xdmp:document-get-collections($uri) = $nwn:scoll)
                                  then "comment staging"
                                  else "comment" }
                    }
                    <img align='right'
               src='http://www.gravatar.com/avatar.php?gravatar_id={$hash}&amp;rating=PG&amp;size=40&amp;default=http://norman.walsh.name/graphics/empty-avatar.jpg' />
                    <div class="prose">
                      { $comment/patom:content/node() }
                    </div>
                    <div class="name">
                      Posted by
                      { if (normalize-space($comment/patom:author/patom:uri) != "")
                        then
                          <a href="{$comment/patom:author/patom:uri}">
                            {string($comment/patom:author/patom:name)}
                          </a>
                        else
                          string($comment/patom:author/patom:name)
                      }
                      { " on " }
                      {format-dateTime($comment/patom:modified,
                                       "[D01] [MNn,*-3] [Y0001] @ [h01]:[m01][P] UTC")}
                      { " " }
                      <span class="link"><a href="{$comment/patom:id}">#</a></span>
                    </div>

                    { if (nwn:admin() and (xdmp:document-get-collections($uri) = $nwn:scoll))
                      then
                        <div class="comment-admin">
                          <a href="/process-comment/approve?uri={$uri}">Approve</a>
                          { " / " }
                          <a href="/process-comment/reject?uri={$uri}">Reject</a>
                        </div>
                      else
                        ()
                    }
                  </div>
              }
          </div>
      }

      <div id="addcomment">
        <a id="addcommentlink" href="/cgi-bin/talkback?page={$baseuri}"
        onclick="inlineComment(); return false;">Add</a>
        a comment or
        <a href="{$baseuri}/comments.atom">subscribe</a> to (existing and future)
        comments on this essay.
        { if (empty($staged))
          then ()
          else (<br/>,concat(count($staged), " comment",
                      if (count($staged) > 1) then "s" else "",
                      " await",
                      if (count($staged) > 1) then "" else "s",
                      " moderator approval."))
        }
      </div>
      <div id="newcomment">
        { local:comment-form() }
      </div>
    </div>
};

declare function local:special-case-404($uri as xs:string) {
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Resource not found</title>
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner((), concat("Resource not found: ", $uri), (), ()) }
      <div id="content">
        <div class="abstract">
          <p>We apologize for the inconvenience...</p>
        </div>
        <p>There's nothing here with that name. I've reported the problem, perhaps
        Norm will be able to get it online.</p>
      </div>
      { nwn:footer() }
    </body>
  </html>
};

let $docuri := nwn:docuri($uri)
return
  if (doc-available($docuri))
  then
    doc($docuri)
  else
    if (contains($docuri, "/examples/") and doc-available(concat($docuri, ".xml")))
    then
      (xdmp:set-response-code(404, "Document does not exist."),
       local:special-case-404($uri))
    else
      local:decorate(concat($docuri, ".xml"), nwn:format-essay($docuri))
