xquery version "1.0";
(: --------------------------------------
   Oppidoc Case Tracker application

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   Activities Workflow Status controller.
   Manages POST submission to change workflow status.

   Returns either success with a Location header to redirect the page,
   or an error message

   November 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace ajax = "http://oppidoc.com/oppidum/ajax" at "../../lib/ajax.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace workflow = "http://platinn.ch/coaching/workflow" at "../workflow/workflow.xqm";
import module namespace alert = "http://oppidoc.com/ns/cctracker/alert" at "../workflow/alert.xqm";

declare option exist:serialize "method=xml media-type=application/xml";

(: ======================================================================
   Implements @Launch attribute on Transition element to launch external 
   service before entering a new status (see in application.xml)
   Returns an error if service could not be started or the empty sequence
   ======================================================================
:)
declare function local:launch-services( $transition as element(), $case as element(), $activity as element() ) as element()? {
  let $pass := ()
  return $pass
};

(: MAIN ENTRY POINT :)
let $m := request:get-method()
let $cmd := oppidum:get-command()
let $case-no := tokenize($cmd/@trail, '/')[2]
let $case := fn:collection($globals:cases-uri)/Case[No = $case-no]
let $activity-no := tokenize($cmd/@trail, '/')[4]
let $activity := $case/Activities/Activity[No = $activity-no]
let $transition := workflow:pre-check-transition($m, 'Activity', $case, $activity)
return
  if (local-name($transition) eq 'error') then (: exit on error :)
    $transition
  else
    let $stop := local:launch-services($transition, $case, $activity)
    return
      if (exists($stop)) then (: exit on error :)
        $stop
      else (: TODO: factorize with status.xql in cases from this point ? :)
        let $errors := workflow:apply-transition($transition, $case, $activity)
        return
          if ($errors) then
            $errors
          else
            let $success := ajax:report-success-redirect('WFSTATUS-UPDATED', (), 
                              concat($cmd/@base-url, replace($cmd/@trail,'/status','')))
            return
              (: TODO: implement local:finish-status-change($transition, $case, $activity) if more side effects needed :)
              let $response := workflow:apply-notification('Activity', $success, $transition, $case, $activity)
              return 
                (: filters response to short-circuit notification if no recipients :)
                if (empty($transition/Recipients) and empty($response/done)) then 
                  <success>
                    <done/>
                    { $response/* }
                  </success>
                else
                  $response
