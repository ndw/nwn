<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:db="http://docbook.org/ns/docbook"
                xmlns:f="http://docbook.org/xslt/ns/extension"
                xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0"
		xmlns:t="http://docbook.org/xslt/ns/template"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="db f l t xs xdmp"
                version="2.0">

<xsl:import href="/DocBook/base/html/docbook.xsl"/>

<xsl:param name="l10n.locale.dir" select="'/production/etc/locales/'"/>

<xsl:function name="f:load-locale" as="element(l:l10n)">
  <xsl:param name="lang" as="xs:string"/>
  <xsl:variable name="locale-file"
                select="resolve-uri(concat($lang,'.xml'), $l10n.locale.dir)"/>
  <xsl:variable name="l10n" select="doc($locale-file)/l:l10n"/>
  <xsl:sequence select="(if (empty($l10n))
                         then xdmp:log(concat('Failed to load localization: ', $locale-file))
                         else (), $l10n)"/>
</xsl:function>

<xsl:template name="t:user-localization-data">
  <xsl:sequence select="f:load-locale('en')"/>
</xsl:template>

</xsl:stylesheet>

