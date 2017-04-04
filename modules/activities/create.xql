xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   Controller to create a new coaching activity into workflow

   December 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace ajax = "http://oppidoc.com/oppidum/ajax" at "../../lib/ajax.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../../lib/display.xqm";
import module namespace misc = "http://oppidoc.com/ns/cctracker/misc" at "../../lib/util.xqm";
import module namespace workflow = "http://platinn.ch/coaching/workflow" at "../workflow/workflow.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Returns a confirmation message with eventually some warnings in case
   the need analysis is uncomplete. This allows to implement a two steps
   protocol for activity creation.
   ======================================================================
:)
declare function local:confirm-activity-submission( $case as element(), $needs as element()?, $lang as xs:string ) as element()* {
  if (empty($needs)) then
    oppidum:throw-error("ACTIVITY-CREATE-MISS-NEED-ANALYSIS", ())
  else
    let $check := count($needs/Impact/*/*)
    let $author := display:gen-person-name($case/Management/AccountManagerRef/text(), $lang)
    return
      if ($check > 0) then
        oppidum:throw-message("ACTIVITY-CREATE-OK-CONFIRM", $author)
      else
        oppidum:throw-message("ACTIVITY-CREATE-MISS-CONFIRM", $author)
};

(: ======================================================================
   Returns a new Activity to insert into the case 
   ======================================================================
:)
declare function local:gen-activity-for-writing( $id as xs:integer, $needs as element(), $case as element() ) {
  let $date :=  substring(string(current-dateTime()), 1, 10) 
  let $src := fn:doc($globals:templates-uri)/Templates/Template[@Mode eq 'create'][@Name eq 'activity']
  return
    if ($src) then
      misc:prune(util:eval(string-join($src/text(), '')))
    else
      oppidum:throw-error('CUSTOM', 'Missing "activity" template for create mode')
 };

(: ======================================================================
   Creates an empty coaching activity inside case with a duplicated NeedsAnalysis from the Case
   ======================================================================
:)
declare function local:create-activity( $lang as xs:string, $needs as element(), $case as element(), $baseUrl as xs:string ) {
  let $activities := $case/Activities
  return
    if ($activities) then (: simple insertion into list of Activities :)
      let $index :=
        if ($activities/@LastIndex castable as xs:integer) then
          number($activities/@LastIndex) + 1
        else (: unlikely :)
          1
      let $activity := local:gen-activity-for-writing($index, $needs, $case)
      return
        (
        update insert $activity into $activities,
        update value $activities/@LastIndex with $index,
        ajax:report-success-redirect('ACTIVITY-CREATED', string($index), concat($baseUrl, '/', $index))
        )
    else (: first one, creation of list of Activities :)
      let $activity := local:gen-activity-for-writing( 1, $needs, $case)
      let $activities :=
        <Activities LastIndex="1">
          { $activity }
        </Activities>
      return
        (
        update insert $activities into $case,
        ajax:report-success-redirect('ACTIVITY-CREATED', '1', concat($baseUrl, '/1'))
        )
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $lang := string($cmd/@lang)
let $case-no := tokenize($cmd/@trail, '/')[2]
let $case := fn:collection($globals:cases-uri)/Case[No eq $case-no]
return
  if ($case) then
    let $transition := workflow:get-transition-for('Case', '1', '-1')
    let $omissions := workflow:validate-transition($transition, $case, ())
    return
      if (count($omissions) eq 0) then
        if (($m = 'POST') and access:check-user-can('create', 'Assignment', $case)) then
          (: uses current NeedsAnalysis data inside Case which should be the similar to submitted data :)
          let $needs := $case/NeedsAnalysis
          let $confirm := if (request:get-parameter('_confirmed', '0') = '0') then
                            local:confirm-activity-submission($case, $needs, $lang)
                          else
                            ()
          return
            if (empty($confirm)) then
              local:create-activity($lang, $needs, $case, concat($cmd/@base-url,$cmd/@trail))
            else
              $confirm
        else
          oppidum:throw-error('FORBIDDEN', ())
      else if (count($omissions) gt 1) then
        let $explain :=
          string-join(
            for $o in $omissions
            let $e := ajax:throw-error($o, ())
            return $e/message/text(), '&#xa;&#xa;')
        return
          oppidum:throw-error(string($transition/@GenericError), concat('&#xa;&#xa;',$explain))
      else if (count($omissions) eq 1) then
        ajax:throw-error($omissions, ())
      else
        ()
  else
    ajax:throw-error('CASE-NOT-FOUND', ())
