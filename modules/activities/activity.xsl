<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:template match="/">
    <xsl:apply-templates select="success | Activity | Display"/>
  </xsl:template>

  <xsl:template match="success">
    <success>
      <xsl:copy-of select="message"/>
      <payload>
        <xsl:apply-templates select="payload/*"/>
      </payload>
    </success>
  </xsl:template>

  <!-- Intermediate element carrying @No to generate a correct Link when answering to Activity creation with POST  -->
  <xsl:template match="Display">
    <xsl:apply-templates select="Activity"/>
  </xsl:template>

  <xsl:template match="Activity">
    <tr>
      <xsl:if test="../@Current and No = string(../@Current)">
        <xsl:attribute name="class">current</xsl:attribute>
      </xsl:if>
      <td><xsl:apply-templates select="No"/></td>
      <td><xsl:value-of select="ResponsibleCoach"/></td>
      <td><xsl:value-of select="CreationDate"/></td>
      <td><xsl:value-of select="Phase"/></td>
      <td><xsl:value-of select="Hours"/></td>
      <td><xsl:value-of select="ServiceName"/></td>
      <td><xsl:value-of select="Status"/></td>
    </tr>
  </xsl:template>

  <!-- Rendering from a Case view -->
  <xsl:template match="No[not(ancestor::Activities/@Current)]">
    <a href="{ancestor::Display/@ResourceNo}/activities/{.}"><xsl:value-of select="."/></a>
  </xsl:template>

  <!-- Rendering from an Activity view -->
  <xsl:template match="No[ancestor::Activities/@Current]">
    <a href="{.}"><xsl:value-of select="."/></a>
  </xsl:template>

  <!-- Rendering from an Activity view -->
  <xsl:template match="No[. = ancestor::Activities/@Current]">
    <b><xsl:value-of select="."/></b>
  </xsl:template>

</xsl:stylesheet>
