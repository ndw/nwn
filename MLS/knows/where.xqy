xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "/nwn.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace owl="http://www.w3.org/2002/07/owl#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace a="http://nwalsh.com/rdf/accounts#";
declare namespace c="http://nwalsh.com/rdf/contacts#";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace etc="http://norman.walsh.name/ns/etc";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace v="http://nwalsh.com/rdf/vCard#";

declare option xdmp:mapping "false";

declare function local:redirect($where as xs:string) {
  let $newuri := concat("http://", /etc:host-config/etc:reader/etc:host,
                        if (/etc:host-config/etc:reader/etc:port)
                        then concat(":", /etc:host-config/etc:reader/etc:port)
                        else "",
                        "/knows/where/", $where, ".html")
  return
    (xdmp:set-response-code(303, "See Other"),
     xdmp:add-response-header("Location", $newuri),
     concat("303 See other: ", $newuri))
};

declare function local:rdf($rdf as element(rdf:Description)?) as element(rdf:RDF) {
  <rdf:RDF>
    {$rdf}
  </rdf:RDF>
};

declare function local:html($rdf as element(rdf:Description)?) as element(html:html) {
  let $addr := $rdf/v:unlabeledAdr | $rdf/v:workAdr | $rdf/v:homeAdr
  let $page := $rdf/foaf:homepage | $rdf/foaf:page
  return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{string($rdf/c:associatedName)}</title>
      <meta name="foaf:maker" content="foaf:mbox mailto:ndw@nwalsh.com" />
      <meta name="DC.title" content="{string($rdf/c:associatedName)}"/>
      <link rel="alternate" type="application/rdf+xml" title="Essay metadata"
            href="{substring-after(xdmp:node-uri($rdf), '/knows/where/')}" />
      <link rel="icon" href="/graphics/nwn.png" type="image/png" />
      <link rel="home" href="/" title="NWN" />
      <link rel="contents" title="Contents" href="/dates.html" />
      <link rel="index" title="Index" href="/subjects.html" />
      { nwn:css-links() }

      { if ($rdf/geo:lat and $rdf/geo:long)
        then
          (<script type="text/javascript" src="/js/jquery-1.4.2.min.js">,
           </script>,
           <script type="text/javascript" src="/js/jquery.timers-1.2.js">
           </script>,
           <script type="text/javascript" src="/js/nwn.js">
           </script>,
           <script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false">
           </script>,
           <script type="text/javascript" src="/js/gmapfunc.js"></script>)
        else
           ()
      }
    </head>
    <body>
      { nwn:banner(nwn:httpuri(xdmp:node-uri($rdf)),
                   $rdf/c:associatedName, (), nwn:most-recent-update()) }
      <div id="content">
        { if ($rdf/dc:description)
          then
            <div class="abstract"><p>{string($rdf/dc:description)}</p></div>
          else
            ()
        }

      { if ($rdf/geo:lat and $rdf/geo:long)
        then
          (<div class="artwork" id="map" style="width: 540px; height: 540px;"></div>,
           <div class="map-messages" id="map_messages"></div>,
           <script type="text/javascript">
var mapdata = {{
     "centerlat": {string($rdf/geo:lat)},
     "centerlng": {string($rdf/geo:long)},
     "zoom": 13,
     "showTrackMarks": false,
     "showImageMarks": true,
     "tracks": []
}}</script>,
           <script type="text/javascript">// Populate map(s)
$(document).ready(function() {{
      plotTracks(mapdata,"map")
}});</script>)
        else
          ()
      }

        <dl>
          <dt>URI</dt>
          <dd>
            <ul>
              <li><a href="{string($rdf/@rdf:about)}">{string($rdf/@rdf:about)}</a></li>
            </ul>
          </dd>

          { if ($addr/v:country-name)
            then
              (<dt>Country</dt>,
               <dd>
                 <ul>
                   <li>
                     {string(($addr/v:country-name)[1])}
                     {if ($rdf/c:ciaFactbook)
                      then
                        (" ",
                         <a href="{$rdf/c:ciaFactbook/@rdf:resource}">
                           <img border="0" alt="[CIA Factbook]" src="/graphics/ciafbook.png"/>
                         </a>)
                       else
                         ()
                     }
                   </li>
                 </ul>
               </dd>)
             else
               ()
          }

          { if ($addr/v:street-address)
            then
              (<dt>Address</dt>,
               <dd>
                 <ul>
                   { for $a in $addr[v:street-address]
                     return
                       <li>
                         {string($a/v:street-address)}
                         <br/>
                         {string($a/v:locality)}
                         { if ($a/v:region) then ", " else "" }
                         {string($a/v:region)}
                         { " " }
                         {string($a/v:postal-code)}
                         { if ($a/v:country-name and $a/v:country-name != "US")
                           then (<br/>, string($a/v:country-name))
                           else ()
                         }
                       </li>
                   }
                 </ul>
               </dd>)
             else
               ()
          }

          { if ($rdf/geo:lat and $rdf/geo:long)
            then
              (<dt>Location</dt>,
               <dd>
                 <ul>
                   <li>{string($rdf/geo:lat)},{string($rdf/geo:long)}</li>
                   <li>
                     <a href="http://maps.google.com/maps?q=&amp;ll={$rdf/geo:lat},{$rdf/geo:long}">Google</a>
                   </li>
                   <li>
                     <a href="http://www.mapquest.com/maps/map.adp?latlongtype=decimal&amp;latitude={$rdf/geo:lat}&amp;longitude={$rdf/geo:long}&amp;size=big&amp;zoom=8">MapQuest</a>
                   </li>
                   <li>
                     <a href="http://www.bing.com/maps/?lvl=14&amp;cp={$rdf/geo:lat}~{$rdf/geo:long}">bing Maps</a>
                   </li>
                 </ul>
               </dd>)
             else
               ()
          }

          { if ($page)
            then
              (<dt>See also</dt>,
               <dd>
                 <ul>
                   { for $home in $page
                     let $uri := string($home/@rdf:resource)
                     let $title
                       := if (contains($uri, 'getty.edu'))
                          then "Getty Thesaurus of Geographic Names"
                          else $uri
                     return
                       <li><a href="{$uri}">{$title}</a></li>
                   }
                 </ul>
               </dd>)
            else
              ()
          }

          { (: HACK! :) }
          { let $essays := /db:essay[db:info/dc:coverage/@rdf:resource=$rdf/@rdf:about
                                     and starts-with(xdmp:node-uri(.),"/production/")]
            return
              if ($essays)
              then
                (<dt>Essays</dt>,
                 <dd>
                   <ul>
                     { for $essay in $essays
                       order by $essay/db:info/mldb:pubdate descending
                       return
                         <li>
                           <a href="{nwn:httpuri(xdmp:node-uri($essay))}">
                             { string($essay/db:info/db:title) }
                             </a>, {
                               format-dateTime($essay/db:info/mldb:pubdate,
                                               "[D01]&#160;[MNn,*-3]&#160;[Y0001]")
                             }
                             <div class="listabstract">
                               { string($essay/db:info/db:abstract) }
                             </div>
                         </li>
                     }
                   </ul>
                 </dd>)
              else
                ()
          }
        </dl>
      </div>
      { nwn:footer() }
    </body>
  </html>
};

