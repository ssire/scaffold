xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Utilities to update enterprise data

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace enterprise = "http://oppidoc.fr/ns/ctracker/enterprise";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace ajax = "http://oppidoc.com/oppidum/ajax" at "../../lib/ajax.xqm";
import module namespace cache = "http://oppidoc.com/ns/cctracker/cache" at "../../lib/cache.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Normalizes a string to compare it with another one
   TODO: handle accentuated characters (canonical form ?)
   ======================================================================
:)
declare function local:normalize( $str as xs:string? ) as xs:string {
  upper-case(normalize-space($str))
};

(: ======================================================================
   Checks submitted enterprise data is valid and check Name fields 
   are unique or correspond to the submitted enterprise in case of update ($curNo defined).
   Returns a list of error messages or the emtpy sequence if no errors.
   TODO: improve error generation for internationalization
   ======================================================================
:)
declare function enterprise:validate-enterprise-submission( $data as element(), $curNo as xs:string? ) as element()* {
  let $key1 := local:normalize($data/Name/text())
  let $cname := fn:doc($globals:enterprises-uri)/Enterprises/Enterprise[local:normalize(Name) = $key1]
  return (
      if ($curNo and empty(fn:doc($globals:enterprises-uri)/Enterprises/Enterprise[Id = $curNo])) then
        ajax:throw-error('UNKNOWN-ENTERPRISE', $curNo)
      else (),
      if ($cname) then 
        if (not($curNo) or ($cname/Id != $curNo)) then
          ajax:throw-error('ENTERPRISE-NAME-CONFLICT', $data/Name/text())
        else ()
      else ()
      )
};

(: ======================================================================
   Serializes new element if it exists 
   ======================================================================
:)
declare function local:persists_annotation( $current as element()?, $new as element()? ) as element()? {
  if ($new) then
    if ($current/@_Source) then (: persists importer _Source annotation :)
      element { local-name($new) } {(
        $current/@_Source,
        $new/text()
      )}
    else
      $new
  else
    ()
};

(: ======================================================================
   Reconstructs an Enterprise record from current Enterprise data and from new submitted
   Enterprise data. Current Enterprise may be the empty sequence in case of creation.
   ======================================================================
:)
declare function enterprise:gen-enterprise-for-writing( $current as element()?, $new as element(), $index as xs:integer? ) {
  <Enterprise>
    {(
    if ($current) then 
      (
      $current/@EnterpriseId,
      $current/Id
      )
    else 
      <Id>{$index}</Id>,
    $new/Name,
    $new/ShortName,
    local:persists_annotation($current/CreationYear, $new/CreationYear),
    local:persists_annotation($current/SizeRef, $new/SizeRef),
    $new/DomainActivityRef,
    $new/WebSite,
    $new/MainActivities,
    $new/TargetedMarkets,
    $new/Address
    )}
  </Enterprise>
};

(: ======================================================================
   Updates an enterprise record into database if the submitted data is different
   Invalidates cache in case enterprise name 
   Returns true() if data was updated, false() otherwise (no need to update)
   ======================================================================
:)
declare function enterprise:update-enterprise( $ref as xs:string, $data as element(), $lang as xs:string ) as xs:boolean {
  let $current := fn:doc($globals:enterprises-uri)/Enterprises/Enterprise[Id = $ref]
  let $new := enterprise:gen-enterprise-for-writing($current, $data, ())
  let $dirty-name := $current/Name/text() ne $new/Name/text()
  let $dirty-town := $current/Address/Town/text() ne $new/Address/Town/text()
  return
    if (deep-equal($current, $new)) then
      false()
    else
      (
      update replace $current with $new,
      if ($dirty-name) then cache:invalidate('enterprise', $lang) else (),
      if ($dirty-town) then cache:invalidate('town', $lang) else (),
      true()
      )[last()]
};
