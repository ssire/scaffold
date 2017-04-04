xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   CRUD controller to manage Assignment document inside Activity workflow.

   November 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
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
  if (string-length(normalize-space(string-join($submitted/Description/Text, ' '))) > 1000) then
    let $length := string-length(normalize-space(string-join($submitted/Description/Text, ' ')))
    return
      oppidum:throw-error('CUSTOM', concat("The commentary associated to the SME's expectation contains ", $length, ' characters; you must remove at least ', $length - 1000, ' characters to remain below 1000 characters'))
  else
    ()
};

(: ======================================================================
   Returns a forward element to include in Ajax response
   FIXME: hard coded status, l14n
   ======================================================================
:)
declare function local:gen-forward-notification( $case as element(), $activity as element() ) as element()* {
  if (access:assert-transition('1', '2', $case, $activity)) then
    (
    <forward command="autoexec">ae-advance</forward>,
    <confirmation>Do you want to move to Coaching plan now ?</confirmation>
    )
  else 
    ()
};

(: ======================================================================
   Replaces Assignment document inside existing activity inside case
   FIXME: pass $forward to misc:save-content
   ======================================================================
:)
declare function local:save-assignment( $lang as xs:string, $submitted as element(), $case as element(), $activity as element() ) {
  let $result := template:save-document('assignment', $case, $activity, $submitted)
  return 
    if (local-name($result) eq 'success') then (: Rewrite response to insert forward command :)
      <success>
       {
         $result/*,
        local:gen-forward-notification($case, $activity)
       }
      </success>
    else
      $result
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $lang := string($cmd/@lang)
let $case-no := tokenize($cmd/@trail, '/')[2]
let $activity-no := tokenize($cmd/@trail, '/')[4]
let $case := fn:collection($globals:cases-uri)/Case[No eq $case-no]
let $activity := $case/Activities/Activity[No = $activity-no]
let $goal := request:get-parameter('goal', 'read')
let $errors := access:pre-check-activity($case, $activity, $m, $goal, 'Assignment')
return
  if (empty($errors)) then
    if ($m = 'POST') then
      let $submitted := oppidum:get-data()
      let $errors := local:validate-submission($submitted)
      return
        if (empty($errors)) then
          local:save-assignment($lang, $submitted, $case, $activity)
        else
          ajax:report-validation-errors($errors)
    else (: assumes GET on assignment :)
      template:get-document('assignment', $case, $activity, $lang)
  else
    $errors
