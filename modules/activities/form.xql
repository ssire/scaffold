xquery version "1.0";
(: --------------------------------------
   CCTRACKER - Oppidoc Case Tracker

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Extension points for Activity workflow formulars

   TODO:
   - SuperGrid Constant 'html' field (for Comments in Opinions)

   November 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace form = "http://oppidoc.com/oppidum/form" at "../../lib/form.xqm";
import module namespace custom = "http://oppidoc.com/ns/application/custom" at "../../app/custom.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../../lib/display.xqm";


declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace site = "http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Generates Timessheet field for coach (or coaching-manager / assistant) 
   to upload time sheet
   NOTE: ts flag could be spoofed however server-side access control would make it useless
   ====================================================================== 
:)
declare function local:gen-timesheet( $goal as xs:string ) {
  let $can-update := request:get-parameter('ts', ())
  let $activity-no := request:get-parameter('activity', '#')
  return
    if ($can-update) then
      <site:field Key="timesheet-upload">
        <xt:use types="file" label="TimesheetFile" param="file_delete={$activity-no}/timesheets/remove;file_URL={$activity-no}/timesheets;file_base={$activity-no}/timesheets;file_gen_name=auto;file_size_limit=1024;file_button_class=btn btn-primary"/>
      </site:field>
      else
      <site:field Key="timesheet-upload">
        <xt:use types="constant" param="class=uneditable-input span a-control;constant_media=file;file_base={$activity-no}/timesheets" label="TimesheetFile"/>
      </site:field>
};

(: ======================================================================
   Returns field to select challenge weights for selected challenges
   FIXME: case and activity should be coded into template URL to be RESTfull
   ======================================================================
:)
declare function local:gen-challenge-weights( $lang as xs:string, $noedit as xs:boolean, $section as xs:string ) as element()* {
  let $case-no := request:get-parameter('case', '#')
  let $activity-no := request:get-parameter('activity', '#')
  let $root := fn:collection($globals:global-info-uri)/GlobalInformation/Description[@Lang eq 'en']/CaseImpact/Sections/Section[Id eq $section]/SectionRoot/text()
  let $targets := fn:collection($globals:cases-uri)/Case[No eq $case-no]//Activity[No eq $activity-no]/NeedsAnalysis/Impact/*[local-name(.) eq $root]/*/text()
  let $xtra := if ($noedit) then ';noedit=true' else ''
  let $pairs := 
      for $p in fn:collection($globals:global-info-uri)//GlobalInformation/Description[@Lang = $lang]/CaseImpact/Sections/Section[Id=$section]/SubSections/SubSection[Id = $targets]
      let $n := $p/SubSectionName
      return
         <Name id="{string($p/Id)}">{$n/text()}</Name>
  return
    if (count($pairs) > 0) then
      for $n in $pairs
      return
        <xhtml:p style="margin-bottom:10px"><xhtml:span style="display:block;margin-right:10px;float:left;width:240px;color:#004563">{$n/text()}</xhtml:span> <xt:use label="{$root}-{string($n/@id)}" types="choice" param="appearance=full;multiple=no;class=c-inline-choice{$xtra}" values="1 2 3" i18n="no medium high"/></xhtml:p>
    else
      <xhtml:p style="margin-bottom:10px;font-style:italic;color:lightgray">no challenge in needs analysis at coaching activity creation time</xhtml:p>
};

