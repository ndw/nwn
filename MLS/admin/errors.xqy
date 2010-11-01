xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "/nwn.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Errors</title>
    { nwn:css-links() }
  </head>
  <body>
    { nwn:banner("/admin/errors", "Errors", (), current-dateTime()) }
    <div id="content">
      { xdmp:invoke("/error-report.xqy", (),
                    <options xmlns="xdmp:eval">
                      <database>{xdmp:database("nwn-audit")}</database>
                    </options>)
      }
    </div>
    { nwn:footer() }
  </body>
</html>

