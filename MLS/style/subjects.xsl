<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:cts="http://marklogic.com/cts"
                xmlns:mldb="http://norman.walsh.name/ns/metadata"
                xmlns:f="http://norman.walsh.name/ns/functions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:nwn="http://norman.walsh.name/ns/modules/utils"
		exclude-result-prefixes="nwn xdmp xs"
                extension-element-prefixes="xdmp"
                version="2.0">

<xdmp:import-module namespace="http://norman.walsh.name/ns/modules/utils"
                    href="/nwn.xqy"/>

<xsl:template match="/">
  <subjects>
    <xsl:for-each-group select="cts:element-values(xs:QName('mldb:subject'), (), (),
                                cts:collection-query(nwn:essay-collections()))"
                        group-by="f:group-id(.)">
      <group key="{current-grouping-key()}">
        <xsl:for-each select="current-group()">
          <xsl:sort select="upper-case(.)"/>
          <subject><xsl:value-of select="."/></subject>
        </xsl:for-each>
      </group>
    </xsl:for-each-group>
  </subjects>
</xsl:template>

<xsl:function name="f:group-id">
  <xsl:param name="subject"/>
  <xsl:variable name="first" select="upper-case(substring($subject, 1, 1))"/>
  <xsl:choose>
    <xsl:when test="translate($first, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', '') = ''">
      <xsl:value-of select="$first"/>
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:function>

</xsl:stylesheet>