let $cmd := request:get-attribute('oppidum.command')
let $lang := string($cmd/@lang)
let $goal := request:get-parameter('goal', 'read')
let $template := string(oppidum:get-resource($cmd)/@name)
return
  if ($goal = 'read') then

    if ($template = 'coaching-assignment') then
      <site:view>
        <site:field Key="weights-vectors" filter="no">
          { local:gen-challenge-weights($lang, true(), '1') }
        </site:field>
        <site:field Key="weights-ideas" filter="no">
          { local:gen-challenge-weights($lang, true(), '2') }
        </site:field>
        <site:field Key="weights-resources" filter="no">
          { local:gen-challenge-weights($lang, true(), '3') }
        </site:field>
        <site:field Key="weights-partners" filter="no">
          { local:gen-challenge-weights($lang, true(), '4') }
        </site:field>
        <site:field Key="likert-scale">
          { form:gen-radio-selector-for('RatingScales', $lang, true(), 'c-inline-choice') }
        </site:field>
      </site:view>

    else if ($template = 'funding-request') then
      <site:view>
      </site:view>

    else if ($template = 'final-report-approval') then
      <site:view>
        <site:field Key="likert-scale">
          { form:gen-radio-selector-for('RatingScales', $lang, true(), 'c-inline-choice') }
        </site:field>
      </site:view>

    else if ($template = 'final-report') then
      <site:view>
        { local:gen-timesheet($goal) }
        <site:field Key="likert-scale">
          { form:gen-radio-selector-for('RatingScales', $lang, true(), 'c-inline-choice') }
        </site:field>
      </site:view>

    else if ($template = ('evaluations')) then (: relies on Template with breadcrumbs in application.xml :)
      let $case-no := request:get-parameter('case', '#')
      let $activity-no := request:get-parameter('activity', '#')
      let $order := fn:collection($globals:cases-uri)/Case[No eq $case-no]//Activity[No eq $activity-no]/Evaluation/Order[Questionnaire/text() eq 'cctracker-sme-feedback']
      return
        <site:view>
          {
          for $var in $order//Variable
          return
            <site:field Key="{$var/@Key}" filter="no"><span>{ $var/text() }</span></site:field>
          }
        </site:view>

    else
      <site:view/>

  else (: assumes 'update' or 'create' :)
  
    if ($template = 'coaching-assignment') then
      <site:view>
        <site:field Key="service">
          { form:gen-selector-for('Services', $lang, ";multiple=no;typeahead=yes") }
        </site:field>
        <site:field Key="assigned-coach">
          { custom:gen-person-with-role-selector('coach', $lang, " optional;multiple=no;typeahead=yes", "span") }
        </site:field>
        <site:field Key="suggested-coach">
          <xt:use types="constant" param="class=uneditable-input span">Will be available soon</xt:use>
        </site:field>        
        <site:field Key="weights-vectors" filter="no">
          { local:gen-challenge-weights($lang, false(), '1') }
        </site:field>
        <site:field Key="weights-ideas" filter="no">
          { local:gen-challenge-weights($lang, false(), '2') }
        </site:field>
        <site:field Key="weights-resources" filter="no">
          { local:gen-challenge-weights($lang, false(), '3') }
        </site:field>
        <site:field Key="weights-partners" filter="no">
          { local:gen-challenge-weights($lang, false(), '4') }
        </site:field>        
        <site:field Key="date">
          <xt:use types="constant" param="class=uneditable-input span">
            {display:gen-display-date(string(current-date()),$lang)}
            </xt:use>
        </site:field>
        <site:field Key="likert-scale">
          { form:gen-radio-selector-for('RatingScales', $lang, false(), 'c-inline-choice') }
        </site:field>
      </site:view>

  else if ($template = 'funding-request') then
    let $yesno := form:gen-selector-for('YesNoScales', $lang, " optional;multiple=no;typeahead=no")
    return
      <site:view>
        <site:field Key="sme-approval">{ $yesno }</site:field>
        <site:field Key="yes-no-mandatory">{ $yesno }</site:field>
      </site:view>

  else if ($template = 'position') then
      <site:view>
        <site:field Key="position">
          { 
          let $scale := 
            if (request:get-parameter('yesno', ())) then 
              'YesNoScales'
            else if (request:get-parameter('decision', ())) then 
              'Decisions'
            else
              'Positions'
          return
            form:gen-selector-for($scale, $lang, ";multiple=no;typeahead=no") 
          }
        </site:field>
      </site:view>

  else if ($template = 'funding-decision') then
    <site:view>
      <site:field Key="decision">
        { form:gen-selector-for('Decisions', $lang, " optional;multiple=no;typeahead=no") }
      </site:field>
    </site:view>

  else if ($template = 'final-report') then
    <site:view>
      { local:gen-timesheet($goal) }
      <site:field Key="likert-scale">
        { form:gen-radio-selector-for('RatingScales', $lang, false(), 'c-inline-choice') }
      </site:field>
      <site:field Key="to-appear-in-news">
        { form:gen-selector-for('CommunicationAdvices', $lang, ";multiple=no;typeahead=no") }
      </site:field>
      <site:field Key="type">
        { form:gen-selector-for('PartnerTypes', $lang, ";multiple=no;typeahead=no") }
      </site:field>
      <site:field Key="role">
        { form:gen-selector-for('PartnerRoles', $lang, ";multiple=no;typeahead=no") }
      </site:field>
      <site:field Key="country">
        { form:gen-selector-for('Countries', $lang, " optional;multiple=no;typeahead=yes") }
      </site:field>
      <site:field Key="targeted-markets">
        { (:form:gen-selector-for('TargetedMarkets', $lang, ";multiple=yes;xvalue=TargetedMarketRef;typeahead=yes") :)
          form:gen-json-selector-for('TargetedMarkets', $lang, "multiple=yes;xvalue=TargetedMarketRef;choice2_width1=280px;choice2_width2=250px;choice2_closeOnSelect=true")
        }
      </site:field>
    </site:view>

  else if ($template = 'final-report-approval') then
    <site:view>
      <site:field Key="likert-scale">
        { form:gen-radio-selector-for('RatingScales', $lang, false(), 'c-inline-choice') }
      </site:field>
      <site:field Key="to-appear-in-news">
        { form:gen-selector-for('CommunicationAdvices', $lang, ";multiple=no;typeahead=no") }
      </site:field>
      <site:field Key="expectation">
        { form:gen-selector-for('ExpectationScales', $lang, ";multiple=no;typeahead=no") }
      </site:field>
      <site:field Key="appropriateness">
        { form:gen-selector-for('FitScales', $lang, ";multiple=no;typeahead=no") }
      </site:field>
      <site:field Key="support">
        { form:gen-selector-for('SupportScales', $lang, ";multiple=no;typeahead=no") }
      </site:field>
    </site:view>

  else
    <site:view/>
