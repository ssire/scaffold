xquery version "1.0";
(:~ 
 : Oppidoc Business Application Development Framework
 :
 : This module provides the helper functions that depend on the application
 : specific data model, such as :
 : <ul>
 : <li> label generation for different data types (display)</li>
 : <li> drop down list generation to include in formulars (form)</li>
 : <li> access control rules implementation (access)</li>
 : <li> miscellanous utilities (misc)</li>
 : </ul>
 : 
 : You most probably need to update that module to reflect your data model.
 : 
 : NOTE: actually eXist-DB does not support importing several modules
 : under the same prefix. Once this is supported this module could be 
 : splitted into corresponding modules (display, form, access, misc)
 : to be merged through import with their generic module counterpart.
 :
 : January 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
 :
 : @author Stéphane Sire
 :)
module namespace custom = "http://oppidoc.com/ns/application/custom";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../lib/globals.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../lib/display.xqm";
import module namespace cache = "http://oppidoc.com/ns/cctracker/cache" at "../lib/cache.xqm";
import module namespace form = "http://oppidoc.com/oppidum/form" at "../lib/form.xqm";
import module namespace user = "http://oppidoc.com/ns/user" at "../lib/user.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";

(: ======================================================================
   Generates an enterprise name from a reference to an enterprise
   ======================================================================
:)
declare function custom:gen-enterprise-name( $ref as xs:string?, $lang as xs:string ) {
  if ($ref) then
    let $p := fn:doc($globals:enterprises-uri)/Enterprises/Enterprise[Id = $ref]
    return
      if ($p) then
        $p/Name/text()
      else
        display:noref($ref, $lang)
  else
    ""
};
(: ======================================================================
   Generates an element with a given tag holding the display name of the enterprise
   passed as a parameter and its reference as content
   ======================================================================
:)
declare function custom:unreference-enterprise( $ref as element()?, $tag as xs:string, $lang as xs:string ) as element() {
  let $sref := $ref/text()
  return
    element { $tag }
      {(
      attribute { '_Display' } { custom:gen-enterprise-name($sref, $lang) },
      $sref
      )}
};

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting a person
   We do a single-pass algorithm to be sure we get same ordering between Names and Ids
   FIXME: handle case with no Person in database (?)
   ======================================================================
:)
declare function custom:gen-person-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $pairs :=
      for $p in fn:doc($globals:persons-uri)/Persons/Person
      let $fn := $p/Name/FirstName
      let $ln := $p/Name/LastName
      where ($p/Name/LastName/text() ne '')
      order by $ln ascending
      return
         <Name id="{$p/Id/text()}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}</Name>
  return
    let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
    let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
    return
      <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
};

(: ======================================================================
   Same as function form:gen-person-selector with a restriction to a given Role
   ======================================================================
:)
declare function custom:gen-person-with-role-selector ( $roles as xs:string+, $lang as xs:string, $params as xs:string, $class as xs:string? ) as element() {
  let $roles-ref := user:get-function-ref-for-role($roles)
  let $pairs :=
      for $p in fn:doc($globals:persons-uri)/Persons/Person[UserProfile//Role[FunctionRef = $roles-ref]]
      let $fn := $p/Name/FirstName
      let $ln := $p/Name/LastName
      where ($p/Name/LastName/text() ne '')
      order by $ln ascending
      return
         <Name id="{$p/Id/text()}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}</Name>
  return
    let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
    let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
    return
      if ($ids) then
        <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
      else
        <xt:use types="constant" param="noxml=true;class=uneditable-input {$class}">Not available</xt:use>
};

(: ======================================================================
  Same as form:gen-person-selector but with person's enterprise as a satellite
  It doubles request execution times
   ======================================================================
:)
declare function custom:gen-person-enterprise-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $pairs :=
      for $p in fn:doc($globals:persons-uri)/Persons/Person
      let $fn := $p/Name/FirstName
      let $ln := $p/Name/LastName
      let $pe := $p/EnterpriseRef/text()
      order by $ln ascending
      return
        let $en := if ($pe) then fn:doc($globals:enterprises-uri)//Enterprise[Id = $pe]/Name/text() else ()
        return
          <Name id="{$p/Id/text()}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}{if ($en) then concat('::', replace($en,' ','\\ ')) else ()}</Name>
  return
    let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
    let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
    return
      <xt:use types="choice" values="{$ids}" i18n="{$names}" param="select2_complement=town;{form:setup-select2($params)}"/>
};

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting an enterprise
   We do a single-pass algorithm to be sure we get same ordering between Names and Ids
   ======================================================================
