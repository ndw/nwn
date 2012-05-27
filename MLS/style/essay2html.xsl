<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:etc="http://norman.walsh.name/ns/etc"
                xmlns:atom="http://www.w3.org/2005/Atom"
		xmlns:c="http://nwalsh.com/rdf/contacts#"
                xmlns:cvs="http://nwalsh.com/rdf/cvs#"
                xmlns:daml="http://www.daml.org/2001/03/daml+oil#"
                xmlns:db="http://docbook.org/ns/docbook"
		xmlns:dbf="http://docbook.org/xslt/ns/extension"
		xmlns:dbm="http://docbook.org/xslt/ns/mode"
                xmlns:dbt="http://docbook.org/xslt/ns/template"
                xmlns:dc='http://purl.org/dc/elements/1.1/'
                xmlns:dcterms="http://purl.org/dc/terms/"
		xmlns:f="http://nwalsh.com/ns/xslfunctions#"
                xmlns:foaf="http://xmlns.com/foaf/0.1/"
                xmlns:gal='http://norman.walsh.name/rdf/gallery#'
                xmlns:geo='http://www.w3.org/2003/01/geo/wgs84_pos#'
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:itin="http://nwalsh.com/rdf/itinerary#"
                xmlns:m="http://docbook.org/xslt/ns/mode"
		xmlns:out="http://docbook.org/xslt/ns/output"
                xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:skos="http://www.w3.org/2004/02/skos/core#"
                xmlns:t="http://norman.walsh.name/knows/taxonomy#"
                xmlns:tmpl="http://docbook.org/xslt/ns/template"
                xmlns:ttag="http://developers.technorati.com/wiki/RelTag#"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:nwn="http://norman.walsh.name/ns/modules/utils"
                xmlns:flickr="http://www.flickr.com/services/api/"
                exclude-result-prefixes="atom db dbf dbm dbt html itin c cvs daml
					 dc dcterms etc f foaf gal geo
					 m out rdf rdfs skos nwn flickr
					 t tmpl ttag xlink xs xdmp"
                extension-element-prefixes="xdmp"
		version="2.0">

<!--
   xmlns:palm="http://nwalsh.com/rdf/palm#"
   xmlns:p="http://nwalsh.com/rdf/pim#"
-->

<xsl:import href="mldbhtml.xsl"/>

<xdmp:import-module namespace="http://norman.walsh.name/ns/modules/utils"
                    href="/nwn.xqy"/>

<!--
<xsl:import href="../2005/projects/examples/flickr.xsl"/>
<xsl:include href="/home/ndw/stylesheets/myFlickrKeys.xsl"/>
<xsl:include href="atom2html.xsl"/>
-->
<xsl:include href="common.xsl"/>
<xsl:include href="itin2html.xsl"/>

<rdf:Description rdf:about=''>
  <rdf:type rdf:resource="http://norman.walsh.name/knows/taxonomy#XSL"/>
  <dc:type rdf:resource='http://purl.org/dc/dcmitype/Text'/>
  <dc:format>application/xsl+xml</dc:format>
  <dc:title>HTML stylesheet for essays</dc:title>
  <dc:date>2005-12-28</dc:date>
  <cvs:date>$Date$</cvs:date>
  <dc:creator rdf:resource='http://norman.walsh.name/knows/who#norman-walsh'/>
  <dc:rights>Copyright &#169; 2005 Norman Walsh. All rights reserved.</dc:rights>
  <dc:description>Convert an NWN essay to HTML.</dc:description>
</rdf:Description>

<xsl:output method="xml" encoding="utf-8" indent="no"/>

<xsl:param name="pygments-default" select="1"/>
<xsl:param name="annotation.graphic.open" select="'/graphics/annot-open.png'"/>
<xsl:param name="annotation.graphic.close" select="'/graphics/annot-close.png'"/>
<xsl:param name="offline" select="0"/>

<xsl:param name="pygmenter-uri" select="'http://localhost:8200/cgi-bin/pygmenter'"/>

<xsl:param name="linenumbering" as="element()*">
<ln path="literallayout" everyNth="0"/>
<ln path="programlisting" everyNth="1"/>
<ln path="programlistingco" everyNth="0"/>
<ln path="screen" everyNth="0"/>
<ln path="synopsis" everyNth="0"/>
<ln path="address" everyNth="0"/>
</xsl:param>

<!-- Keys -->

