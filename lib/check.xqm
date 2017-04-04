xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidoc Business Application Development Framework

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Validation utilities

   April 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved. 
   ------------------------------------------------------------------ :)

module namespace check = "http://oppidoc.com/ns/cctracker/check";

(: ======================================================================
   Returns true() if $mail is a valid e-mail address
   ======================================================================
:)
declare function check:is-email ( $mail as xs:string? ) as xs:boolean {
  let $m := normalize-space($mail)
  return
    ($m ne '') and matches($m, '^\w([\-_\.]?\w)+@\w([\-_\.]?\w)+\.[a-z]{2,6}$')
};
