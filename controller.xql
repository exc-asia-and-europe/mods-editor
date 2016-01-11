xquery version "3.0";

import module namespace theme="http://exist-db.org/xquery/biblio/theme" at "../theme.xqm";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

if (starts-with($exist:path, "/theme")) then
    let $path := theme:resolve($exist:prefix || "/" || $config:app-id, $exist:root, substring-after($exist:path, "/theme"))
    let $themePath := replace($path, "^(.*)/[^/]+$", "$1")
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$path}">
                <set-attribute name="theme-collection" value="{$themePath}"/>
            </forward>
        </dispatch>
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>