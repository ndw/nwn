<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:c="http://nwalsh.com/rdf/contacts#"
                xmlns:cvs="http://nwalsh.com/rdf/cvs#"
                xmlns:daml="http://www.daml.org/2001/03/daml+oil#"
                xmlns:db="http://docbook.org/ns/docbook"
                xmlns:dbf="http://docbook.org/xslt/ns/extension"
                xmlns:dc='http://purl.org/dc/elements/1.1/'
                xmlns:f="http://nwalsh.com/ns/xslfunctions#"
                xmlns:foaf="http://xmlns.com/foaf/0.1/"
                xmlns:gal='http://norman.walsh.name/rdf/gallery#'
                xmlns:geo='http://www.w3.org/2003/01/geo/wgs84_pos#'
                xmlns:it="http://nwalsh.com/rdf/itinerary#"
                xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:t="http://norman.walsh.name/knows/taxonomy#"
		xmlns:up="http://nwalsh.com/rdf/upcoming.org#"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:atom="http://www.w3.org/2005/Atom"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:nwn="http://norman.walsh.name/ns/modules/utils"
                exclude-result-prefixes="db dbf h f foaf it c cvs daml dc gal geo
                                         rdf rdfs t up xs atom nwn xdmp"
                version="2.0">

<xsl:include href="cal2html.xsl"/>

<xdmp:import-module namespace="http://norman.walsh.name/ns/modules/utils"
                    href="/nwn.xqy"/>

<rdf:Description rdf:about=''>
  <rdf:type rdf:resource="http://norman.walsh.name/knows/taxonomy#XSL"/>
  <dc:type rdf:resource='http://purl.org/dc/dcmitype/Text'/>
  <dc:format>application/xsl+xml</dc:format>
  <dc:title>Itinerary Stylesheet</dc:title>
  <dc:date>2003-12-23</dc:date>
  <cvs:date>$Date$</cvs:date>
  <dc:creator rdf:resource='http://norman.walsh.name/knows/who#norman-walsh'/>
  <dc:rights>Copyright &#169; 2003 Norman Walsh. All rights reserved.</dc:rights>
  <dc:description>Handle itineraries.</dc:description>
</rdf:Description>

<xsl:variable name="GMT" select="xs:dayTimeDuration('PT0H')"/>

<!-- ====================================================================== -->
<!-- calendars -->

<xsl:template match="processing-instruction('year-calendar')">
  <xsl:call-template name="calendar-year">
    <xsl:with-param name="year"
		    select="xs:decimal(dbf:pi(.,'year'))"/>
    <xsl:with-param name="wholeyear" select="true()"/>
    <xsl:with-param name="highlights"
		    select="..//processing-instruction('calhighlight')"/>
  </xsl:call-template>
</xsl:template>

<xsl:template match="processing-instruction('upcoming-calendar')">
  <xsl:call-template name="calendar-year">
    <xsl:with-param name="year"
		    select="xs:decimal(dbf:pi(.,'year'))"/>
    <xsl:with-param name="highlights"
		    select="..//processing-instruction('calhighlight')"/>
  </xsl:call-template>
</xsl:template>

<xsl:template match="processing-instruction('calendar')">
  <xsl:call-template name="calendar">
    <xsl:with-param name="month" select="dbf:pi(.,'month')"/>
    <xsl:with-param name="start"
		    select="xs:decimal(dbf:pi(.,'highlight-start'))"/>
    <xsl:with-param name="end"
		    select="xs:decimal(dbf:pi(.,'highlight-end'))"/>
  </xsl:call-template>
</xsl:template>

<!-- ====================================================================== -->
<!-- itineraries -->

<xsl:template match="it:trip">
  <!-- do nothing for an empty trip -->
</xsl:template>

