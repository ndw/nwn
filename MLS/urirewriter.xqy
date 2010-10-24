xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

import module namespace audit="http://norman.walsh.name/ns/modules/audit"
       at "audit.xqy";

import module namespace rwlib="http://norman.walsh.name/ns/modules/rwlib"
       at "rwlib.xqy";

declare variable $method := xdmp:get-request-method();

declare variable $rwopts
  := <options xmlns="http://norman.walsh.name/ns/modules/rwlib">
       <map>
         <pattern>^((/.*)\.xqy(\?.*)?)$</pattern>
         <privilege uri="http://norman.walsh.name/ns/priv/weblog-update">execute</privilege>
         <replace>$1</replace>
       </map>
       <map>
         <pattern>^/cgi-bin/talkback(\?(.*))?$</pattern>
         <replace>/talkback.xqy$1</replace>
       </map>
       <map method="POST">
         <pattern>^(/[^?]+)(\?(.*))?$</pattern>
         <replace>/post.xqy?uri=$1&amp;$3</replace>
       </map>
       <map>
         <pattern>^/(\?.*)?$</pattern>
         <replace>/default.xqy$1</replace>
       </map>
       <map>
         <pattern>^/dates(/(.*))?(\?(.*))?$</pattern>
         <replace>/dates.xqy?year=$2&amp;$4</replace>
       </map>
       <map>
         <pattern>^/topics(\?.*)?$</pattern>
         <replace>/topics.xqy$1</replace>
       </map>
       <map>
         <pattern>^/subjects(/(.?))?(\?(.*))?$</pattern>
         <replace>/subjects.xqy?letter=$2&amp;$4</replace>
       </map>
       <map>
         <pattern>^/coverage(\?.*)?$</pattern>
         <replace>/coverage.xqy$1</replace>
       </map>
       <map>
         <pattern>^/search(\?.*)?$</pattern>
         <replace>/search.xqy$1</replace>
       </map>
       <map>
         <pattern>^/atom(/(.*)\.xml)(\?(.*))?$</pattern>
         <replace>/feed.xqy?feed=$2&amp;type=atom&amp;$4</replace>
       </map>
       <map>
         <pattern>^/atom(/(.*)\.atom)(\?(.*))?$</pattern>
         <replace>/feed.xqy?feed=$2&amp;type=atom&amp;$4</replace>
       </map>
       <map>
         <pattern>^/rss(/(.*)\.rss)?(\?(.*))?$</pattern>
         <replace>/feed.xqy?feed=$2&amp;type=rss&amp;$4</replace>
       </map>
       <map>
         <pattern>^/local(/[^?]+)(\?(.*))?$</pattern>
         <replace>/local.xqy?uri=$1&amp;$3</replace>
       </map>
       <map>
         <pattern>^/errors(\?(.*))?$</pattern>
         <privilege uri="http://norman.walsh.name/ns/priv/weblog-update">execute</privilege>
         <replace>/error-report.xqy$1</replace>
       </map>
       <map>
         <pattern>^(/audit/.+)$</pattern>
         <privilege uri="http://norman.walsh.name/ns/priv/weblog-update">execute</privilege>
         <exists>$1</exists>
         <replace>/serve.xqy?uri=$1</replace>
       </map>
       <map>
         <pattern>^/knows/who/((.*)\.html)?(\?(.*))?$</pattern>
         <replace>/knows/who.xqy?who=$2&amp;type=html&amp;$4</replace>
       </map>
       <map>
         <pattern>^/knows/who/((.*)\.rdf)?(\?(.*))?$</pattern>
         <replace>/knows/who.xqy?who=$2&amp;type=rdf&amp;$4</replace>
       </map>
       <map>
         <pattern>^/knows/who/(.*)?(\?(.*))?$</pattern>
         <replace>/knows/who.xqy?who=$1&amp;$3</replace>
       </map>
       <map>
         <pattern>^/knows/who/?(\?(.*))?$</pattern>
         <replace>/knows/who.xqy$1</replace>
       </map>
       <map>
         <pattern>^/knows/where/((.*)\.html)?(\?(.*))?$</pattern>
         <replace>/knows/where.xqy?where=$2&amp;type=html&amp;$4</replace>
       </map>
       <map>
         <pattern>^/knows/where/((.*)\.rdf)?(\?(.*))?$</pattern>
         <replace>/knows/where.xqy?where=$2&amp;type=rdf&amp;$4</replace>
       </map>
       <map>
         <pattern>^/knows/where/(.*)?(\?(.*))?$</pattern>
         <replace>/knows/where.xqy?where=$1&amp;$3</replace>
       </map>
       <map>
         <pattern>^/knows/where/?(\?(.*))?$</pattern>
         <replace>/knows/where.xqy?$1</replace>
       </map>
       <map>
         <pattern>^/knows/what/((.*)\.html)?(\?(.*))?$</pattern>
         <replace>/knows/what.xqy?what=$2&amp;type=html&amp;$4</replace>
       </map>
       <map>
         <pattern>^/knows/what/((.*)\.rdf)?(\?(.*))?$</pattern>
         <replace>/knows/what.xqy?what=$2&amp;type=rdf&amp;$4</replace>
       </map>
       <map>
         <pattern>^/knows/what/(.*)?(\?(.*))?$</pattern>
         <replace>/knows/what.xqy?what=$1&amp;$3</replace>
       </map>
       <map>
         <pattern>^/knows/what(\?(.*))?$</pattern>
         <replace>/knows/what.xqy?$1</replace>
       </map>
       <map>
         <pattern>^/near/([\+\-]?[0-9]+[^,]*),([\+\-]?[0-9]+[^\?]*)(\?(.*))?$</pattern>
         <replace>/near.xqy?lat=$1&amp;long=$2</replace>
       </map>
       <map>
         <pattern>^(/.*)/comments.atom$</pattern>
         <function apply="doc-exists"
                   ns="http://norman.walsh.name/ns/modules/utils" at="nwn.xqy">$1.xml</function>
         <replace>/comments.xqy?uri=$1</replace>
       </map>

       <map>
         <pattern>^/flush-cache(\?(.*))$</pattern>
         <privilege uri="http://norman.walsh.name/ns/priv/weblog-update">execute</privilege>
         <replace>/admin/flush-cache.xqy$1</replace>
       </map>
       <map>
         <pattern>^/process-comment/([^\?]+)(\?(.*))$</pattern>
         <privilege uri="http://norman.walsh.name/ns/priv/weblog-update">execute</privilege>
         <replace>/admin/process-comment.xqy?action=$1&amp;$3</replace>
       </map>

       <map>
         <pattern>^(/.*).html$</pattern>
         <function apply="doc-exists"
                   ns="http://norman.walsh.name/ns/modules/utils" at="nwn.xqy">$1.xml</function>
         <replace>/redirect.xqy?uri=http://norman.walsh.name$1</replace>
       </map>

       <map>
         <pattern>^/home(.html)?$</pattern>
         <replace>/redirect.xqy?uri=http://norman.walsh.name/</replace>
       </map>

       <map>
         <pattern>^(/.*).html$</pattern>
         <function apply="doc-exists"
                   ns="http://norman.walsh.name/ns/modules/utils" at="nwn.xqy">$1.jpg</function>
         <replace>/photopage.xqy?uri=$1.jpg</replace>
       </map>

       <map method="HEAD">
         <pattern>^(/.*).rdf$</pattern>
         <function apply="doc-exists"
                   ns="http://norman.walsh.name/ns/modules/utils" at="nwn.xqy">$1.xml</function>
         <replace>/head.xqy?uri=$1.xml</replace>
       </map>
       <map>
         <pattern>^(/.*).rdf$</pattern>
         <function apply="doc-exists"
                   ns="http://norman.walsh.name/ns/modules/utils" at="nwn.xqy">$1.xml</function>
         <replace>/rdf.xqy?uri=$1</replace>
       </map>
       <map method="HEAD">
         <pattern>^(.+)$</pattern>
         <function apply="doc-exists"
                   ns="http://norman.walsh.name/ns/modules/utils" at="nwn.xqy">$1</function>
         <replace>/head.xqy?uri=$1</replace>
       </map>
       <map method="HEAD">
         <pattern>^(.+)$</pattern>
         <function apply="doc-exists"
                   ns="http://norman.walsh.name/ns/modules/utils" at="nwn.xqy">$1.xml</function>
         <replace>/head.xqy?uri=$1.xml</replace>
       </map>
       <map>
         <pattern>^(.+)$</pattern>
         <function apply="doc-exists"
                   ns="http://norman.walsh.name/ns/modules/utils" at="nwn.xqy">$1.xml</function>
         <replace>/dispatch.xqy?uri=$1</replace>
       </map>
       <map>
         <pattern>^(.+)$</pattern>
         <function apply="doc-exists"
                   ns="http://norman.walsh.name/ns/modules/utils" at="nwn.xqy">$1</function>
         <replace>/serve.xqy?uri=$1</replace>
       </map>
       <map>
         <pattern>^(.+[^/])/?$</pattern>
         <function apply="doc-exists"
                   ns="http://norman.walsh.name/ns/modules/utils" at="nwn.xqy">$1/overview.xml</function>
         <replace>/dispatch.xqy?uri=$1/overview</replace>
       </map>
       <map>
         <pattern>^(.+[^/])/?$</pattern>
         <function apply="dir-exists"
                   ns="http://norman.walsh.name/ns/modules/utils" at="nwn.xqy">$1/</function>
         <replace>/dir.xqy?uri=$1/</replace>
       </map>
       <map>
         <pattern>^(.+\.xml)$</pattern>
         <privilege uri="http://norman.walsh.name/ns/priv/weblog-update">execute</privilege>
         <replace>/create.xqy?uri=$1</replace>
       </map>
     </options>;

let $uri    := xdmp:get-request-url()
let $result := rwlib:rewrite($uri, $rwopts)
return
  if (empty($result))
  then
    ( (:xdmp:log(concat("URI Rewrite: ", $uri, " => 404!")), :)
     audit:http(xdmp:get-request-method(), $uri, 404),
     $uri)
  else
    ( (:xdmp:log(concat("URI Rewrote: ", $uri, " => ", $result)), :)
     audit:http(xdmp:get-request-method(), $uri, 200),
     $result)