<xsl:key name="types" match="rdf:Description" use="rdf:type/@rdf:resource"/>
<xsl:key name="foaf:names" match="rdf:Description" use="foaf:name"/>
<xsl:key name="foaf:nicks" match="rdf:Description" use="foaf:nick"/>
<xsl:key name="wikipedia" match="rdf:Description" use="t:wikipedia"/>
<xsl:key name="rdfs:label" match="rdf:Description" use="rdfs:label"/>
<xsl:key name="rdf:about" match="rdf:Description" use="@rdf:about"/>

<!-- DocBook stylesheet parameters -->

<xsl:param name="admon.graphics" select="1"/>
<xsl:param name="admon.graphics.path" select="'/graphics/'"/>
<xsl:param name="admon.default.titles" select="0"/>
<xsl:param name="annotation-graphic-open" select="'/graphics/annot-open.png'"/>
<xsl:param name="annotation-graphic-close" select="'/graphics/annot-close.png'"/>
<xsl:param name="callout.graphics.path" select="'/graphics/callouts/'"/>
<xsl:param name="table.borders.with.css" select="1"/>
<xsl:param name="funcsynopsis.style" select="'ansi'"/>
<xsl:param name="formal.title.placement" as="element()*">
  <db:figure placement="after"/>
  <db:example placement="after"/>
  <db:equation placement="after"/>
  <db:table placement="before"/>
  <db:procedure placement="before"/>
  <db:task placement="before"/>
</xsl:param>

<xsl:param name="root.elements">
  <db:essay/>
</xsl:param>

<!-- Convenience variables for URIs -->

<xsl:variable name="t:Article"
	      select="'http://norman.walsh.name/knows/taxonomy#Article'"/>

<xsl:variable name="t:Thread"
	      select="'http://norman.walsh.name/knows/taxonomy#Thread'"/>

<xsl:variable name="t:Omit"
	      select="'http://norman.walsh.name/knows/taxonomy#Omit'"/>

<xsl:variable name="t:Travel"
	      select="'http://norman.walsh.name/knows/taxonomy#Travel'"/>

<xsl:variable name="t:OmitTags"
	      select="'http://norman.walsh.name/knows/taxonomy#OmitTags'"/>

<xsl:variable name="skos:Concept"
	      select="'http://www.w3.org/2004/02/skos/core#Concept'"/>

<!-- Variables -->

<xsl:variable name="rdfAllArticles"
	      select="key('types',$t:Article,$allrdf)"/>

<xsl:variable name="rdfOmitArticles"
	      select="$rdfAllArticles[dc:subject[@rdf:resource=$t:Omit]]"/>

<xsl:variable name="sortedArticles" as="element()*">
  <xsl:perform-sort select="$rdfAllArticles except $rdfOmitArticles">
    <xsl:sort select="dcterms:issued" data-type="text" order="ascending"/>
  </xsl:perform-sort>
</xsl:variable>

<xsl:variable name="images.xml" select="document('/etc/images.xml')/*"/>

<!-- ====================================================================== -->

<xsl:template match="/">
  <xsl:apply-templates select="/*"/>
</xsl:template>

<xsl:template match="db:essay">
  <article>
    <xsl:sequence select="dbf:html-attributes(.,'content')"/>

    <div class="abstract" itemprop="description">
      <xsl:if test="db:info/db:abstract">
        <xsl:apply-templates select="db:info/db:abstract/db:para"/>
      </xsl:if>
    </div>

    <xsl:apply-templates/>

    <xsl:call-template name="tmpl:process-footnotes"/>
  </article>
</xsl:template>

<xsl:template match="db:info"/>

<!-- ============================================================ -->

<xsl:template match="db:textdata">
  <xsl:variable name="filename">
    <xsl:choose>
      <xsl:when test="@entityref">
        <xsl:value-of select="unparsed-entity-uri(@entityref)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="resolve-uri(@fileref,.)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="encoding">
    <xsl:choose>
      <xsl:when test="@encoding">
        <xsl:value-of select="@encoding"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$textdata.default.encoding"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="readFrom" select="nwn:docuri(resolve-uri($filename, base-uri()))"/>

  <xsl:value-of select="if ($encoding = '')
			then unparsed-text($readFrom)
			else  unparsed-text($readFrom,$encoding)"/>
</xsl:template>

<!-- ====================================================================== -->

<xsl:template match="gal:image|gal:graphic">
  <xsl:param name="source"/>
  <xsl:param name="about"/>

  <xsl:variable name="path">
    <xsl:choose>
      <xsl:when test="@base">
        <xsl:value-of select="@base"/>
      </xsl:when>
      <xsl:otherwise>images/</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <div class="photos">
    <xsl:call-template name="image">
      <xsl:with-param name="rsrc" select="@rdf:resource"/>
      <xsl:with-param name="path" select="$path"/>
      <xsl:with-param name="caption" select="not(self::gal:graphic)"/>
    </xsl:call-template>
  </div>
