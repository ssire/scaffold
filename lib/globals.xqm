xquery version "1.0";
(: --------------------------------------
   SCAFFOLD - Case tracker pilote library

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Global variables or utility functions for the application

   Customize this file for your application

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace globals = "http://oppidoc.com/oppidum/globals";

(: Application collection name and project folder name :)
declare variable $globals:app-name := 'scaffold';
declare variable $globals:app-folder := 'projects';

(: Database paths :)
declare variable $globals:dico-uri := '/db/www/scaffold/config/dictionary.xml';
declare variable $globals:cache-uri := '/db/caches/scaffold/cache.xml';
declare variable $globals:global-info-uri := '/db/sites/scaffold/global-information';
declare variable $globals:settings-uri := '/db/www/scaffold/config/settings.xml';
declare variable $globals:log-file-uri := '/db/debug/login.xml';
declare variable $globals:application-uri := '/db/www/scaffold/config/application.xml';

(: Application entities paths :)
declare variable $globals:persons-uri := '/db/sites/scaffold/persons/persons.xml';
declare variable $globals:enterprises-uri := '/db/sites/scaffold/enterprises/enterprises.xml'; (: NOT IMPLEMENTED :)
declare variable $globals:cases-uri := '/db/sites/cases'; (: NOT IMPLEMENTED :)
