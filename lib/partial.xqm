xquery version "1.0";
(: --------------------------------------
   Oppidoc Business Application Development Framework

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   This modules contains functions using XPath expressions with no namespace
   to be called from epilogue.xql which is in the default XHTML namespace.

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace partial = "http://oppidoc.com/oppidum/partial";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace session = "http://exist-db.org/xquery/session";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "globals.xqm";
import module namespace user = "http://oppidoc.com/ns/user" at "user.xqm";

(: Sets time in minute before kick out in maintenance mode :)
declare variable $partial:kick-out-delay := 5;

(: ======================================================================
   Checks if the application is in maintenance mode with kick out option
   to ask users to logout and kick them out after a minimum notification time.
   Note that Oppidum messages will be rendered immediately after leaving the function
   ======================================================================
:)
declare function partial:filter-for-maintenance ( $cmd as element(), $isa_tpl as xs:boolean ) {
  if ( not($isa_tpl)
       and (fn:doc($globals:log-file-uri)/Logs/@KickOut eq 'on')
       and not($cmd/@action = ('logout', 'login')) ) then (: kick out users for maintenance :)

    let $user := oppidum:get-current-user()
    return
      if ((fn:doc($globals:log-file-uri)/Logs/@Hold ne $user) and session:exists()) then
        let $warned := session:get-attribute('kick-out')
        return
          if (empty($warned)) then (
            session:set-attribute('kick-out', current-dateTime()),
            oppidum:add-message('ASK-LOGOUT', concat($partial:kick-out-delay, ' minutes'), false())
            )
          else (: tester le temps et delogger de force... :)
            let $ellapsed := current-dateTime() - $warned
            return
              if ($ellapsed > xs:dayTimeDuration(concat('PT', $partial:kick-out-delay, 'M'))) then (
                oppidum:add-error('LOGOUT-FOR-MAINTENANCE', (), true()),
                oppidum:add-message('ACTION-LOGOUT-SUCCESS', (), true()),
                xdb:login("/db", "guest", "guest"),
                let $ts := substring(string(current-dateTime()), 1, 19)
                return
                  update insert <Logout User="{$user}" TS="{$ts}">forced</Logout> into fn:doc($globals:log-file-uri)/Logs
                )
              else
                let $minutes := $partial:kick-out-delay - minutes-from-duration($ellapsed)
                return
                  oppidum:add-message('ASK-LOGOUT', if ($minutes > 0) then concat($minutes, ' minutes') else 'less than 1 minute', false())
    else
      ()
  else
    ()
};

(: ======================================================================
   Generates a menu, one item per Call
   ======================================================================
:)
declare function partial:gen-call-menu ( $base as xs:string, $action as xs:string, $lang as xs:string ) as element() {
  <ul class="dropdown-menu">
    {
      for $cut at $i in fn:collection($globals:global-info-uri)//Description[@Lang = $lang]//Selector[@Name eq 'CallRollOuts']/Option
      return
        <li><a target="_blank" href="{$base}calls/{$i}/{$action}">{ concat('Call ', $cut/Name, ' ') }</a></li>
    }
  </ul>
};

declare function partial:gen-todos-menu ( $base as xs:string, $user as xs:string, $groups as xs:string* ) as element()? {
  let $checks := fn:doc('/db/www/cctracker/config/checks.xml')//Check[@No]
  return
    if (empty($checks)) then
      ()
    else if ($groups = ('admin-system', 'coaching-assistant', 'coaching-manager')) then
      (: groups with holistic view :)
      <li class="dropdown">
        <a class="dropdown-toggle" data-toggle="dropdown" href="#">To do</a>
        <ul class="dropdown-menu">
          {
          for $c in $checks
          let $cached := fn:collection($globals:checks-uri)//Check[@No eq $c/@No]
          let $anchor := concat("#", $c/@No, " ", $c/Title/text())
          return
            <li>
              <a target="_blank" href="{$base}alerts/{$c/@No}">
                {
                if (empty($cached)) then
                  concat($anchor, " (?)")
                else if ($cached/@Total eq '0') then
                  concat($anchor, " (0)")
                else (
                  concat($anchor, " ("),
                  <span class="over">{string($cached/@Total)}</span>,
                  ")"
                  )
                }
              </a>
            </li>
          }
          <li class="divider"></li>
          <li><a target="_blank" href="{$base}reminders">Show latest Reminders</a></li>
        </ul>
      </li>
    else (: alerts for semantic roles :)
      let $user-ref := user:get-current-person-id()
      let $todos := fn:collection('/db/sites/cctracker/checks/')//Case[ReRef eq $user-ref]
      let $count := count($todos)
      return
        if ($count > 0) then
          <li><a href="{$base}alerts" class="over">To do (<span class="over">{ $count }</span>)</a></li>
        else
          <li><a href="{$base}alerts">To do</a></li>
};