<xsl:template match="it:trip[*]" priority="100">
  <xsl:variable name="upcoming"
		select="document(concat($root,'/atom/upcoming.rss'))"/>

  <xsl:variable name="dopplr"
		select="document(concat($root,'/atom/dopplr.xml'))"/>

  <div class="itinerary">
    <div class="calendar">
      <xsl:choose>
        <xsl:when test="substring(@startDate,1,7) != substring(@endDate,1,7)">
          <table id="itincal" border="0" cellpadding="0" cellspacing="0" summary="Calendar" class="calendar">
            <tr>
              <td valign="top">
                <xsl:call-template name="calendar">
                  <xsl:with-param name="month" select="substring(@startDate,1,7)"/>
                  <xsl:with-param name="start"
                                  select="xs:decimal(substring(@startDate,9,2))"/>
                  <xsl:with-param name="end" select="32"/>
                </xsl:call-template>
              </td>
              <td>&#160;&#160;&#160;</td>
              <td valign="top">
                <xsl:call-template name="calendar">
                  <xsl:with-param name="month" select="substring(@endDate,1,7)"/>
                  <xsl:with-param name="start" select="1"/>
                  <xsl:with-param name="end"
                                  select="xs:decimal(substring(@endDate,9,2))"/>
                </xsl:call-template>
              </td>
            </tr>
          </table>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="calendar">
            <xsl:with-param name="month" select="substring(@startDate,1,7)"/>
            <xsl:with-param name="start"
                            select="xs:decimal(substring(@startDate,9,2))"/>
            <xsl:with-param name="end"
                            select="xs:decimal(substring(@endDate,9,2))"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </div>

    <xsl:apply-templates/>

    <xsl:variable name="mappoints"
	  select="it:itinerary/it:leg[@class='flight'][it:arrive and it:depart]
		  |it:itinerary/it:leg[@class='train'][it:arrive and it:depart]"/>

    <xsl:if test="$mappoints">
      <div id="routemap" class="itingrp">
        <p class="bigtitle">Map:</p>
        <div class="artwork" id="flightmap" style="width: 640px; height: 480px;">
        </div>
        <xsl:sequence select="nwn:flight-map(.)"/>
      </div>
    </xsl:if>
  </div>
</xsl:template>

<xsl:function name="f:idKey">
  <xsl:param name="about"/>

  <xsl:value-of
      select="translate(substring-after($about, '#'),'-.','__')"/>
</xsl:function>

<xsl:template match="it:itinerary">
  <div id="grpitinerary" class="itingrp">
    <p class="bigtitle">Itinerary:</p>
    <table border="0" summary="Itinerary" class="itinerary">
      <xsl:apply-templates/>

      <xsl:if test="it:leg/it:duration or it:leg/it:distance">
        <tr>
          <td>&#160;</td>
          <td>&#160;</td>
          <td>&#160;</td>
          <td>&#160;</td>
          <td align="right">
            <xsl:text>&#160;</xsl:text>
            <xsl:if test="it:leg/it:duration">
              <xsl:variable name="durs" as="xs:dayTimeDuration*">
                <xsl:for-each select="it:leg/it:duration">
                  <xsl:value-of select="xs:dayTimeDuration(.)"/>
                </xsl:for-each>
              </xsl:variable>
              <xsl:variable name="dur" select="sum($durs)"/>
              <xsl:variable name="d" select="days-from-duration($dur)"/>
              <xsl:variable name="h" select="hours-from-duration($dur)"/>
              <xsl:variable name="m" select="minutes-from-duration($dur)"/>

              <xsl:if test="$d &gt; 0">
                <xsl:value-of select="$d"/>
                <xsl:text>d</xsl:text>
              </xsl:if>

              <xsl:value-of select="$h"/>
              <xsl:text>h</xsl:text>
              <xsl:if test="$m &lt; 10">0</xsl:if>
              <xsl:value-of select="$m"/>
              <xsl:text>m</xsl:text>
            </xsl:if>
          </td>
          <td>&#160;</td>
          <td>
            <xsl:if test="it:leg/it:distance">
              <xsl:text>(≈</xsl:text>
              <xsl:value-of select="sum(it:leg/it:distance)"/>
              <xsl:value-of select="(it:leg/it:distance)[1]/@units"/>
              <xsl:text>)</xsl:text>
              <xsl:text>&#160;</xsl:text>
            </xsl:if>
          </td>
        </tr>
      </xsl:if>
    </table>
  </div>
</xsl:template>

