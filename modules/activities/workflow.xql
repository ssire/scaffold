xquery version "1.0";
(: --------------------------------------
   Oppidoc Business Application Development Framework

   Authors: Stéphane Sire <s.sire@oppidoc.fr>

   Activity workflow controller

   Manages the display of an activity state and documents.
   Generates a page model to be transformed into the HTML UI by workflow.xsl
   using Workflow, Tab, Drawer and Documents (i.e. accordion) vocabulary.

   NOTE:
   - localized workflow state name are part of the model (Dictionary) element and injected in workflow.xsl
     to avoid duplicating global-information.xml content into dictionary.xml

   November 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../../lib/display.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace activity = "http://platinn.ch/coaching/activity" at "../activities/activity.xqm";
import module namespace workflow = "http://platinn.ch/coaching/workflow" at "../workflow/workflow.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $case-no := tokenize($cmd/@trail, '/')[2]
let $activity-no := string($cmd/resource/@name)
let $lang := string($cmd/@lang)
let $case := fn:collection($globals:cases-uri)/Case[No eq $case-no]
let $activity := $case/Activities/Activity[No = $activity-no]
let $errors := () (:access:pre-check-activity($case, $activity, $m, (), ()):)
return
  if (empty($errors)) then
    <Display ResourceNo="{$activity-no}" Mode="workflow">
      <Cartouche>
        <Window>{ concat($case/Information/Title, " coaching activity (", display:gen-display-date($case/CreationDate, 'en'), ")") }</Window>
        <Title LinkToCase="{ $case/No }">
          {
          workflow:gen-source($cmd/@mode, $case),
          workflow:gen-title($case, $lang)
          }
        </Title>
      </Cartouche>
      { workflow:gen-workflow-steps('Activity', $activity, $lang) }
      <Tabs>
        <!-- ************* -->
        <!-- Documents tab -->
        <!-- ************* -->
        <Tab Id="case" Link="../../{$case/No}">
          <Name loc="workflow.tab.case.info">Case</Name>
          <Legend>Click on Case title at the top to return Case workflow view</Legend>
        </Tab>
        <!-- ***************** -->
        <!-- Case messages tab -->
        <!-- ***************** -->
        <Tab Id="case-alerts" Counter="Alert" ExtraFeed="case-init">
          <Name loc="workflow.tab.case.messages">Case messages</Name>
          <Heading class="case">
            <Title loc="workflow.title.case.messages">Messages</Title>
          </Heading>
          { workflow:gen-alerts-list('Case', 'c-case-alerts-list', $case, '../../', $lang) }
        </Tab>
        { workflow:gen-activities-tab($case, $activity, $lang) }
        { workflow:gen-new-activity-tab($case, $activity, '../../') }
        <!-- ************* -->
        <!-- Documents tab -->
        <!-- ************* -->
        <Tab Id="activity" class=" active">
          <Name loc="workflow.tab.activity.info">Activity information</Name>
          { 
          workflow:gen-information('Activity', $case, $activity, $lang) 
          }
        </Tab>
        <!-- ********************* -->
        <!-- Activity messages tab -->
        <!-- ********************* -->
        <Tab Id="activity-alerts" Counter="Alert" ExtraFeed="funding-request">
          <Name loc="workflow.tab.activity.messages">Coaching activity messages</Name>
          <Drawer Command="edit" loc="action.add.message" PrependerId="c-activity-alerts-list">
            <Title loc="workflow.title.activity.messages">Messages</Title>
            <Initialize>alerts?goal=init</Initialize>
            <Controller>alerts</Controller>
            <Template>../../../templates/mail?goal=create</Template>
          </Drawer>
          { workflow:gen-alerts-list('Activity', 'c-activity-alerts-list', $activity, '', $lang) }
        </Tab>
        <!--<Tab Id="whois">
          <Name loc="workflow.tab.whois">Who is</Name>
          <Controller>{$activity-no}/whois</Controller>
          <Heading class="activity">
            <Title loc="workflow.title.activity.whois">Who is</Title>
          </Heading>
          <div class="ajax-res"/>
        </Tab>-->
      </Tabs>
      <Modals>
        <Modal Id="c-alert" Width="620" data-backdrop="static" data-keyboard="false">
          <Name>Send and archive an email message</Name>
          <Legend class="text-info">The status has been changed with success. You now have the possibility to send a notification message by e-mail to some stakeholders in relation with the new status. You may also choose not to send it.</Legend>
          <Initialize>alerts?goal=init&amp;from=status</Initialize>
          <Controller>alerts?next=redirect</Controller>
          <Template>../../../templates/mail?goal=create&amp;auto=1</Template>
          <Commands>
            <Save data-replace-type="event"><Label loc="action.send">Send</Label></Save>
            <Cancel><Label loc="action.dontSend">Continue w/o sending</Label></Cancel>
          </Commands>
        </Modal>
        <Modal Id="c-alert-details" Width="700">
          <Name loc="term.alert">Alert messages</Name>
        </Modal>
      </Modals>
      <Dictionary>
        <WorkflowStatus>
          { globals:get-normative-selector-for('ActivityWorkflowStatus')/* }
        </WorkflowStatus>
      </Dictionary>
    </Display>
  else
    $errors
