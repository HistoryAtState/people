xquery version "3.1";

import module namespace console="http://exist-db.org/xquery/console";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
(:declare option output:method "json";:)
(:declare option output:media-type "application/json";:)

declare function local:service-metadata() {
    map {
        "name": "HSG People Reconciliation service",
        "identifierSpace": "HSG People Reconciliation service",
        "schemaSpace": "HSG People Reconciliation service",
        "defaultTypes": array {()},
        "view": map { "url": "http://localhost:8080/exist/apps/people/id/{{id}}" },
        "preview": map { 
            "url": "http://localhost:8080/exist/apps/people/id/{{id}}",
            "width": 430,
            "height": 300
        }
    }
};

declare function local:query($query) {
    if (matches($query, '^\d+$')) then
        let $id := $query
        let $hit := doc('/db/apps/people/data/consolidated/' || $id || '.xml')/person
        return
            map { "result": 
                array {
                    let $name := $hit/names/preferred/name/string()
                    let $id := $query
                    let $score := 1
                    return
                        map {
                            "id": $id,
                            "name": $name,
                            "type": array {"person"},
                            "score": $score cast as xs:double,
                            "match": "true" cast as xs:boolean
                        }
                }
            }
    else
        let $hits := 
            for $hit in collection('/db/apps/people/data')/person[ft:query(.//name, $query)]
            let $score := ft:score($hit)
            order by $score descending
            return
                element hit { 
                    attribute score { $score }, 
                    $hit/id, 
                    $hit 
                }
        let $log := console:log(count($hits) || ' found for ' || $query)
        let $hits-to-show := subsequence($hits, 1, 3)
        return
            map { "result": 
                array {
                    for $hit in $hits-to-show
                    let $name := $hit/person/names/preferred/name/string()
                    let $id := $hit/id/string()
                    let $score := $hit/@score cast as xs:double
                    order by $score descending
                    return
                        map {
                            "id": $id,
                            "name": $name,
                            "type": array {"person"},
                            "score": $score
                        }
                }
            }
};

declare function local:queries($queries) {
    let $results := 
        map:new(
            for $q in $queries?*
            let $query := map:get($queries, $q)?query
            return
                map:entry($q, local:query($query))
            )
    return
        (
        $results,
        console:log(
            serialize(
                $results, 
                <output:serialization-parameters>
                    <output:method>json</output:method>
                    <output:indent>yes</output:indent>
                </output:serialization-parameters>
                )
            )
        )
};

let $query := 
    request:get-parameter('query', ())
(:'chou shu-kai':)
let $queries := 
    request:get-parameter('queries', ())
(:    '{"q0":{"query":"Abrams, Creighton W.","limit":3},"q1":{"query":"Abrasimov, Pyotr A.","limit":3},"q2":{"query":"Acheson, Dean G.","limit":3},"q3":{"query":"Agnew, Spiro T.","limit":3},"q4":{"query":"Alsop, Joseph","limit":3},"q5":{"query":"Arbatov, Georgi A.","limit":3},"q6":{"query":"Atherton, Alfred L., Jr. (\u201cRoy\u201d)","limit":3},"q7":{"query":"Bahr, Egon","limit":3},"q8":{"query":"Baker, John A., Jr.","limit":3},"q9":{"query":"Ball, George W.","limit":3}}':)
let $callback := request:get-parameter('callback', ())
let $log := console:log(string-join(for $param in request:get-parameter-names() return ($param || ': ' || request:get-parameter($param, ())), ' ')) 
return
    if ($query) then 
        (
        response:set-header('Content-Type', 'application/json'),
        serialize(
            local:query($query), 
            <output:serialization-parameters>
                <output:method>json</output:method>
                <output:indent>yes</output:indent>
            </output:serialization-parameters>
            )
        )
    else if ($queries) then
        (
        response:set-header('Content-Type', 'application/json'),
        serialize(
            local:queries(parse-json($queries)), 
            <output:serialization-parameters>
                <output:method>json</output:method>
                <output:indent>yes</output:indent>
            </output:serialization-parameters>
            )
        )
    else (: if (not($query or $queries)) then :) 
        if ($callback) then
            (
            response:set-header('Content-Type', 'application/javascript'),
            concat(
                $callback, 
                '(', 
                serialize(
                    local:service-metadata(), 
                    <output:serialization-parameters>
                        <output:method>json</output:method>
                        <output:indent>no</output:indent>
                    </output:serialization-parameters>
                    ), 
                ');'
                )
            )
        else
            (
            response:set-header('Content-Type', 'application/json'),
            serialize(
                local:service-metadata(), 
                <output:serialization-parameters>
                    <output:method>json</output:method>
                    <output:indent>yes</output:indent>
                </output:serialization-parameters>
                )
            )