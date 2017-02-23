xquery version "1.0";
(: --------------------------------------
   CCTRACKER - Oppidum Case Tracker

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   Controller to delete an Activity

   June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)
import module namespace xdb = "http://exist-db.org/xquery/xmldb";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../../lib/display.xqm";
import module namespace ajax = "http://oppidoc.com/oppidum/ajax" at "../../lib/ajax.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Checks that deleting activity is compatible with current DB state
   Currently pre-checks are sufficient since this can only be called
   from Coach assignemnt status
   ======================================================================
:)
declare function local:validate-activity-delete( $case as element(), $activity as element() ) as element()* {
  let $errors := ()
  return $errors
};

(: ======================================================================
   Deletes the activity and redirects to case if it contains no other
   activities or to the activity if it contains only one
   ======================================================================
:)
declare function local:delete-activity( $case as element(), $activity, $base as xs:string, $name as xs:string ) as element()* {
  let $case-uri := concat($base, 'cases/', $case/No)
  let $nb-activities := count($case/Activities/Activity)
  return (
    if (($nb-activities eq 1) and ($case/Activities/Activity[1]/No eq string($activity/No))) then
      update delete $case/Activities
    else
      update delete $activity,
    if ($nb-activities eq 2) then (: redirects to last remaining activity :)
      ajax:report-success-redirect('DELETE-ACTIVITY-SUCCESS', ($name, $case/Information/Acronym),
        concat($case-uri, '/activities/', $case/Activities/Activity[1]/No))
    else
      ajax:report-success-redirect('DELETE-ACTIVITY-SUCCESS', ($name, $case/Information/Acronym),
        $case-uri)
    )
};

(: *** MAIN ENTRY POINT *** :)
let $m := request:get-method()
let $cmd := oppidum:get-command()
let $lang := string($cmd/@lang)
let $case-no := tokenize($cmd/@trail, '/')[2]
let $activity-no := tokenize($cmd/@trail, '/')[4]
let $case := fn:collection($globals:cases-uri)/Case[No eq $case-no]
let $activity := $case/Activities/Activity[No = $activity-no]
let $goal := 'delete'
let $errors := access:pre-check-activity($case, $activity, $m, $goal, 'Assignment')
return
  if (empty($errors)) then
    let $cannot := local:validate-activity-delete($case, $activity)
    let $name := display:gen-activity-title($case, $activity, $lang)
    return
      if (empty($cannot)) then
        if ($m = 'DELETE' or (($m = 'POST') and (request:get-parameter('_delete', ()) eq "1"))) then (: real delete :)
          local:delete-activity($case, $activity, string($cmd/@base-url), $name)
        else if ($m = 'POST') then (: delete pre-step - POST to complicate forgery :)
          ajax:report-success('DELETE-ACTIVITY-CONFIRM', ($name, $case/Information/Acronym))
        else
          ajax:throw-error('URI-NOT-SUPPORTED', ())
      else
        $cannot
  else
    $errors