</xsl:template>

<xsl:template match="gal:images">
  <xsl:param name="source"/>
  <xsl:param name="about"/>

  <xsl:variable name="path">
    <xsl:choose>
      <xsl:when test="@base">
        <xsl:value-of select="@base"/>
      </xsl:when>
      <xsl:otherwise>images/</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <div class="photos">
    <xsl:for-each select="rdf:Seq/rdf:li">
      <xsl:call-template name="image">
        <xsl:with-param name="rsrc" select="@rdf:resource"/>
        <xsl:with-param name="pos" select="position()"/>
        <xsl:with-param name="path" select="$path"/>
      </xsl:call-template>
    </xsl:for-each>
  </div>
</xsl:template>

<xsl:template name="image">
  <xsl:param name="rsrc"/>
  <xsl:param name="pos" select="0"/>
  <xsl:param name="path" select="''"/>
  <xsl:param name="caption" select="true()"/>

  <xsl:variable name="uri" select="resolve-uri($rsrc, base-uri(.))"/>
  <xsl:variable name="rdfuri"
                select="substring-after(substring-after($uri, '/'), '/')"/>
  <xsl:variable name="image" select="$images.xml/etc:image[etc:rdfuri = $rdfuri]"/>

  <div>
    <xsl:attribute name="class">
      <xsl:choose>
	<xsl:when test="$pos = 1">firstphoto</xsl:when>
        <xsl:otherwise>photo</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>

    <xsl:choose>
      <xsl:when test="not($image)">
        <p>FIXME: MISSING IMAGE</p>
        <xsl:message>Missing image: <xsl:value-of select="@rdf:resource"/></xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <img border="0" alt="[Photo]" src="{$image/etc:thumburi}"/>

        <xsl:if test="$caption and
                      ($image/etc:title|$image/etc:description)">
          <div class="photoinfo">
            <h3>
              <xsl:choose>
                <xsl:when test="$image/etc:title">
                  <xsl:value-of select="$image/etc:title"/>
                </xsl:when>
                <xsl:otherwise>Untitled</xsl:otherwise>
              </xsl:choose>
            </h3>
            <xsl:if test="$image/etc:description">
              <p class="description">
                <xsl:value-of select="$image/etc:description"/>
              </p>
            </xsl:if>
          </div>
        </xsl:if>
        <br clear="all"/>
      </xsl:otherwise>
    </xsl:choose>
  </div>
</xsl:template>

<xsl:template match="gal:photo">
  <xsl:variable name="uri" select="resolve-uri(@rdf:resource, base-uri(.))"/>
  <xsl:variable name="rdfuri"
                select="substring-after(substring-after($uri, '/'), '/')"/>
  <xsl:variable name="image" select="$images.xml/etc:image[etc:rdfuri = $rdfuri]"/>

  <xsl:choose>
    <xsl:when test="not($image)">
      <p>FIXME: MISSING IMAGE</p>
      <xsl:message>Missing image: <xsl:value-of select="@rdf:resource"/></xsl:message>
    </xsl:when>
    <xsl:otherwise>
      <div class="artwork">
        <img border="0" alt="[Photo]" src="{$image/etc:thumburi}"/>
        <div class="artinfo">
          <h3><xsl:value-of select="$image/etc:title"/></h3>
        </div>
      </div>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="db:figure[@role='photo']">
  <xsl:variable name="width" select="db:mediaobject/db:imageobject/db:imagedata/@width"/>
  <xsl:variable name="uri" select="db:mediaobject/db:imageobject/db:imagedata/@fileref"/>
  <xsl:variable name="link"
                select="replace(replace($uri, '/small/', '/'), '.jpg', '')"/>

  <div class="artwork">
    <div class="local-photo">
      <div class="photo">
        <xsl:if test="$width">
          <!-- +6 for border and padding -->
          <xsl:attribute name="style"
                         select="concat('width: ', $width+6, 'px;')"/>
        </xsl:if>
        <a href="{$link}">
          <img border="0" alt="[Photo]" src="{$uri}"/>
        </a>
      </div>
      <div class="link">
        <h3>
          <xsl:apply-templates select="db:title/node()"/>
        </h3>
      </div>
    </div>
  </div>
</xsl:template>

