xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidoc Business Application Development Framework

   Creation: Stéphane Sire <s.sire@opppidoc.fr>

   January 2016 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace stats = "http://oppidoc.com/ns/cctracker/stats";

declare namespace json="http://www.json.org";
declare namespace site = "http://oppidoc.com/oppidum/site";

import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../../lib/display.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";

(: ======================================================================
   TODO: move to misc: ?
   ====================================================================== 
:)
declare function local:get-local-string( $lang as xs:string, $key as xs:string ) as xs:string {
  let $res := fn:doc($globals:dico-uri)/site:Dictionary/site:Translations[@lang = $lang]/site:Translation[@key = $key]/text()
  return
    if ($res) then
      $res
    else
      concat('missing [', $key, ', lang="', $lang, '"]')
};

declare function local:gen-values( $value as element()?, $literal as xs:boolean ) {
  <Values>
    {
    if ($literal) then 
      attribute { 'json:literal' } { 'true' }
    else
      (),
      $value/text()
    }
  </Values>
};

(: ======================================================================
   Generates code book for a Composition
   ====================================================================== 
:)
declare function stats:gen-composition-domain( $composition as element() ) as element()* {
  element { string($composition/@Name) }
  {
  for $m in $composition/Mean
  return
    <Labels>{ local:get-local-string('en', string($m/@loc)) }</Labels>,
  for $m in $composition/Mean
  return
    <Values>{ string($m/@Filter) }</Values>,
  for $m in $composition/Mean
  return
    <Legends>{ local:get-local-string('en', concat(string($m/@loc), '.legend')) }</Legends>
  }
};

(: ======================================================================
   Generates labels and values decoding book for a given selector name
   See also form:gen-selector-for in lib/form.xqm
   TODO: restrict to existing values in data set for some large sets (e.g. NOGA) ?
   FIXME: hard coded language parameter 'en'
   ====================================================================== 
:)
declare function stats:gen-selector-domain( $name as xs:string, $selector as xs:string, $literal as xs:boolean) as element()* {
  let $sel := fn:collection($globals:global-info-uri)//Description[@Lang = 'en']//Selector[@Name eq $selector]
  return
    element { $name } {
      if ($sel/Group) then (: nested selector :)
        (
        for $v in $sel//Option
        let $concatWithId := starts-with($sel/@Label, 'V+')
        let $ltag := replace($sel/@Label, '^V\+', '')
        let $vtag := string($sel/@Value)
        return
          <Labels>
            { 
              if ($concatWithId) then
                concat($v/*[local-name(.) eq $vtag], ' - ', $v/*[local-name(.) eq $ltag])
              else
                $v/*[local-name(.) eq $ltag]/text()
            }
          </Labels>,
        for $v in $sel//Option
        let $tag := string($sel/@Value)
        return
          local:gen-values($v/*[local-name(.) eq $tag], $literal)
        )
      else (: flat selector :)
        (
        for $v in $sel/Option
        let $tag := string($sel/@Label)
        let $l := $v/*[local-name(.) eq $tag]/text()
        return
          <Labels>
            { 
            if (contains($l, "::")) then
              concat(replace($l, "::", " ("), ")")
            else 
              $l
            }
          </Labels>,
        for $v in $sel/Option
        let $tag := string($sel/@Value)
        return
          local:gen-values($v/*[local-name(.) eq $tag], $literal)
        )
    }
};

(: ======================================================================
   Stub to generates decoding books (labels, values) for a given selector
   ====================================================================== 
:)
declare function stats:gen-selector-domain( $name as xs:string, $selector as xs:string ) as element()* {
  stats:gen-selector-domain($name, $selector, false())
};

(: ======================================================================
   Generates decoding books (labels, values) for a given selector with 
   a specific format (i.e. literal)
   ====================================================================== 
:)
declare function stats:gen-selector-domain( $name as xs:string, $selector as xs:string, $format as xs:string? ) as element()* {
  stats:gen-selector-domain($name, $selector, not(empty($format)) and ($format eq 'literal'))
};

(: ======================================================================
   Generates labels and values decoding book for status of a given workflow name
   FIXME: hard coded language parameter 'en'
   ====================================================================== 
:)
declare function stats:gen-workflow-status-domain( $tag as xs:string, $name as xs:string ) as element()* {
  let $set := globals:get-normative-selector-for(concat($name, 'WorkflowStatus'))
  
  (:fn:collection($globals:global-information-uri)/GlobalInformation/Description[@Lang = 'en']/WorkflowStatus[@Name eq $name]:)
  
  return
    element { $tag } {
      (
      for $v in $set/Option
      return
        <Labels>{ $v/Name/text() }</Labels>,
      for $v in $set/Option
      return
        <Values>{ $v/Id/text() }</Values>
      )
    }
};

(: ======================================================================
   Generates labels and values decoding book for a sequence of person's references
   This way the set can include persons who no longer hold the required role
   ======================================================================
:)
declare function stats:gen-persons-domain-for( $refs as xs:string*, $tag as xs:string ) as element()* {
  element { $tag }
    {
    (: Double FLWOR because of eXist 1.4.3 oddity see http://markmail.org/thread/mehfwoj6enc2z65v :)
    let $sorted := 
      for $p in fn:doc($globals:persons-uri)/Persons/Person[Id = $refs]
      order by $p/Name/LastName
      return $p
    return
      for $s in $sorted 
      return (
        <Labels>{ concat(normalize-space($s/Name/LastName), ' ', normalize-space($s/Name/FirstName)) }</Labels>,
        <Values>{ $s/Id/text() }</Values>
        )
    }
};

(: ======================================================================
   Generates years values for a sample set
   NOTE: Year tag name MUST BE consistent with stats.xml
   FIXME: could be directly computed client-side from the set (?)
   ======================================================================
:)
declare function stats:gen-year-domain( $set as element()* ) as element()* {
  for $y in distinct-values($set//Yr)
  where matches($y, "^\d{4}$")
  order by $y
  return
    <Yr>{ $y }</Yr>
};

(: ======================================================================
   Generates labels and values decoding book for case impact variable with name and id
   ====================================================================== 
:)
declare function stats:gen-case-vector( $name as xs:string, $id  as xs:string ) {
  (: TODO: $lang :)
  let $set := fn:collection($globals:global-info-uri)//Description[@Lang = 'en']/CaseImpact/Sections/Section[Id eq $id]
  return
    element { $name } {
      (
      for $v in $set/SubSections/SubSection
      return
        <Labels>{$v/SubSectionName/text()}</Labels>,
      for $v in $set/SubSections/SubSection
        return
        <Values>{$v/Id/text()}</Values>
      )
    }
};
