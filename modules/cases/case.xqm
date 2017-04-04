xquery version "1.0";
(: ------------------------------------------------------------------
   Case tracker pilote

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Utilities for case creation either single one or batch import

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace cases = "http://oppidoc.fr/ns/ctracker/cases";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace compat = "http://oppidoc.com/oppidum/compatibility" at "../../../oppidum/lib/compat.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";

(: ======================================================================
   Creates a new collection inside the home collection for Case collections
   Returns a pair : (new case collection URI, new case index)
   or the empty sequence in case of failure. Sets hard coded permissions.
   ======================================================================
:)
declare function cases:create-case-collection( $date as xs:string ) as xs:string* {
  let $spec := fn:doc(concat('/db/www/', $globals:app-name, '/config/database.xml'))//Entity[@Name = 'case']
  let $policy := fn:doc(concat('/db/www/', $globals:app-name, '/config/database.xml'))//Policy[@Name = $spec/@Policy]
  (: FIXME: use a @LastIndex scheme :)
  let $index :=
        if (fn:collection($globals:cases-uri)/Case/No) then (: bootstrap :)
          max(
            for $key in fn:collection($globals:cases-uri)/Case/No
            return if ($key castable as xs:integer) then number($key) else 0
            ) + 1
        else
          1
  return
    let $year := substring($date, 1, 4)
    let $month := substring($date, 6, 2)
    let $home-year-col-uri := concat($globals:cases-uri, '/', $year)
    let $home-col-uri := concat($home-year-col-uri, '/', $month)
    return (
      (: Lazy creation of home collection with YEAR :)
      if (not(xdb:collection-available($home-year-col-uri))) then
        if (xdb:create-collection($globals:cases-uri, $year)) then
          compat:set-owner-group-permissions($home-year-col-uri, $policy/@Owner, $policy/@Group, $policy/@Perms)
        else
         ()
      else
        (),
      (: Lazy creation of home collection with MONTH :)
      if (not(xdb:collection-available($home-col-uri))) then
        if (xdb:create-collection($home-year-col-uri, $month)) then
          compat:set-owner-group-permissions($home-col-uri, $policy/@Owner, $policy/@Group, $policy/@Perms)
        else
         ()
      else
        (),
      (: Case collection creation :)
      let $col-uri := concat($home-col-uri, '/', $index)
      return
        if (not(xdb:collection-available($col-uri))) then
          if (xdb:create-collection($home-col-uri, string($index))) then
            let $perms := compat:set-owner-group-permissions($col-uri, $policy/@Owner, $policy/@Group, $policy/@Perms)
            return
              ($col-uri, string($index))
          else
            ()
        else
          ($col-uri, string($index))
      )
};

