xquery version "1.0";
(:~ 
 : Case tracker pilote
 :
 : CRUD controller to manage Case document (read and update)
 :
 : November 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
 :
 : @author Stéphane Sire <s.sire@oppidoc.fr>
 :)

import module namespace request="http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace template = "http://oppidoc.com/ns/cctracker/template" at "../../lib/template.xqm";
import module namespace misc = "http://oppidoc.com/ns/cctracker/misc" at "../../lib/util.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace ajax = "http://oppidoc.com/oppidum/ajax" at "../../lib/ajax.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(:~
 : Validates submitted data
 : @return A sequence or error elements or the empty sequence
 :)
declare function local:validate-submission( $case as element(), $submitted as element() ) as element()* {
  let $errors := (
    )
  return $errors
};

(:~
 : Updates a case document
 : @return A success or error element
 :)
declare function local:POST-document( $case as element(), $form as element(), $lang as xs:string ) {
  let $date :=  substring(string(current-dateTime()), 1, 10)
  let $src := fn:doc($globals:templates-uri)/Templates/Template[@Mode eq 'update'][@Name eq 'case']
  return
    if ($src) then
      let $delta := util:eval(string-join($src/text(), ''))
      return (
        misc:apply-updates($case, $delta),
        oppidum:throw-message('ACTION-UPDATE-SUCCESS', ())
      )
    else
      oppidum:throw-error('CUSTOM', 'Missing "case" template for update mode')
};

(:----------------------------------------------------------------------------------------------------:)
(: MAIN ENTRY POINT :)

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $lang := string($cmd/@lang)
let $case-no := tokenize($cmd/@trail, '/')[2]
let $case := fn:collection($globals:cases-uri)/Case[No eq $case-no]
let $goal := request:get-parameter('goal', 'read')
let $root := misc:rest-to-Root($cmd/resource/@name)
let $errors := access:pre-check-case($case, $m, $goal, $root)
return
  if (empty($errors)) then
    if ($m = 'POST') then
      let $submitted := oppidum:get-data()
      let $errors := local:validate-submission($case, $submitted)
      return
        if (empty($errors)) then
          local:POST-document($case, $submitted, $lang)
        else
          ajax:report-validation-errors($errors)
    else (: assumes GET :)
      template:get-document('case', $case, $lang)
  else
    $errors
