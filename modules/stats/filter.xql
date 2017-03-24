xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidoc Business Application Development Framework

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Statistical filtering for diagrams view

   TODO:
   - factorize gen-cases and gen-activities with filter.xql in stats.xqm

   January 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace json="http://www.json.org";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace stats = "http://oppidoc.com/ns/cctracker/stats" at "stats.xqm";

declare option exist:serialize "method=json media-type=application/json";

declare variable $local:weight-thresholds := ('2', '3');
declare variable $local:graph-weight-thresholds := '3';

(: ======================================================================
   CASE samples set generation matching $filter criteria
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
        local:gen-case-sample($c, $lang)
        }
      </Cases>
};

(: ======================================================================
   Single CASE sample generation suitable for JSON conversion
   Tag names aligned with Variable and Vector elements content in stats.xml
   ======================================================================
:)
declare function local:gen-case-sample ( $c as element(), $lang as xs:string ) as element()* {
  let $e := fn:doc($globals:enterprises-uri)/Enterprises/Enterprise[Id = $c/Information/ClientEnterprise/EnterpriseRef]
  let $na := $c/NeedsAnalysis
  return
    (
    <CS>{ $c/StatusHistory/CurrentStatusRef/text() }</CS>,
    <Co>{ $e//Country/text() }</Co>,
    <Nc>{ $e/DomainActivityRef/text() }</Nc>,
    for $i in $e//TargetedMarketRef
    return
      <TM>{ $i/text() }</TM>,
    <Sz>{ $e/SizeRef/text() }</Sz>,
    <Yr>{ $e/CreationYear/text() }</Yr>,
    <IC>{ $na//InitialContextRef/text() }</IC>,
    <TC>{ $na//TargetedContextRef/text() }</TC>,
    for $i in $na//VectorRef
    return
      <Vct>{ $i/text() }</Vct>,
    for $i in $na//IdeaRef
    return
      <Ids>{ $i/text() }</Ids>,
    for $i in $na//ResourceRef
    return
      <Rsc>{ $i/text() }</Rsc>,
    for $i in $na//PartnerRef
    return
      <Ptn>{ $i/text() }</Ptn>
    )
};

let $cmd := oppidum:get-command()
let $submitted := oppidum:get-data()
(: decodes stats specification name from submitted root element name :)
let $target := lower-case(substring-before(local-name($submitted), 'Filter'))
let $filter-spec-uri := oppidum:path-to-config('stats.xml')
(: gets stats specification :)
let $stats-spec := fn:doc($filter-spec-uri)/Statistics//Filter[@Page = $target]
let $sets := distinct-values($stats-spec//Set)
let $cases := if ('Cases' = $sets) then local:gen-cases($submitted, 'fr') else  ()
let $action := string($cmd/@action)
let $filter := fn:doc(oppidum:path-to-config('stats.xml'))/Statistics/Filters/Filter[@Page = $target]
let $command := $filter/Formular/Command[@Action eq $action]
return
  (: TODO: use access:check-user-can instead and move spec to application.xml ? :)
  if (access:check-rule(string($command/@Allow))) then 
    <DataSet Size="{count($cases)}">
      <Name>{ local-name($submitted) }</Name>
      { $cases }
      <Variables>
        {
        for $d in $stats-spec//Composition
        return stats:gen-composition-domain($d),
        for $d in $stats-spec//*[local-name(.) ne 'Composition'][@Selector]
        return stats:gen-selector-domain($d, $d/@Selector, $d/@Format),
        for $d in $stats-spec//*[@WorkflowStatus]
        return stats:gen-workflow-status-domain($d, $d/@WorkflowStatus),
        for $d in distinct-values($stats-spec//@Domain)
        return
          if ($d eq 'year') then
            stats:gen-year-domain($cases)
          else if ($d eq 'CaseImpact') then
            for $i in $stats-spec/Charts/Chart/Vector[@Domain eq 'CaseImpact']
            return
              stats:gen-case-vector($i/text(), string($i/@Section))
          else
            (),
        for $d in $stats-spec//*[@Persons]
        let $tag := string($d)
        let $refs := $cases/*[local-name(.) eq $tag]
        return stats:gen-persons-domain-for($refs, $tag)
        }
      </Variables>
    </DataSet>
  else
    oppidum:throw-error('FORBIDDEN', ())
