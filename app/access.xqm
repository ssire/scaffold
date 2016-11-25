xquery version "1.0";
(: --------------------------------------
   SCAFFOLD - Case tracker pilote library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Database content dependent access control functions

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace access = "http://oppidoc.com/oppidum/access/app";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../lib/globals.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";

(: ======================================================================
   Tests current user is compatible with semantic role and given resource
   Implement this function if your application defines semantic roles
   ======================================================================
:)
declare function access:assert-semantic-role( $role as xs:string, $resource as element()? ) as xs:boolean {
  (: unimplemented in SCAFFOLD :)
  let $res := false()
  return false()
};