<xsl:template match="db:mediaobject[@role='flickr']" priority="100">
  <xsl:variable name="uri" select="db:imageobject/@xlink:href"/>
  <xsl:variable name="jpg" select="db:imageobject/db:imagedata/@fileref"/>

<!--
<mediaobject role="flickr">
  <imageobject xlink:href="http://www.flickr.com/photos/ndw/4997854687/">
    <imagedata fileref="http://farm5.static.flickr.com/4087/4997854687_33511f4437.jpg"/>
  </imageobject>
</mediaobject>
-->

  <xsl:variable name="photoId"
		select="substring-before(substring-after($uri,'/photos/ndw/'),
			                 '/')"/>

  <xsl:variable name="photo" as="element()?" select="nwn:get-photo($photoId)"/>

  <xsl:variable name="flickr.width"
		select="$photo/flickr:sizes/flickr:size[@label='Medium']/@width"/>

  <xsl:variable name="width">
    <xsl:choose>
      <xsl:when test="string($flickr.width) = ''">
	<xsl:message>
	  <xsl:text>Failed to get width for photo in flickr.xml: </xsl:text>
	  <xsl:value-of select="$jpg"/>
	</xsl:message>
	<xsl:value-of select="500"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$flickr.width"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="title" select="$photo/flickr:title"/>

  <xsl:variable name="t_geotagged"
		select="$photo/flickr:tags/flickr:tag[@raw='geotagged']"/>
  <xsl:variable name="t_geolat"
		select="$photo/flickr:tags/flickr:tag[starts-with(@raw,'geo:lat=')]"/>
  <xsl:variable name="t_geolong"
		select="$photo/flickr:tags/flickr:tag[starts-with(@raw,'geo:long=')]"/>

  <xsl:variable name="geotagged"
		select="$t_geotagged and $t_geolat and $t_geolong"/>

  <xsl:variable name="geo:lat" as="xs:decimal"
		select="if ($t_geotagged and $t_geolat)
                        then xs:decimal(substring-after($t_geolat/@raw,'='))
                        else 0.0"/>

  <xsl:variable name="geo:long" as="xs:decimal"
		select="if ($t_geotagged and $t_geolong)
                        then xs:decimal(substring-after($t_geolong/@raw,'='))
                        else 0.0"/>

  <div class="artwork">
    <div class="flickr-photo">
      <div class="photo" style="width: {$width}px">
	<a href="{$uri}">
	  <img border="0" alt="[Photo]" src="{$jpg}"/>
	</a>
      </div>

      <xsl:choose>
	<xsl:when test="$geotagged">
	  <div class="link" style="left: {round($width div 2.0) - 40}px;">
	    <a href="http://www.flickr.com/">
	      <img src="/graphics/flickrt.png" border="0" alt="[Flickr]"/>
	    </a>
	    <xsl:text> </xsl:text>
	    <a href="http://maps.google.com/maps?ll={$geo:lat},{$geo:long}&amp;z=16&amp;t=k">
	      <!--iPhotoID={$photoId}&amp;-->
	      <img src="/graphics/map.png" border="0" alt="[Google maps]"/>
	    </a>
	  </div>
	</xsl:when>
	<xsl:otherwise>
	  <div class="link" style="left: {round($width div 2.0) - 25}px;">
	    <a href="http://www.flickr.com/">
	      <img src="/graphics/flickrt.png" border="0" alt="[Flickr]"/>
	    </a>
	  </div>
	</xsl:otherwise>
      </xsl:choose>

      <h3>
	<xsl:value-of select="$title[1]"/>
      </h3>
    </div>
  </div>
</xsl:template>

<xsl:template match="db:mediaobject[@role='youtube']" priority="100">
  <xsl:variable name="uri" select="db:videoobject/db:videodata/@fileref"/>
  <xsl:variable name="width" select="db:videoobject/db:videodata/@width"/>
  <xsl:variable name="height" select="db:videoobject/db:videodata/@depth"/>

  <object width="{$width}" height="{$height}">
    <param name="movie" value="{$uri}"/>
    <embed src="{$uri}" type="application/x-shockwave-flash"
	   width="{$width}" height="{$height}"/>
  </object>
</xsl:template>

