<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:error="http://marklogic.com/xdmp/error"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="error"
                version="2.0">

<xsl:output method="xml" encoding="utf-8" indent="yes"
        omit-xml-declaration="yes"/>

<xsl:preserve-space elements="*"/>

<xsl:template match="/">
  <xsl:apply-templates select="(.//error:error)[1]"/>
</xsl:template>

<xsl:template match="error:error">
  <!-- style is a hack! -->
  <div class="error" style="margin-left: 1em">
    <p>
      <xsl:if test="error:name != ''">
        <b><xsl:value-of select="error:name"/></b>
        <xsl:text>: </xsl:text>
      </xsl:if>
      <b>
        <xsl:choose>
          <xsl:when test="error:format-string = ''">
            <xsl:value-of select="error:message"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="error:format-string"/>
          </xsl:otherwise>
        </xsl:choose>
      </b>
    </p>
    <xsl:apply-templates select="error:stack"/>
  </div>
</xsl:template>

<xsl:template match="error:stack">
  <div>
    <xsl:apply-templates select="error:frame"/>
  </div>
</xsl:template>

<xsl:template match="error:frame">
  <div style="margin-top: 1ex;">
    <xsl:text>In </xsl:text>
    <tt>
      <xsl:value-of select="error:uri"/>
    </tt>
    <xsl:text> on line </xsl:text>
    <xsl:value-of select="error:line"/>
  </div>
  <xsl:if test="error:operation">
    <div style="margin-left: 2em; text-indent: -1em;">
      <xsl:text>In </xsl:text>
      <xsl:value-of select="error:operation"/>
    </div>
  </xsl:if>

  <xsl:if test="error:variables">
    <xsl:for-each select="error:variables/error:variable">
      <div style="margin-left: 3em; text-indent: -1em;">
        <xsl:text>$</xsl:text>
        <xsl:value-of select="error:name"/>
        <xsl:text> = </xsl:text>
        <xsl:value-of select="error:value"/>
      </div>
    </xsl:for-each>
  </xsl:if>
</xsl:template>

<xsl:template match="*">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<xsl:template match="comment()|processing-instruction()|text()">
  <xsl:copy/>
</xsl:template>

</xsl:stylesheet>

<!--
<error:error xsi:schemaLocation="http://marklogic.com/xdmp/error error.xsd" xmlns:error="http://marklogic.com/xdmp/error" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <error:code>Endpoint '/' requires the caller to accept one of the following media types: 'application/pdf', 'text/binary'</error:code>
  <error:name>ep:UNACCEPTABLE_TYPE</error:name>
  <error:xquery-version>1.0-ml</error:xquery-version>
  <error:message>Endpoint '/' requires the caller to accept one of the following media types: 'application/pdf', 'text/binary'</error:message>
  <error:format-string/>
  <error:retryable>false</error:retryable>

  <error:expr> </error:expr>
  <error:data/>
  <error:stack>
    <error:frame>
      <error:uri>/endpoints.xqy</error:uri>
      <error:line>45</error:line>
      <error:operation>ep:reply(("application/pdf", "text/binary"))</error:operation>

      <error:variables>
	<error:variable>
	  <error:name xmlns="http://marklogic.com/appservices/utils/endpoints">types</error:name>
	  <error:value>("application/pdf", "text/binary")</error:value>
	</error:variable>
	<error:variable>
	  <error:name xmlns="http://marklogic.com/appservices/utils/endpoints">match</error:name>

	  <error:value>(0, 0, 0, ...)</error:value>
	</error:variable>
	<error:variable>
	  <error:name xmlns="http://marklogic.com/appservices/utils/endpoints">trace</error:name>
	  <error:value>()</error:value>
	</error:variable>
      </error:variables>

      <error:xquery-version>1.0-ml</error:xquery-version>
    </error:frame>
    <error:frame>
      <error:uri>/</error:uri>
      <error:line>13</error:line>
      <error:xquery-version>1.0-ml</error:xquery-version>
    </error:frame>

  </error:stack>
</error:error>
-->