declare function local:index() as element(html:html) {
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Where</title>
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner("/where", "Where", (), nwn:most-recent-update()) }
      <div id="content">
        <div class="abstract">
          <p>Where norm knows...</p>
        </div>

        <p>I've assigned URIs to the places listed below.</p>

        <dl>
          { for $rdf in /rdf:Description[rdf:type/@rdf:resource
                                         ="http://nwalsh.com/rdf/contacts#Place"]
            order by string($rdf/c:associatedName)
            return
              <dt id="{substring-after($rdf/@rdf:about, 'knows/where/')}">
                <a href="/knows/where/{substring-after($rdf/@rdf:about, 'knows/where/')}">
                  { string($rdf/c:associatedName) }
                </a>
              </dt>
          }
        </dl>
      </div>
      { nwn:footer() }
    </body>
  </html>
};

let $where    := xdmp:get-request-field("where")
let $type     := xdmp:get-request-field("type")
let $wheredoc := doc(concat("/production/etc/knows/where/", $where, ".rdf"))
let $rdf      := $wheredoc/rdf:Description
return
  if (empty($where))
  then
    local:index()
  else
    if (empty($rdf))
    then
      (xdmp:set-response-code(404, "Not Found."),
       concat("404 resource not found: /knows/where/", $where))
    else
      if ($type eq "html")
      then
        local:html($rdf)
      else
        if ($type eq "rdf")
        then
          local:rdf($rdf)
        else
          local:redirect($where)
