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
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../../lib/display.xqm";
import module namespace misc = "http://oppidoc.com/ns/cctracker/misc" at "../../lib/util.xqm";

(: ======================================================================
   Returns the saved search request in the user's profile if it exists
   or a default one otherwise
   ======================================================================
:)
declare function search:get-default-request () as element() {
  let $profile := access:get-current-person-profile()
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

declare function search:find-stage-results ( $lang as xs:string ) as element() {
  <Results Scope="All">
    {
    local:gen-result-sample($lang)
    }
  </Results>
};

(: ======================================================================
   FIXME: remove [. ne 'any'] guard because optional filter does not works
   after data has been loaded into the editor (to be fixed in AXEL) with load function
   such as with saved filters
   ======================================================================
:)
declare function search:find-stage-results ( $filter as element(), $lang as xs:string ) as element() {
  let $country := $filter//Country/text()
  return
    <Results>
      {
      local:gen-result-sample($lang)
      }
    </Results>
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
      search:find-stage-results($lang)
  else
    search:find-stage-results($request, $lang)
};
