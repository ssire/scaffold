xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Brings up stage (case and activities) search page with default search submission results
   or execute a search submission (POST) to return an HTML fragment.

   May 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace search = "http://platinn.ch/coaching/search" at "search.xqm";
import module namespace submission = "http://www.oppidoc.fr/oppidum/submission" at "../submission/submission.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $lang := string($cmd/@lang)
return
  if ($m eq 'POST') then (: executes search requests :)
    let $request := oppidum:get-data()
    return
      <Search>
        {
        search:fetch-stage-results($request, $lang)
        }
      </Search>
  else (: shows search page with default results - assumes GET :)
    <Search Initial="true" Controller="stage">
      {
        let $saved-request := submission:get-default-request('SearchStageRequest')
        return
          if (local-name($saved-request) = local-name($submission:empty-req)) then
            <NoRequest/>
          else
            search:fetch-stage-results($saved-request, $lang)
      }
    </Search>
