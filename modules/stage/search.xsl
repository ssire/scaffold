<?xml version="1.0" encoding="UTF-8"?>
<!--
     Case tracker pilote application

     Creator: Stéphane Sire <s.sire@opppidoc.fr>

     November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
  -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">
  
  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>
  
  <xsl:param name="xslt.base-url">/</xsl:param>

  <xsl:include href="../../lib/search.xsl"/>
  
  <xsl:template match="/Search">
    <div id="results">
      <xsl:apply-templates select="NoRequest | Results"/>
    </div>
  </xsl:template>
  
  <xsl:template match="/Search[Confirm]">
    <success status="202">
        <message loc="stage.request.empty">Voulez vous vraiment voir l'ensemble des données ?</message>
    </success>
  </xsl:template>
  
  <xsl:template match="/Search[@Initial='true']">
    <site:view skin="stage">
      <site:window><title loc="stage.search.title">Title</title></site:window>
      <site:title>
        <h1 loc="stage.search.title">Title</h1>
      </site:title>
      <site:content>
        <xsl:call-template name="formular"/>
        <div class="row">
          <div class="span12">
            <p id="c-busy" style="display: none; color: #999;margin-left:380px;height:32px">
              <span loc="term.loading" style="margin-left: 50px;vertical-align:middle">Recherche en cours...</span>
            </p>
            <div id="results">
              <xsl:apply-templates select="NoRequest | /Search/Results/Result"/>
            </div>
          </div>
        </div>
      </site:content>
    </site:view>
  </xsl:template>

  <xsl:template match="NoRequest">
  </xsl:template>
 
  <!-- No results -->
  <xsl:template match="Results[not(Result)]">
    <h2 loc="app.title.noResults">Pas de résultats</h2>
    <p><i loc="stage.message.noCase">Il n'y a pas de résultats pour les critères sélectionnés.</i></p>
  </xsl:template>
  
  <!-- One or more results -->
  <xsl:template match="Results[Result]">
    <h2>
      <span loc="stage.results.head">Results</span> (<xsl:value-of select="count(Result)"/>)
    </h2>
    <table class="table table-bordered">
      <thead>
        <tr>
          <th loc="term.country">Country</th>
        </tr>
      </thead>
      <tbody localized="1">
        <xsl:apply-templates select="Result"/>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template match="Result">
    <tr>
      <td><i><xsl:value-of select="Column"/></i></td>
    </tr>
  </xsl:template>

</xsl:stylesheet>
