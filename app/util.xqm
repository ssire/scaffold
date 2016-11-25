xquery version "1.0";
(: --------------------------------------
   SCAFFOLD - Case tracker pilote library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Utilities

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace misc = "http://oppidoc.com/ns/cctracker/misc/app";

import module namespace _display = "http://oppidoc.com/oppidum/display/app" at "../lib/display.xqm";

(: ======================================================================
   Generates an element with a given tag holding the display name of the enterprise
   passed as a parameter and its reference as content
   ======================================================================
:)
declare function misc:unreference-enterprise( $ref as element()?, $tag as xs:string, $lang as xs:string ) as element() {
  let $sref := $ref/text()
  return
    element { $tag }
      {(
      attribute { '_Display' } { _display:gen-enterprise-name($sref, $lang) },
      $sref
      )}
};