<xsl:template match="it:leg">
  <xsl:variable name="forecast" select="nwn:forecast(it:arrive)"/>

  <tr class="vevent">
    <td valign="top">
      <xsl:call-template name="it:date">
	<xsl:with-param name="hcal" select="1"/>
      </xsl:call-template>
    </td>
    <td valign="top" align="right">
      <xsl:apply-templates select="it:startDate">
	<xsl:with-param name="hcal" select="1"/>
      </xsl:apply-templates>
    </td>
    <td valign="top">–</td>
    <td valign="top">
      <xsl:apply-templates select="it:endDate">
	<xsl:with-param name="hcal" select="1"/>
      </xsl:apply-templates>
    </td>

    <td align="right">
      <xsl:apply-templates select="it:duration"/>
    </td>

    <td valign="top">
      <xsl:call-template name="it:icon"/>
    </td>
    <td valign="top">
      <span class="summary">
	<xsl:value-of select="it:description"/>
      </span>
      <xsl:apply-templates select="it:distance"/>
      <xsl:sequence select="$forecast"/>
    </td>
  </tr>
</xsl:template>

<xsl:template match="it:duration">
  <xsl:variable name="dur" select="xs:duration(.)"/>
  <xsl:variable name="h" select="hours-from-duration($dur)"/>
  <xsl:variable name="m" select="minutes-from-duration($dur)"/>

  <xsl:value-of select="$h"/>
  <xsl:text>h</xsl:text>
  <xsl:if test="$m &lt; 10">0</xsl:if>
  <xsl:value-of select="$m"/>
  <xsl:text>m</xsl:text>
</xsl:template>

<xsl:template match="it:distance">
  <xsl:text> (≈</xsl:text>
  <xsl:value-of select="."/>
  <xsl:value-of select="@units"/>
  <xsl:text>) </xsl:text>
</xsl:template>

<xsl:template match="it:seealso">
  <div id="grpseealso" class="itingrp">
    <p class="bigtitle">See also:</p>
    <dl>
      <dt>
        <a href="overview">Other itineraries</a>
      </dt>
      <xsl:apply-templates select="it:see[@ref]">
        <xsl:sort data-type="text" select="."/>
      </xsl:apply-templates>
    </dl>
  </div>
</xsl:template>

<xsl:template match="it:see">
  <dt>
    <xsl:choose>
      <xsl:when test="@ref">
	<a href="http://norman.walsh.name/knows/where/{substring-after(@ref,'#')}">
	  <xsl:value-of select="."/>
	</a>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="@iata">
      <xsl:text> (</xsl:text>
      <xsl:value-of select="@iata"/>
      <xsl:text>)</xsl:text>
    </xsl:if>
  </dt>
</xsl:template>

<xsl:template match="it:lodging">
  <div id="grplodging" class="itingrp">
    <p class="bigtitle">Lodging:</p>
    <table border="0" summary="Lodging" class="lodging">
      <xsl:apply-templates>
        <xsl:sort select="it:startDate" order="ascending"/>
      </xsl:apply-templates>
    </table>
  </div>
</xsl:template>

<xsl:template match="it:stay">
  <tr>
    <td valign="top">
      <xsl:call-template name="it:date"/>
    </td>
    <td valign="top">
      <xsl:choose>
	<xsl:when test="@ref">
	  <a href="http://norman.walsh.name/knows/where/{substring-after(@ref,'#')}">
	    <xsl:value-of select="it:description"/>
	  </a>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="it:description"/>
	</xsl:otherwise>
      </xsl:choose>

      <xsl:for-each select="it:phone">
	<br/>
	<xsl:value-of select="."/>
      </xsl:for-each>

      <xsl:if test="it:location">
	<br/>
	<xsl:value-of select="it:location"/>
	<xsl:if test="it:address">
	  <xsl:text> (</xsl:text>
	  <a href="http://maps.google.com/maps?f=q&amp;hl=en&amp;q={encode-for-uri(it:address)}&amp;btnG=Search">map</a>
	  <xsl:text>)</xsl:text>
	</xsl:if>
      </xsl:if>
    </td>
  </tr>
</xsl:template>

<xsl:template match="it:rentalcars">
  <div id="grprentalcar" class="itingrp">
    <p class="bigtitle">Rental:</p>
    <table border="0" summary="Rental cars" class="rentalcars">
      <xsl:apply-templates/>
    </table>
  </div>
</xsl:template>

