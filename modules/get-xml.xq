xquery version "3.1";

import module namespace people="http://history.state.gov/ns/xquery/people" at "/db/apps/people/modules/people.xqm";

let $id := request:get-parameter('id', ())
return
    if (exists($id) and $id ne '') then
        people:get-person($id)
    else
        <error>Missing expected "id" parameter</error>