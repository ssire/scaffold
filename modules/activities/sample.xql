xquery version "1.0";
(: --------------------------------------
   CCTRACKER - Oppidum Case Tracker

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   Generic CRUD controller to manage sample documents into Activity workflow

   March 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace template = "http://oppidoc.com/ns/cctracker/template" at "../../lib/template.xqm";
import module namespace misc = "http://oppidoc.com/ns/cctracker/misc" at "../../lib/util.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace ajax = "http://oppidoc.com/oppidum/ajax" at "../../lib/ajax.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Validates submitted data.
   Returns a list of errors to report or the empty sequence.
   ======================================================================
:)
declare function local:validate-submission( $submitted as element() ) as element()* {
  let $errors := (
    )
  return $errors
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $lang := string($cmd/@lang)
let $case-no := tokenize($cmd/@trail, '/')[2]
let $activity-no := tokenize($cmd/@trail, '/')[4]
let $case := fn:collection($globals:cases-uri)/Case[No eq $case-no]
let $activity := $case/Activities/Activity[No = $activity-no]
let $goal := request:get-parameter('goal', 'read')
let $target := $cmd/resource/@name
let $root := request:get-attribute('xquery.root')
let $errors := access:pre-check-activity($case, $activity, $m, $goal, $root)
return
  if (empty($errors)) then
    if ($m = 'POST') then
      let $submitted := oppidum:get-data()
      let $errors := local:validate-submission($submitted)
      return
        if (empty($errors)) then
          template:save-vanilla($root, $case, $activity, $submitted)
        else
          ajax:report-validation-errors($errors)
    else (: assumes GET on assignment :)
      template:get-vanilla($root, $case, $activity, $lang)
  else
    $errors
