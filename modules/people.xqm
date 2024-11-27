xquery version "3.1";

module namespace people="http://history.state.gov/ns/xquery/people";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $people:app-base := '/exist/apps/people/';
declare variable $people:server-url := request:get-scheme() || '://' || request:get-server-name() || (if (request:get-server-port() = (80, 443)) then () else (':' || request:get-server-port()));
declare variable $people:app-base-url := $people:server-url || $people:app-base;
declare variable $people:open-refine-endpoint-url := $people:app-base-url || 'reconcile';

declare function people:wrap-html($content as element(), $title as xs:string+) {
    <html>
        <head>
            <title>{string-join(reverse($title), ' | ')}</title>
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
                <h3><a href="{$people:app-base}">{$title[1]}</a></h3>
                {$content}
            </div>
        </body>
    </html>    
};

declare function people:source-url-to-link($source-url) {
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
