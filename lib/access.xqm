xquery version "1.0";
(: --------------------------------------
   Oppidoc Business Application Development Framework

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Access control functions
   Implements access control micro-language in application.xml

   Can be used :
   - to control display of command buttons in the user interface
   - fine grain access to CRUD controllers

   Conventions :
   - assert:check-* : high-level boolean functions to perform a check
   - access:assert-* : low-level interpretor functions

   Do not forget to also set mapping level <access> rules to prevent URL forgery !

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)
module namespace access = "http://oppidoc.com/oppidum/access";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "globals.xqm";
import module namespace user = "http://oppidoc.com/ns/user" at "user.xqm";
import module namespace custom = "http://oppidoc.com/ns/application/custom" at "../app/custom.xqm";

(: ======================================================================
   Interprets Omnipotent access control rule (see application.xml)
   Returns true if current user is allowed to do anything
   ======================================================================
:)
declare function access:check-omnipotent-user() as xs:boolean {
  let $security-model := fn:doc($globals:application-uri)/Application/Security
  let $rules := $security-model/Omnipotent
  let $user := oppidum:get-current-user()
  let $groups := oppidum:get-current-user-groups()
  return
    (empty($rules/Meet) or (some $rule in $rules/Meet satisfies access:assert-rule($user, $groups, $rule, ())))
    and
    (empty($rules/Avoid) or not(some $rule in $rules/Avoid satisfies access:assert-rule($user, $groups, $rule, ())))
};

(: ======================================================================
   Returns true() if the user profile is omniscient (i.e. can see everything)
   ======================================================================
:)
declare function access:check-omniscient-user( $profile as element()? ) as xs:boolean {
  some $function-ref in $profile//FunctionRef
  satisfies $function-ref = globals:get-normative-selector-for('Functions')/Option[@Sight = 'omni']/Id
};

(: ======================================================================
   Implements Allow access control rules
   Currently limited to comma separated list of g:token
   TODO: implement s:omni for omniscient users
   ======================================================================
:)
declare function access:check-rule( $rule as xs:string? ) as xs:boolean {
  if (empty($rule) or ($rule eq '')) then
    true()
  else
    let $user := oppidum:get-current-user()
    let $groups := oppidum:get-current-user-groups()
    let $allowed := tokenize($rule,"\s*g:")[. ne '']
    return
        if ($groups = $allowed) then
          true()
        else
          access:check-rules($user, $allowed)
};

(: ======================================================================
   Checks user has at least one of the given roles
   ======================================================================
:)
declare function access:check-rules( $user as xs:string, $roles as xs:string* ) as xs:boolean {
  some $ref in fn:collection($globals:global-info-uri)//Description[@Role = 'normative']//Selector[@Name eq 'Functions']/Option[@Role = $roles]/Id
  satisfies fn:doc($globals:persons-uri)//Person/UserProfile[Username eq $user]//FunctionRef = $ref
};

(: ======================================================================
   Interprets application access control rules (see application.xml)
   Context independent version: returns true() if current user is allowed
   to do some action on a given type of resource independently of its content
   ======================================================================
:)
declare function access:check-user-can( $action as xs:string, $type as xs:string ) (:as xs:boolean:) {
  let $security-model := fn:doc(oppidum:path-to-config('application.xml'))//Security/Resources/Resource[@Name = $type]
  let $rules := $security-model/Action[@Type eq $action]
  return
    access:assert-access-rules($rules, ())
};

(: ======================================================================
   Interprets application access control rules (see application.xml)
   Mono-dimensional version with one context resource: returns true() if
   current user is allowed to do some action on a given resource of a given type
   ======================================================================
:)
declare function access:check-user-can( $action as xs:string, $type as xs:string, $resource as element()? ) as xs:boolean {
  let $security-model := fn:doc(oppidum:path-to-config('application.xml'))//Security/Resources/Resource[@Name = $type]
  let $rules := $security-model/Action[@Type eq $action]
  return
    access:assert-access-rules($rules, $resource)
};

(: ======================================================================
   Tests if action on the document of given case or activity is allowed.
   The document is identified by its root element name.
   Returns true if allowed or false otherwise
   ======================================================================
:)
declare function access:check-user-can( $action as xs:string, $root as xs:string, $case as element(), $activity as element()? ) as xs:boolean {
  let $control := fn:doc($globals:application-uri)/Application/Security/Documents/Document[@Root = $root]
  let $rules := $control/Action[@Type eq $action]
  return
    if (access:assert-user-role-for($action, $control, $case, $activity)) then
      let $item := if ($activity) then $activity else $case
      let $workflow := if ($activity) then 'Activity' else 'Case'
      return
        access:assert-workflow-state($action, $workflow, $control, $item/StatusHistory/CurrentStatusRef/text())
    else
      false()
};

