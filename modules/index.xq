xquery version "3.0";

import module namespace console="http://exist-db.org/xquery/console";
import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace people="http://history.state.gov/ns/xquery/people" at "/db/apps/people/modules/people.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "html5";
declare option output:media-type "text/html";

let $people := collection('/db/apps/people/data')
let $view-all := request:get-parameter('view', ())
let $q := request:get-parameter('q', ())
let $remarks := request:get-parameter('remarks', ())
let $id := request:get-parameter('id', ())
let $content := 
    <div>
        <form class="form-inline" action="{$people:app-base}" method="get">
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
        if ($view-all or $q or $remarks or $id) then
            ()
        else 
            <div id="about">
                <h2>About</h2>
                <p>“People” is a draft-stage database of persons who played some role in U.S. foreign relations, 1776–present, drawn from select Office of the Historian publications and datasets. It currently contains {format-number(count($people), '#,###.##')} person records, consolidated and de-duplicated from {format-number(count(collection('/db/apps/people/data')//source-url[parent::original]), '#,###.##')} entries, and can be searched using the form above, downloaded as a complete dataset via the <a href="https://github.com/HistoryAtState/people">HistoryAtState/people</a> repository on GitHub, installed on ones computer as part of <a href="https://github.com/HistoryAtState/hsg-project">history.state.gov’s suite of eXist applications</a>, or accessed as an OpenRefine Reconciliation Service (see <a href="#openrefine">OpenRefine</a> below). To view a table with each person’s name and most frequent description, select <a href="{$people:app-base}?view=all">View All</a>.</p>
                <div id="sources">
                    <h3>Sources</h3>
                    <ol>
                        <li><a href="https://history.state.gov/historicaldocuments">The <em>Foreign Relations of the United States</em> (<em>FRUS</em>) series</a>: The official documentary history of U.S. foreign relations. Many volumes contain a List of Persons, people who played a significant role in the volume. These lists consist of the person’s name and a brief description of their role during the period covered by the volume. (The raw data is available at the <a href="https://github.com/HistoryAtState/frus">HistoryAtState/frus</a> GitHub repository.)</li>
                        <li><a href="https://history.state.gov/departmenthistory/visits"><em>Visits to the United States by Foreign Leaders and Heads of State</em></a>: A comprehensive database of official visits by foreign leaders and heads of state. (The raw data is available at the <a href="https://github.com/HistoryAtState/visits">HistoryAtState/visits</a> GitHub repository.)</li>
                        <li><a href="https://history.state.gov/departmenthistory/principals-chiefs"><em>Principal Officers and Chiefs of Mission of the U.S. Department of State</em></a>: A comprehensive database of U.S. ambassadors and principal officers at and above the rank of Assistant Secretary, including dates of birth and death. (The raw data is available at the <a href="https://github.com/HistoryAtState/pocom">HistoryAtState/pocom</a> GitHub repository.)</li>
                        <li>Presidents of the United States</li>
                    </ol>
                </div>
                <div id="features">
                    <h3>Features</h3>
                    <ul>
                        <li><strong>Many variants:</strong> The database preserves and exposes all variant spellings of a person’s name, as captured in the source datasets. These variants most often arise from changes in the spelling of a person’s name over time (e.g., the change from “Teng Hsiao-p’ing” to “Deng Xiaoping”), orthographic variants (the many spellings of “Muammar Qaddafi”), and house style, but also reflect contemporary usage in archival sources and, occasionally, typos in the source publication or dataset.</li>
                        <li><strong>Broad descriptions:</strong> The database preserves all descriptions, verbatim, from source publications and datasets, to help in finding people by the positions they held.</li>
                        <li><strong>Citations:</strong> Each name and description is linked back to its source publication or dataset.</li>
                        <li><strong>Search:</strong> The database allows all name and descriptions to be searched broadly or precisely. See <a href="#search">Searching the Database</a> below.</li>
                        <li><strong>Citable URLs:</strong> Each person record contains a unique, persistent identifier. During the current draft phase, identifiers and the application’s URL may change, but once the application is finalized, the identifiers and thus the URLs for the database’s records will be persistent, facilitating citation and integration with linked data applications.</li>
                        <li><strong>Integrated with OpenRefine:</strong> <a href="http://openrefine.org/">OpenRefine</a>, the free, open source tool for cleaning up messy data, can query this database thanks to its support for OpenRefine’s Reconciliation Service API. Researchers can paste names of people into OpenRefine and allow OpenRefine to query this database and provide suggestions.</li>
                    </ul>
                    <p>Each person record contains the following information:</p>
                    <ul>
                        <li><strong>Names:</strong> Besides all variants from the source publications and datasets, each person entry contains a <em>preferred</em> spelling, which appears as the main entry. Some records also contain <em>alternate</em> spellings, known valid alternates. When source names contained military or royal titles, the titles are listed in a <em>titles extracted from names</em> field.</li>
                        <li><strong>Remarks:</strong> Either the source description (as in the case of entries from <em>FRUS</em>) or a summary of the information from the source (as in the case of the other datasets).</li>
                        <li><strong>Dates:</strong> When available, the database captures the year of birth and death. Most of this information currently comes from the <em>Principal Officers and Chiefs of Mission</em> database.</li>
                        <li><strong>ID:</strong> A unique number identifier serves as the persistent identifier of each person.</li>
                    </ul>
                </div>
                <div id="search">
                    <h3>Searching the database</h3>
                    <p>The database allows search within the “names” and “remarks” fields of each person record. By default, the database searches for all terms entered in each field. So a search of the names field for <code>John Smith</code> will return all records with the terms John AND Smith (not necessarily in this order), not all records containing either John OR Smith. To broaden the query, use the boolean <code>OR</code> operator: <code>John or Smith</code>. The database also supports phrase searches (<code>"John Smith"</code>) and wildcards (<code>?</code> for a single character, <code>*</code> for zero or more characters). Punctuation is dropped from searches. Examples of these searches include:</p>
                    <ul>
                        <li>[to be added]</li>
                    </ul>
                </div>
                <div id="contributing">
                    <h3>Contributing</h3>
                    <p>If you notice a problem for an entry or have a question, please <a href="https://github.com/HistoryAtState/people/issues/new">file an issue</a> on GitHub (requires a free GitHub account). Pull requests are also welcome.</p>
                </div>
                <div id="openrefine">
                    <h3>OpenRefine Reconciliation Service</h3>
                    <p>This application’s OpenRefine Reconciliation Service endpoint is <a href="{$people:open-refine-endpoint-url}">{$people:open-refine-endpoint-url}</a>. </p>
                </div>
            </div>
        }
        {
            if ($view-all) then
                <div>
                    <p>Showing all {count($people)} people. (This summary view shows primary name, most frequent remark, the number of variants for each name and remark, and the number of sources.)</p>
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
                let $query-options := 
                    <options>
                        <default-operator>and</default-operator>
                        <phrase-slop>0</phrase-slop>
                        <leading-wildcard>no</leading-wildcard>
                        <filter-rewrite>yes</filter-rewrite> 
                    </options>
                let $hits := 
                    if ($q ne '' and $remarks ne '') then 
                        (
                            $people//name[ft:query(., $q, $query-options)]/ancestor::person
                            intersect
                            $people//p[ft:query(., $remarks, $query-options)]/ancestor::person
                        )
                    else if ($q ne '') then 
                        $people//name[ft:query(., $q, $query-options)]/ancestor::person
                    else 
                        $people//p[ft:query(., $remarks, $query-options)]/ancestor::person
                return
                    <div>
                        <p>{count($hits)} hits for { if ($q ne '') then concat('name “', $q, '”') else ()} { if ($remarks ne '') then concat('remarks “', $remarks, '”') else ()}. {if ($hits) then '(This summary view shows primary name, most frequent remark, the number of variants for each name and remark, and the number of sources.)' else 'Please try again.'}</p>
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
                            <li>ID: {$id}&#0160;<a href="{$people:app-base}id/{$id}.xml">(View XML)</a></li>
                            <li>Year of Birth: {($person/birth-year/string(), '?')[. ne ''][1]}</li>
                            {if ($person/death-year ne '') then <li>Year of Death: {$person/death-year/string()}</li> else ()}
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
                                            <li>{people:source-url-to-link($n)}</li>
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
                                                    <li>{people:source-url-to-link($n)}</li>
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
                                                <li>{people:source-url-to-link($n)}</li>
                                        }</ul></td>
                                    </tr>
                            }</tbody>
                        </table>
                        <script>$(function () {{ $('[data-toggle="popover"]').popover() }})</script>
                    </div>
            else ()
        }
    </div>
let $site-title := 'People'
let $page-title := $content//h2
let $titles := if ($page-title = 'About') then $site-title else ($site-title, $page-title)
return 
    (
        (: strip search box from google refine results :)
        if (contains(request:get-header('Referer'), ':3333/')) then 
            people:wrap-html($content//div[@id = 'entry'], $titles)
        else
            people:wrap-html($content, $titles)
    )