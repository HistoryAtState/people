xquery version "3.1";

module namespace pi="http://history.state.gov/ns/xquery/people-import";

import module namespace pocom="http://history.state.gov/ns/site/hsg/pocom-html" at "xmldb:exist:///db/apps/hsg-shell/modules/pocom-html.xqm";
import module namespace gsh="http://history.state.gov/ns/xquery/geospatialhistory" at "/db/apps/gsh/modules/gsh.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function pi:get-original($url) {
    let $is-frus := matches($url, '^https://history\.state\.gov/historicaldocuments')
    let $is-pocom := matches($url, '^https://history\.state\.gov/departmenthistory/people')
    return
        if ($is-frus) then
            let $analysis := analyze-string($url, '^https://history.state.gov/historicaldocuments/([^/]*?)/persons#(.*)$')
            let $vol-id := $analysis/fn:match/fn:group[@nr = '1']
            let $person-id := $analysis/fn:match/fn:group[@nr = '2']
            let $name := doc('/db/apps/frus/volumes/' || $vol-id || '.xml')/id($person-id)
            let $following := 
                if ($name/parent::tei:hi) then
                    $name/parent::tei:hi/following-sibling::node() 
                else 
                    $name/following-sibling::node()
            let $remark := replace(replace(normalize-space(string-join($following ! (if (./self::element() and following-sibling::node()[1]/self::element()) then (., ' ') else . ))), '\s([.,;)])', '$1'), '\( ', '(')
            let $remark := if (matches($remark, '^\s*[,.]\s*')) then replace($remark, '^\s*[,.]+\s*', '') else $remark
            return
                <original>
                    <name>{$name}</name>
                    <remark>{$remark}</remark>
                </original>
        else if ($is-pocom) then
            let $analysis := analyze-string($url, '^https://history\.state\.gov/departmenthistory/people/(.*?)$')
            let $person-id := $analysis/fn:match/fn:group[@nr = '1']
            let $initial := substring($person-id, 1, 1)
            let $person := doc('/db/apps/pocom/people/' || $initial || '/' || $person-id || '.xml')/person
            let $name := $person/persName ! (string-join((./surname, ./forename, ./genName), ", "))
            let $birth := $person/birth/string()
            let $death := $person/death/string()
            let $remark := 
                let $id := $person/id
                let $roles := collection('/db/apps/pocom')//person-id[. = $id]/..
                let $titles := 
                    for $role in $roles 
                    let $role-title-id := $role/role-title-id
                    let $roleinfo := collection('/db/apps/pocom')/*[id = $role-title-id]
                    let $roletitle := $roleinfo/names/singular/text()
                    let $rolesubtype := $roleinfo/category
                    let $roleclass := root($role)/*/name()
                    let $current-territory-id := root($role)/*/territory-id
                    let $contemporary-territory-id := $role/contemporary-territory-id
                    let $whereserved := if ($contemporary-territory-id) then (gsh:territory-id-to-short-name($contemporary-territory-id), (: fall back on original country ID in case it's different than GSH's country ID :) collection($pocom:OLD-COUNTRIES-COL)//id[. = $contemporary-territory-id]/label)[1] else ()
                    let $dates := distinct-values(for $date in $role//date[not(empty(.)) and not(. = '')] order by $date return ($date/string() ! substring(., 1, 4)))
                    order by $dates[1]
                    return
                        concat(
                            if ($roleclass eq 'country-mission') then 
                                concat($roletitle, ' (', $whereserved, ')')
                            else if ($roleclass eq 'org-mission') then
                                $roletitle
                            else (: if ($roleclasss eq 'principal-position') then :)
                                $roletitle
                            ,
                            if (exists($dates)) then
                                concat(
                                    ', ',
                                    if ($dates[1] = $dates[last()]) then 
                                        $dates[1] 
                                    else
                                        $dates[1] || '–' || $dates[last()]
                                    )
                            else
                                ()
                        )
                return
                    concat(string-join(distinct-values($titles), '; '), '.')
            return 
                <original>
                    <name>{$name}</name>
                    <remark>{$remark}</remark>
                    <birth>{$birth}</birth>
                    <death>{$death}</death>
                </original>
        else
            <error>Couldn't recognize the source-url {$url}</error>
};


declare function pi:get-original-name($url as xs:string) {
    let $original := pi:get-original($url)
    return
        if ($original/self::error) then $original else $original/name/node()
};

declare function pi:get-original-remarks($url as xs:string) {
    let $original := pi:get-original($url)
    return
        if ($original/self::error) then $original else $original/remarks/node()
};

declare function pi:get-person($id) {
    collection('/db/apps/people/data')//person[id = $id]
};

declare function pi:get-entries($url) {
    let $entries := collection('/db/apps/people/data')//source-url[. = $url]/..
    let $ids := $entries/ancestor::person/id
    return
        <entries person-id="{string-join($ids, ';')}">{$entries ! element {./name()} {./*[1]/string()} }</entries>
};

declare function pi:get-entries($id, $url) {
    let $person := pi:get-person($id)
    let $entries := $person//source-url[. = $url]/..
    return
        <entries person-id="{$id}">{$entries/*[1]}</entries>
};

declare function pi:update-name($person-id as xs:string, $source-url as xs:string, $new-name as xs:string) {
    let $person := pi:get-person($person-id)
    let $source-url-entry := $person//source-url[. = $source-url][parent::original]
    let $new-entry := 
        <original>
            <name>{normalize-space($new-name)}</name>
            <source-url>{$source-url}</source-url>
        </original>
    return 
        (
            if ($source-url-entry) then update delete $source-url-entry else ()
            ,
            update insert $new-entry into $person/names/originals
        )
};

declare function pi:update-remark($person-id as xs:string, $source-url as xs:string, $new-remark as xs:string) {
    let $person := pi:get-person($person-id)
    let $source-url-entry := $person//source-url[. = $source-url][parent::remark]
    let $new-entry := 
        <remark>
            <p>{normalize-space($new-remark)}</p>
            <source-url>{$source-url}</source-url>
        </remark>
    return 
        (
            if ($source-url-entry) then update delete $source-url-entry else ()
            ,
            update insert $new-entry into $person/remarks
        )
};

declare function pi:update-title($person-id as xs:string, $source-url as xs:string, $new-title as xs:string) {
    let $person := pi:get-person($person-id)
    let $source-url-entry := $person//source-url[. = $source-url][parent::title]
    let $new-entry := 
        <title>
            <name>{normalize-space($new-title)}</name>
            <source-url>{$source-url}</source-url>
        </title>
    return 
        (
            if ($source-url-entry) then update delete $source-url-entry else ()
            ,
            update insert $new-entry into $person/names/titles-from-name
        )
};

declare function pi:consolidate-originals($person-id) {
    let $person := pi:get-person($person-id)
    let $originals := $person/names/originals
    let $distinct-originals := distinct-values($originals/original[source-url]/name)
    let $new-originals := 
        <originals variants="{count($distinct-originals)}">
            {
            for $name in $distinct-originals
            let $source-urls := for $url in $originals//source-url[preceding-sibling::name = $name] order by $url return $url
            order by $source-urls[1] 
            return
                <original source-urls="{count($source-urls)}">
                    <name>{$name}</name>
                    {$source-urls}
                </original>
            }
        </originals>
    let $remarks := $person/remarks
    let $distinct-remarks := distinct-values($remarks/remark[source-url]/p)
    let $new-remarks := 
        <remarks variants="{count($distinct-remarks)}">
            {
            for $remark in $distinct-remarks
            let $source-urls := for $url in $remarks//source-url[preceding-sibling::p = $remark] order by $url return $url
            order by $source-urls[1]
            return
                <remark source-urls="{count($source-urls)}">
                    <p>{$remark}</p>
                    {$source-urls}
                </remark>
            }
        </remarks>
    let $titles := $person/names/titles-from-name
    let $distinct-titles := distinct-values($titles/title[source-url]/name[. ne ''])
    let $new-titles := 
        <titles-from-name variants="{count($distinct-titles)}">
            {
            for $title in $distinct-titles
            let $source-urls := for $url in $titles//source-url[preceding-sibling::name = $title] order by $url return $url
            order by $source-urls[1]
            return
                <title source-urls="{count($source-urls)}">
                    <name>{$title}</name>
                    {$source-urls}
                </title>
            }
        </titles-from-name>
    return 
        (
        update replace $originals with $new-originals
        ,
        update replace $titles with $new-titles
        ,
        update replace $remarks with $new-remarks
        )
};

declare function pi:create-new-person($preferred as xs:string, $birth-year as xs:integer, $death-year as xs:integer) as xs:integer {
    let $new-id := max(collection('/db/apps/people/data')//id) + 1
    let $new-person-template :=
        <person>
            <id>{$new-id}</id>
            <authorities>
                <authority service="viaf"/>
            </authorities>
            <names>
                <preferred>
                    <name>{$preferred}</name>
                </preferred>
                <alternates/>
                <originals variants="0"/>
                <titles-from-name variants="0"/>
            </names>
            <birth-year>{$birth-year}</birth-year>
            <death-year>{$death-year}</death-year>
            <remarks variants="0"/>
        </person>
    let $store := pi:store($person)
    return 
        $new-id
};

declare function pi:find-differences($string1 as xs:string, $string2 as xs:string) {
    <differences>{
        if ($string1 = $string2) then 
            ()
        else
            let $codepoints1 := string-to-codepoints($string1)
            let $codepoints2 := string-to-codepoints($string2)
            for $codepoint1 at $n in $codepoints1
            let $codepoint2 := $codepoints2[$n]
            return
                if ($codepoint1 = $codepoint2) then 
                    () 
                else 
                    <difference position="{$n}">
                        <string1 codepoint="{$codepoint1}">{codepoints-to-string($codepoint1)}</string1>
                        <string2 codepoint="{$codepoint2}">{codepoints-to-string($codepoint2)}</string2>
                    </difference>
    }</differences>
};

declare function pi:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            pi:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: limit collections to 100 documents  :)
declare function pi:id-to-collection-components($id) {
    let $length := string-length($id)
    let $initial := math:pow(10, $length - 1)
    return
        (
            $initial cast as xs:integer (: avoid exponential notation :)
            ,
            for $digit at $n in (1 to $length - 2)
            let $dir := substring($id, $digit, 1)
            return
                $dir
        )
};

declare function pi:prepare-collection($id) {
    let $components := pi:id-to-collection-components($id) 
    return
        pi:mkcol-recursive('/db/apps/people/data', $components)
};

declare function pi:store($person) {
    let $prepare := pi:prepare-collection($id) 
    let $components := pi:id-to-collection-components($id) 
    return
        xmldb:store(string-join(('/db/apps/people/data', $components), '/'), $person/id || '.xml', $person)
};