:)
declare function custom:gen-enterprise-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $inCache := cache:lookup('enterprise', $lang)
  return
    if ($inCache) then
      <xt:use hit="1" types="choice" values="{$inCache/Values}" i18n="{$inCache/I18n}" param="select2_complement=town;select2_minimumInputLength=2;{form:setup-select2($params)}"/>
    else
      let $pairs :=
          for $p in fn:doc($globals:enterprises-uri)/Enterprises/Enterprise[not(@EnterpriseId)]
          let $n := $p/Name
          order by $n ascending
          return
             <Name id="{$p/Id/text()}">{replace($n,' ','\\ ')}{if ($p/Address/Town/text()) then concat('::', replace($p/Address/Town,' ','\\ ')) else ()}</Name>
      return
        let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
        let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
        return (
          cache:update('enterprise',$lang, $ids, $names),
          <xt:use types="choice" values="{$ids}" i18n="{$names}" param="select2_complement=town;select2_minimumInputLength=2;{form:setup-select2($params)}"/>
          )
};

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting an enterprise town
   We do a single-pass algorithm to be sure we get same ordering between Names and Ids
   ======================================================================
:)
declare function custom:gen-town-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $inCache := cache:lookup('town', $lang)
  return
    if ($inCache) then
      <xt:use hit="1" types="choice" values="{$inCache/Values}" param="{form:setup-select2($params)}"/>
    else
      let $towns :=
        for $t in distinct-values ((fn:doc($globals:enterprises-uri)//Enterprise[not(@EnterpriseId)]/Address/Town/text()))
        order by $t ascending
        return
          replace($t,' ','\\ ')
      return
        let $ids := string-join($towns, ' ')
        return (
          cache:update('town',$lang, $ids, ()),
          <xt:use types="choice" values="{$ids}" param="{form:setup-select2($params)}"/>
          )
};

(: ======================================================================
   Generates selector for creation years 
   ======================================================================
:)
declare function custom:gen-creation-year-selector ( ) as element() {
  let $years := 
    for $y in distinct-values(fn:doc($globals:enterprises-uri)//CreationYear)
    where matches($y, "^\d{4}$")
    order by $y descending
    return $y
  return
    <xt:use types="choice" values="{ string-join($years, ' ') }" param="select2_dropdownAutoWidth=on;select2_width=off;class=year a-control;filter=optional select2;multiple=no"/>
};

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting a  Case Impact (Vecteur d'innovation)
   TODO: 
   - caching
   - use Selector / Group generic structure with a gen-selector-for( $name, $group, $lang, $params) generic function
   ======================================================================
:)
declare function custom:gen-challenges-selector-for  ( $root as xs:string, $lang as xs:string, $params as xs:string ) as element() {
  let $pairs :=
        for $p in fn:collection($globals:global-info-uri)//Description[@Lang = $lang]/CaseImpact/Sections/Section[SectionRoot eq $root]/SubSections/SubSection
        let $n := $p/SubSectionName
        return
           <Name id="{$p/Id/text()}">{(replace($n,' ','\\ '))}</Name>
  return
   let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
   let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
   return
     <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
};

(: ======================================================================
   Tests current user is compatible with semantic role and given resource
   Implement this function if your application defines semantic roles
   ======================================================================
:)
declare function custom:assert-semantic-role( $role as xs:string, $resource as element()? ) as xs:boolean {
  (: no single resource semantic role actually :)
  let $res := false()
  return false()
};

(: ======================================================================
   Tests current user is compatible with semantic role given as parameter
   Implements r:kam and r:coach semantic roles agains Case / Activity

   See also default email recipients list generation in workflow/alert.xql
   ======================================================================
:)
declare function custom:assert-semantic-role( $suffix as xs:string, $case as element(), $activity as element()? ) as xs:boolean {
  let $pid := user:get-current-person-id() 
  return
    if ($pid) then
      if ($suffix eq 'kam') then
        $pid = $case/Management/AccountManagerRef/text()
      else if ($suffix eq 'coach') then
        $pid = $activity/Assignment/ResponsibleCoachRef/text()
      else
        false()
    else
      false()
};

declare function custom:gen-short-case-title( $case as element(), $lang as xs:string ) as xs:string {
  let $ctx := $case/NeedsAnalysis/Context/InitialContextRef
  return
    if ($ctx) then
      concat(display:gen-name-for("InitialContexts", $ctx, $lang), ' - ', substring($case/CreationDate, 1, 4))
    else
      concat('... - ', substring($case/CreationDate, 1, 4))
};

declare function custom:gen-case-title( $case as element(), $lang as xs:string ) as xs:string {
  concat(
    custom:gen-enterprise-name($case/Information/ClientEnterprise/EnterpriseRef, 'en'),
    ' - ',
    custom:gen-short-case-title($case, $lang)
    )
};

declare function custom:gen-activity-title( $case as element(), $activity as element(), $lang as xs:string ) as xs:string {
  let $service := $activity/Assignment/ServiceRef
  return
    concat(
      custom:gen-enterprise-name($case/Information/ClientEnterprise/EnterpriseRef, 'en'),
      ' - ',
      if ($service) then
        concat(display:gen-name-for("Services", $service, $lang), ' - ', substring($activity/CreationDate, 1, 4))
      else
        concat('service pending - ', substring($activity/CreationDate, 1, 4))
      )
};

