xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

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

   TARGETS (users,config,bootstrap,data,forms,mesh,templates,stats,policies)
   - forms : generate all formulars with supergrid (see $formulars in this script)

   November 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   -------------------------------------- :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace install = "http://oppidoc.com/oppidum/install" at "../../oppidum/lib/install.xqm";
import module namespace sg = "http://coaching.ch/ns/supergrid" at "../modules/formulars/install.xqm";
(:import module namespace services = "http://oppidoc.com/ns/services" at "../lib/services.xqm";:)
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../lib/globals.xqm";

declare option exist:serialize "method=xml media-type=text/html indent=yes";

declare variable $formulars := 
  let $reg := fn:doc(concat('file://', system:get-exist-home(), '/webapp/projects/scaffold/formulars/_register.xml'))
  return string-join(for $i in $reg//Form return substring-after($i, 'forms/'), '+');
  
declare variable $policies := <policies xmlns="http://oppidoc.com/oppidum/install">
  <user name="demo" password="test" groups="users account-manager admin-system developer"/>
  <user name="coach" password="test" groups="users"/>
  <!-- Policies -->
  <policy name="admin" owner="admin" group="users" perms="rwxr-x---"/>
  <policy name="users" owner="admin" group="users" perms="rwxrwx---"/>
  <policy name="open" owner="admin" group="users" perms="rwxrwxrwx"/>
  <policy name="strict" owner="admin" group="users" perms="rwxrwx---"/>
  <policy name="guest" owner="admin" group="users" perms="rwxr-xr-x"/>
</policies>;

(: ======================================================================
   TODO: implement inherit-policy to set collection policy different 
    than its resources policies
    <collection name="/db/sites/scaffold/checks" policy="open" inherit-policy="users"/> 
   ======================================================================
:)

declare variable $code := <code xmlns="http://oppidoc.com/oppidum/install">
  <!-- top level collection instructions to apply policies -->
  <collection name="/db/www/scaffold" policy="guest" inherit="true"/>
  <collection name="/db/sites/scaffold" policy="users" inherit="true"/>
  <!-- policies inside group elements to refine top level collection policies -->
  <!--<group name="caches">
    <collection name="/db/caches/scaffold" policy="strict" inherit="true">
      <files pattern="caches/cache.xml"/>
    </collection>
  </group>-->
  <!--<group name="debug">
    <collection name="/db/debug" policy="open" inherit="true">
      <files pattern="debug/debug.xml"/>
      <files pattern="debug/login.xml"/>
    </collection>
  </group>-->
  <group name="config">
    <collection name="/db/www/scaffold/config">
      <files pattern="config/mapping.xml"/>
      <files pattern="config/modules.xml"/>
      <files pattern="config/application.xml"/>
      <files pattern="config/database.xml"/>
      <files pattern="config/skin.xml"/>
      <files pattern="config/errors.xml"/>
      <files pattern="config/messages.xml"/>
      <files pattern="config/dictionary.xml"/>
      <files pattern="config/variables.xml"/>
      <files pattern="config/settings.xml"/>
      <!--<files pattern="config/services.xml"/>-->
      <!--<files pattern="modules/alerts/checks.xml"/>-->
    </collection>
  </group>
  <group name="mesh" mandatory="true">
    <collection name="/db/www/scaffold/mesh">
      <files pattern="mesh/*.html"/>
    </collection>
  </group>
  <group name="data">
    <collection name="/db/sites/scaffold/cases"/>
    <collection name="/db/sites/scaffold/global-information">
      <files pattern="data/global-information/*.xml"/>
    </collection>
  </group>
  <group name="templates">
    <collection name="/db/sites/scaffold/global-information">
      <files pattern="data/global-information/templates.xml"/>
    </collection>
  </group>
  <group name="stats">
    <collection name="/db/www/scaffold/config">
      <files pattern="modules/stats/stats.xml"/>
    </collection>
    <collection name="/db/www/scaffold/formulars">
      <files pattern="formulars/stats.xml"/>
      <files pattern="formulars/stats-cases.xml"/>
    </collection>
  </group>
  <group name="bootstrap">
    <collection name="/db/sites/scaffold/persons">
      <files pattern="data/persons/*.xml"/>
    </collection>
    <collection name="/db/sites/scaffold/enterprises">
      <files pattern="data/enterprises/*.xml"/>
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
    <target name="users">
      { 
      (: TODO: add function compat:make-user-groups and use it in install-users :)
      (: the code below creates the groups first so it can use deprecated xdb:create/change-user :)
      let $groups := sm:list-groups()
      return 
        (: pre-condition: target config already deployed :)
        for $group in ('users', fn:doc(concat('file://', system:get-exist-home(), '/webapp/projects/scaffold/data/global-information/global-information.xml'))//Description[@Role eq 'normative']/Selector[@Name eq 'Functions']/Option[@Group]/string(@Group))
        return
          if ($group = $groups) then
            <li>no need to create group {$group} which already exists</li>
          else
            <li>Created group { sm:create-group($group), $group }</li>,
      install:install-users($policies) 
      }
    </target>
  else
    (),
  let $itargets := $targets[not(. = ('users', 'policies', 'forms', 'services'))]
  return
    if (count($itargets) > 0) then
      <target name="{string-join($itargets,', ')}">
        {  
        install:install-targets($dir, $itargets, $code, ())
        }
      </target>
    else
      (),
  if ('policies' = $targets) then
    let $refine := 
      for $group in $code/install:group[install:collection/@policy]
      return string($group/@name)
    return
      <target name="policies">{ install:install-policies($refine, $policies, $code, ())}</target>
  else
    (),
  if ('forms' = $targets) then
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
let $fallback := fn:doc('/db/www/scaffold/config/mapping.xml')/site/@mode
let $mode := request:get-parameter('m', if ($fallback) then $fallback else 'dev')
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
      <results>Usage : deploy?t=users,config,bootstrap,data,forms,mesh,templates,stats,policies&amp;pwd=[ADMIN PASSWORD]&amp;m=(dev | test | [prod])</results>
  else
    <results>This script can be called only from the server</results>
