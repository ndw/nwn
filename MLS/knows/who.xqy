xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "/nwn.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace owl="http://www.w3.org/2002/07/owl#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace a="http://nwalsh.com/rdf/accounts#";
declare namespace c="http://nwalsh.com/rdf/contacts#";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace etc="http://norman.walsh.name/ns/etc";
declare namespace html="http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "false";

declare function local:redirect($who as xs:string) {
  let $newuri := concat("http://", /etc:host-config/etc:reader/etc:host,
                        if (/etc:host-config/etc:reader/etc:port)
                        then concat(":", /etc:host-config/etc:reader/etc:port)
                        else "",
                        "/knows/who/", $who, ".html")
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
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{string($rdf/foaf:name)}</title>
      <meta name="foaf:maker" content="foaf:mbox mailto:ndw@nwalsh.com" />
      <meta name="DC.title" content="{string($rdf/foaf:name)}"/>
      <link rel="alternate" type="application/rdf+xml" title="Essay metadata"
            href="{substring-after(xdmp:node-uri($rdf), '/knows/who/')}" />
      <link rel="icon" href="/graphics/nwn.png" type="image/png" />
      <link rel="home" href="/" title="NWN" />
      <link rel="contents" title="Contents" href="/dates.html" />
      <link rel="index" title="Index" href="/subjects.html" />
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner(nwn:httpuri(xdmp:node-uri($rdf)),
                   $rdf/foaf:name, (), nwn:most-recent-update()) }
      <div id="content">
        <dl>
          <dt>URI</dt>
          <dd>
            <ul>
              <li>
                <a href="{string($rdf/@rdf:about)}">{string($rdf/@rdf:about)}</a>
             </li>
            </ul>
          </dd>
          { for $type in (xs:QName("c:associatedName"), xs:QName("c:associatedTitle"),
                          xs:QName("foaf:mbox_sha1sum"),
                          xs:QName("foaf:homepage"), xs:QName("foaf:weblog"),
                          xs:QName("foaf:page"), xs:QName("foaf:depiction"))
            let $elem := $rdf/*[node-name(.) = $type]
            return
              if (empty($elem)) then ()
              else
                (<dt>{local-name($elem[1])}</dt>,
                 <dd>
                   <ul>
                     { for $n in $elem
                       return
                         <li>
                           { if ($n/@rdf:resource)
                             then
                               <a href="{$n/@rdf:resource}">
                                 { string($n/@rdf:resource) }
                               </a>
                             else
                               string($n)
                           }
                         </li>
                     }
                   </ul>
                 </dd>)
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
      <title>Who</title>
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner("/who", "Who", (), nwn:most-recent-update()) }
      <div id="content">
        <div class="abstract">
          <p>Who norm knows...</p>
        </div>
        <dl>
          { for $rdf in /rdf:Description[rdf:type/@rdf:resource="http://xmlns.com/foaf/0.1/Person"]
            order by concat($rdf/foaf:surname, ",", $rdf/foaf:firstName)
            return
              <dt>
                <a href="/knows/who/{substring-after($rdf/@rdf:about, 'knows/who/')}">
                  { string($rdf/foaf:name) }
                </a>
              </dt>
          }
        </dl>
      </div>
      { nwn:footer() }
    </body>
  </html>
};

let $who    := xdmp:get-request-field("who")
let $type   := xdmp:get-request-field("type")
let $whodoc := doc(concat("/production/etc/knows/who/", $who, ".rdf"))
let $rdf    := $whodoc/rdf:Description
return
  if (empty($who) or $who = "")
  then
    local:index()
  else
    if (empty($rdf))
    then
      (xdmp:set-response-code(404, "Not Found."),
       concat("404 resource not found: /knows/who/", $who))
    else
      if ($type eq "html")
      then
        local:html($rdf)
      else
        if ($type eq "rdf")
        then
          local:rdf($rdf)
        else
          local:redirect($who)
