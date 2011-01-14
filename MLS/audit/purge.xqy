xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

xdmp:invoke("/audit/do-purge.xqy", (),
            <options xmlns="xdmp:eval">
              <database>{xdmp:database("nwn-audit")}</database>
            </options>)
