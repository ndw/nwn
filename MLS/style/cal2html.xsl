<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:cal="http://nwalsh.com/ns/xslfunctions/calendar#"
		xmlns:cvs="http://nwalsh.com/rdf/cvs#"
		xmlns:dbf="http://docbook.org/xslt/ns/extension"
		xmlns:dc='http://purl.org/dc/elements/1.1/'
		xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="cal cvs dbf dc rdf rdfs xs"
		version="2.0">

<rdf:Description rdf:about=''>
  <rdf:type rdf:resource="http://norman.walsh.name/knows/taxonomy#XSL"/>
  <dc:type rdf:resource='http://purl.org/dc/dcmitype/Text'/>
  <dc:format>application/xsl+xml</dc:format>
  <dc:title>Calendar Stylesheet</dc:title>
  <dc:date>2005-12-28</dc:date>
  <cvs:date>$Date: 2005-04-29 07:33:10 -0400 (Fri, 29 Apr 2005) $</cvs:date>
  <dc:creator rdf:resource='http://norman.walsh.name/knows/who#norman-walsh'/>
  <dc:rights>Copyright &#169; 2003 Norman Walsh. All rights reserved.</dc:rights>
  <dc:description>Creates a small calendar for a given month.</dc:description>
</rdf:Description>

<xsl:template name="calendar-year">
  <xsl:param name="year" select="2004" as="xs:decimal"/>
  <xsl:param name="wholeyear" select="false()"/>
  <xsl:param name="highlights"/>

  <!-- if wholeyear is true, prints 12 months; otherwise prints a three -->
  <!-- month window centered on the current month -->

  <xsl:choose>
    <xsl:when test="$wholeyear">
      <table class="yearcalendar" cellspacing="0" cellpadding="1"
	     summary="Calendar">
	<xsl:for-each select="(0, 1, 2, 3)">
	  <xsl:variable name="rowcount" select="."/>
	  <tr>
	    <xsl:for-each select="(1, 2, 3)">
	      <xsl:variable name="colcount" select="."/>
	      <xsl:variable name="month" select="$rowcount*3 + $colcount"/>

	      <td valign="top" class="yearmonth">
		<xsl:call-template name="calendar">
		  <xsl:with-param name="month"
				  select="concat(string($year), '-',
					         format-number($month,'00'))"/>
		  <xsl:with-param name="ranges">
		    <xsl:call-template name="find-ranges">
		      <xsl:with-param name="month" select="$month"/>
		      <xsl:with-param name="pis" select="$highlights"/>
		    </xsl:call-template>
		  </xsl:with-param>
		</xsl:call-template>
	      </td>
	    </xsl:for-each>
	  </tr>
	</xsl:for-each>
      </table>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="P1M" select="xs:yearMonthDuration('P1M')"/>
      <!--
      <xsl:variable name="lastmonth" select="current-date()-$P1M"/>
      <xsl:variable name="thismonth" select="current-date()"/>
      <xsl:variable name="nextmonth" select="current-date()+$P1M"/>
      -->
      <xsl:variable name="thismonth" select="current-date()"/>
      <xsl:variable name="nextmonth" select="current-date()+$P1M"/>
      <xsl:variable name="nextnextmonth" select="current-date()+$P1M+$P1M"/>

      <table class="yearcalendar" cellspacing="0" cellpadding="1"
	     summary="Calendar">
	<tr>
	  <xsl:for-each
	      select="(substring(string($thismonth), 1, 7),
	               substring(string($nextmonth), 1, 7),
		       substring(string($nextnextmonth), 1, 7))">
	    <td valign="top" class="yearmonth">
	      <xsl:call-template name="calendar">
		<xsl:with-param name="month" select="."/>
		<xsl:with-param name="ranges">
		  <xsl:call-template name="find-ranges">
		    <xsl:with-param name="month"
				    select="xs:decimal(substring(.,6,2))"/>
		    <xsl:with-param name="pis" select="$highlights"/>
		  </xsl:call-template>
		</xsl:with-param>
	      </xsl:call-template>
	    </td>
	  </xsl:for-each>
	</tr>
      </table>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="find-ranges">
  <xsl:param name="month" select="0" as="xs:decimal"/>
  <xsl:param name="pis"/>

  <!--
  <xsl:message>
    <xsl:text>Find ranges for </xsl:text>
    <xsl:value-of select="$month"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="count($pis)"/>
  </xsl:message>
  -->

  <xsl:variable name="ranges">
    <xsl:for-each select="$pis">
      <xsl:variable name="hmonth" select="dbf:pi(., 'month')"/>
      <xsl:variable name="highlight" select="dbf:pi(., 'highlight')"/>

    <!--
    <xsl:message>
      <xsl:text>  Month: </xsl:text>
      <xsl:value-of select="$hmonth"/>
      <xsl:text>: </xsl:text>
      <xsl:value-of select="$highlight"/>
    </xsl:message>
    -->

      <xsl:if test="$month = xs:decimal($hmonth)">
        <xsl:value-of select="$highlight"/>
      </xsl:if>
    </xsl:for-each>
  </xsl:variable>

  <xsl:value-of select="string-join($ranges, ';')"/>
