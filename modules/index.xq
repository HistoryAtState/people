xquery version "3.0";

import module namespace console="http://exist-db.org/xquery/console";
import module namespace templates="http://exist-db.org/xquery/templates";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "html5";
declare option output:media-type "text/html";

declare function local:wrap-html($content as element(), $title as xs:string) {
    <html>
        <head>
            <title>{$title}</title>
            <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css" rel="stylesheet"/>
            <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
            <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
            <style type="text/css">
                body {{ font-family: HelveticaNeue, Helvetica, Arial, sans }}
                table {{ page-break-inside: avoid }}
                dl {{ margin-above: 1em }}
                dt {{ font-weight: bold }}
            </style>
            <style type="text/css" media="print">
                a, a:visited {{ text-decoration: underline; color: #428bca; }}
                a[href]:after {{ content: "" }}
            </style>
        </head>
        <body>
            <div class="container">
                <h3>{$title}</h3>
                {$content}
            </div>
        </body>
    </html>    
};

declare function local:source-url-to-link($source-url) {
    <a href="{$source-url}">{
        if (contains($source-url, 'historicaldocuments')) then
            substring-before(substring-after($source-url, '/historicaldocuments/'), '/persons')
        else if (contains($source-url, 'departmenthistory/people')) then
            concat('pocom/', substring-after($source-url, 'departmenthistory/people/'))
        else if (contains($source-url, 'visits')) then
            substring-after($source-url, '/departmenthistory/')
        else if (contains($source-url, 'presidents')) then
            substring-after($source-url, '/data/')
        else
            $source-url
    }</a>
};

let $app-base := '/exist/apps/people/'
let $people := collection('/db/apps/people/data')
let $title := 'People Browser'
let $view-all := request:get-parameter('view', ())
let $q := request:get-parameter('q', ())
let $remarks := request:get-parameter('remarks', ())
let $id := request:get-parameter('id', ())
let $content := 
    <div>
        <p>{count($people)} records. (<a href="{$app-base}?view=all">View all</a>.)</p>
        <form class="form-inline" action="{$app-base}" method="get">
            <div class="form-group">
                <label for="q" class="control-label">Search Names</label>
                <input type="text" name="q" id="q" class="form-control" value="{$q}"/>
            </div>
            <div class="form-group">
                <label for="remarks" class="control-label">Search Remarks</label>
                <input type="text" name="remarks" id="remarks" class="form-control" value="{$remarks}"/>
            </div>
            <button type="submit" class="btn btn-default">Submit</button>
        </form>
        {
            if ($view-all) then
                <div>
                    <p>Showing all {count($people)} people. Notes: (1) The name shown is the name that has been selected as the “preferred” form of the name; if acceptable alternates have been identified, these are also shown. The total number of variant spellings is shown in small gray text. (2) The remark shown is the most common description used for the person in the database. The total number of variant descriptions is shown in small gray text. (3) Select a person to see all variant names and remarks, along with other data about the person.</p>
                    <table class="table table-bordered table-striped">
                        <thead>
                            <tr>
                                <th class="col-md-1">ID</th>
                                <th class="col-md-3">Name</th>
                                <th>Remarks</th>
                                <th>Sources</th>
                            </tr>
                        </thead>
                        <tbody>
                        {
                            for $person in $people/person
                            let $preferred := $person/names/preferred/name
                            let $alternates := $person/names/alternates/name
                            let $originals := $person/names/originals/original
                            let $titles := $person/names/titles-from-name/title/name
                            let $remarks := $person/remarks/remark
                            let $birth := $person/birth-year
                            let $death := $person/death-year
                            let $name-variants-count := count($originals)
                            let $remark-variants-count := count($remarks)
                            let $id := $person/id/string()
                            order by $preferred collation "?lang=en-US" 
                            return
                                <tr>
                                    <td>{$id}</td>
                                    <td>
                                        <a href="./id/{$id}">{$preferred/string()}</a> {if (($birth, $death)[. ne '']) then <span> ({concat(($birth, '?')[. ne ''][1], '–', $death)})</span> else ()}
                                        {if ($alternates) then <ul class="list-unstyled">{for $n in $alternates return <li>{$n/string()}</li>}</ul> else ()}
                                        &#160;<span style="color: gray; font-size: smaller">{$name-variants-count}</span>
                                    </td>
                                    <td>
                                        {(for $remark in $person/remarks/remark[not(matches(., '^[Ss]ee '))] order by xs:integer($remark/@source-urls) return $remark)[last()]/p/string()}&#160;<span style="color: gray; font-size: smaller">{$remark-variants-count}</span>
                                    </td>
                                    <td>{sum($originals/@source-urls)}</td>
                                </tr>
                        }
                        </tbody>
                    </table>
                </div>
            else ()
        }
        {
            if (($q and $q ne '') or ($remarks and $remarks ne '')) then
                let $hits := 
                    if ($q ne '' and $remarks ne '') then 
                        (
                            $people//name[ft:query(., $q)]/ancestor::person
                            | 
                            $people//p[ft:query(., $remarks)]/ancestor::person
                        )
                    else if ($q ne '') then 
                        $people//name[ft:query(., $q)]/ancestor::person
                    else 
                        $people//p[ft:query(., $remarks)]/ancestor::person
                return
                    <div>
                        <p>{count($hits)} hits for { if ($q ne '') then concat('name “', $q, '”') else ()} { if ($remarks ne '') then concat('remarks “', $remarks, '”') else ()}. {if ($hits) then 'Notes: (1) The name shown is the name that has been selected as the “preferred” form of the name; if acceptable alternates have been identified, these are also shown. The total number of variant spellings is shown in small gray text. (2) The remark shown is the most common description used for the person in the database. The total number of variant descriptions is shown in small gray text. (3) Select a person to see all variant names and remarks, along with other data about the person.' else 'Please try again.'}</p>
                        <table class="table table-bordered table-striped">
                            <thead>
                                <tr>
                                    <th class="col-md-1">ID</th>
                                    <th class="col-md-3">Name</th>
                                    <th>Remarks</th>
                                    <th>Sources</th>
                                </tr>
                            </thead>
                            <tbody>
                            {
                                for $person in $hits
                                let $preferred := $person/names/preferred/name
                                let $alternates := $person/names/alternates/name
                                let $originals := $person/names/originals/original
                                let $titles := $person/names/titles-from-name/title/name
                                let $remarks := $person/remarks/remark
                                let $birth := $person/birth-year
                                let $death := $person/death-year
                                let $name-variants-count := count($originals)
                                let $remark-variants-count := count($remarks)
                                let $id := $person/id/string()
                                order by $preferred collation "?lang=en-US" 
                                return
                                    <tr>
                                        <td>{$id}</td>
                                        <td>
                                            <a href="./id/{$id}">{$preferred/string()}</a> {if (($birth, $death)[. ne '']) then <span> ({concat(($birth, '?')[. ne ''][1], '–', $death)})</span> else ()}
                                            {if ($alternates) then <ul class="list-unstyled">{for $n in $alternates return <li>{$n/string()}</li>}</ul> else ()}
                                            &#160;<span style="color: gray; font-size: smaller">{$name-variants-count}</span>
                                        </td>
                                        <td>
                                            {(for $remark in $person/remarks/remark[not(matches(., '^[Ss]ee '))] order by xs:integer($remark/@source-urls) return $remark)[last()]/p/string()}&#160;<span style="color: gray; font-size: smaller">{$remark-variants-count}</span>
                                        </td>
                                        <td>{sum($originals/@source-urls)}</td>
                                    </tr>
                            }
                            </tbody>
                        </table>
                    </div>
            else 
                ()
        }
        {
            if ($id and $id ne '') then
                let $person := collection('/db/apps/people/data')/person[id = $id]
                let $preferred := $person/names/preferred/name
                let $alternates := $person/names/alternates/name
                let $originals := $person/names/originals/original
                let $titles := $person/names/titles-from-name/title
                let $remarks := $person/remarks/remark
                let $authorities := $person/authorities/authority[. ne '']
                return
                    <div id="entry">
                        <h2>{$person/names/preferred/name/string(), if (count($preferred/genName) gt 1) then <span class="text-warning">{concat(' [', count($preferred/genName), ' gennames?]')}</span> else ()}</h2>
                        <ul>
                            <li>ID: {$id}&#0160;<a href="{$app-base}id/{$id}.xml">(View XML)</a></li>
                            <li>Year of Birth: {($person/birth-year/string(), '?')[. ne ''][1]}</li>
                            {if ($person/death-year ne '') then <li>Year of Death: {$person/death-year/string()}</li> else ()}
                            <!--<li>{$person/gender/string()} <em> (note: unless F, this values may be wrong)</em></li>-->
                        </ul>
                        <h3><ul class="list-unstyled">{
                            for $name in $person/names/alternates/name
                            return
                                <li>{$name/string()}</li>
                        }</ul></h3>
                        {
                            for $authority in $authorities
                            let $record-id := $authority/string()
                            let $authority-name := 'VIAF'
                            let $authority-url := 'https://viaf.org/viaf/'
                            let $url := $authority-url || $record-id
                            return
                                <p>{$authority-name}: <a href="{$url}">{$record-id}</a></p>
                        }
                        <table class="table table-bordered table-striped">
                            <thead>
                                <tr>
                                    <th>Original Rendering</th>
                                    <th class="col-md-3">Sources</th>
                                </tr>
                            </thead>
                            <tbody>{
                                for $original in $originals
                                let $name := $original/name
                                let $source-urls := $original/source-url
                                let $sources := 
                                    <ul>{
                                        for $n in $source-urls 
                                        order by $n 
                                        return 
                                            <li>{local:source-url-to-link($n)}</li>
                                    }</ul>
                                let $serialization-parameters := 
                                    <output:serialization-parameters>
                                        <output:method>html</output:method>
                                        <output:indent>no</output:indent>
                                    </output:serialization-parameters>
                                return
                                    <tr>
                                        <td>{$name/string()}</td>
                                        <td>
                                            <a tabindex="0" class="btn btn-default" role="button" data-toggle="popover" data-trigger="focus" title="{count($source-urls)} Sources" data-content="{serialize($sources, $serialization-parameters)}" data-html="true">{count($source-urls)}</a>
                                        </td>
                                    </tr>
                            }</tbody>
                        </table>
                        {
                            if ($titles) then 
                                <table class="table table-bordered table-striped">
                                    <thead>
                                        <tr>
                                            <th>Titles Extracted from Name Field</th>
                                            <th class="col-md-3">Sources</th>
                                        </tr>
                                    </thead>
                                    <tbody>{
                                        for $original in $titles
                                        let $name := $original/name
                                        let $source-urls := $original/source-url
                                        let $sources := 
                                            <ul>{
                                                for $n in $source-urls 
                                                order by $n 
                                                return 
                                                    <li>{local:source-url-to-link($n)}</li>
                                            }</ul>
                                        let $serialization-parameters := 
                                            <output:serialization-parameters>
                                                <output:method>html</output:method>
                                                <output:indent>no</output:indent>
                                            </output:serialization-parameters>
                                        return
                                            <tr>
                                                <td>{$name/string()}</td>
                                                <td>
                                                    <a tabindex="0" class="btn btn-default" role="button" data-toggle="popover" data-trigger="focus" title="{count($source-urls)} Sources" data-content="{serialize($sources, $serialization-parameters)}" data-html="true">{count($source-urls)}</a>
                                                </td>
                                            </tr>
                                    }</tbody>
                                </table>
                            else 
                                ()
                        }
                        <table class="table table-bordered table-striped">
                            <thead>
                                <tr>
                                    <th>Remarks</th>
                                    <th class="col-md-3">Sources</th>
                                </tr>
                            </thead>
                            <tbody>{
                                for $remark in $remarks
                                let $p := $remark/p
                                let $source-urls := $remark/source-url
                                return
                                    <tr>
                                        <td>{$p/string()}</td>
                                        <td><ul class="list-unstyled">{
                                            for $n in $source-urls 
                                            order by $n 
                                            return 
                                                <li>{local:source-url-to-link($n)}</li>
                                        }</ul></td>
                                    </tr>
                            }</tbody>
                        </table>
                        <script>$(function () {{ $('[data-toggle="popover"]').popover() }})</script>
                    </div>
            else ()
        }
    </div>
return 
    (
        (: strip search box from google refine results :)
        if (starts-with(request:get-header('Referer'), ('http://localhost:3333', 'http://127.0.0.1:3333'))) then 
            local:wrap-html($content//div[@id = 'entry'], $title)
        else
            local:wrap-html($content, $title)
    )