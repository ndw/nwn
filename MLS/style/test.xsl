<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0">

<xsl:template match="*">
  <xsl:variable name="label" as="node()*">
    <xsl:apply-templates select="." mode="label-content"/>
  </xsl:variable>
  <xxx><xsl:sequence select="$label"/></xxx>
</xsl:template>

<xsl:template match="*" mode="label-content">
  <xsl:value-of select="1"/>
</xsl:template>

</xsl:stylesheet>
