<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
		xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
		xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
		xmlns:dc='http://purl.org/dc/elements/1.1/'
		xmlns:cvs="http://nwalsh.com/rdf/cvs#"
		xmlns:f="http://nwalsh.com/ns/xslfunctions#"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		exclude-result-prefixes="rdf rdfs dc cvs f xs"
                version="2.0">

<xsl:include href="config.xsl"/>

<rdf:Description rdf:about=''>
  <rdf:type rdf:resource="http://norman.walsh.name/knows/taxonomy#XSL"/>
  <dc:type rdf:resource='http://purl.org/dc/dcmitype/Text'/>
  <dc:format>application/xsl+xml</dc:format>
  <dc:title>Common functions and templates</dc:title>
  <dc:date>2005-12-27</dc:date>
  <cvs:date>$Date$</cvs:date>
  <dc:creator rdf:resource='http://norman.walsh.name/knows/who#norman-walsh'/>
  <dc:rights>Copyright &#169; 2005 Norman Walsh. All rights reserved.</dc:rights>
  <dc:description>Stylesheet containing common functions and templates</dc:description>
</rdf:Description>

<xsl:function name="f:source" as="xs:string">
  <xsl:param name="base-uri" as="xs:string"/>
  <xsl:param name="ext" as="xs:string"/>

  <xsl:value-of
      select="substring-before(substring-after($base-uri,$rooturisl),$ext)"/>
</xsl:function>

<xsl:function name="f:file-path" as="xs:string">
  <xsl:param name="filename" as="xs:string"/>

  <xsl:choose>
    <xsl:when test="matches($filename,'^.*/[^/]+$')">
      <xsl:value-of select="replace($filename,'^(.*)/[^/]+$','$1')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="''"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<xsl:function name="f:link-uri" as="xs:string">
  <xsl:param name="uri" as="xs:string"/>

  <xsl:choose>
    <xsl:when test="starts-with($uri,$hostsl)">
      <xsl:value-of select="substring-after($uri,$host)"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$uri"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<xsl:function name="f:get-rdf" as="element()?">
  <xsl:param name="about"/>
  <xsl:message><xsl:value-of select="concat('f:get-rdf(', $about, ')')"/></xsl:message>
  <xsl:sequence select="()"/>
</xsl:function>

<xsl:function name="f:X-get-rdf" as="element()?">
  <xsl:param name="about"/>

  <xsl:choose>
    <xsl:when test="empty($about)">
      <xsl:sequence select="$about"/>
    </xsl:when>
    <xsl:when test="$about instance of element()">
      <xsl:choose>
	<xsl:when test="$about/@rdf:nodeID">
	  <xsl:variable name="node"
			select="key('nodeID', $about/@rdf:nodeID, $allrdf)"/>
	  <xsl:choose>
	    <xsl:when test="$node">
	      <xsl:sequence select="$node"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:sequence select="$about"/>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:when>
	<xsl:when test="$about/@rdf:resource">
	  <xsl:variable name="node"
			select="key('about', $about/@rdf:resource, $allrdf)"/>
	  <xsl:choose>
	    <xsl:when test="$node">
	      <xsl:sequence select="$node"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:sequence select="$about"/>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:sequence select="$about"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="key('about',string($about), $allrdf)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<xsl:template name="print-date">
  <xsl:param name="date" select="."/>
  <xsl:param name="includeYear" select="1"/>

  <xsl:if test="string-length($date) &gt; 7">
    <xsl:value-of select="substring($date, 9, 2)"/>
    <xsl:text>&#160;</xsl:text>
  </xsl:if>
  <xsl:if test="string-length($date) &gt; 4">
    <xsl:call-template name="month-name">
      <xsl:with-param name="month"
		      select="xs:decimal(substring($date, 6, 2))"/>
      <xsl:with-param name="abbreviate" select="true()"/>
    </xsl:call-template>
  </xsl:if>
  <xsl:if test="$includeYear != 0">
    <xsl:text>&#160;</xsl:text>
    <xsl:value-of select="substring($date, 1, 4)"/>
  </xsl:if>
</xsl:template>

<xsl:template name="print-time">
  <xsl:param name="time" select="."/>
  <xsl:param name="includeSeconds" select="0"/>

  <xsl:variable name="hours" select="substring($time, 1, 2)"/>
  <xsl:variable name="mins" select="substring($time, 4, 2)"/>
  <xsl:variable name="secs" select="substring($time, 7, 2)"/>

  <xsl:variable name="ampm">
    <xsl:choose>
      <xsl:when test="xs:integer($hours) &gt;= 12">p</xsl:when>
      <xsl:otherwise>a</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="phours">
    <xsl:choose>
      <xsl:when test="xs:integer($hours) &gt; 12">
	<xsl:value-of select="xs:integer($hours) - 12"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$hours"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:value-of select="$phours"/>
  <xsl:text>:</xsl:text>
  <xsl:value-of select="$mins"/>
  <xsl:if test="xs:integer($includeSeconds) != 0">
    <xsl:text>:</xsl:text>
    <xsl:value-of select="$secs"/>
  </xsl:if>

  <xsl:value-of select="$ampm"/>
