xquery version "1.0";

module namespace template = "http://oppidoc.com/ns/cctracker/template";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "globals.xqm";
import module namespace misc = "http://oppidoc.com/ns/cctracker/misc" at "util.xqm";
import module namespace user = "http://oppidoc.com/ns/user" at "user.xqm";

declare function template:get-document( $name as xs:string, $case as element(), $lang as xs:string ) as element() {
  template:get-document($name, $case, (), $lang)
};

declare function template:get-document( $name as xs:string, $case as element(), $activity as element()?, $lang as xs:string ) as element() {
  let $src := fn:doc($globals:templates-uri)/Templates/Template[@Mode eq 'read'][@Name eq $name]
  return
    if ($src) then
      misc:unreference(util:eval(string-join($src/text(), ''))) (: FIXME: $lang :)
    else
      oppidum:throw-error('CUSTOM', concat('Missing "', $name, '" template for read mode'))
};

declare function template:save-document( $name as xs:string, $case as element(), $form as element() ) as element() {
  template:save-document($name, $case, (), $form)
};

declare function template:save-document(
  $name as xs:string, 
  $case as element(), 
  $activity as element(), 
  $form as element() 
  ) as element()
{
  let $date := current-dateTime()
  let $uid := user:get-current-person-id() 
  let $src := fn:doc($globals:templates-uri)/Templates/Template[@Mode eq 'update'][@Name eq $name]
  return
    if ($src) then
      let $delta := misc:prune(util:eval(string-join($src/text(), '')))
      return (
        misc:apply-updates(if ($activity) then $activity else $case, $delta),
        oppidum:throw-message('ACTION-UPDATE-SUCCESS', ())
        )
    else
      oppidum:throw-error('CUSTOM', concat('Missing "', $name, '" template for update mode'))
};
