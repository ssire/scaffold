xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidoc Business Application Development Framework

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Statistical table export

   TODO:
   - factorize gen-cases and gen-activities with filter.xql in stats.xqm

   OPTIMIZATIONS:
   - replace direct compressed table generation (<td class="xy">) 
     with embedded JSON + d3.js generation (?)

   January 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace site = "http://oppidoc.com/oppidum/site";

import module namespace xdb="http://exist-db.org/xquery/xmldb";

import module namespace util="http://exist-db.org/xquery/util";
import module namespace epilogue = "http://oppidoc.com/oppidum/epilogue" at "../../../oppidum/lib/epilogue.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace user = "http://oppidoc.com/ns/user" at "../../lib/user.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../../lib/display.xqm";
import module namespace stats = "http://oppidoc.com/ns/cctracker/stats" at "stats.xqm";

declare variable $local:separator := '; ';
declare variable $local:weight-thresholds := ('2', '3');

(: TODO: declare colors for columns inside stats.xml :)
declare variable $local:cols-name := ('none', 'enterprise', 'case', 'needs');
declare variable $local:cols-backgrounds := ('#FFF', '#C2FFFF', '#99C2EB', '#83D6C3');

(: ======================================================================
   Returns the name of the current user as First name Last name or falls back to user login
   ======================================================================
:)
declare function local:gen-current-person-name() as xs:string {
  let $uid := user:get-current-person-id()
  return
    if ($uid) then
      display:gen-person-name($uid, 'en')
    else
      concat("user (", $uid, ")")
};

(: ======================================================================
   TODO: fallback to warning if no Email
   ======================================================================
:)
declare function local:gen-person-email( $refs as element()* ) as element()* {
  for $r in $refs
  return
    let $p := fn:doc($globals:persons-uri)/Persons/Person[Id = $r]
    return
      if ($p) then
        <a href="mailto:{$p/Contacts/Email}">{ concat($p/Name/FirstName, ' ', $p/Name/LastName) }</a>
      else
        <span>{ display:noref($r, 'en') }</span>
};

(: ======================================================================
   Returns a Variables structure for un$target as xs:string, $action as xs:string, $mode as xs:string?$target as xs:string, $action as xs:string, $mode as xs:string?$target as xs:string, $action as xs:string, $mode as xs:string?referencing labels client side in export table

   Note the first string must corresponds to a class name on the td host element

  { stats:gen-case-vector('vct', '1') }
  { stats:gen-case-vector('sci', '2') }
  { stats:gen-case-vector('rsc', '3') }
  { stats:gen-case-vector('prt', '4') }
   ======================================================================
:)
declare function local:gen-variables( ) as element() {
  <Variables>
    {
    stats:gen-selector-domain('sz', 'Sizes'),
    stats:gen-selector-domain('co', 'Countries'),
    stats:gen-selector-domain('ctx', 'TargetedContexts'),
    stats:gen-selector-domain('da', 'DomainActivities'),
    stats:gen-selector-domain('tm', 'TargetedMarkets'),
    stats:gen-workflow-status-domain('cs', 'Case'),
    stats:gen-workflow-status-domain('as', 'Activity'),
    stats:gen-case-vector('vr', '1'),
    stats:gen-case-vector('ir', '2'),
    stats:gen-case-vector('rr', '3'),
    stats:gen-case-vector('pr', '4')
  }
  </Variables>
};

