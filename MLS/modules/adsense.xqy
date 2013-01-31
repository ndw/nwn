xquery version "1.0-ml";

module namespace adsense="http://norman.walsh.name/ns/modules/adsense";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function adsense:ads()
{
  <div xmlns="http://www.w3.org/1999/xhtml" class="adsense">
   <script type="text/javascript">
     { "//", comment {
"&#10;
google_ad_client = ""ca-pub-6050294877545622"";
/* NWN */
google_ad_slot = ""3303390638"";
google_ad_width = 728;
google_ad_height = 90;
//" } }</script>
   <script type="text/javascript"
     src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
   </script>
  </div>
};