</xsl:template>

<xsl:template name="month-name">
  <xsl:param name="month" as="xs:decimal"/>
  <xsl:param name="abbreviate" select="false()"/>

  <xsl:variable name="name" as="xs:string">
    <xsl:choose>
      <xsl:when test="$month =  1">January</xsl:when>
      <xsl:when test="$month =  2">February</xsl:when>
      <xsl:when test="$month =  3">March</xsl:when>
      <xsl:when test="$month =  4">April</xsl:when>
      <xsl:when test="$month =  5">May</xsl:when>
      <xsl:when test="$month =  6">June</xsl:when>
      <xsl:when test="$month =  7">July</xsl:when>
      <xsl:when test="$month =  8">August</xsl:when>
      <xsl:when test="$month =  9">September</xsl:when>
      <xsl:when test="$month = 10">October</xsl:when>
      <xsl:when test="$month = 11">November</xsl:when>
      <xsl:when test="$month = 12">December</xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$month"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$abbreviate">
      <xsl:value-of select="substring($name, 1, 3)"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$name"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="html">
  <xsl:param name="filename" required="yes"/>
  <xsl:param name="title" required="yes"/>
  <xsl:param name="content" required="yes"/>
  <xsl:param name="abstract" select="()"/>
  <xsl:param name="sidebar" select="()"/>
  <xsl:param name="bannerlink" select="()"/>
  <xsl:param name="metadata" select="()"/>
  <xsl:param name="verbose" select="0"/>
  <xsl:param name="extracss" select="()"/>
  <xsl:param name="head"/>

  <xsl:if test="$verbose != 0">
    <xsl:message>
      <xsl:text>Writing </xsl:text>
      <xsl:value-of select="$filename"/>
    </xsl:message>
  </xsl:if>

  <xsl:result-document
      href="{$filename}"
      encoding="utf-8"
      doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
      doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html>
      <head>
	<title><xsl:value-of select="$title"/></title>

	<xsl:comment>
	  <xsl:text>#include virtual="/include/scripts.html"</xsl:text>
	</xsl:comment>

	<xsl:comment>
	  <xsl:text>#include virtual="/include/csslinks.html"</xsl:text>
	</xsl:comment>

	<xsl:copy-of select="$extracss"/>

	<meta name="foaf:maker" content="foaf:mbox mailto:ndw@nwalsh.com"/>
	<meta name="DC.title" content="{$title}"/>

	<xsl:if test="$metadata">
	  <link rel="alternate" type="application/rdf+xml" title="Metadata"
		href="{$metadata}"/>
	</xsl:if>
      
	<link rel="icon" href="/graphics/nwn.png" type="image/png"/>

	<link rel="home" href="/" title="NWN"/>
	<link rel="contents" title="Contents" href="/dates.html" />
	<link rel="index" title="Index" href="/subjects.html" />

	<xsl:if test="$head">
	  <xsl:copy-of select="$head"/>
	</xsl:if>
      </head>
      <body>
	<div id="banner">
	  <div id="header">
	    <a href="/">Norman.Walsh.name</a>
	    <xsl:if test="$bannerlink">
	      <span class="div"> / </span>
	      <xsl:copy-of select="$bannerlink"/>
	    </xsl:if>
	  </div>

	  <h1><xsl:value-of select="$title"/></h1>

	  <h2>
            <xsl:value-of select="format-date(current-date(),
                                              '[D01] [MNn,*-3] [Y0001]')"/>
	  </h2>

	  <xsl:comment>#include virtual="/include/search.html"</xsl:comment>
	</div>

	<div id="content">
	  <xsl:if test="$abstract">
	    <div class="abstract">
	      <p>
		<xsl:value-of select="$abstract"/>
	      </p>
	    </div>
	  </xsl:if>

	  <xsl:copy-of select="$content"/>

	  <div class="footer">
	    <xsl:comment>#include virtual="/include/footer.html"</xsl:comment>
	  </div>
	</div>

	<xsl:if test="$sidebar">
	  <div id="sidebar">
	    <div id="close"></div>
	    <xsl:copy-of select="$sidebar"/>
	  </div>
	</xsl:if>
      </body>
    </html>
  </xsl:result-document>
</xsl:template>

</xsl:stylesheet>
