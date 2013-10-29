<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
    xmlns:sfdc-func="http://www.salesforce.com/exsl/functions"
    xpath-default-namespace="http://www.w3.org/1999/xhtml" 
    exclude-result-prefixes="xs xd sfdc-func" version="2.0">
    <xsl:output omit-xml-declaration="yes" indent="no"/>
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Oct 14, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> sanderson@salesforce.com</xd:p>
            <xd:p>Generate a toc file for RedSofa help system</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="root">/</xsl:param>
    <xsl:param name="lang">en-us</xsl:param>
    <xsl:param name="version">1.0</xsl:param>
    <xsl:param name="deliverable">help</xsl:param>

    <xd:doc>
        <xd:desc>Strip out white space and newlines</xd:desc>
    </xd:doc>
    <xsl:function name="sfdc-func:strip-newlines">
        <xsl:param name="text"/>
        <xsl:value-of select="normalize-space(translate($text,'&#x0d;&#x0a;', ''))"/>
    </xsl:function>

    <xd:doc>
        <xd:desc>If it's not specifically matched, ignore it</xd:desc>
    </xd:doc>
    <xsl:template match="/ | node() | @*">
        <xsl:apply-templates/>
    </xsl:template>

    <xd:doc>
        <xd:desc>Create the outer div structure</xd:desc>
    </xd:doc>
    <xsl:template match="nav">
        <div class="sidebar-nav" id="side-menu">
            <div class="accordion" id="toc">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>



    <xd:doc>
        <xd:desc>
            <xd:p>There are 4 cases for li elements. <xd:ul>
                    <xd:li>li with an href and a child ul <xd:p>Result: A parent node that links to a topic</xd:p>
                    </xd:li>
                    <xd:li>li with an href without a child ul <xd:p>Result: A toc entry</xd:p>
                    </xd:li>
                    <xd:li>li without an href and a child ul <xd:p>Result: A parent node that doesn't link to a topic</xd:p>
                    </xd:li>
                    <xd:li>li without an href without a child ul <xd:p>No-op</xd:p>
                    </xd:li>
                </xd:ul>
            </xd:p>
        </xd:desc>
    </xd:doc>

    <xd:doc>
        <xd:desc>Cases 1 and 3 <xd:p>A ToC entry with a child group</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="li[child::ul[child::li[child::a[string-length(@href) > 0]]]]">
        <xsl:variable name="level" select="concat('toc-level-',count(ancestor::ul))"/>
        <xsl:variable name="subnav-id" select="concat('subnav-', generate-id(child::ul[1]))"/>
        <div class="accordion-group" id="{generate-id()}">
            <div class="accordion-heading accordion-toggle {$level}">
                <xsl:choose>
                    <xsl:when test="child::a[string-length(@href) > 0]">
                        <a href="{concat($root, $lang, '/', $version, '/', $deliverable, '/', child::a/@href)}" class="toc-a-block">
                            <span class="toc-text">
                                <xsl:value-of select="sfdc-func:strip-newlines(a/text()[normalize-space()])"/>
                            </span>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="toc-text">
                            <xsl:value-of select="sfdc-func:strip-newlines(self::li/text()[normalize-space()])"/>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>

                <a data-toggle="collapse" class="pull-right toc-plus-block" href="#{$subnav-id}">
                    <i class="icon-plus toc-icon pull-right">
                        <xsl:comment> </xsl:comment>
                    </i>
                </a>
            </div>
            <div id="{$subnav-id}" class="accordion-body collapse">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="li[not(child::ul)][child::a[string-length(@href) > 0]]">
        <xsl:variable name="level" select="concat('toc-level-',count(ancestor::ul))"/>
        <xsl:variable name="my_id">
            <xsl:variable name="my_href_with_anchor">
                <xsl:call-template name="convert_path">
                    <xsl:with-param name="path" select="child::a/@href"/>
                    <xsl:with-param name="file_separator">/</xsl:with-param>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="my_href_no_anchor">
                <xsl:choose>
                    <xsl:when test="contains($my_href_with_anchor, '#')">
                        <xsl:value-of select="substring-before(substring-before($my_href_with_anchor, '#'), '.')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="substring-before($my_href_with_anchor, '.')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="contains($my_href_no_anchor, '/')">
                    <xsl:value-of select="tokenize($my_href_no_anchor, '/')[last()]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$my_href_no_anchor"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <div id="{$my_id}" class="{$level} leaf toc-a-block">
            <a href="{concat($root, $lang, '/', $version, '/', $deliverable, '/', child::a/@href)}">
                <span class="toc-text">
                    <xsl:value-of select="sfdc-func:strip-newlines(child::a/text()[normalize-space()])"/>
                </span>
            </a>
        </div>
    </xsl:template>

    <xsl:template name="convert_path">
        <xsl:param name="path"/>
        <xsl:param name="file_separator"/>
        <xsl:value-of select="translate(translate($path, '\',$file_separator),'/', $file_separator)"/>
    </xsl:template>

</xsl:stylesheet>