</xsl:template>

<xsl:template name="calendar">
  <xsl:param name="month" select="'2004-01'"/>
  <xsl:param name="start" select="0" as="xs:decimal"/>
  <xsl:param name="end" select="0" as="xs:decimal"/>
  <xsl:param name="ranges" select="''"/>

  <!--
  <xsl:message>Calendar for <xsl:value-of select="$month"/>; <xsl:value-of select="$start"/>; <xsl:value-of select="$end"/></xsl:message>
  -->

  <xsl:variable name="date" select="xs:date(concat($month,'-01'))"/>
  <xsl:variable name="last" select="$date
                                    + xs:yearMonthDuration('P1M')
                                    - xs:dayTimeDuration('P1D')"/>

  <xsl:variable name="monthDays" select="day-from-date($last)"/>

  <!--
  <xsl:message>date: <xsl:value-of select="$date"/></xsl:message>
  -->

  <!-- [Fo]: 1=monday, 2=tuesday, ... 6=saturday, 7=sunday -->
  <!-- [Fo] mod 7: 0=sunday, 1=monday, ... 5=friday, 6=saturday -->
  <!--
  <xsl:variable name="firstDay"
		select="xs:decimal(format-date($date,'[F1]','en',(),'us'))
			mod 7"/>
  -->

  <!-- MARKLOGIC XSLT BUG 12150
       [Fo]: 1=sunday, 2=monday, ... 6=friday, 7=saturday
       [Fo] mod 7: 1=sunday, 2=monday, ... 6=friday, 0=saturday -->
  <xsl:variable name="firstDayBug"
		select="xs:decimal(format-date($date,'[F1]','en',(),'us'))
			mod 7"/>
  <xsl:variable name="firstDay" select="if ($firstDayBug=0) then 6 else $firstDayBug - 1"/>

  <!--
  <xsl:message>firstday: <xsl:value-of select="$firstDay"/></xsl:message>
  -->

  <xsl:variable name="sunday" select="0 - $firstDay + 1"/>

  <!--
  <xsl:message>sunday: <xsl:value-of select="$sunday"/></xsl:message>
  -->

  <table class="calendar" cellspacing="0" cellpadding="1"
	 summary="{format-date($date, '[MNn], [Y0001]')} Calendar">
    <tr class="title">
      <td colspan="5" align="left" class="calmonth">
	<xsl:value-of select="format-date($date, '[MNn]')"/>
      </td>
      <td colspan="2" align="right" class="calyear">
	<xsl:value-of select="format-date($date, '[Y0001]')"/>
      </td>
    </tr>
    <tr class="dow" align="right">
      <td class="sun">Su</td>
      <td class="mon">Mo</td>
      <td class="tue">Tu</td>
      <td class="wed">We</td>
      <td class="thu">Th</td>
      <td class="fri">Fr</td>
      <td class="sat">Sa</td>
    </tr>
    <xsl:call-template name="cal:week">
      <xsl:with-param name="monthDays" select="$monthDays"/>
      <xsl:with-param name="start" select="$start"/>
      <xsl:with-param name="end" select="$end"/>
      <xsl:with-param name="ranges" select="$ranges"/>
      <xsl:with-param name="count" select="$sunday"/>
    </xsl:call-template>
  </table>
</xsl:template>

