<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0">

<xsl:template match="/">
  <essays>
    <xsl:for-each-group select="//essay" group-by="dist">
      <dist mi="{current-grouping-key()}">
        <xsl:for-each select="current-group()">
          <xsl:sequence select="uri"/>
        </xsl:for-each>
      </dist>
    </xsl:for-each-group>
  </essays>
</xsl:template>

</xsl:stylesheet>