<xsl:template match="gal:float">
  <xsl:variable name="path">
    <xsl:choose>
      <xsl:when test="@base">
        <xsl:value-of select="@base"/>
      </xsl:when>
      <xsl:otherwise>images/</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="rsrc" select="@rdf:resource"/>
  <xsl:variable name="float">
    <xsl:choose>
      <xsl:when test="@align"><xsl:value-of select="@align"/></xsl:when>
      <xsl:otherwise>left</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="filename"
		select="substring-after(base-uri(), $rooturisl)"/>

  <xsl:variable name="about"
                select="concat($hostsl, f:file-path($filename), '/', $rsrc)"/>

  <xsl:variable name="basename" select="tokenize($about,'/')[last()]"/>

  <a href="images/{$basename}.html">
    <img align="{$float}" border="0" alt="[Image]">
      <xsl:attribute name="src">
        <xsl:if test="$path = ''">../</xsl:if>
        <xsl:text>thumbs/</xsl:text>
        <xsl:value-of select="$basename"/>
      </xsl:attribute>
    </img>
  </a>
</xsl:template>

<xsl:template match="processing-instruction('include')">
  <xsl:copy/>
</xsl:template>

<xsl:template match="processing-instruction('br')">
  <br />
</xsl:template>

<xsl:template match="processing-instruction('flightmap')">
  <div id="flightmap" class="artwork" style="{.}">
  </div>
</xsl:template>

<xsl:template match="processing-instruction('twitter-pre-nav')
                     |processing-instruction('twitter-post-nav')">
  <xsl:copy/>
</xsl:template>

<xsl:template match="processing-instruction('shortform-stats')">
  <xsl:variable name="conv" select="count(//db:bridgehead)"/>
  <xsl:variable name="mine" select="count(//db:para[@role='mine'])"/>
  <xsl:variable name="favs" select="count(//db:para[@role='favorite'])"/>
  <span class='stats'>
    <xsl:text>This week, </xsl:text>
    <xsl:value-of select="$mine"/>
    <xsl:text> message</xsl:text>
    <xsl:if test="$mine != 1">s</xsl:if>
    <xsl:text> in </xsl:text>
    <xsl:value-of select="$conv"/>
    <xsl:text> conversation</xsl:text>
    <xsl:if test="$conv != 1">s</xsl:if>
    <xsl:text>.</xsl:text>
    <xsl:if test="$favs &gt; 0">
      <xsl:text> (With </xsl:text>
      <xsl:value-of select="$favs"/>
      <xsl:text> favorite</xsl:text>
      <xsl:if test="$favs != 1">s</xsl:if>
      <xsl:text>.)</xsl:text>
    </xsl:if>
  </span>
</xsl:template>

<xsl:template match="processing-instruction('x-html')">
  <xsl:variable name="uri" select="dbf:pi(.,'uri')"/>
  <xsl:variable name="html" select="document($uri,.)"/>
  <xsl:copy-of select="$html"/>
</xsl:template>

<xsl:template match="processing-instruction('subject-feeds')">
  <!-- nop; only produces output in sidebar mode -->
</xsl:template>

<!-- ====================================================================== -->

<xsl:template match="db:tag">
  <xsl:choose>
    <!-- grotesque hack to get around programlisting reformatting over linebreaks -->
    <xsl:when test="starts-with(string(.), ' ')
		    or starts-with(string(.), '&#9;')">
      <xsl:apply-templates/>
    </xsl:when>
    <xsl:when test="not(@class)">
      <xsl:call-template name="format-tag">
        <xsl:with-param name="class" select="'starttag'"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="format-tag"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="db:section">
  <xsl:variable name="firstelem"
                select="(*[not(self::db:info) and not(self::db:title)])[1]"/>

  <!-- Sections that start with an initial para are run-in -->
  <xsl:choose>
    <xsl:when test="$firstelem/self::db:para and not(contains(@role,'no-runin'))">
      <section>
        <xsl:sequence select="dbf:html-attributes(.,dbf:node-id(.))"/>
        <xsl:apply-templates select="*[not(self::db:info) and not(self::db:title)]"/>
      </section>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-imports/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="db:section/db:para[1]" priority="100">
  <xsl:choose>
    <xsl:when test="preceding-sibling::*[1][self::db:info or self::db:title]">
      <h2 class="runin">
	<xsl:value-of select="(preceding-sibling::db:info/db:title|preceding-sibling::db:title)"/>
	<xsl:text>&#160;</xsl:text>
      </h2>
      <p class="runin" id="{@xml:id}">
	<xsl:if test="../@xml:id">
	  <a id="{../@xml:id}"/>
	</xsl:if>
	<xsl:apply-templates/>
      </p>
      <xsl:if test="not(following-sibling::db:para)">
	<p>
	  <xsl:comment> This is just a spacer </xsl:comment>
	</p>
      </xsl:if>
    </xsl:when>
    <xsl:otherwise>
      <xsl:next-match/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--