<xsl:template name="cal:week">
  <xsl:param name="monthDays" select="31" as="xs:decimal"/>
  <xsl:param name="start" select="0" as="xs:decimal"/>
  <xsl:param name="end" select="0" as="xs:decimal"/>
  <xsl:param name="ranges" select="''"/>
  <xsl:param name="count" select="1"/>

  <tr align="right" class="week">
    <xsl:call-template name="cal:days">
      <xsl:with-param name="monthDays" select="$monthDays"/>
      <xsl:with-param name="start" select="$start"/>
      <xsl:with-param name="end" select="$end"/>
      <xsl:with-param name="ranges" select="$ranges"/>
      <xsl:with-param name="count" select="$count"/>
    </xsl:call-template>
  </tr>

  <xsl:if test="$count+7 &lt;= $monthDays">
    <xsl:call-template name="cal:week">
      <xsl:with-param name="monthDays" select="$monthDays"/>
      <xsl:with-param name="start" select="$start"/>
      <xsl:with-param name="end" select="$end"/>
      <xsl:with-param name="ranges" select="$ranges"/>
      <xsl:with-param name="count" select="$count+7"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template name="cal:days">
  <xsl:param name="monthDays" select="31" as="xs:decimal"/>
  <xsl:param name="start" select="0" as="xs:decimal"/>
  <xsl:param name="end" select="0" as="xs:decimal"/>
  <xsl:param name="count" select="1" as="xs:decimal"/>
  <xsl:param name="ranges" select="''"/>
  <xsl:param name="dayCount" select="0"/>

  <!--
  <xsl:message>
    <xsl:text>day: </xsl:text>
    <xsl:value-of select="$count"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$dayCount"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$start"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$end"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$monthDays"/>
  </xsl:message>
  -->

  <xsl:variable name="uri">
    <xsl:call-template name="in-range-uri">
      <xsl:with-param name="ranges" select="$ranges"/>
      <xsl:with-param name="day" select="$count"/>
    </xsl:call-template>
  </xsl:variable>

<!--
  <xsl:if test="$uri != ''">
    <xsl:message>
      <xsl:value-of select="$count"/>
      <xsl:text> URI: </xsl:text>
      <xsl:value-of select="$uri"/>
    </xsl:message>
  </xsl:if>
-->

  <td>
    <xsl:attribute name="class">
      <xsl:choose>
	<xsl:when test="$uri != ''">highlight</xsl:when>
	<xsl:when test="$count &gt; 0
			and $start &lt;= $count
			and $end &gt;= $count">
	  <xsl:text>highlight</xsl:text>
	</xsl:when>
	<xsl:when test="$dayCount = 0">sun</xsl:when>
	<xsl:when test="$dayCount = 1">mon</xsl:when>
	<xsl:when test="$dayCount = 2">tue</xsl:when>
	<xsl:when test="$dayCount = 3">wed</xsl:when>
	<xsl:when test="$dayCount = 4">thu</xsl:when>
	<xsl:when test="$dayCount = 5">fri</xsl:when>
	<xsl:when test="$dayCount = 6">sat</xsl:when>
      </xsl:choose>
    </xsl:attribute>

    <xsl:choose>
      <xsl:when test="$count &lt; 1">&#160;</xsl:when>
      <xsl:when test="$count &gt; $monthDays">&#160;</xsl:when>
      <xsl:otherwise>
	<xsl:choose>
	  <xsl:when test="$uri != '' and $uri != '*'">
	    <a href="{$uri}" class="caldaylink">
	      <xsl:value-of select="$count"/>
	    </a>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="$count"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </td>

  <xsl:if test="$dayCount &lt; 6">
    <xsl:call-template name="cal:days">
      <xsl:with-param name="monthDays" select="$monthDays"/>
      <xsl:with-param name="start" select="$start"/>
      <xsl:with-param name="end" select="$end"/>
      <xsl:with-param name="ranges" select="$ranges"/>
      <xsl:with-param name="count" select="$count+1"/>
      <xsl:with-param name="dayCount" select="$dayCount+1"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template name="in-range-uri">
  <xsl:param name="ranges" select="''"/>
  <xsl:param name="day" select="0"/>

  <xsl:variable name="range">
    <xsl:choose>
      <xsl:when test="contains($ranges, ';')">
	<xsl:value-of select="substring-before($ranges, ';')"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$ranges"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="moreranges" select="substring-after($ranges, ';')"/>

  <xsl:if test="$range != ''">
    <xsl:variable name="start"
		  select="xs:decimal(substring-before($range, ','))"/>

    <xsl:variable name="end"
		  select="xs:decimal(substring-before(substring-after($range, ','),','))"/>

    <xsl:variable name="uri"
		  select="substring-after(substring-after($range, ','),',')"/>

    <!--
    <xsl:message>
      <xsl:text>Range: </xsl:text>
      <xsl:value-of select="$range"/>
      <xsl:text>: </xsl:text>
      <xsl:value-of select="$start"/>
      <xsl:text>: </xsl:text>
      <xsl:value-of select="$end"/>
      <xsl:text>: </xsl:text>
      <xsl:value-of select="$uri"/>
      <xsl:text>: </xsl:text>
      <xsl:value-of select="$day"/>
    </xsl:message>
    -->

    <xsl:choose>
      <xsl:when test="$start &lt;= $day and $end &gt;= $day">
	<xsl:value-of select="$uri"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="in-range-uri">
	  <xsl:with-param name="ranges" select="$moreranges"/>
	  <xsl:with-param name="day" select="$day"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
