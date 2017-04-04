xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidoc Business Application Development Framework

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Mail utilities to generate notifications and to archive mail messages

   Variables are defined in config/variables.xml

   Extra variables (not defined in config/variables.xml) include : 

    Mail_To
    Mail_CC
    Mail_From
    Mail_From
    First_Name
    Last_Name
    Link_To_Form
    Login
    Password
    Action_Verb
    Status_Name

   January 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved. 
   ------------------------------------------------------------------ :)

module namespace email = "http://oppidoc.com/ns/cctracker/mail";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "globals.xqm";
import module namespace display = "http://oppidoc.com/oppidum/display" at "display.xqm";
import module namespace media = "http://oppidoc.com/ns/cctracker/media" at "media.xqm";
import module namespace services = "http://oppidoc.com/ns/services" at "services.xqm";
import module namespace alert = "http://oppidoc.com/ns/cctracker/alert" at "../modules/workflow/alert.xqm";
import module namespace workflow = "http://platinn.ch/coaching/workflow" at "../modules/workflow/workflow.xqm";
import module namespace custom = "http://oppidoc.com/ns/application/custom" at "../app/custom.xqm";

(: ======================================================================
   Generic function to generate e-mail template variables for a given 
   template name and given a case and an activity and extra variables
   Variables are resolved FIRST in the extra variables and SECOND 
   using config/variables.xml definitions which must be kept up to date
   ====================================================================== 
:)
declare function email:gen-variables-for( 
  $name as xs:string,
  $lang as xs:string,
  $case as element()?,
  $activity as element()?,
  $extras as element()* ) as element() 
{
  <vars>
    {
    let $template := fn:collection($globals:global-info-uri)/Emails/*[@Name eq $name][@Lang eq $lang]
    return
      if ($template) then 
        let $keys := tokenize(string($template), '@@')[position() mod 2 = 0]
        let $defs := fn:doc($globals:variables-uri)/Variables
        return
          for $k in $keys
          return
            if ($extras[@name eq $k]) then
              $extras[@name eq $k]
            else if ($defs/Variable[Name eq $k]) then
              let $d := $defs/Variable[Name eq $k]
              return 
                if ($d/Name[. eq $k]/preceding-sibling::Name) then
                  (: multi-variables definitions are generated at first pass :)
                  ()
                else
                  let $res := util:eval($d/Expression/text())
                  return
                    if ($res instance of element()+) then
                      $res
                    else
                      <var name="{ $k }">{ string($res) }</var>
            else
              <var name="{ $k }">MISSING ({ $k })</var>
      else
        ()
      }
  </vars>
};

(: ======================================================================
   Generates Email model with variables expansion
   ====================================================================== 
:)
declare function email:render-email( 
  $name as xs:string,
  $lang as xs:string,
  $case as element()?,
  $activity as element()?,
  $extras as element()* ) as element() 
{
  media:render-email($name, email:gen-variables-for($name, $lang, $case, $activity, $extras), $lang)
};

(: ======================================================================
   Generates Alert model with variables expansion
   ====================================================================== 
:)
declare function email:render-alert( 
  $name as xs:string,
  $lang as xs:string,
  $case as element()?,
  $activity as element()?,
  $extras as element()* ) as element() 
{
  media:render-alert($name, email:gen-variables-for($name, $lang, $case, $activity, $extras), $lang)
};

(: ======================================================================
   Generates Alert model with variables expansion (version w/o extras)
   ====================================================================== 
:)
declare function email:render-alert( 
  $name as xs:string,
  $lang as xs:string,
  $case as element()?,
  $activity as element()?) as element() 
{
  media:render-alert($name, email:gen-variables-for($name, $lang, $case, $activity, ()), $lang)
};

