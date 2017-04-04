xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   Case workflow controller that manages the display of a case state and documents.
   Generates a display model to be transformed into the HTML UI by workflow.xsl implementing
   the Workflow, Tab, Drawer and Documents (i.e. accordion) widgets.

   NOTE:
   - localized workflow state name are part of the model (Dictionary) element and injected in workflow.xsl
     to avoid duplicating global-information.xml content into dictionary.xml

   January 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../../lib/display.xqm";
import module namespace access = "http://oppidoc.com/oppidum/access" at "../../lib/access.xqm";
import module namespace workflow = "http://platinn.ch/coaching/workflow" at "../workflow/workflow.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $case-no := string($cmd/resource/@name)
let $lang := string($cmd/@lang)
let $case := fn:collection($globals:cases-uri)/Case[No eq $case-no]
let $errors := () (:access:pre-check-case($case, $m, (), ()):)
return
  if (empty($errors)) then
    <Display ResourceNo="{$case-no}" Mode="workflow">
      <Cartouche>
        <Window>{ concat($case/Information/Title, " case (", display:gen-display-date($case/CreationDate, 'en'), ")") }</Window>
        <Title>
          {
          workflow:gen-source($cmd/@mode, $case),
          workflow:gen-title($case, $lang)
          }
        </Title>
      </Cartouche>
      { workflow:gen-workflow-steps('Case', $case, $lang) }
      <Tabs>
        <!-- ************* -->
        <!-- Documents tab -->
        <!-- ************* -->
        <Tab Id="case" class=" active">
          <Name loc="workflow.tab.documents">Documents</Name>
          { 
          workflow:gen-information('Case', $case, (), $lang) 
          }
        </Tab>
        <!-- ***************** -->
        <!-- Case messages tab -->
        <!-- ***************** -->
        <Tab Id="case-alerts" Counter="Alert" ExtraFeed="case-init">
          <Name loc="workflow.tab.case.messages">Case messages</Name>
          <Drawer Command="edit" loc="action.add.message" PrependerId="c-case-alerts-list" class="case">
            <Title loc="workflow.title.case.messages">Messages</Title>
            <Initialize>alerts?goal=init</Initialize>
            <Controller>alerts</Controller>
            <Template>../templates/mail?goal=create</Template>
          </Drawer>
          { workflow:gen-alerts-list('Case', 'c-case-alerts-list', $case, '', $lang) }
        </Tab>
        <!-- ********************** -->
        <!-- List of activities tab -->
        <!-- ********************** -->
        { workflow:gen-activities-tab($case, (), $lang) }
        <!-- *********** -->
        <!-- Who is tab -->
        <!-- *********** -->
        <Tab Id="whois">
          <Name loc="workflow.tab.whois">Who is</Name>
          <Controller>{$case-no}/whois</Controller>
          <Heading class="activity">
            <Title loc="workflow.title.activity.whois">Who is</Title>
          </Heading>
          <div class="ajax-res"/>
        </Tab>
      </Tabs>
      <Modals>
        <Modal Id="c-alert" Width="620" data-backdrop="static" data-keyboard="false">
          <Name>Send and archive an email message</Name>
          <Legend class="text-info">The status has been changed with success. You now have the possibility to send a notification message by e-mail to some stakeholders in relation with the new status. You may also choose not to send it.</Legend>
          <Initialize>alerts?goal=init&amp;from=status</Initialize>
          <Controller>alerts?next=redirect</Controller>
          <Template>../templates/mail?goal=create&amp;auto=1</Template>
          <Commands>
            <Save data-replace-type="event"><Label loc="action.send">Send</Label></Save>
            <Cancel><Label loc="action.dontSend">Continue w/o sending</Label></Cancel>
          </Commands>
        </Modal>
        <Modal Id="c-alert-details" Width="700">
          <Name loc="term.alert">Alert messages</Name>
          <div class="ajax-res"/>
        </Modal>
      </Modals>
      <Dictionary>
        <WorkflowStatus>
          { globals:get-normative-selector-for('CaseWorkflowStatus')/* }
        </WorkflowStatus>
      </Dictionary>
    </Display>
  else
    $errors
