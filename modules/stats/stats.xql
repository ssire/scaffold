xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidoc Business Application Development Framework

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Statistical filtering for diagrams view

   January 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../../lib/display.xqm";

let $cmd := oppidum:get-command()
let $filter-spec-uri := oppidum:path-to-config('stats.xml')
let $target := string($cmd/resource/@name)
let $user := oppidum:get-current-user()
return
  if (doc-available($filter-spec-uri)) then (
    <Stats>
      <Window>Statistics for {$target}</Window>-
      {
      let $forms := fn:doc($filter-spec-uri)/Statistics/Filters/Filter[@Page = $target]/Formular
      return
        <Formular Id="editor">
          {
          $forms/*[local-name(.) ne 'Command'],
          <Commands>
            {
            for $c in $forms/Command
            return
              if ($c/@Allow) then (: access control :)
                <Command>
                  {
                  if (access:check-rule(string($c/@Allow))) then
                    ()
                  else
                    attribute Access { 'disabled' },
                  $c/(@* | text())
                  }
                </Command>
              else
                $c
            }
          </Commands>
          }
        </Formular>,
      fn:doc($filter-spec-uri)/Statistics/Filters/Filter[@Page = $target]/*[local-name(.) ne 'Formular']
      }
    </Stats>)[last()]
  else
    oppidum:throw-error('DB-NOT-FOUND', 'stats.xml')
