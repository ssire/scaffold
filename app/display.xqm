xquery version "1.0";
(: --------------------------------------
   SCAFFOLD - Case tracker pilote library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Database content dependent access control functions

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace display = "http://oppidoc.com/oppidum/display/app";

import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../lib/globals.xqm";
import module namespace display_ = "http://oppidoc.com/oppidum/display" at "../lib/display.xqm";

(: ======================================================================
   Generates an enterprise name from a reference to an enterprise
   ======================================================================
:)
declare function display:gen-enterprise-name( $ref as xs:string?, $lang as xs:string ) {
  if ($ref) then
    let $p := fn:doc($globals:enterprises-uri)/Enterprises/Enterprise[Id = $ref]
    return
      if ($p) then
        $p/Name/text()
      else
        display_:noref($ref, $lang)
  else
    ""
};