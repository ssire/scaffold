xquery version "1.0";
(: --------------------------------------
   XQuery Business Application Development Framework

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Sample service to return options to dynamically load into a 'choice' plugin
   using an 'ajax' binding

   February 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare namespace json="http://www.json.org";

declare option exist:serialize "method=json media-type=application/json";

(: JSON protocol requires that items property contains an array
   do not forget to add a json:array="true" on items if it is unique 
:)
let $samples := 
  <samples>
    <sample cache="1">
      <items>
        { attribute { 'json:array' } { 'true' } }
        <label>Minny</label>
        <value>1</value>
      </items>
      <items>
        <label>Steve</label>
        <value>2</value>
      </items>
    </sample>
    <sample cache="2">
      <items>
        <label>John</label>
        <value>3</value>
      </items>
      <items>
        <label>Paul</label>
        <value>4</value>
      </items>  
      <items>
        <label>Saul</label>
        <value>5</value>
      </items>
    </sample>
    <sample cache="3">
      <items>
        <label>Raul</label>
        <value>6</value>
      </items>
      <items>
        <label>Bill</label>
        <value>7</value>
      </items>
      <items>
        <label>Melinda</label>
        <value>8</value>
      </items>
    </sample>
  </samples>
  
let $company := request:get-parameter('company', ())
return $samples/sample[@cache eq $company]
