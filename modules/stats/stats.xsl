<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="xslt.base-url">/</xsl:param>

  <xsl:include href="../../lib/commons.xsl"/>

  <!-- Forwards error displaying at the epilogue step -->
  <xsl:template match="/error">
    <site:view skin="stats">
    </site:view>
  </xsl:template>

  <!-- Real entry point  -->
  <xsl:template match="/Stats">
    <site:view skin="stats c3">
      <xsl:apply-templates select="Window"/>
      <site:content>
        <xsl:apply-templates select="Formular"/>
        <h2 id="with-sample">
          <span>Data set contains </span><xsl:text> </xsl:text>
          <span id="cases-nb">0</span><span> cases</span> <span id="activities-nb">0</span><span> activities</span>
        </h2>
        <h2 id="no-sample">Data set is empty</h2>
        <div class="row">
          <div class="span12">
            <xsl:apply-templates select="Charts"/>
          </div>
        </div>
      </site:content>
    </site:view>
  </xsl:template>

  <!-- TODO: merge with Formular into widgets.xsl
       But both commands menu use different layout algorithm ? -->
  <xsl:template match="Formular">
    <form class="form-horizontal c-search" action="" onsubmit="return false;">
      <xsl:apply-templates select="@Width"/>
      <div data-template="{Template}">
        <xsl:apply-templates select="@Id"/>
        <noscript loc="app.message.js">Activez Javascript</noscript>
        <p loc="app.message.loading">Chargement du formulaire en cours</p>
      </div>
      <div class="row-fluid noprint">
        <xsl:apply-templates select="Commands/*"/>
      </div>
    </form>
    <div class="row">
      <div class="span12">
        <p id="c-busy" style="display: none; color: #999;margin-left:380px;height:32px">
          <span loc="term.loading" style="margin-left: 50px;vertical-align:middle">Recherche en cours...</span>
        </p>
      </div>
    </div>
    <xsl:apply-templates select="Commands/Command[@Name = 'submit']" mode="form"/>
  </xsl:template>
  
  <!-- Installs HTML form for 'submit' command submission -->
  <xsl:template match="Command" mode="form">
    <form id="c-{@Form}-form" enctype="multipart/form-data" accept-charset="UTF-8"
      action="{@Action}" method="post" target="_blank" style="display:none">
      <input type="hidden" name="data"/>
    </form>
  </xsl:template>

  <!-- Installs 'submit' command to open a new window using classical form submission -->
  <xsl:template match="Command[@Name = 'submit']">
    <xsl:variable name="offset"><xsl:if test="@Offset"><xsl:value-of select="concat(' offset', @Offset)"/></xsl:if></xsl:variable>
    <div class="span{@W}{$offset}">
      <button class="btn btn-primary" data-command="submit" data-target="editor" data-form="c-{@Form}-form"><xsl:value-of select="."/></button>
    </div>
  </xsl:template>

  <!-- Installs 'export' command for generating a link to a generated Excel file -->
  <xsl:template match="Command[@Name = 'export']">
    <xsl:variable name="offset"><xsl:if test="@Offset"><xsl:value-of select="concat(' offset', @Offset)"/></xsl:if></xsl:variable>
    <div class="span{@W}{$offset}">
      <xsl:value-of select="@Prompt"/><a data-command="export" data-target="editor" data-action="{@Action}" href="#"><xsl:value-of select="."/></a>
    </div>
  </xsl:template>

  <!-- TODO: use @Action (create real command in stats.js)  -->
  <xsl:template match="Command[@Name = 'stats']">
    <xsl:variable name="offset"><xsl:if test="@Offset"><xsl:value-of select="concat(' offset', @Offset)"/></xsl:if></xsl:variable>
    <div class="span{@W}{$offset}">
      <button id="c-stats-submit" class="btn btn-primary"><xsl:value-of select="."/></button>
    </div>
  </xsl:template>

  <xsl:template match="Command[@Access = 'disabled']">
    <xsl:variable name="offset"><xsl:if test="@Offset"><xsl:value-of select="concat(' offset', @Offset)"/></xsl:if></xsl:variable>
    <div class="span{@W}{$offset}">
      <!-- placeholder -->
    </div>
  </xsl:template>

  <xsl:template match="Charts">
    <xsl:apply-templates select="Chart"/>
  </xsl:template>

  <!-- Single Chart diagram -->
  <xsl:template match="Chart">
    <xsl:call-template name="chart"/>
  </xsl:template>

  <!-- Single Chart diagram with Composition (non iteratable with @Max) -->
  <xsl:template match="Chart[Composition]">
    <div style="display:none" class="chart" data-set="{Set}">
      <xsl:apply-templates select="Layout/*"/>
      <xsl:apply-templates select="Composition"/>
      <h3>
        <xsl:value-of select="Title"/>
      </h3>
      <xsl:apply-templates select="Comment"/>
      <table class="stats">
        <thead>
          <th>
            <xsl:value-of select="Title"/>
          </th>
          <th>Average rating</th>
          <th>Nbr of significative answers</th>
        </thead>
        <tbody>
        </tbody>
      </table>
      <div class="export noprint">Export <a download="case-tracker-{translate(Composition/@Name, $uppercase, $smallcase)}.xls" href="#" class="export">excel</a> <a download="case-tracker-{translate(Composition/@Name, $uppercase, $smallcase)}.csv" href="#" class="export">csv</a></div>
    </div>
  </xsl:template>

  <!-- Iterated Chart -->
  <xsl:template match="Chart[@Max]">
    <xsl:call-template name="chart-iter">
      <xsl:with-param name="nb" select="1"/>
      <xsl:with-param name="reminder" select="number(@Max)"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Call $reminder times chart template with successive nb -->
  <!-- recursive version of 1 to @Max in XLST 1.0  -->
  <xsl:template name="chart-iter">
    <xsl:param name="nb"/>
    <xsl:param name="reminder"/>
    <xsl:call-template name="chart">
      <xsl:with-param name="nb" select="$nb"/>
    </xsl:call-template>
    <xsl:if test="$reminder > 1">
      <xsl:call-template name="chart-iter">
        <xsl:with-param name="nb" select="$nb + 1"/>
        <xsl:with-param name="reminder" select="$reminder - 1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="chart">
    <xsl:param name="nb"/>
    <xsl:variable name="download">
      <xsl:apply-templates select="Variable | Vector" mode="download"/>
      <xsl:if test="@Max">-q<xsl:value-of select="$nb"/></xsl:if>
    </xsl:variable>
    <div style="display:none" class="chart" data-set="{Set}">
      <xsl:apply-templates select="Layout/*"/>
      <xsl:apply-templates select="Vector | Variable">
        <xsl:with-param name="nb" select="$nb"/>
      </xsl:apply-templates>
      <h3>
        <xsl:if test="$nb != ''">
          <xsl:attribute name="loc"><xsl:value-of select="concat(Title/@loc, $nb)"/></xsl:attribute>
        </xsl:if>
        <xsl:value-of select="Title"/>
      </h3>
      <xsl:apply-templates select="Comment"/>
      <table class="stats">
        <thead>
          <th>
            <xsl:if test="$nb != ''">
              <xsl:attribute name="loc"><xsl:value-of select="concat(Title/@loc, $nb)"/></xsl:attribute>
            </xsl:if>
            <xsl:value-of select="Title"/>
          </th>
          <th>Number</th>
          <xsl:if test="Vector/@Type[.='Amount']">
            <th>SFR</th>
          </xsl:if>
          <th>%</th>
        </thead>
        <tbody>
        </tbody>
      </table>
      <div class="export noprint">Export <a download="case-tracker-{$download}.xls" href="#" class="export">excel</a> <a download="case-tracker-{$download}.csv" href="#" class="export">csv</a></div>
    </div>
  </xsl:template>
  
  <xsl:template match="Vector[@Selector] | Variable[@Selector]" mode="download"><xsl:value-of select="translate(@Selector, $uppercase, $smallcase)"/>
  </xsl:template>

  <xsl:template match="Vector[@Persons] | Variable[@Persons]" mode="download"><xsl:value-of select="translate(@Persons, $uppercase, $smallcase)"/>
  </xsl:template>

  <xsl:template match="Variable[@WorkflowStatus]" mode="download"><xsl:value-of select="translate(@WorkflowStatus, $uppercase, $smallcase)"/>-status</xsl:template>

  <xsl:template match="Variable[@Domain]" mode="download"><xsl:value-of select="translate(@Domain, $uppercase, $smallcase)"/>
  </xsl:template>

  <xsl:template match="Vector[@Domain]" mode="download"><xsl:value-of select="translate(@Domain, $uppercase, $smallcase)"/>-sec<xsl:value-of select="translate(@Section, $uppercase, $smallcase)"/>
  </xsl:template>

  <xsl:template match="Comment">
    <p class="text-hint"><xsl:value-of select="."/></p>
  </xsl:template>

  <xsl:template match="Bottom">
    <xsl:attribute name="data-bottom"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Angle">
    <xsl:attribute name="data-angle"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Left">
    <xsl:attribute name="data-left"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Size">
    <xsl:attribute name="data-Size"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Variable">
    <xsl:attribute name="data-variable"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Update">
    <xsl:attribute name="data-update"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="Vector">
    <xsl:param name="nb"/>
    <xsl:attribute name="data-variable"><xsl:value-of select="."/></xsl:attribute>
    <xsl:if test="$nb">
      <xsl:attribute name="data-rank"><xsl:value-of select="$nb"/></xsl:attribute>
    </xsl:if>
    <xsl:attribute name="data-type">vector</xsl:attribute>
  </xsl:template>

  <xsl:template match="Composition">
    <xsl:attribute name="data-type">composition</xsl:attribute>
    <xsl:attribute name="data-variable"><xsl:value-of select="@Name"/></xsl:attribute>
    <xsl:attribute name="data-composition"><xsl:value-of select="@Variable"/></xsl:attribute>
    <xsl:apply-templates select="Mean"/>
  </xsl:template>

  <xsl:template match="Mean">
    <xsl:attribute name="data-dimension-{@Filter}"><xsl:apply-templates select="Rank"/></xsl:attribute>
  </xsl:template>
  
  <!-- <xsl:attribute name="data-dimension-{@Filter}"><xsl:apply-templates select="ancestor::Composition/Mean/Rank"/></xsl:attribute> -->
  <xsl:template match="Mean[not(Rank)]">
    <xsl:attribute name="data-dimension-{@Filter}">-1</xsl:attribute>    
  </xsl:template>

  <xsl:template match="Rank"><xsl:value-of select="."/><xsl:text> </xsl:text>
  </xsl:template>

  <!-- does not work with Mean[not(Rank)] why ? -->
  <!-- <xsl:template match="Rank[position() = count(parent::Mean/Rank)]"><xsl:value-of select="."/>
  </xsl:template> -->
</xsl:stylesheet>