<xsl:template match="db:epigraph">
  <div class="{local-name(.)}">
    <xsl:apply-templates select="*[not(self::db:attribution)]"/>
    <xsl:if test="db:attribution">
      <div class="attribution">
	<span>—<xsl:apply-templates select="db:attribution"/></span>
      </div>
    </xsl:if>
  </div>
</xsl:template>
-->

<xsl:template match="db:personname">
  <xsl:variable name="pname" as="element()">
    <db:personname>
      <xsl:for-each select="node()">
	<xsl:choose>
	  <xsl:when test=". instance of element() and @role = 'suppress'">
	    <!-- nop -->
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:copy-of select="."/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:for-each>
    </db:personname>
  </xsl:variable>

  <xsl:call-template name="dbt:inline-charseq">
    <xsl:with-param name="content">
      <xsl:call-template name="tmpl:person-name">
	<xsl:with-param name="node" select="$pname"/>
      </xsl:call-template>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template match="db:blockquote[@role='rant']">
  <div class="rant">
    <xsl:if test="@xml:lang">
      <xsl:call-template name="lang-attribute"/>
    </xsl:if>
    <xsl:call-template name="tmpl:id"/>

    <blockquote class="{local-name(.)}">
      <div><b><i>&lt;rant&gt;</i></b></div>
      <xsl:apply-templates/>
      <div><b><i>&lt;/rant&gt;</i></b></div>
    </blockquote>
  </div>
</xsl:template>

<xsl:template match="processing-instruction('nwn-stylesheet')">
  <xsl:processing-instruction name="xml-stylesheet">
    <xsl:value-of select="."/>
  </xsl:processing-instruction>
</xsl:template>

<xsl:template match="db:date">
  <xsl:value-of select="substring(., 9, 2)"/>
  <xsl:text>&#160;</xsl:text>
  <xsl:call-template name="month-name">
    <xsl:with-param name="month" select="xs:decimal(substring(., 6, 2))"/>
  </xsl:call-template>
  <xsl:text>&#160;</xsl:text>
  <xsl:value-of select="substring(., 1, 4)"/>
</xsl:template>

<xsl:template match="db:para[@xlink:actuate='onLoad']" priority="100">
  <div class="artwork" id="{@xml:id}" style="width: 540px; height: 540px;"/>
  <div class="map-messages" id="{@xml:id}_messages"></div>
  <script type="text/javascript" src="{nwn:httpuri(resolve-uri(@xlink:href, base-uri(.)))}"></script>
</xsl:template>

<xsl:template match="db:para[@revisionflag='deleted']">
  <xsl:param name="class" select="''" tunnel="yes"/>

  <p>
    <xsl:call-template name="dbt:id"/>
    <xsl:choose>
      <xsl:when test="$class = ''">
        <xsl:call-template name="class"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="class" select="$class"/>
      </xsl:otherwise>
    </xsl:choose>

    <del>
      <xsl:apply-templates/>
    </del>
  </p>
</xsl:template>

<xsl:template match="db:phrase[@revisionflag='deleted']">
  <del>
    <xsl:apply-templates/>
  </del>
</xsl:template>

<xsl:template match="db:application[@revisionflag='deleted']">
  <del>
    <xsl:apply-imports/>
  </del>
</xsl:template>

<xsl:template match="db:phrase[@role='install']">
  <p class='install'>
    <xsl:call-template name="tmpl:id"/>
    <xsl:apply-templates/>
  </p>
</xsl:template>

<xsl:template match="db:phrase[@role='bubble']">
  <span class="thoughtbubble">
    <tt>.oO(</tt>
    <xsl:apply-templates/>
    <tt>)</tt>
  </span>
</xsl:template>

<xsl:template match="db:phrase[@role='censored']">
  <span class="censored">
    <xsl:apply-templates/>
  </span>
</xsl:template>

<xsl:template match="html:*" priority="200">
  <xsl:element name="{local-name(.)}">
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates/>
  </xsl:element>
</xsl:template>

<!-- ====================================================================== -->

<xsl:template match="db:link">
  <!-- wtf!? -->
  <xsl:variable name="base" select="resolve-uri(base-uri(.), 'http://norman.walsh.name/')"/>

  <xsl:variable name="href"
		select="if (@xlink:href)
			then iri-to-uri(resolve-uri(@xlink:href,$base))
			else ''"/>

  <xsl:variable name="link" as="element(html:a)">
    <xsl:choose>
      <xsl:when test="starts-with($href,$host)">
        <xsl:call-template name="db:link">
          <xsl:with-param name="href" select="$href"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="db:link"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <a>
    <xsl:for-each select="@html:*">
      <xsl:attribute name="{local-name(.)}" select="."/>
    </xsl:for-each>
    <xsl:copy-of select="$link/@*"/>
    <xsl:sequence select="$link/node()"/>
  </a>