<xsl:template match="it:car">
  <tr>
    <td valign="top">
      <xsl:call-template name="it:date"/>
    </td>
    <td valign="top">
      <xsl:choose>
	<xsl:when test="@ref">
	  <a href="http://norman.walsh.name/knows/where/{substring-after(@ref,'#')}">
	    <xsl:value-of select="it:description"/>
	  </a>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="it:description"/>
	</xsl:otherwise>
      </xsl:choose>

      <xsl:for-each select="it:phone">
	<br/>
	<xsl:value-of select="."/>
      </xsl:for-each>

      <xsl:if test="it:location">
	<br/>
	<xsl:value-of select="it:location"/>
      </xsl:if>
    </td>
  </tr>
</xsl:template>

<xsl:template match="it:appointments">
  <div id="grpappt" class="itingrp">
    <p class="bigtitle">Appointments:</p>
    <table border="0" summary="Appointments" class="appointments">
      <xsl:apply-templates/>
    </table>
  </div>
</xsl:template>

<xsl:template match="it:appointment">
  <xsl:variable name="this" select="."/>

  <!-- check for overlapping appointments -->
  <xsl:variable name="overlapping" as="element()*">
    <xsl:for-each select="../it:appointment[@type != 'all-day']">
      <xsl:if test=". != $this">
	<xsl:variable name="ts"
		      select="if (string-length($this/it:startDate) &gt; 10)
			      then xs:dateTime($this/it:startDate)
			      else xs:dateTime(concat($this/it:startDate,'T000000Z'))"/>
	<xsl:variable name="te"
		      select="if (string-length($this/it:endDate) &gt; 10)
			      then xs:dateTime($this/it:endDate)
			      else xs:dateTime(concat($this/it:endDate,'T235959Z'))"/>
	<xsl:variable name="ds"
		      select="if (string-length(it:startDate) &gt; 10)
			      then xs:dateTime(it:startDate)
			      else xs:dateTime(concat(it:startDate,'T000000Z'))"/>
	<xsl:variable name="de"
		      select="if (string-length(it:endDate) &gt; 10)
			      then xs:dateTime(it:endDate)
			      else xs:dateTime(concat(it:endDate,'T235959Z'))"/>

	<!--
	<xsl:message>compare:</xsl:message>
	<xsl:message>
	  <xsl:value-of select="$this/it:description"/>
	  <xsl:text>: </xsl:text>
	  <xsl:value-of select="$ts"/>, <xsl:value-of select="$te"/>
	</xsl:message>
	<xsl:message>
	  <xsl:value-of select="it:description"/>
	  <xsl:text>: </xsl:text>
	  <xsl:value-of select="$ds"/>, <xsl:value-of select="$de"/>
	</xsl:message>
	-->

	<xsl:if test="($ts &gt;= $ds and $ts &lt;= $de)
	              or ($te &gt;= $ds and $te &lt;= $de)">
	  <!--
	  <xsl:message>overlap</xsl:message>
	  -->
	  <!--
	  <xsl:message>overlap: <xsl:value-of select="$this/it:description"/>; <xsl:value-of select="it:description"/></xsl:message>
	  -->
	  <xsl:sequence select="."/>
	</xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:variable>

  <tr class="vevent">
    <xsl:if test="@id">
      <xsl:attribute name="id">
	<xsl:value-of select="@id"/>
      </xsl:attribute>
    </xsl:if>

    <xsl:if test="count($overlapping) &gt; 1">
      <xsl:attribute name="class">
	<xsl:text>conflict</xsl:text>
      </xsl:attribute>
    </xsl:if>

    <td valign="top">
      <xsl:call-template name="it:date">
	<xsl:with-param name="hcal" select="1"/>
      </xsl:call-template>
    </td>
    <td valign="top">
      <xsl:choose>
	<xsl:when test="@type = 'all-day'">&#160;</xsl:when>
	<xsl:otherwise>
	  <xsl:call-template name="it:time">
	    <xsl:with-param name="hcal" select="1"/>
	  </xsl:call-template>
	</xsl:otherwise>
      </xsl:choose>
    </td>
    <td valign="top">
      <xsl:call-template name="it:icon"/>
    </td>
    <td valign="top">
      <xsl:if test="@upcoming.org">
	<span class="upcoming">
	  <a href="http://upcoming.org/event/{@upcoming.org}/">
	    <img align="bottom" src="/graphics/upcoming.png" border="0" alt="Upcoming.org"/>
	  </a>
	  <xsl:text> </xsl:text>
	</span>
      </xsl:if>

      <xsl:if test="it:map">
	<span class="map">
	  <a href="{it:map/@href}">
	    <img align="bottom" src="/graphics/map.png" border="0" alt="Map"/>
	  </a>
	  <xsl:text> </xsl:text>
	</span>
      </xsl:if>

      <xsl:choose>
	<xsl:when test="it:uri">
	  <a href="{it:uri[1]}" class="url summary">
	    <xsl:value-of select="it:description"/>
	  </a>
	</xsl:when>
	<xsl:otherwise>
	  <span class="summary">
	    <xsl:value-of select="it:description"/>
	  </span>
	</xsl:otherwise>
      </xsl:choose>
    </td>
  </tr>

  <xsl:apply-templates select="it:location|it:place"/>
