xquery version "1.0";
(: --------------------------------------
   Case tracker pilote application

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Generates extension points for the stage search formular.

   Basically this is a stub file to call database field generation functions in lib/form.xqm.

   BE AWARE OF THE DEFAULT NAMESPACE !

   January 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace form = "http://oppidoc.com/oppidum/form" at "../../lib/form.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace site = "http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=text/xml";

let $cmd := request:get-attribute('oppidum.command')
let $lang := string($cmd/@lang)
return
  <site:view>
    <site:field Key="countries">
      { form:gen-selector-for('Countries', $lang, ";multiple=yes;xvalue=Country;typeahead=yes") }
    </site:field>
  </site:view>
