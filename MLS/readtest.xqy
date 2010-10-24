xquery version "1.0-ml";

declare option xdmp:output "indent=no";

let $xslt := <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0">

<!--
<xsl:output method="xml" encoding="utf-8" indent="no"
	    omit-xml-declaration="yes"/>
-->

<xsl:template match="/">
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head></head>
    <body>
      <xsl:apply-templates/>
    </body>
  </html>
</xsl:template>

<xsl:template match="doc">
  <div xmlns="http://www.w3.org/1999/xhtml">
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="pl">
  <pre xmlns="http://www.w3.org/1999/xhtml">
    <xsl:apply-templates/>
  </pre>
</xsl:template>

<xsl:template match="comment()|processing-instruction()|text()">
  <xsl:copy/>
</xsl:template>

</xsl:stylesheet>

let $doc := document {
  <doc>
    <pl>Some text
that's
not
indented</pl>
  </doc>
}

let $map := map:map()
return
  xdmp:xslt-eval($xslt, $doc, $map)