</xsl:template>

<xsl:template match="it:place">
  <tr>
    <td colspan="3">&#160;</td>
    <td>
      <xsl:value-of select="it:name"/>
      <br/>
      <xsl:value-of select="it:address"/>
      <xsl:for-each select="it:phone">
        <br/>
        <xsl:value-of select="."/>
      </xsl:for-each>
    </td>
  </tr>
</xsl:template>

<xsl:template match="it:location">
  <tr>
    <td colspan="3">&#160;</td>
    <td valign="top">
      <xsl:value-of select="."/>
    </td>
  </tr>
</xsl:template>

<!-- ============================================================ -->

<xsl:template name="it:date">
  <xsl:param name="hcal" select="0"/>

  <xsl:variable name="startDate"
		select="if (contains(it:startDate,'T'))
                        then substring-before(it:startDate,'T')
			else it:startDate"/>

  <xsl:variable name="endDate"
		select="if (contains(it:endDate,'T'))
                        then substring-before(it:endDate,'T')
			else it:endDate"/>

  <xsl:variable name="displayStart"
		select="format-date(xs:date($startDate),
                                    '[D01]&#160;[MNn,*-3]')"/>

  <xsl:variable name="displayEnd"
		select="format-date(xs:date($endDate),
                                    '[D01]&#160;[MNn,*-3]')"/>

  <span class="daterange" style="white-space: nowrap;">
    <xsl:choose>
      <xsl:when test="$hcal != 0 and @type = 'all-day'">
        <abbr class="dtstart" title="{it:startDate}">
          <xsl:copy-of select="$displayStart"/>
        </abbr>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$displayStart"/>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="$startDate != $endDate">
      <xsl:text>–</xsl:text>
      <xsl:choose>
        <xsl:when test="$hcal != 0 and @type = 'all-day'">
          <abbr class="dtend" title="{it:endDate}">
            <xsl:copy-of select="$displayEnd"/>
          </abbr>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="$displayEnd"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </span>
</xsl:template>

<xsl:template name="it:time">
  <xsl:param name="hcal" select="0"/>

  <span class="timerange" style="white-space: nowrap;">
    <xsl:apply-templates select="it:startDate">
      <xsl:with-param name="hcal" select="$hcal"/>
    </xsl:apply-templates>
    <xsl:text>–</xsl:text>
    <xsl:apply-templates select="it:endDate">
      <xsl:with-param name="hcal" select="$hcal"/>
    </xsl:apply-templates>
  </span>
</xsl:template>

<xsl:template match="it:startDate">
  <xsl:param name="hcal" select="0"/>

  <xsl:variable name="sofsx"
                select="if (../it:startOffset)
                        then $GMT - xs:dayTimeDuration(string(../it:startOffset))
                        else timezone-from-dateTime(xs:dateTime(.))"/>

  <xsl:variable name="sofs" as="xs:dayTimeDuration"
                select="if (empty($sofsx))
                        then $GMT
                        else $sofsx"/>

<!--
  <xsl:message>
    <xsl:value-of select="concat(., ' :: ', $sofs)"/>
  </xsl:message>
-->

  <xsl:choose>
    <xsl:when test="$hcal != 0">
      <abbr class="dtstart" title="{.}">
	<xsl:value-of select="format-dateTime(adjust-dateTime-to-timezone(
                                                xs:dateTime(.), $sofs),
	                                      '[h01]:[m01][Pn,*-1]')"/>
      </abbr>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="format-dateTime(adjust-dateTime-to-timezone(
                                                xs:dateTime(.), $sofs),
	                                    '[h01]:[m01][Pn,*-1]')"/>
    </xsl:otherwise>
  </xsl:choose>

  <xsl:if test="../it:startTZ">
    <abbr class="tz">
      <xsl:text>&#160;</xsl:text>
      <xsl:value-of select="../it:startTZ"/>
    </abbr>
  </xsl:if>
