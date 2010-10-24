<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
		xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
		xmlns:dc='http://purl.org/dc/elements/1.1/'
		xmlns:cvs="http://nwalsh.com/rdf/cvs#"
		exclude-result-prefixes="rdf rdfs dc cvs"
                version="2.0">

<rdf:Description rdf:about=''>
  <rdf:type rdf:resource="http://norman.walsh.name/knows/taxonomy#XSL"/>
  <dc:type rdf:resource='http://purl.org/dc/dcmitype/Text'/>
  <dc:format>application/xsl+xml</dc:format>
  <dc:title>Global configuration</dc:title>
  <dc:date>2005-09-08</dc:date>
  <cvs:date>$Date: 2005-02-12 16:57:25 -0500 (Sat, 12 Feb 2005) $</cvs:date>
  <dc:creator rdf:resource='http://norman.walsh.name/knows/who#norman-walsh'/>
  <dc:rights>Copyright &#169; 2005 Norman Walsh. All rights reserved.</dc:rights>
  <dc:description>Stylesheet containing global configuration info</dc:description>
</rdf:Description>

<xsl:variable name="root" select="'/home/ndw/norman.walsh.name'"/>
<xsl:variable name="rooturi" select="concat('file:', $root)"/>
<xsl:variable name="rooturisl" select="concat($rooturi, '/')"/>

<xsl:variable name="allrdf"
	      select="document(concat($root,'/knows/norman.walsh.name.rdf'))"/>

<xsl:variable name="host" select="'http://norman.walsh.name'"/>
<xsl:variable name="hostsl" select="concat($host,'/')"/>

<xsl:key name="about" match="rdf:Description" use="@rdf:about"/>
<xsl:key name="nodeID" match="rdf:Description" use="@rdf:nodeID"/>

</xsl:stylesheet>
