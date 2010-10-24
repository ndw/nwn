xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace owl="http://www.w3.org/2002/07/owl#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace a="http://nwalsh.com/rdf/accounts#";
declare namespace c="http://nwalsh.com/rdf/contacts#";
declare namespace foaf="http://xmlns.com/foaf/0.1/";

let $uri := xdmp:get-request-field("uri")
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>FIXME: Image title</title>
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner($uri, "FIXME: Image title", (), ()) }
      <div id="content">
        <img src="{$uri}" width="100%"/>
      </div>
      { nwn:footer() }
    </body>
  </html>

