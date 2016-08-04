xquery version "3.0";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

(: redirect requests for app root ('') to '/' :)
if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{(request:get-header('nginx-request-uri'), request:get-uri())[1]}/"/>
    </dispatch>
    
(: handle request for landing page, e.g., http://history.state.gov/ :)
else if ($exist:path eq "/") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/index.xq"/>
    </dispatch>

(: handle request for OpenRefine Reconciliation Service :)
else if (matches($exist:path, "^/reconcile$")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/reconcile.xq"/>
    </dispatch>

(: handle request for person HTML :)
else if (matches($exist:path, "^/id/\d+$")) then
    let $id := replace($exist:path, "^/id/(\d+)$", "$1")
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/modules/index.xq">
                <add-parameter name="id" value="{$id}"/>
            </forward>
        </dispatch>

(: handle request for person XML :)
else if (matches($exist:path, "^/id/\d+\.xml$")) then
    let $id := replace($exist:path, "^/id/(\d+)\.xml$", "$1")
    let $log := console:log($id)
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/modules/get-xml.xq">
                <add-parameter name="id" value="{$id}"/>
            </forward>
        </dispatch>

(: handle requests for ajax services :)
else 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <ignore/>
    </dispatch>