(: ======================================================================
   Returns a <script> element to insert at the end of the export tables
   for client side decompression of labels
   Optimization to lower results table weight and to server processing
   ======================================================================
:)
declare function local:gen-decompress-script( ) as element() {
  let $DB :=  <DB>{ local:gen-variables() }</DB>
  let $string := util:serialize($DB, 'method=json')
  return
    <script type="text/javascript">
DB = { $string };

function decodeLabel ( varname, value ) {{
var convert = DB.Variables[varname], trans, pos, output, res = "";
if (convert) {{
trans = convert.Values || convert,
pos = trans.indexOf(value),
output = convert.Labels || convert;
res = output[pos] ? output[pos].replace('amp;', '') : value;
}}
return res;
}}

function uncompress (klass) {{
var i, cur;
while (cur = klass.pop()) {{
$('td.' + cur).each( function (i, e) {{
var n = $(e), v = n.attr('class'), src = n.text(), input = src.split("{$local:separator}"), output = [], k;
while (k = $.trim(input.pop())) {{
output.push(decodeLabel(v, k));
}}
n.text(output.join("{$local:separator}"));
}}
);
}}
}}

function uncompressWeights (klass) {{
  var cur;
  while (cur = klass.pop()) {{
    $('td.' + cur).each( function (i, e) {{
    var n = $(e), nn = n.next('td').first(); src = n.text();
    n.text(src.replace(/(\d+)#(\d+)/g, function(a, variable, value) {{ var res = decodeLabel(cur.substr(1), variable); return value === '2' ? res : ''; }}).split("; ").filter(function (n) {{ return n === "" ? false : true; }}).join('; '));
    nn.text(src.replace(/(\d+)#(\d+)/g, function(a, variable, value) {{ var res = decodeLabel(cur.substr(1), variable); return value === '3' ? res : ''; }}).split("; ").filter(function (n) {{ return n === "" ? false : true; }}).join('; '));
    }}
    );
  }}
}}

uncompress(['co', 'sz', 'ctx', 'cs', 'as', 'da', 'tm', 'vr', 'ir', 'rr', 'pr']);
uncompressWeights(['_vr', '_ir', '_rr', '_pr'])
</script>
};

(: ======================================================================
   COPIED FROM filter.xql
   ======================================================================
:)
declare function local:gen-cases ( $filter as element(), $lang as xs:string ) as element()* {
  let $user := oppidum:get-current-user()

  (: --- case criteria --- :)
  let $status := $filter//CaseStatusRef
  let $start-date := $filter/CaseStartDate/text()
  let $end-date := $filter/CaseEndDate/text()
  let $status-any-time := if ($start-date or $end-date) then () else $status
  let $status-after := if ($start-date and not($end-date)) then if (empty($status)) then 1 to 10 else $status else ()
  let $status-before := if ($end-date and not($start-date)) then if (empty($status)) then 1 to 10 else $status else ()
  let $status-between := if ($start-date and $end-date) then if (empty($status)) then 1 to 10 else $status else ()
  let $init-context := $filter//InitialContextRef
  let $target-context := $filter//TargetedContextRef
  let $vector := $filter//VectorRef/text()
  let $idea := $filter//IdeaRef/text()
  let $resource := $filter//ResourceRef/text()
  let $partner := $filter//PartnerRef/text()

  (: --- client enterprise criteria --- :)
  let $country := $filter//Country
  let $domain := $filter//DomainActivityRef
  let $market := $filter//TargetedMarketRef/text()
  let $size := $filter//SizeRef/text()
  let $creation-start-year := $filter//CreationStartYear
  let $creation-end-year := $filter//CreationEndYear
  let $any-enterprise := empty(($country, $market, $domain, $size, $creation-start-year, $creation-end-year))
  let $enterprises := fn:doc($globals:enterprises-uri)
  
  return
    for $c in fn:collection($globals:cases-uri)/Case
    let $e := if ($any-enterprise) then
                ()
              else
                $enterprises//Enterprise[Id eq $c/Information/ClientEnterprise/EnterpriseRef]
    where
      (: --- client enterprise filtering --- :)
      ( $any-enterprise or 
        (
            (empty($country) or $e//Country = $country)
        and (empty($domain) or $e/DomainActivityRef = $domain)
        and (empty($market) or $e//TargetedMarketRef = $market)
        and (empty($size) or $e/SizeRef = $size)
        and (not($creation-start-year) or $e/CreationYear >= $creation-start-year)
        and (not($creation-end-year) or $e/CreationYear <= $creation-end-year)
        )
      )
      (: --- case status filtering --- :)
      and   (empty($status-after) or
          $c/StatusHistory/Status[./ValueRef = $status-after][./Date >= $start-date])
      and (empty($status-before) or
          $c/StatusHistory/Status[./ValueRef = $status-before][./Date <= $end-date])
      and (empty($status-between) or
          $c/StatusHistory/Status[./ValueRef = $status-between][./Date >= $start-date and ./Date <= $end-date])
      and (empty($status-any-time) or $c[StatusHistory[CurrentStatusRef = $status-any-time]])
      (: --- case filtering --- :)
      and (empty($init-context) or $c/NeedsAnalysis//InitialContextRef = $init-context)
      and (empty($target-context) or $c/NeedsAnalysis//TargetedContextRef = $target-context)
      and (empty($vector) or $c/NeedsAnalysis//VectorRef = $vector)
      and (empty($idea) or $c/NeedsAnalysis//IdeaRef = $idea)
      and (empty($resource) or $c/NeedsAnalysis//ResourceRef = $resource)
      and (empty($partner) or $c/NeedsAnalysis//PartnerRef = $partner)
    return
      <Cases>
        {
        local:gen-case-sample($c, $e, $lang)
        }
      </Cases>
};

(: ======================================================================
   Case sample (manually aligned with Table structure in stats.xml)
   ====================================================================== 
:)
declare function local:gen-case-sample ( $c as element(), $e as element()?, $lang as xs:string ) as element()* {
  let $case-nb := $c/No/text()
  let $na := $c/NeedsAnalysis
  let $enterprise := if ($e) then 
                $e 
              else 
                fn:doc($globals:enterprises-uri)//Enterprise[Id eq $c/Information/ClientEnterprise/EnterpriseRef]
  return
    <tr>
      <td><a href="../cases/{$case-nb}" target="_blank">{$case-nb}</a></td>
      <td class="cs">{ $c/StatusHistory/CurrentStatusRef/text() }</td>
      <td>{ local:gen-person-email($c/Management/AccountManagerRef) }</td>
      <td>{ $enterprise/Name/text() }</td>
      <td class="co">{ $enterprise//Country/text() }</td>
      <td class="da">{ $enterprise/DomainActivityRef/text() }</td>
      <td class="tm">{ string-join($enterprise//TargetedMarketRef, $local:separator) }</td>
      <td class="sz">{ $enterprise/SizeRef/text() }</td>
      <td>{ $enterprise/CreationYear/text() }</td>
      <td class="ctx">{ $na//InitialContextRef/text() }</td>
      <td class="ctx">{ $na//TargetedContextRef/text() }</td>
      <td class="vr">{ string-join($na//VectorRef, $local:separator) }</td>
      <td class="ir">{ string-join($na//IdeaRef, $local:separator) }</td>
      <td class="rr">{ string-join($na//ResourceRef, $local:separator) }</td>
      <td class="pr">{ string-join($na//PartnerRef, $local:separator) }</td>
    </tr>
};

(: ======================================================================
   Returns column headers for cases or activities export to table for Excel export
   ======================================================================
:)
declare function local:gen-headers-for( $target as xs:string, $type as xs:string ) as element()* {
  let $filter-spec-uri := oppidum:path-to-config('stats.xml')
  let $table := fn:doc($filter-spec-uri)/Statistics//Table[(@Page eq $target) and contains(@Type, $type)]
  return
    (
    for $h in $table//Header[not(@Avoid) or (@Avoid ne $type)]
    let $group := string($h/@BG)
    let $i := if ($group ne '') then index-of($local:cols-name, $group) else 1
    let $color := if ($i) then $local:cols-backgrounds[$i] else $local:cols-backgrounds[1]
    return
      <col span="1" style="background:{$color}"/>,
      <thead>
        <tr>
          {
          for $h in $table//Header[not(@Avoid) or (@Avoid ne $type)]
          return <th>{ $h/text() }</th>
          }
        </tr>
      </thead>
    )
};

(: ======================================================================
   Turns a time interval [from A? to B?] into appropriate sentence 
   ====================================================================== 
:)
declare function local:serialize-interval( $start as xs:string?, $end as xs:string? ) as xs:string? {
  if ($start and $end) then 
    concat('from ', $start, ' to ', $end) 
  else if ($start) then 
    concat('after ', $start) 
  else if ($end) then 
    concat('before ', $end) 
  else 
    ()
};

(: ======================================================================
   Turns a time interval [between A? and B?] into appropriate sentence 
   ====================================================================== 
:)
declare function local:serialize-period( $start as xs:string?, $end as xs:string? ) as xs:string? {
  if ($start and $end) then 
    concat('between ', $start, ' and ', $end) 
  else if ($start) then 
    concat('since ', $start) 
  else if ($end) then 
    concat('before ', $end) 
  else 
    ()
};

(: ======================================================================
   Turns a range [between A? and B?] into appropriate sentence 
   ====================================================================== 
:)
declare function local:serialize-range( $range as element()? ) as xs:string? {
  let $start := $range/Min
  let $end := $range/Max
  return
    if ($start and $end) then 
      concat('between ', $start, ' and ', $end) 
    else if ($start) then 
      concat('superior or equal to ', $start) 
    else if ($end) then 
      concat('inferior or equal to ', $end) 
    else 
      ()
};
(: ======================================================================
   Switch function to call correct function in stats.xqm to generate
   the samples corresponding to submitted criterias as HTML table rows
   See also stats:gen-cases and stats:gen-activities in stats.xqm
   ======================================================================
:)
declare function local:serialize-data-set( $target as xs:string, $type as xs:string, $filter as element(), $lang as xs:string ) as element()* {
  if ($target eq 'cases') then
    local:gen-cases($filter, $lang)
  else
    ()
};

(: ======================================================================
   Renders field values inside Criteria
   Implements @render, @selector, @status and @function annotations of stats.xml
   ======================================================================
:)
declare function local:gen-current-filter ( $filter as element(), $criteria as element() ) as xs:string {
  if ($criteria/@render) then
    string-join(util:eval($criteria/@render), ' ')
  else if ($criteria/@selector) then
    if ($criteria/@ValuePath) then
      string-join(
        for $i in util:eval(concat('$filter/', $criteria/@ValuePath))
        return display:gen-name-for($criteria/@selector, $i, 'en'),
        $local:separator
        )
    else (: assumes @ValueTag :)
      string-join(
        for $i in $filter//*[local-name(.) eq string($criteria/@ValueTag)]
        return display:gen-name-for($criteria/@selector, $i, 'en'),
        $local:separator
        )
  else if ($criteria/@function) then
    string-join(
      for $i in $filter//*[local-name(.) eq string($criteria/@ValueTag)]
      let $src := concat('display:', string($criteria/@function), '($i, "en")')
      return util:eval($src),
      $local:separator
    )
  else if ($criteria/@status) then
    string-join(
      for $i in $filter//*[local-name(.) eq string($criteria/@ValueTag)]
      return display:gen-name-for(concat($criteria/@status, 'WorkflowStatus'), $i, 'en'),
      $local:separator
      )
  else if ($criteria/@ValueTag) then
    string-join($filter//*[local-name(.) eq string($criteria/@ValueTag)], $local:separator)
  else
    string-join($filter//*[local-name(.) eq string($criteria/@Tag)], $local:separator)
};

(: ======================================================================
   Generates an optionally localized criteria field label
   TODO: $lang parameter
   ======================================================================
:)
declare function local:criteria-field-label( $field as element()? ) as xs:string {
  if ($field/@loc) then
    let $dico := fn:doc($globals:dico-uri)/site:Dictionary/site:Translations[@lang = 'en']
    let $t := $dico/site:Translation[@key = $field/@loc]/text()
    return
      if ($t) then 
        $t 
      else 
        $field/text()
  else
    $field/text()
};

(: ======================================================================
   Returns true() if the given Criteria has a non empty filter set in the query mask
   ====================================================================== 
:)
declare function local:has-filter($criteria as element(), $filter as element(), $plugins as element()* ) {
  let $name :=
    if ($criteria/@Tag) then
      string($criteria/@Tag)
    else (: actually no @Tag implies a Period plugin :)
      let $period := $plugins/Period[contains(@Keys, $criteria/@Key)]
      let $suffix := if ($period/@Span eq 'Year') then 'Year' else 'Date'
      return (: see also search-mask.xsl :)
        (concat($period/@Prefix, 'Start', $suffix), concat($period/@Prefix, 'End', $suffix)) 
  let $mask := $filter/*[local-name(.) = $name]
  return
    some $m in $mask satisfies normalize-space(string($m)) ne ''
};

declare function local:gen-criterias-iter( $filter as element(), $nodes as item()*, $plugins as element()* ) as item()* {
  for $n in $nodes
  return
    typeswitch($n)
      case element() return
        if (local-name($n) eq 'Group') then (
          let $span := count($n/descendant::Criteria[local:has-filter(., $filter, $plugins)]) - (count($n/descendant::SubGroup/Criteria[local:has-filter(., $filter, $plugins)]) + count($n/descendant::Criteria[preceding-sibling::*[1][local-name() = 'SubGroup']][local:has-filter(., $filter, $plugins)]))
          return
            if ($span > 0) then
              let $first := $n/Criteria[local:has-filter(., $filter, $plugins)][1]
              return
                <tr style="background:{$n/@Background}">
                  <td style="width:20%" rowspan="{$span}">{$n/Title/text()}</td>
                  <td style="width:30%">{ local:criteria-field-label($first) }</td>
                  <td style="width:50%">{ local:gen-current-filter($filter, $first) }</td>
                </tr>
            else
              (),
          let $followers := $n/(SubGroup[descendant::Criteria[local:has-filter(., $filter, $plugins)]] | Criteria[local:has-filter(., $filter, $plugins)][position()>1])
          return
            if (exists($followers)) then
              local:gen-criterias-iter($filter, $followers, $plugins)
            else
              ()
          )
        else if (local-name($n) eq 'SubGroup') then (
          let $span := count($n/Criteria[local:has-filter(., $filter, $plugins)]) + count($n/following-sibling::Criteria[local:has-filter(., $filter, $plugins)])
          return
            if ($span > 0) then
              let $first := $n/Criteria[local:has-filter(., $filter, $plugins)][1]
              return
                <tr style="background:{$n/ancestor::Group/@Background}">
                  <td style="width:20%" rowspan="{$span}">{$n/Title/text()}</td>
                  <td style="width:30%">{ local:criteria-field-label($first) }</td>
                  <td style="width:50%">{ local:gen-current-filter($filter, $first) }</td>
                </tr>
            else
              (),
          let $followers := $n/Criteria[local:has-filter(., $filter, $plugins)][position()>1]
          return
            if (exists($followers)) then
              local:gen-criterias-iter($filter, $followers, $plugins)
            else
              ()
          )
        else if (local-name($n) eq 'Criteria') then
          <tr style="background:{$n/ancestor::Group/@Background}">
            <td>{ local:criteria-field-label($n) }</td>
            <td>{ local:gen-current-filter($filter, $n) }</td>
          </tr>
        else
          ()
      default return ()
};

(: ======================================================================
   Generates the search criteria table filled with the current filter
   Pre-condition: copy formulars/stats.xml spec into $globals:stats-formulars-uri
   ======================================================================
:)
declare function local:serialize-criterias( $target as xs:string, $type as xs:string, $filter as element(), $lang as xs:string ) as element() {
  <table id="filters">
    <caption style="font-size:24px;margin:20px 0 10px;text-align:left">
      <b>Search criterias</b>
    </caption>
    {
    let $maskpath := concat('/db/www/scaffold/formulars/stats-', $target, '.xml')
    let $searchmask := fn:doc($maskpath)//SearchMask
    return
      for $c in $searchmask/Include
      let $stats-uri := concat($globals:stats-formulars-uri, '/', $c/@src)
      let $rowspec :=  fn:doc($stats-uri)//Component[@Name eq $c/@Name]
      let $plugins := fn:doc($stats-uri)//Plugins
      return
        local:gen-criterias-iter($filter, $rowspec/*, $plugins)
    }
  </table>
};

(: ======================================================================
   Generate a page with an HTML table for the filter criteria and an HTML table
   for the results, both can be exported to Excel
   ======================================================================
:)
declare function local:export-html ( $target as xs:string, $type as xs:string, $filter as element(), $lang as xs:string ) {
  let $base := epilogue:make-static-base-url-for('scaffold')
  let $subject := if ($target eq 'cases') then 'Cases' else 'Activities'
  let $brand := ' data set '
  let $date := string(current-dateTime())
  let $timestamp := concat(' exported on ', display:gen-display-date($date, $lang), ' at ', substring($date, 12, 5))
  let $username := local:gen-current-person-name()
  let $rows := local:serialize-data-set($target, $type, $filter, $lang)
  return
    <html xmlns="http://www.w3.org/TR/REC-html40">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <title>{$subject} {$timestamp}</title>
        <script src="{epilogue:make-static-base-url-for('oppidum')}/contribs/jquery/js/jquery-1.7.1.min.js" type="text/javascript">//</script>
        <script src="{$base}contribs/excellentexport/excellentexport.js" type="text/javascript">//</script>
        <link href="{$base}css/stats.css" rel="stylesheet" type="text/css" />
        <script src="{$base}lib/stats.js" type="text/javascript">//</script>
        <script src="{$base}contribs/tablesorter/jquery.tablesorter.min.js" type="text/javascript">//</script>
      </head>
      <body id="export">
        <h1>{$subject} {$brand} {$timestamp}</h1>
        <div id="results-export">Export <a download="case-tracker-{$target}.xls" href="#" class="export">excel</a> | <a download="case-tracker-{$target}.csv" href="#" class="export">csv</a></div>
        { local:serialize-criterias($target, $type, $filter, $lang) }
        <table id="results">
          <caption style="font-size:24px;margin:20px 0 10px;text-align:left"><b>{ concat(count($rows), ' ', upper-case($subject), ' in ', $brand, $timestamp, ' by ', $username) }</b></caption>
          { local:gen-headers-for($target, $type) }
          <tbody>
            { $rows }
          </tbody>
        </table>
        { local:gen-decompress-script() }
      </body>
    </html>
};

(: ======================================================================
   Trick to catch errors when parsing submitted data
   ======================================================================
:)
declare function local:gen-error() as element() {
  <error><message>Failed to read submitted parameters</message></error>
};

let $cmd := oppidum:get-command()
let $data := request:get-parameter('data', ())
let $submitted := util:catch('*', util:parse($data), local:gen-error())
return
  if (node-name($submitted) eq 'error') then
    $submitted
  else
    let $target := lower-case(substring-before(local-name($submitted/*[1]), 'Filter'))
    let $type := request:get-parameter('t', ())
    let $action := concat(string($cmd/@action), '?t=', $type)
    let $filter := fn:doc(oppidum:path-to-config('stats.xml'))/Statistics/Filters/Filter[@Page = $target]
    let $command := $filter/Formular/Command[@Action eq $action]
    return
      if (access:check-rule(string($command/@Allow))) then
        if ($target = ('cases')) then
          if ($type = ('all')) then
            (
            util:declare-option("exist:serialize", "method=html media-type=text/html"),
            (: TODO: access:check-stats(...) :)
            local:export-html($target, $type, $submitted/*[1], 'en')
            )
          else
            <error>Unkown export type { $type }</error>
        else
          <error>Unkown export target { $target }</error>
      else
        oppidum:throw-error('FORBIDDEN', ())