</xsl:template>

<xsl:template match="db:productname">
  <span class="productname">
    <xsl:apply-templates/>
  </span>

  <xsl:variable name="linkgroup"
		select="nwn:rdf(xs:QName('rdfs:label'), .,
                                'http://norman.walsh.name/knows/taxonomy#LinkGroup')"/>

  <xsl:if test="$linkgroup">
    <xsl:variable name="link"
		  select="concat('/knows/what/', $linkgroup/rdfs:label)"/>

    <a href="{$link}" title="Links: {$linkgroup/rdfs:label}">
      <img border="0" src="/graphics/linkgroup.gif" alt="[L]"/>
    </a>
  </xsl:if>
</xsl:template>

<xsl:template match="db:wikipedia">
  <xsl:variable name="page"
		select="if (@page) then @page else normalize-space(.)"/>

  <xsl:variable name="t1" select="translate($page,'_',' ')"/>
  <xsl:variable name="t2" select="replace($t1,'%2[cC]',',')"/>
  <xsl:variable name="t3" select="replace($t2,'%28','(')"/>
  <xsl:variable name="t4" select="replace($t3,'%29',')')"/>

  <xsl:variable name="title" select="$t4"/>

  <a href="http://en.wikipedia.org/wiki/{encode-for-uri($page)}"
     title="Wikipedia: {$title}">
    <xsl:apply-templates/>
  </a>

  <xsl:variable name="linkgroup"
		select="nwn:rdf(xs:QName('t:wikipedia'), .,
                                'http://norman.walsh.name/knows/taxonomy#LinkGroup')"/>

  <xsl:choose>
    <xsl:when test="$linkgroup">
      <xsl:variable name="link"
                    select="concat('/knows/what/', $linkgroup/rdfs:label)"/>
      <a href="{$link}">
        <img border="0" src="/graphics/linkgroup.gif" alt="[L]"/>
      </a>
    </xsl:when>
<!-- an interest idea that doesn't quite work...
    <xsl:when test="nwn:subject-mentions($page) &gt; 1">
      <a href="/knows/what/{$page}">
        <img border="0" src="/graphics/linkgroup.gif" alt="[L]"/>
      </a>
    </xsl:when>
-->
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="foaf:name|foaf:nick">
  <xsl:variable name="rdf"
                select="if (self::foaf:name)
                        then nwn:foaf-name(string(.))
                        else nwn:foaf-nick(string(.))"/>

  <xsl:variable name="displayName" as="xs:string?">
    <xsl:choose>
      <xsl:when test="@role = 'fullname'">
	<xsl:value-of select="$rdf/foaf:name"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$rdf/foaf:firstName"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <span class="foafName">
    <xsl:choose>
      <xsl:when test="empty($displayName)">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:when test="$rdf/foaf:weblog">
        <a href="{$rdf/foaf:weblog}">
          <xsl:value-of select="$displayName"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
          <xsl:value-of select="$displayName"/>
      </xsl:otherwise>
    </xsl:choose>
  </span>

  <a href="{substring-after($rdf/@rdf:about, '.name')}">
    <img border="0" alt="[L]" src="/graphics/linkgroup.gif"/>
  </a>
</xsl:template>

<!-- ====================================================================== -->
<!-- Sidebar mode -->

<!-- default is to output *nothing* -->

<xsl:template match="*" mode="sidebar">
  <xsl:apply-templates mode="sidebar"/>
</xsl:template>

<xsl:template match="text()|comment()|processing-instruction()"
	      mode="sidebar"/>

<xsl:template match="processing-instruction('subject-feeds')" priority="10"
	      mode="sidebar">
  <div class="feeds">
    <h3>Subject feeds</h3>
    <ul>
      <xsl:for-each
	  select="key('types','http://norman.walsh.name/knows/taxonomy#Topic',$allrdf)">
	<xsl:sort select="skos:prefLabel" order="ascending"/>
	<xsl:if test="t:feed and skos:broader">
	  <li>
	    <a href="/atom/{t:feed}.xml">
	      <xsl:value-of select="skos:prefLabel"/>
	    </a>
	  </li>
	</xsl:if>
      </xsl:for-each>
    </ul>
  </div>
</xsl:template>

<!-- ====================================================================== -->

