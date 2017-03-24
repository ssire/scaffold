xquery version "1.0";
(: --------------------------------------
   Oppidoc Business Application Development Framework

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Generates XTiger XML controls for insertion into stats filter masks

   January 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace form = "http://oppidoc.com/oppidum/form" at "../../lib/form.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../../lib/display.xqm";
import module namespace custom = "http://oppidoc.com/ns/application/custom" at "../../app/custom.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace site = "http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=text/xml";

let $cmd := request:get-attribute('oppidum.command')
let $template := string(oppidum:get-resource($cmd)/@name)
let $lang := string($cmd/@lang)
return
  <site:view>
    <site:field Key="case-status">
      { form:gen-selector-for('CaseWorkflowStatus', $lang, " event;multiple=yes;xvalue=CaseStatusRef;typeahead=no") }
    </site:field>
    <site:field Key="countries">
      { form:gen-selector-for('Countries', $lang, ";multiple=yes;xvalue=Country;typeahead=yes") }
    </site:field>
    <site:field Key="domains-of-activities">
      { form:gen-json-selector-for('DomainActivities', $lang, "multiple=yes;xvalue=DomainActivityRef;choice2_width1=250px;choice2_width2=250px;choice2_closeOnSelect=true") }
    </site:field>
    <site:field Key="targeted-markets">
      { form:gen-json-selector-for('TargetedMarkets', $lang, "multiple=yes;xvalue=TargetedMarketRef;choice2_width1=250px;choice2_width2=250px;choice2_closeOnSelect=true") }
    </site:field>
    <site:field Key="sizes">
      { form:gen-selector-for('Sizes', $lang, ";multiple=yes;typeahead=no;xvalue=SizeRef") }
    </site:field>
    <site:field Key="ctx-initial">
      { form:gen-selector-for('InitialContexts', $lang, ";multiple=yes;xvalue=InitialContextRef;typeahead=no") }
    </site:field>
    <site:field Key="ctx-target">
      { form:gen-selector-for('TargetedContexts', $lang, ";multiple=yes;xvalue=TargetedContextRef;typeahead=no") }
    </site:field>
    <site:field Key="vectors">
      { custom:gen-challenges-selector-for('Vectors', $lang, ";multiple=yes;xvalue=VectorRef;typeahead=no") }
    </site:field>
    <site:field Key="ideas">
      { custom:gen-challenges-selector-for('Ideas', $lang, ";multiple=yes;xvalue=IdeaRef;typeahead=no") }
    </site:field>
    <site:field Key="resources">
      { custom:gen-challenges-selector-for('Resources', $lang, ";multiple=yes;xvalue=ResourceRef;typeahead=no") }
    </site:field>
    <site:field Key="partners">
      { custom:gen-challenges-selector-for('Partners', $lang, ";multiple=yes;xvalue=PartnerRef;typeahead=no") }
    </site:field>
    <site:field Key="creation-year">
      { custom:gen-creation-year-selector() }
    </site:field>
  </site:view>
