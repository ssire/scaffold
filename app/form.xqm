xquery version "1.0";
(: --------------------------------------
   SCAFFOLD - Case tracker pilote library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Functions to generate extension points for the application formulars.
   Each function has to localize its results in the current language.

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace form = "http://oppidoc.com/oppidum/form/app";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../lib/globals.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "display.xqm";
import module namespace cache = "http://oppidoc.com/ns/cctracker/cache" at "cache.xqm";
import module namespace form_ = "http://oppidoc.com/oppidum/form" at "../lib/form.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting a person
   We do a single-pass algorithm to be sure we get same ordering between Names and Ids
   FIXME: handle case with no Person in database (?)
   ======================================================================
:)
declare function form:gen-person-selector ( $lang as xs:string, $params as xs:string ) as element() {
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
      <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form_:setup-select2($params)}"/>
};

(: ======================================================================
  Same as form:gen-person-selector but with person's enterprise as a satellite
  It doubles request execution times
   ======================================================================
:)
declare function form:gen-person-enterprise-selector ( $lang as xs:string, $params as xs:string ) as element() {
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
      <xt:use types="choice" values="{$ids}" i18n="{$names}" param="select2_complement=town;{form_:setup-select2($params)}"/>
};

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting an enterprise
   We do a single-pass algorithm to be sure we get same ordering between Names and Ids
   ======================================================================
:)
declare function form:gen-enterprise-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $inCache := cache:lookup('enterprise', $lang)
  return
    if ($inCache) then
      <xt:use hit="1" types="choice" values="{$inCache/Values}" i18n="{$inCache/I18n}" param="select2_complement=town;select2_minimumInputLength=2;{form_:setup-select2($params)}"/>
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
          <xt:use types="choice" values="{$ids}" i18n="{$names}" param="select2_complement=town;select2_minimumInputLength=2;{form_:setup-select2($params)}"/>
          )
};

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting an enterprise town
   We do a single-pass algorithm to be sure we get same ordering between Names and Ids
   ======================================================================
:)
declare function form:gen-town-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $inCache := cache:lookup('town', $lang)
  return
    if ($inCache) then
      <xt:use hit="1" types="choice" values="{$inCache/Values}" param="{form_:setup-select2($params)}"/>
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
          <xt:use types="choice" values="{$ids}" param="{form_:setup-select2($params)}"/>
          )
};