(: ======================================================================
   Interprets sight role token from role specificiation micro-language
   Sight defines an transversal roles independent of context
   ======================================================================
:)
declare function access:assert-sight( 
  $suffix as xs:string 
  ) as xs:boolean 
{
  let $groups-ref := fn:collection($globals:global-info-uri)//Description[@Role = 'normative']/Selector[@Name eq 'Functions']/Option[@Sight eq $suffix]/Id/text()
  let $user-profile := user:get-current-person-profile()
  return
    $user-profile//FunctionRef = $groups-ref
};

(: ======================================================================
   Interprets access control rules micro-language (Meet | Avoid)* against 
   an optional single resource
   ======================================================================
:)
declare function access:assert-access-rules( 
  $rules as element()?, 
  $resource as element()? 
  ) as xs:boolean
{
  let $user := oppidum:get-current-user()
  let $groups := oppidum:get-current-user-groups()
  return
    if (empty($rules/Meet[@Policy eq 'strict']) and access:check-omnipotent-user()) then
      true()
    else
      (empty($rules/Meet) or (some $rule in $rules/Meet satisfies access:assert-rule($user, $groups, $rule, $resource)))
      and
      (empty($rules/Avoid) or not(some $rule in $rules/Avoid satisfies access:assert-rule($user, $groups, $rule, $resource)))
      and
      (exists($rules/Meet) or exists($rules/Avoid))
};

(: ======================================================================
   Interprets access control rules micro-language (Meet | Avoid)* against 
   a case and an optional activity
   @return An xs:boolean
   ======================================================================
:)
declare function access:assert-access-rules( 
  $rules as element()?, 
  $case as element()?, 
  $activity as element()? 
  ) as xs:boolean 
{
  let $user := oppidum:get-current-user()
  let $groups := oppidum:get-current-user-groups()
  return
    if (empty($rules/Meet[@Policy eq 'strict']) and access:check-omnipotent-user()) then
      true()
    else
      (empty($rules/Meet) or (some $rule in $rules/Meet satisfies access:assert-rule($user, $groups, $rule/text(), $case, $activity)))
      and
      (empty($rules/Avoid) or not(some $rule in $rules/Avoid satisfies access:assert-rule($user, $groups, $rule/text(), $case, $activity)))
      and
      (exists($rules/Meet) or exists($rules/Avoid))
};

(: ======================================================================
   Interprets role specification micro-language (role tokens)
   with or without context dependent resource
   ======================================================================
:)
declare function access:assert-rule( 
  $user as xs:string, 
  $groups as xs:string*, 
  $rule as element()?, 
  $resource as element()? 
  ) as xs:boolean 
{
  if ($rule/@Format eq 'eval') then
    util:eval($rule/text())
  else
    some $token in tokenize($rule, " ")
      satisfies
        let $prefix := substring-before($token, ':')
        let $suffix := substring-after($token, ':')
        return
          (($prefix eq 'u') and ($user eq $suffix))
          or (($prefix eq 'g') and ($groups = $suffix))
          or (($prefix eq 'r') and custom:assert-semantic-role($suffix, $resource))
          or (($prefix eq 's') and access:assert-sight($suffix))
};

(: ======================================================================
   Returns true if any of the token role definition from the rule
   yields for current user, groups, case, optional activity
   ======================================================================
:)
declare function access:assert-rule( 
  $user as xs:string, 
  $groups as xs:string*, 
  $rule as xs:string, 
  $case as element()?, 
  $activity as element()? 
  ) as xs:boolean 
{
  some $token in tokenize($rule, " ")
    satisfies
      let $prefix := substring-before($token, ':')
      let $suffix := substring-after($token, ':')
      return
        (($prefix eq 'u') and ($user eq $suffix))
        or (($prefix eq 'g') and ($groups = $suffix))
        or (($prefix eq 'r') and custom:assert-semantic-role($suffix, $case, $activity))
        or (($prefix eq 's') and access:assert-sight($suffix)) (: FIXME: actually only 'omni' sight :)
        or false()
};

