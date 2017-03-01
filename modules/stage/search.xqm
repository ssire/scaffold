xquery version "1.0";
(: --------------------------------------
   Case tracker pilote application

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Stage request handling

   November 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace search = "http://platinn.ch/coaching/search";

import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace user = "http://oppidoc.com/ns/user" at "../../lib/user.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../../lib/display.xqm";
import module namespace misc = "http://oppidoc.com/ns/cctracker/misc" at "../../lib/util.xqm";

(: ======================================================================
   Returns the saved search request in the user's profile if it exists
   or a default one otherwise
   ======================================================================
:)
declare function search:get-default-request () as element() {
  let $profile := user:get-user-profile()
  return
    if ($profile/SearchStageRequest) then
      $profile/SearchStageRequest
    else
      <Request/>
};

(: ======================================================================
   Generates one result row
   ======================================================================
:)
declare function local:gen-result-sample ( $lang as xs:string ) as element()? {
  let $sample := ()
  return <Result><Column>Edit /modules/stage/search.[xqm,.xsl] to generate search results</Column></Result>
};

(: ======================================================================
   Generates Case information fields to display in result table for a given case
   FIXME: hard-coded status name
   ======================================================================
:)
declare function local:gen-case-sample ( $c as element(), $lang as xs:string ) as element()* {
  let $e := fn:doc($globals:enterprises-uri)/Enterprises/Enterprise[Id = $c/Information/ClientEnterprise/EnterpriseRef/text()]
  let $manager := $c/Management/AccountManagerRef
  return
    (
    <Enterprise>
      { $e/Id, $e/Name }
    </Enterprise>,
    $e/Address/Country,
    $c/No,
    $c/Information/Title,
    misc:gen_display_name($c/Information/Call/PhaseRef , 'Phase'),
    <Date>{ display:gen-display-date($c/Information/Call/Date, $lang) }</Date>,
    <Grant>{ display:gen-display-date($c/Information/Contract/Date, $lang) }</Grant>,
    <Coach>
      {
      if ($manager[. ne '']) then (
        <Id>{$manager/text()}</Id>,
        <FullName>{ display:gen-person-name($manager/text(), $lang) }</FullName>
        )
      else if ($c/StatusHistory/CurrentStatusRef = ('1', '9', '10')) then
        <No/>
      else if ($c/StatusHistory/CurrentStatusRef eq '2') then   
        <Soon/>
      else 
        <Miss/>
      }
    </Coach>,
    if (empty($c/Activities/Activity)) then
      <Status>{ display:gen-name-for('CaseWorkflowStatus', $c/StatusHistory/CurrentStatusRef, $lang) }</Status>
    else
      ()
    )
};

(: ======================================================================
   Generates Activity information fields to display in result table for a given activity
   FIXME: hard-coded status name
   ======================================================================
:)
declare function local:gen-activity-sample ( $a as element(), $lang as xs:string ) as element() {
  let $coach-id := $a/Assignment/ResponsibleCoachRef/text()
  return
    <Activity>
      { $a/@legacy }
      { $a/No }
      <Title>TO BE DONE</Title>
      <Coach>
        {
        if ($coach-id) then (
          <Id>{ $coach-id }</Id>,
          <FullName>{ display:gen-person-name($coach-id, $lang) }</FullName>
          )
        else if ($a/StatusHistory/CurrentStatusRef eq '1') then
          <Soon/>
        else
          <Miss/>
        }
      </Coach>
      <Status>{ display:gen-name-for('ActivityWorkflowStatus', $a/StatusHistory/CurrentStatusRef, $lang) }</Status>
    </Activity>
};

declare function local:open-access( $all as xs:boolean, $case as xs:boolean?, $activity as xs:boolean? ) as attribute()?
{
  if ($all and empty($case) and empty($activity)) then (: top-level call :)
    attribute { 'Open' } { 'y' }
  else if (not($all) and $case and empty($activity)) then (: case level call :)
    attribute { 'Open' } { 'y' }
  else if (not($all) and $activity) then (: activity level call :)
    attribute { 'Open' } { 'y' }
  else
    ()
};

(: ======================================================================
   Returns all results w/o any filtering
   ====================================================================== 
:)
declare function search:find-stage-results ( $lang as xs:string ) as element() {
  (: --- access control layer --- :)
  let $profile := user:get-user-profile()
  let $omni-sight := access:check-omniscient-user($profile)
  let $person := $profile/ancestor::Person  
  return
    <Cases Scope="All">
      { 
      local:open-access($omni-sight, (), ()),
      for $c in fn:collection($globals:cases-uri)//Case
      let $can-case := $omni-sight or access:check-user-can('open', $c)
      return
        <Case>
          { local:open-access($omni-sight, $can-case, ()) }
          { local:gen-case-sample($c, $lang) }
          <Activities>
            {
            for $a in $c/Activities/Activity
            order by $a/CreationDate
            return local:gen-activity-sample($a, $lang)
            }
          </Activities>
        </Case>
      }
    </Cases>
};

(: ======================================================================
   Returns filtered results by criteria
   ====================================================================== 
:)
declare function search:find-stage-results ( $filter as element(), $lang as xs:string ) as element()* {
  (: --- access control layer --- :)
  let $profile := user:get-user-profile()
  let $omni-sight := access:check-omniscient-user($profile)
  let $person := $profile/ancestor::Person

  (: --- enterprise criteria --- :)
  let $country := $filter//Country
  let $filter-enterprise := not(empty(($country)))

  return
    <Cases>
      { 
      local:open-access($omni-sight, (), ()),
      for $c in fn:collection($globals:cases-uri)//Case
      let $e := if ($filter-enterprise) then
                  fn:doc($globals:enterprises-uri)//Enterprise[Id eq $c/Information/ClientEnterprise/EnterpriseRef]
                else
                  ()
      where 
        (: --- client enterprise filter --- :)
        (
          not($filter-enterprise) or
          (empty($country) or $e//Country = $country)
        )
      return
        let $can-case := $omni-sight or access:check-user-can('open', $c)
        return
          <Case>
            { local:open-access($omni-sight, $can-case, ()) }
            { local:gen-case-sample($c, $lang) }
            <Activities>
              {
              for $a in $c/Activities/Activity
              order by $a/CreationDate
              return local:gen-activity-sample($a, $lang)
              }
            </Activities>
          </Case>
      }
    </Cases>
};

(: ======================================================================
   Returns Cases and Activities matching request
   also returns individual Coach modal windows
   TODO: return Enterprise modal windows
   ======================================================================
:)
declare function search:fetch-stage-results ( $request as element() , $lang as xs:string ) as element()* {
  if ((count($request/*/*) + count($request/*[local-name(.)][normalize-space(.) != ''])) = 0) then (: empty request :)
    if (request:get-parameter('_confirmed', '0') = '0') then
      (
      <Confirm/>,
      response:set-status-code(202)
      )
    else
    <Results>{ search:find-stage-results($lang) }</Results>
  else
    <Results>{ search:find-stage-results($request, $lang) }</Results>
};
