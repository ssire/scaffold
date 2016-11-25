xquery version "1.0";
(: --------------------------------------
   Case tracker pilote library

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
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../lib/globals.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace _access = "http://oppidoc.com/oppidum/access/app" at "../app/access.xqm";

(: ======================================================================
   Returns the Id of the current user or () if the current user
   is not associated with a person in the databse.
   ======================================================================
:)
declare function access:get-current-person-id () as xs:string? {
  access:get-current-person-id (oppidum:get-current-user())
};

declare function access:get-current-person-profile() as element()? {
  let $realm := oppidum:get-current-user-realm()
  let $user := oppidum:get-current-user()
  return
    if (empty($realm)) then
      fn:doc($globals:persons-uri)/Persons/Person/UserProfile[Username eq $user]
    else
      fn:doc($globals:persons-uri)/Persons/Person/UserProfile[Remote[@Name eq $realm] eq $user]
};

(: ======================================================================
   Variant of the above function when the current user is known
   ======================================================================
:)
declare function access:get-current-person-id ( $user as xs:string ) as xs:string? {
  let $realm := oppidum:get-current-user-realm()
  return
    if (empty($realm)) then
      fn:doc($globals:persons-uri)/Persons/Person/UserProfile[Username eq $user]/Id/text()
    else
      fn:doc($globals:persons-uri)/Persons/Person/UserProfile[Remote[@Name eq $realm] eq $user]/Id/text()
};

(: ======================================================================
   Returns the function reference corresponding to a role identified by its name
   Returns the empty sequence in case role unknown or empty input
   This is mainly to ease up code maintenance
   ======================================================================
:)
declare function access:get-function-ref-for-role( $roles as xs:string* ) as xs:string*  {
  if (exists($roles)) then
    fn:collection($globals:global-info-uri)//Description[@Role = 'normative']/Selector[@Name eq 'Functions']/Option[@Role = $roles]/Id/text()
  else
    ()
};

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
  satisfies $function-ref = fn:collection($globals:global-info-uri)//Description[@Role = 'normative']/Selector[@Name eq 'Functions']/Option[@Sight = 'omni']/Id
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
   Interprets sight role token from role specificiation micro-language
   Sight defines an transversal roles independent of context
   ======================================================================
:)
declare function access:assert-sight( $suffix as xs:string ) as xs:boolean {
  let $groups-ref := fn:collection($globals:global-info-uri)//Description[@Role = 'normative']/Selector[@Name eq 'Functions']/Option[@Sight eq $suffix]/Id/text()
  let $user-profile := access:get-current-person-profile()
  return
    $user-profile//FunctionRef = $groups-ref
};

(: ======================================================================
   Interprets access control rules micro-language (Meet | Avoid)*
   ======================================================================
:)
declare function access:assert-access-rules( $rules as element()?, $resource as element()? ) (:as xs:boolean:) {
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
   Interprets role specification micro-language (role tokens)
   with or without context dependent resource
   ======================================================================
:)
declare function access:assert-rule( $user as xs:string, $groups as xs:string*, $rule as element()?, $resource as element()? ) as xs:boolean {
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
          or (($prefix eq 'r') and _access:assert-semantic-role($suffix, $resource))
          or (($prefix eq 's') and access:assert-sight($suffix))
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
