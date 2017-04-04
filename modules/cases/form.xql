xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Generates extension points for Case formulars

   December 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace form = "http://oppidoc.com/oppidum/form" at "../../lib/form.xqm";
import module namespace custom = "http://oppidoc.com/ns/application/custom" at "../../app/custom.xqm";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace site = "http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Utility to configure an autofill filter on a referencial input field 
   for transclusion purpose
   TODO: move to lib/form.xqm
   ======================================================================
:)
declare function local:configure-autofill( $cmd as element(), $target as xs:string, $url as xs:string ) as xs:string {
  let $cmd := oppidum:get-command()
  let $url := concat($cmd/@base-url, $url)
  let $container := 'div.c-autofill-border'
  return
    concat('autofill;autofill_target=', $target, ';autofill_url=', $url,';autofill_container=', $container)
};

(: ======================================================================
   Returns field to select challenges
   TODO: converts to selector model and move to lib/form.xqm
   ======================================================================
:)
declare function local:gen-challenges-selector( $lang as xs:string, $noedit as xs:boolean, $section as xs:string, $tag as xs:string ) as element()* {
  let $pairs :=
      for $p in fn:collection($globals:global-info-uri)//Description[@Lang = $lang]/CaseImpact/Sections/Section[Id eq $section]/SubSections/SubSection
      let $n := $p/SubSectionName
      return
         <Name id="{string($p/Id)}">{(replace($n,' ','\\ '))}</Name>
  let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
  let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
  return
    if ($noedit) then
      <xt:use types="choice" param="appearance=full;xvalue={$tag};multiple=yes;class=a-select-box readonly;noedit=true" values="{$ids}" i18n="{$names}"/>
    else
      <xt:use types="choice" param="appearance=full;xvalue={$tag};multiple=yes;class=a-select-box" values="{$ids}" i18n="{$names}"/>
};

(: ======================================================================
   Generates a constant field with a predefined content.noFill message
   TODO: move to form.xql
   ====================================================================== 
:)
declare function local:gen-constant-fields ( $names as xs:string* ) {
  for $name in $names
  return
    <site:field Key="{ $name }">
      <xt:use types="constant" param="class=uneditable-input span" loc="content.noFill">do not fill</xt:use>
    </site:field>
};

(: ======================================================================
   Generates the enterprise field as an (EnterpriseRef, Name) model
   Then EnterpriseRef is hidden and the Name is a constant field
   Configures an autofill filter to complete the enterprise information
   ======================================================================
:)
declare function local:gen-enterprise-readonly( $cmd as element() ) as element() {
  let $autofill := local:configure-autofill($cmd, '.x-ClientEnterprise',
    'enterprises/$_.blend?goal=autofill&amp;context=Case&amp;plugin=constant&amp;envelope=ClientEnterprise')
  return
    <site:field Key="enterprise" filter="no">
      <xhtml:span style="display:none"><xt:use types="constant" label="EnterpriseRef" param="filter={$autofill}"/></xhtml:span>
      <xt:use types="constant" label="Name" param="class=uneditable-input span a-control"/>
    </site:field>
};

(: ======================================================================
   Generates the enterprise field as an EnterpriseRef selector
   Configures an autofill filter to complete the enterprise information
   ======================================================================
:)
declare function local:gen-enterprise-create( $cmd as element(), $lang as xs:string ) as element() {
  let $autofill := local:configure-autofill($cmd, '.x-ClientEnterprise',
    'enterprises/$_.blend?goal=autofill&amp;context=Case&amp;plugin=choice&amp;envelope=ClientEnterprise')
  let $params := ';multiple=no;typeahead=yes'
  return
    <site:field Key="enterprise">
      { custom:gen-enterprise-selector($lang, concat(' ', $autofill, $params)) }
    </site:field>
};

let $cmd := request:get-attribute('oppidum.command')
let $lang := string($cmd/@lang)
let $goal := request:get-parameter('goal', 'read')
let $template := string(oppidum:get-resource($cmd)/@name)
return
  if ($goal = 'read') then
  
    if ($template = 'case') then

      <site:view>
        { local:gen-enterprise-readonly($cmd) }
        <site:field Key="vectors" filter="no">
          { local:gen-challenges-selector($lang, true(), '1', 'VectorRef') }
        </site:field>
        <site:field Key="ideas" filter="no">
          { local:gen-challenges-selector($lang, true(), '2', 'IdeaRef') }
        </site:field>
        <site:field Key="resources" filter="no">
          { local:gen-challenges-selector($lang, true(), '3', 'ResourceRef') }
        </site:field>
        <site:field Key="partners" filter="no">
          { local:gen-challenges-selector($lang, true(), '4', 'PartnerRef') }
        </site:field>
        <site:field Key="ctx-initial" filter="no">
          { form:gen-radio-selector-for('InitialContexts', $lang, true()) }
        </site:field>
        <site:field Key="ctx-target" filter="no">
          { form:gen-radio-selector-for('TargetedContexts', $lang, true()) }
        </site:field>
        <site:field Key="likert-scale">
          { form:gen-radio-selector-for('RatingScales', $lang, true(), 'c-inline-choice') }
        </site:field>
      </site:view>

    else

      <site:view/>


  else (: assumes 'create' or 'update' goal :)

    if ($template = 'case') then
    
      <site:view>
        {
        if ($goal eq 'create') then (
          local:gen-constant-fields(('title', 'initiator', 'number', 'date')),
          local:gen-enterprise-create($cmd, $lang)
          )
        else  (: client enterprise can't be changed after creation :)
          local:gen-enterprise-readonly($cmd)
        }
        <site:field Key="sex">
          <xt:use types="choice" values="M F" i18n="M F" param="class=span12 a-control">M</xt:use>
        </site:field>
        <site:field Key="vectors" filter="no">
          { local:gen-challenges-selector($lang, false(), '1', 'VectorRef') }
        </site:field>
        <site:field Key="ideas" filter="no">
          { local:gen-challenges-selector($lang, false(), '2', 'IdeaRef') }
        </site:field>
        <site:field Key="resources" filter="no">
          { local:gen-challenges-selector($lang, false(), '3', 'ResourceRef') }
        </site:field>
        <site:field Key="partners" filter="no">
          { local:gen-challenges-selector($lang, false(), '4', 'PartnerRef') }
        </site:field>
        <site:field Key="ctx-initial" filter="no">
          { form:gen-radio-selector-for( 'InitialContexts', $lang, false()) }
        </site:field>
        <site:field Key="ctx-target" filter="no">
          { form:gen-radio-selector-for( 'TargetedContexts', $lang, false()) }
        </site:field>
        <site:field Key="likert-scale">
          { form:gen-radio-selector-for('RatingScales', $lang, false(), 'c-inline-choice') }
        </site:field>
        <site:field Key="yes-no">
          { form:gen-selector-for('YesNoScales', $lang, " optional;multiple=no;typeahead=no") }
        </site:field>
      </site:view>

    else

      <site:view/>