(: ======================================================================
   Tests access control model against a given action
   Context independent version
   ======================================================================
:)
declare function access:assert-user-role-for( $action as xs:string, $control as element()? ) as xs:boolean {
  let $rules := $control/Action[@Type eq $action]
  return
    if (empty($rules)) then
      if ($action = 'read') then (: enabled by default, mapping level should block non member users :)
        true()
      else (: any other action requires an explicit rule :)
        false()
    else
      access:assert-access-rules($rules, ())
};

(: ======================================================================
   Tests access control model against a given action on a given case or activity for current user
   Returns a boolean
   ======================================================================
:)
declare function access:assert-user-role-for( $action as xs:string, $control as element()?, $case as element(), $activity as element()? ) {
  let $rules := $control/Action[@Type eq $action]
  return
    if (empty($rules)) then
      if ($action = 'read') then (: enabled by default, mapping level should block non membres of users :)
        true()
      else (: any other action requires an explicit rule :)
        false()
    else
      access:assert-access-rules($rules, $case, $activity)
};

(: ======================================================================
   Tests access control model against a given action on a given worklow actually in cur status
   Returns true if workflow status compatible with action, false otherwise
   See also workflow:gen-information in worklow/workflow.xqm
   ======================================================================
:)
declare function access:assert-workflow-state( $action as xs:string, $workflow as xs:string, $control as element(), $cur as xs:string ) as xs:boolean {
  let $rule :=
    if ($control/@TabRef) then (: main document on accordion tab :)
      fn:doc($globals:application-uri)//Workflow[@Id eq $workflow]/Documents/Document[@Tab eq string($control/@TabRef)]/Action[@Type eq $action]
    else (: satellite document in modal window :)
      let $host := fn:doc($globals:application-uri)//Workflow[@Id eq $workflow]//Host[@RootRef eq string($control/@Root)]
      return
        if ($host/Action[@Type eq $action]) then
          $host/Action[@Type eq $action]
        else
          $host/parent::Document/Action[@Type eq $action]
  return
    empty($rule)
      or $rule[$cur = tokenize(string(@AtStatus), " ")]
};

(: ======================================================================
   Implements one specific Assert element on Transition element from application.xml
   for item which may be a Case or an Activity
   Checks first current status compatibility with transition
   ====================================================================== 
:)
declare function access:assert-transition-partly( $item as element(), $assert as element()?, $subject as element()?) as xs:boolean {
  let $transition := $assert/parent::Transition
  return
    if ($transition and ($item/StatusHistory/CurrentStatusRef eq string($transition/@From))) then
      let $rules := $assert/true
      let $base := $subject
      return 
        if (count($rules) > 0) then
          every $expr in $rules satisfies util:eval($expr/text())
        else 
          false()
    else
      false()
};

(: ======================================================================
   Returns true if the transition is allowed for case or activity for current user,
   or false otherwise
   Pre-condition :
   YOU MUST obtain the transition by a call to workflow:get-transition-for() to be sure
   the transition is feasible from the current state, otherwise you will not be able
   to interpret the false result
   ======================================================================
:)
declare function access:check-status-change( $transition as element(), $case as element(), $activity as element()? ) as xs:boolean {
  let $status :=
    if ($activity) then
      $activity/StatusHistory/CurrentStatusRef/text()
    else
      $case/StatusHistory/CurrentStatusRef/text()
  return
    if ($transition/@From = $status) then (: see pre-condition :)
      access:assert-access-rules($transition, $case, $activity)
    else
      false()
};

(: ======================================================================
   "All in one" utility function
   Checks case exists and checks user has rights to execute the goal action 
   with the given method on the given root document or has access to 
   the whole case if the root is undefined
   Either throws an error (and returns it) or returns the empty sequence
   ======================================================================
:)
declare function access:pre-check-case(
  $case as element()?,
  $method as xs:string,
  $goal as xs:string?,
  $root as xs:string? ) as element()*
{
  if (empty($case)) then
    oppidum:throw-error('CASE-NOT-FOUND', ())
  else if (not(access:check-user-can('open', $case))) then
    oppidum:throw-error("CASE-FORBIDDEN", $case/Title/text())
  else if ($root) then 
    (: access to a specific case document :)
    if (access:check-user-can(if ($method eq 'GET') then 'read' else 'update', $root, $case, ())) then
      ()
    else
      oppidum:throw-error('FORBIDDEN', ())
  else if ($method eq 'GET') then
    (: access to case workflow view :)
    ()
  else
    oppidum:throw-error("URI-NOT-FOUND", ())
};