<xsl:template match="db:essay" mode="m:title-markup">
  <h1>
    <xsl:apply-templates select="." mode="m:title-content">
      <xsl:with-param name="allow-anchors" select="true()"/>
    </xsl:apply-templates>
  </h1>
</xsl:template>

<xsl:template match="db:essay" mode="m:label-content">
  <xsl:if test="@label">
    <xsl:value-of select="@label"/>
  </xsl:if>
</xsl:template>

<xsl:template xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0"
              name="tmpl:user-localization-data">
  <xsl:variable name="en" select="dbf:load-locale('en')"/>
  <l:l10n>
    <xsl:sequence select="$en/@*"/>
    <xsl:sequence select="$en/*"/>
    <l:context name="title">
      <l:template name="essay" text="%t"/>
    </l:context>
  </l:l10n>
</xsl:template>

<!-- ====================================================================== -->

<xsl:template match="db:foil" mode="dbm:foilnum" as="xs:decimal">
  <xsl:choose>
    <xsl:when test="@foilnum">
      <xsl:value-of select="xs:decimal(@foilnum)"/>
    </xsl:when>
    <xsl:when test="preceding::db:foil">
      <xsl:variable name="pnum" as="xs:decimal">
        <xsl:apply-templates select="preceding::db:foil[1]" mode="dbm:foilnum"/>
      </xsl:variable>
      <xsl:value-of select="$pnum + 1"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="xs:decimal(1)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="db:foil">
  <xsl:variable name="foilnum" as="xs:decimal">
    <xsl:apply-templates select="." mode="dbm:foilnum"/>
  </xsl:variable>

  <div class="{local-name(.)}">
    <xsl:call-template name="dbt:id"/>
    <xsl:call-template name="class"/>

    <h3><xsl:value-of select="db:title"/></h3>

    <div class="foil-content">
      <xsl:apply-templates select="*[not(self::db:info) and not(self::db:title)]"/>
    </div>
    <div class="foilnum">Foil #<xsl:value-of select="$foilnum"/></div>
  </div>
</xsl:template>

<!-- ====================================================================== -->

<xsl:template match="db:itemizedlist[@role='tweets']">
  <div class="tweetlist">
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="db:itemizedlist[@role='tweets']/db:listitem">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="db:itemizedlist[@role='tweets']/db:listitem/db:para">
  <div class="tweet {@role}">
    <xsl:if test="@xml:id">
      <xsl:attribute name="id" select="@xml:id"/>
    </xsl:if>
    <xsl:if test="contains(@role, 'favorite')">
      <div class="favmark"><img src="/graphics/favorite.gif" alt="FAV"/></div>
    </xsl:if>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="db:sidebar[@role='googleplus']">
  <h4 class="bridgehead">
    <xsl:value-of select="db:title"/>
  </h4>

  <div class="tweetlist">
    <div class="tweet mine">
      <xsl:apply-templates select="node() except db:title"/>
    </div>
  </div>
</xsl:template>

<xsl:template match="db:sidebar[@role='googleplus']/db:para">
  <div class="{@role}">
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="db:sidebar[@role='googleplus']/db:para[@role='annotation']">
  <div class="gpannot">
    <em>
      <xsl:apply-templates/>
    </em>
  </div>
</xsl:template>

<xsl:template match="db:sidebar[@role='googleplus']/db:para[@role='location']">
  <div class="{@role}">
    <xsl:text>Location: </xsl:text>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<!-- ====================================================================== -->

<xsl:template match="db:qandaset">
  <ol>
    <xsl:apply-templates/>
  </ol>
</xsl:template>

<xsl:template match="db:qandaentry">
  <li>
    <xsl:apply-templates/>
  </li>
</xsl:template>

<xsl:template match="db:question|db:answer">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="db:question/db:para[1]">
  <b><xsl:apply-templates/></b>
</xsl:template>

<!-- ====================================================================== -->


<xsl:template name="dbt:image-properties" as="xs:integer*">
  <xsl:param name="image" required="yes"/>

  <xsl:variable name="uri" select="nwn:docuri($image)"/>
  <xsl:variable name="width"
                select="if (empty($uri))
                        then (xdmp:log(concat('Failed to find image at ', $image)), 500)
                        else xdmp:document-get-properties($uri, xs:QName('etc:width'))[1]"/>
  <xsl:variable name="height"
                select="if (empty($uri))
                        then 250
                        else xdmp:document-get-properties($uri, xs:QName('etc:height'))[1]"/>

  <xsl:sequence select="($height,$width)"/>
</xsl:template>

</xsl:stylesheet>
