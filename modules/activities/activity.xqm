xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Activity shared functions between modules activities and cases

   July 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace activity = "http://platinn.ch/coaching/activity";
import module namespace display = "http://oppidoc.com/oppidum/display" at "../../lib/display.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";

(: ======================================================================
   Constructs an Activity model for displaying 
   Basically that means it must resolve references
   NOTE: we could delay this to the XSLT transformation but unfortunately 
   using document() function in XSLT does not work under Tomcat
   ======================================================================
:)
declare function activity:gen-activity-for-viewing( $case as element(), $activity as element(), $lang as xs:string ) {
  <Activity>
    { $activity/No }
    <ResponsibleCoach>{ display:gen-person-name($activity/Assignment/ResponsibleCoachRef/text(), $lang) }</ResponsibleCoach>
    <CreationDate>{ display:gen-display-date($activity/CreationDate/text(), $lang) }</CreationDate>
    <Phase>{ display:gen-name-for('Phases', $case/Information/Call/PhaseRef, $lang) }</Phase>
    <Hours>{ $activity/FundingRequest/Budget/Tasks/TotalNbOfHours/text() }</Hours>
    <ServiceName>{ display:gen-name-for('Services', $activity/Assignment/ServiceRef, $lang) }</ServiceName>
    <Status>{ display:gen-name-for('ActivityWorkflowStatus', $activity/StatusHistory/CurrentStatusRef, 'en') }</Status>
  </Activity>
};

(: ======================================================================
   Returns the list of activities to display in case workflow view
   ======================================================================
:) 
declare function activity:gen-activities-for-case( $case as element()?, $lang as xs:string ) as element()* {
  for $activity in $case/Activities/Activity
  return  activity:gen-activity-for-viewing($case, $activity, $lang)
};