</xsl:template>

<xsl:template match="it:endDate">
  <xsl:param name="hcal" select="0"/>

  <xsl:variable name="eofsx"
                select="if (../it:endOffset)
                        then $GMT - xs:dayTimeDuration(string(../it:endOffset))
                        else timezone-from-dateTime(xs:dateTime(.))"/>

  <xsl:variable name="eofs" as="xs:dayTimeDuration"
                select="if (empty($eofsx))
                        then $GMT
                        else $eofsx"/>

  <xsl:choose>
    <xsl:when test="$hcal != 0">
      <abbr class="dtend" title="{.}">
	<xsl:value-of select="format-dateTime(adjust-dateTime-to-timezone(
                                                xs:dateTime(.), $eofs),
			                      '[h01]:[m01][Pn,*-1]')"/>
      </abbr>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="format-dateTime(adjust-dateTime-to-timezone(
                                                xs:dateTime(.), $eofs),
			                    '[h01]:[m01][Pn,*-1]')"/>
    </xsl:otherwise>
  </xsl:choose>

  <xsl:if test="../it:endTZ">
    <abbr class="tz">
      <xsl:text>&#160;</xsl:text>
      <xsl:value-of select="../it:endTZ"/>
    </abbr>
  </xsl:if>
</xsl:template>

<xsl:template name="it:icon">
  <xsl:param name="class" select="string(@class)"/>

  <img alt="[I]">
    <xsl:attribute name="src">
      <xsl:text>/graphics/icons/</xsl:text>
      <xsl:choose>
	<xsl:when test="$class = 'holiday'">204</xsl:when>
	<xsl:when test="$class = 'wgmeeting'">44</xsl:when>
	<xsl:when test="$class = 'telcon'">79</xsl:when>
	<xsl:when test="$class = 'vacation'">61</xsl:when>
	<xsl:when test="$class = 'birthday'">7</xsl:when>
	<xsl:when test="$class = 'anniversary'">8</xsl:when>
	<xsl:when test="$class = 'travel'">106</xsl:when>
	<xsl:when test="$class = 'lodging'">106</xsl:when>
	<xsl:when test="$class = 'speaking'">41</xsl:when>
	<xsl:when test="$class = 'presentation'">333</xsl:when>
	<xsl:when test="$class = 'conference'">162</xsl:when>
	<xsl:when test="$class = 'flight'">14</xsl:when>
	<xsl:when test="$class = 'rentcar'">18</xsl:when>
	<xsl:when test="$class = 'drive'">18</xsl:when>
	<xsl:when test="$class = 'train'">17</xsl:when>
	<xsl:when test="$class = 'bus'">16</xsl:when>
	<xsl:when test="$class = 'dinner'">74</xsl:when>
	<xsl:when test="$class = 'drinks'">72</xsl:when>
	<xsl:when test="$class = 'reception'">72</xsl:when>
	<!-- Should I handle this case better? -->
	<xsl:when test="$class = ''">1</xsl:when>
	<xsl:otherwise>
	  <xsl:text>1</xsl:text>
	  <xsl:message>
	    <xsl:text>Unrecognized icon class: "</xsl:text>
	    <xsl:value-of select="$class"/>
	    <xsl:text>"</xsl:text>
	  </xsl:message>
	</xsl:otherwise>
      </xsl:choose>
      <xsl:text>.gif</xsl:text>
    </xsl:attribute>
  </img>
</xsl:template>

<!-- ====================================================================== -->
<!-- summaries -->

