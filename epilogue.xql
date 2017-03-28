xquery version "1.0";
(: --------------------------------------
   Oppidoc Business Application Development Framework

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Copy and customize this file to finalize your application page generation

   January 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace site = "http://oppidoc.com/oppidum/site";
declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "lib/globals.xqm";
import module namespace epilogue = "http://oppidoc.com/oppidum/epilogue" at "../oppidum/lib/epilogue.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "lib/access.xqm";
import module namespace view = "http://oppidoc.com/oppidum/view" at "lib/view.xqm";
(:import module namespace partial = "http://oppidoc.com/oppidum/partial" at "app/partial.xqm";:)

(: ======================================================================
   Trick to use request:get-uri behind a reverse proxy that injects
   /exist/projets/scaffold into the URL in production
   ======================================================================
:)
declare function local:my-get-uri ( $cmd as element() ) {
  concat($cmd/@base-url, $cmd/@trail, if ($cmd/@verb eq 'custom') then concat('/', $cmd/@action) else ())
};

(: ======================================================================
   Typeswitch function
   -------------------
   Plug all the <site:{module}> functions here and define them below
   ======================================================================
:)
declare function site:branch( $cmd as element(), $source as element(), $view as element()* ) as node()*
{
 typeswitch($source)
 case element(site:skin) return view:skin($cmd, $view)
 case element(site:navigation) return site:navigation($cmd, $view)
 case element(site:error) return view:error($cmd, $view)
 case element(site:message) return view:message($cmd)
 case element(site:login) return site:login($cmd)
 case element(site:field) return view:field($cmd, $source, $view)
 case element(site:conditional) return site:conditional($cmd, $source, $view)
 default return $view/*[local-name(.) = local-name($source)]/*
 (: default treatment to implicitly manage other modules :)
};

declare function local:gen-nav-class ( $name as xs:string, $target as xs:string*, $extra as xs:string?  ) as attribute()? {
  if ($name = $target) then
    attribute class { if ($extra) then concat($extra, ' active') else 'active' }
  else if ($extra) then
    attribute class { $extra }
  else
    ()
};

(: ======================================================================
   Generates <site:navigation> menu
   TODO: create markup for menu generation !
   ======================================================================
:)
declare function site:navigation( $cmd as element(), $view as element() ) as element()*
{
  let $base := string($cmd/@base-url)
  let $rsc := string(oppidum:get-resource($cmd)/@name)
  let $name := if (starts-with($cmd/@trail, 'cases')) then
                 (: filters out everything not cases/create as 'stage' :)
                 if ($cmd/@action = 'create') then 'create' else 'stage'
               else
                 $rsc
   let $user := oppidum:get-current-user()
   let $groups := oppidum:get-user-groups($user, oppidum:get-current-user-realm())
  return
    <ul class="nav">
      <li>{ local:gen-nav-class($name, 'stage', ()) }<a href="{$base}stage" loc="app.nav.stage">Stage</a></li>
      <li>
        { local:gen-nav-class($name, ('persons', 'enterprises'), 'dropdown') }
        <a class="dropdown-toggle" data-toggle="dropdown" href="#" loc="app.nav.communities">Communities</a>
        <ul class="dropdown-menu">
          <li><a href="{$base}persons" loc="app.nav.persons">Persons</a></li>
          <li><a href="{$base}enterprises" loc="app.nav.enterprises">Entreprises</a></li>
        </ul>
      </li>
      {
      if ($groups = ('admin-system', 'developer', 'account-manager')) then
        <li>
          {local:gen-nav-class($name, ('cases'), 'dropdown')}
          <a class="dropdown-toggle" data-toggle="dropdown" href="#" loc="app.nav.stats">Stats</a>
          <ul class="dropdown-menu">
            <li><a href="{$base}stats/cases" loc="app.nav.cases">Cases</a></li>
          </ul>
        </li>
      else
        ()
      }
      <li>{local:gen-nav-class($name, 'about', ())}<a href="{$base}about" loc="app.nav.guidelines">About</a></li>
      {
      if (access:check-user-can('create', 'Case')) then
        <li>{local:gen-nav-class($name, 'create', ())}<a href="{$base}cases/create" loc="app.nav.case">Case creation</a></li>
      else
        (),
      if (($user = 'admin') or ($groups = ('developer'))) then (
        <li>
          {local:gen-nav-class($name, ('forms'), 'dropdown')}
          <a class="dropdown-toggle" data-toggle="dropdown" href="#">Devel</a>
          <ul class="dropdown-menu">
            <li><a href="{$base}forms" loc="app.nav.forms">Supergrid</a></li>
            { 
            if ($cmd/@mode eq 'dev') then (
              <li><a href="{$base}/../../oppidum/test/explorer?m={$globals:app-name}">Oppidum IDE</a></li>,
              <li class="divider"></li>,
              for $item in fn:doc(oppidum:path-to-config('mapping.xml'))/*/*[@name eq 'test']/*
              return 
                <li><a href="{$base}test/{$item/@name}">{$item/string(@name)}</a></li>
              )
            else
              ()
            }
          </ul>
        </li>
        )
      else
        ()
      }
      {
      if (($user = 'admin') or $groups = ('admin-system', 'developer', 'account-manager')) then (
        <li id="c-flush-right">{local:gen-nav-class($name, 'management', ())}<a href="{$base}management" loc="app.nav.admin">Admin</a></li>
        )
      else
        ()
      }
    </ul>
};

(: ======================================================================
   Handles <site:login> LOGIN banner
   ======================================================================
:)
declare function site:login( $cmd as element() ) as element()*
{
 let
   $uri := local:my-get-uri($cmd),
   $user := oppidum:get-current-user()
 return
   if ($user = 'guest')  then
     if (not(ends-with($uri, '/login'))) then
       <a class="login" href="{$cmd/@base-url}login?url={$uri}">LOGIN</a>
     else
       <span>...</span>
   else
    let $user := if (string-length($user) > 7) then
                   if (substring($user,8,1) eq '-') then
                     substring($user, 1, 7)
                   else
                     concat(substring($user, 1, 7),'...')
                 else
                   $user
    return
      (
      <a href="{$cmd/@base-url}me" style="color:#333;text-decoration:none">{$user}</a>,
      <a class="login" href="{$cmd/@base-url}logout?url={$cmd/@base-url}">LOGOUT</a>
      )
};

(: ======================================================================
   Implements <site:conditional> in mesh files (e.g. rendering a Supergrid
   generated mesh XTiger template).

   Applies a simple logic to filter conditional source blocks.

   Keeps (/ Removes) the source when all these conditions hold true (logical AND):
   - @avoid does not match current goal (/ matches goal)
   - @meet matches current goal (/ does not match goal)
   - @flag is present in the request parameters  (/ is not present in parameters)
   - @noflag not present in request parameters (/ is present in parameters)

   TODO: move to view module with XQuery 3 (local:render as parameter)
   ======================================================================
:)
declare function site:conditional( $cmd as element(), $source as element(), $view as element()* ) as node()* {
  let $goal := request:get-parameter('goal', 'read')
  let $flags := request:get-parameter-names()
  return
    (: Filters out failing @meet AND @avoid and @noflag AND @flag :)
    if (not( 
               (not($source/@meet) or ($source/@meet = $goal))
           and (not($source/@avoid) or not($source/@avoid = $goal))
           and (not($source/@flag) or ($source/@flag = $flags))
           and (not($source/@noflag) or not($source/@noflag = $flags))
        )) 
    then
      ()
    else
      for $child in $source/node()
      return
        if ($child instance of element()) then
          (: FIXME: hard-coded 'site:' prefix we should better use namespace-uri
                    - currently limited to site:field :)
          if (starts-with(xs:string(node-name($child)), 'site:field')) then
            view:field($cmd, $child, $view)
          else
            local:render($cmd, $child, $view)
        else
          $child
};

(: ======================================================================
   Recursive rendering function
   ----------------------------
   Copy this function as is inside your epilogue to render a mesh
   TODO: move to view module with XQuery 3 (site:branch as parameter)
   ======================================================================
:)
declare function local:render( $cmd as element(), $source as element(), $view as element()* ) as element()
{
  element { node-name($source) }
  {
    $source/@*,
    for $child in $source/node()
    return
      if ($child instance of text()) then
        $child
      else
        (: FIXME: hard-coded 'site:' prefix we should better use namespace-uri :)
        if (starts-with(xs:string(node-name($child)), 'site:')) then
          (
            if (($child/@force) or
                ($view/*[local-name(.) = local-name($child)])) then
                 site:branch($cmd, $child, $view)
            else
              ()
          )
        else if ($child/*) then
          if ($child/@condition) then
          let $go :=
            if (string($child/@condition) = 'has-error') then
              oppidum:has-error()
            else if (string($child/@condition) = 'has-message') then
              oppidum:has-message()
            else if ($view/*[local-name(.) = substring-after($child/@condition, ':')]) then
                true()
            else
              false()
          return
            if ($go) then
              local:render($cmd, $child, $view)
            else
              ()
        else
           local:render($cmd, $child, $view)
        else
         $child
  }
};

(: ======================================================================
   Epilogue entry point
   ======================================================================
:)
let $mesh := epilogue:finalize()
let $cmd := request:get-attribute('oppidum.command')
let $sticky := false() (: TODO: support for forthcoming local:translation-agent() :)
let $lang := $cmd/@lang
let $dico := fn:doc($globals:dico-uri)/site:Dictionary/site:Translations[@lang = $lang]
let $isa_tpl := contains($cmd/@trail,"templates/") or ends-with($cmd/@trail,"/template")
let $maintenance := view:filter-for-maintenance($cmd, $isa_tpl)
return
  if ($mesh) then
    let $type := if (matches($cmd/@trail, "^test/|^calls/|activities/") or $isa_tpl) then
                   "application/xhtml+xml"
                 else
                   "text/html"
    let $page := local:render($cmd, $mesh, oppidum:get-data())
    return (
      util:declare-option("exist:serialize", concat("method=html5 media-type=", $type, " encoding=utf-8 indent=yes")),
      view:localize($dico, $page, $sticky)
      )
  else
    view:localize($dico, oppidum:get-data(), $sticky)
