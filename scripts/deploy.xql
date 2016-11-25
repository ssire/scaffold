xquery version "1.0";
(: --------------------------------------
   Case tracker pilote application

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Utility to deploy the application after a code update on file system with git

   You can use it for initial deployment or for maintenance updates,
   do not forget to separately restore the application data and/or system collection (users accounts)

   PRE-CONDITIONS :
   - scripts/bootstrap.sh has been executed first (to install mapping.xml inside database)
   - must be called from the server (e.g.: using curl or wget)
   - admin password must be provided as a pwd parameter

   SYNOPSIS :
   curl -i [or wget -O-] http:127.0.0.1:[PORT]/exist/projects/scaffold/admin/deploy?pwd=[PASSWORD]&t=[TARGETS]

   TARGETS (users,policies,forms,caches,debug,indexes,config,mesh,templates,jobs,services)
   - forms : generate all formulars with supergrid (see $formulars in this script)

   JOBS:
   curl -i "http://localhost:[PORT]/exist/projects/scaffold/admin/deploy?pwd=[PASSWORD]&t=jobs[,policies]"
   - in addition you MUST copy /db/www/oppidum/lib/util.xqm to database

   POST-INSTALLATION :
   - check user 'zboss' exists or create it manually (see modules/users/account.xqm)
   
   TRICK:
   You can generate $formulars by executing in sandbox :
   let $n := fn:doc(concat('file://', system:get-exist-home(), '/webapp/projects/scaffold/formulars/_register.xml'))
   return string-join(for $i in $n//Form return substring-after($i, 'forms/'), '+')

   November 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   -------------------------------------- :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace install = "http://oppidoc.com/oppidum/install" at "../../oppidum/lib/install.xqm";
import module namespace sg = "http://coaching.ch/ns/supergrid" at "../modules/formulars/install.xqm";
(:import module namespace services = "http://oppidoc.com/ns/services" at "../lib/services.xqm";:)

declare option exist:serialize "method=xml media-type=text/html indent=yes";

declare variable $formulars := "stage+person+person-search+enterprise+enterprise-search+profile+account";

declare variable $policies := <policies xmlns="http://oppidoc.com/oppidum/install">
  <!-- Policies -->
  <policy name="admin" owner="admin" group="users" perms="rwur-u---"/>
  <policy name="any-up" owner="admin" group="users" perms="rwur-u---"/>
  <policy name="users" owner="admin" group="users" perms="rwurwur--"/>
  <policy name="open" owner="admin" group="users" perms="rwurwurwu"/>
  <policy name="strict" owner="admin" group="users" perms="rwurwu---"/>
  <policy name="guest" owner="admin" group="users" perms="rwur-u--u"/>
</policies>;

(: ======================================================================
   TODO: 
   - fix Oppidum inherit eq 'true' test in install-policies
   - invent
     <collection name="/db/sites/scaffold/checks" policy="open" inherit-policy="users"/> 
     to set collection policy different thatn its resources policies
   ======================================================================
:)

declare variable $code := <code xmlns="http://oppidoc.com/oppidum/install">
  <collection name="/db/www/scaffold" policy="admin" inherit="true"/>
  <group name="caches">
    <collection name="/db/caches/scaffold" policy="any-up" inherit="true">
      <files pattern="caches/cache.xml"/>
    </collection>
  </group>
  <group name="debug">
    <collection name="/db/debug" policy="any-up" inherit="true">
      <files pattern="debug/debug.xml"/>
      <files pattern="debug/login.xml"/>
    </collection>
  </group>
  <group name="config" mandatory="true">
    <collection name="/db/www/scaffold/config" policy="guest">
      <files pattern="config/mapping.xml"/>
      <files pattern="config/modules.xml"/>
      <files pattern="config/skin.xml"/>
      <files pattern="config/errors.xml"/>
      <files pattern="config/messages.xml"/>
      <files pattern="config/dictionary.xml"/>
      <!--<files pattern="config/settings.xml"/>-->
      <!--<files pattern="config/services.xml"/>-->
      <!--<files pattern="modules/alerts/checks.xml"/>-->
    </collection>
  </group>
  <group name="mesh" mandatory="true" policy="guest">
    <collection name="/db/www/scaffold/mesh">
      <files pattern="mesh/*.html"/>
    </collection>
  </group>
  <group name="sites">
    <collection name="/db/sites/scaffold" policy="users" inherit="true"/>
  </group>
  <group name="data">
    <collection name="/db/sites/scaffold/global-information" policy="admin" inherit="true">
      <files pattern="data/**/*.xml"/>
    </collection>
  </group>
</code>;

(: ======================================================================
   TODO:
   restore
   <Allow>
       <Category>account</Category>
       <Category>workflow</Category>
       <Category>action</Category>
   </Allow>
   into Media element in settings.xml
   ======================================================================
:)
declare function local:do-post-deploy-actions ( $dir as xs:string,  $targets as xs:string*, $base-url as xs:string, $mode as xs:string ) {
  if ('config' = $targets) then
    let $mapping := fn:doc('/db/www/scaffold/config/mapping.xml')/site
    let $settings := fn:doc('/db/www/scaffold/config/settings.xml')/Settings
    return
      (
      update value $mapping/@mode with $mode,
      <p>Set mode to { $mode }</p>,
      <p>Root mapping supported actions set to { string($mapping/@supported) }</p>,
      if  (not(exists($mapping/@base-url)) and $mode = ('test', 'prod')) then
        (
        update insert attribute { 'base-url' } {'/'} into $mapping,
        <p>Set attribue base-url to '/'</p>
        )
      else (
        if (exists($mapping/@base-url)) then
          update delete $mapping/@base-url
        else
          (),
        <p>Removed attribute base-url for '{ $mode }'</p>
        ),
      if (($settings/SMTPServer eq '!localhost') and $mode = 'prod') then
        (
        update value $settings/SMTPServer with 'localhost',
        <p>Changed SMTP Server to "localhost" to activate mail</p>
        )
      else if (($settings/SMTPServer eq 'localhost') and $mode = ('dev', 'test')) then
        (
        update value $settings/SMTPServer with '!localhost',
        <p>Changed SMTP Server to "!localhost" to inactivate mail for '{ $mode }'</p>
        )
      else
        <p>SMTP Server is configured to "{string($settings/SMTPServer)}"</p>
      )
  else
    ()
};

declare function local:deploy ( $dir as xs:string,  $targets as xs:string*, $base-url as xs:string, $mode as xs:string ) {
  (
  if ('users' = $targets) then
    <target name="users">{ install:install-users($policies) }</target>
  else
    (),
  let $itargets := $targets[not(. = ('users', 'policies', 'forms', 'services'))]
  return
    if (count($itargets) > 0) then
      <target name="{string-join($itargets,', ')}">
        {  
        install:install-targets($dir, $itargets, $code, ()),
        if ('timesheets' = $targets) then
          <policy>{ install:install-policies(('timesheets'), $policies, $code, ())}</policy>
        else
          ()
      }
      </target>
    else
      (),
  if ('policies' = $targets) then
    <target name="policies">{ install:install-policies(('sites'), $policies, $code, ())}</target>
  else
    (),
(:  if ('config' = $targets) then
    xdb:set-resource-permissions('/db/www/scaffold/config', 'settings.xml', 'admin', 'admin-system', 492):)(: "rwur-u-r--" :)
(:  else
    (),
:)  if ('forms' = $targets) then
    <target name="forms" base-url="{$base-url}">{ sg:gen-and-save-forms($formulars, $base-url) }</target>
  else
    (),
  (:if ('services' = $targets) then
    (<target name="services">{ services:deploy($dir) }</target>,
	install:install-targets($dir, ('questionnaires'), $code, ()))
  else
    (),:)
  local:do-post-deploy-actions($dir, $targets, $base-url, $mode)
  )
};

let $dir := install:webapp-home("projects/scaffold")
let $pwd := request:get-parameter('pwd', ())
let $mode := request:get-parameter('m', 'prod')
let $targets := tokenize(request:get-parameter('t', ''), ',')
let $host := request:get-header('Host')
let $cmd := request:get-attribute('oppidum.command')
return
  if (starts-with($host, 'localhost') or starts-with($host, '127.0.0.1')) then
    if ($pwd and (count($targets) > 0)) then
      <results count="{count($targets)}">
        <dir>{$dir}</dir>
        { system:as-user('admin', $pwd, local:deploy($dir, $targets, $cmd/@base-url, $mode)) }
      </results>
    else
      <results>Usage : deploy?t=users,policies,forms,caches,config,mesh,templates,stats&amp;pwd=[ADMIN PASSWORD]&amp;m=(dev | test | [prod])</results>
  else
    <results>This script can be called only from the server</results>