<xsl:template match="processing-instruction('trip-summary')">
  <xsl:variable name="tripname" select="dbf:pi(.,'trip')"/>

  <xsl:variable name="fakebase" select="concat('file:', base-uri())"/>
  <xsl:variable name="fakeresolved" select="resolve-uri($tripname, $fakebase)"/>
  <xsl:variable name="resolved" select="substring-after($fakeresolved, 'file:')"/>

  <xsl:variable name="fileuri" select="concat(nwn:docuri($resolved), '.xml')"/>

  <xsl:variable name="tripdoc" select="document($fileuri)"/>

  <xsl:variable name="trip" select="$tripdoc/db:essay/it:trip"/>
  <xsl:variable name="info" select="$tripdoc/db:essay/db:info"/>

  <xsl:variable name="start" select="$trip/@startDate"/>
  <xsl:variable name="end" select="$trip/@endDate"/>

  <xsl:variable name="status" select="$info/db:bibliomisc[@role='status']"/>
  <xsl:variable name="sclass" select="if ($status = 'Not going' or $status = 'Cancelled')
                                      then ' notgoing' else ''"/>

  <span class="vevent{$sclass}">
    <xsl:choose>
      <xsl:when test="substring($start,1,7) = substring($end,1,7)">
	<abbr class="dtstart" title="{substring($start,1,10)}">
	  <xsl:value-of
	      select="format-date(xs:date(substring($start,1,10)),'[D01]')"/>
	</abbr>
	<xsl:text>–</xsl:text>
	<abbr class="dtend" title="{substring($end,1,10)}">
	  <xsl:value-of
	      select="format-date(xs:date(substring($end,1,10)),'[D01]')"/>
	</abbr>
	<xsl:text>&#160;</xsl:text>
	<xsl:value-of
	    select="format-date(xs:date(substring($start,1,10)),'[MNn,*-3]')"/>
	<xsl:text>, </xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<abbr class="dtstart" title="{substring($start,1,10)}">
	  <xsl:value-of
	      select="format-date(xs:date(substring($start,1,10)),
                                      '[D01]&#160;[MNn,*-3]')"/>
	</abbr>
	<xsl:text>–</xsl:text>
	<abbr class="dtend" title="{substring($end,1,10)}">
	  <xsl:value-of
	      select="format-date(xs:date(substring($end,1,10)),
                                      '[D01]&#160;[MNn,*-3]')"/>
	</abbr>
	<xsl:text>, </xsl:text>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:variable name="fakebase" select="concat('file:', base-uri())"/>
    <xsl:variable name="fakeresolved" select="resolve-uri($tripname, $fakebase)"/>
    <xsl:variable name="resolved" select="substring-after($fakeresolved, 'file:')"/>

    <a class="url" href="{nwn:httpuri($resolved)}">
      <span class="summary">
	<xsl:choose>
	  <xsl:when test="contains($info/db:title, ',')">
	    <xsl:value-of select="substring-before($info/db:title, ',')"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="$info/db:title"/>
	  </xsl:otherwise>
	</xsl:choose>
      </span>
    </a>

    <xsl:text>, </xsl:text>

    <!-- Find the name of the place from our RDF store -->
    <xsl:for-each
	select="$info/dc:coverage[contains(@rdf:resource,'knows/where/')]
		/@rdf:resource">

      <xsl:variable name="fixedURI"
		    select="translate(.,'#','/')"/>

      <xsl:variable name="whereRsrc"
                    select="doc(nwn:docuri(concat('/etc/',substring-after($fixedURI,'.name/'),'.rdf')))/rdf:Description"/>

      <xsl:variable name="where" select="$whereRsrc/c:associatedTitle"/>

      <xsl:choose>
	<xsl:when test="count($where) = 0">
	  <xsl:message>
	    <xsl:text>No data for resource: </xsl:text>
	    <xsl:value-of select="."/>
	  </xsl:message>
	  <xsl:text>??where???</xsl:text>
	</xsl:when>
	<xsl:otherwise>
	  <span class="location">
	    <xsl:value-of select="$where[1]"/>
	  </span>
	</xsl:otherwise>
      </xsl:choose>

      <xsl:if test="position() &lt; last() and last() &gt; 2">
	<xsl:text>, </xsl:text>
      </xsl:if>

      <xsl:if test="position()+1 = last()">
	<xsl:text> and </xsl:text>
      </xsl:if>

      <xsl:if test="position() = last()">
	<xsl:text>. </xsl:text>
      </xsl:if>
    </xsl:for-each>

    <xsl:if test="$status and
                  (not(ancestor::db:itemizedlist[@role='history'])
		   or ($status != 'Booked' and $status != 'Completed'))">
      <xsl:text>(</xsl:text>
      <xsl:value-of select="$info/db:bibliomisc[@role='status']"/>
      <xsl:text>.)</xsl:text>
    </xsl:if>
  </span>
</xsl:template>

</xsl:stylesheet>
