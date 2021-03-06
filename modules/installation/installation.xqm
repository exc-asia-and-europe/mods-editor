xquery version "3.0";

module namespace installation = "http://hra.uni-heidelberg.de/ns/tamboti/installation/";

import module namespace config = "http://hra.uni-heidelberg.de/ns/mods-editor/config/" at "../config.xqm";

(:~ Functions needed for pre-install.xq of tamboti and tamboti-samples apps :)
declare function installation:mkcol-recursive($collection, $components, $permissions as xs:string) {
    if (exists($components))
    then
        let $newColl := concat($collection, "/", $components[1])
        return (
            if (not(xmldb:collection-available($newColl)))
            then
                (
                    xmldb:create-collection($collection, $components[1])
                    ,
                    local:set-resource-permissions(xs:anyURI($newColl), $config:biblio-admin-user, $config:biblio-users-group, $permissions)
                )
            else ()
            ,
            installation:mkcol-recursive($newColl, subsequence($components, 2), $permissions)
        )
    else ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function installation:mkcol($collection, $path, $permissions as xs:string) {
    installation:mkcol-recursive($collection, tokenize($path, "/"), $permissions)
};

declare function installation:set-public-collection-permissions-recursively($collection-path as xs:anyURI) {
    (
        local:set-resource-permissions($collection-path, $config:biblio-admin-user, $config:biblio-users-group, $config:public-collection-mode)
        ,
        for $subcollection-name in xmldb:get-child-collections($collection-path)
        return installation:set-public-collection-permissions-recursively(xs:anyURI($collection-path || "/" || $subcollection-name))
        ,
        for $resource-name in xmldb:get-child-resources($collection-path)
        return local:set-resource-permissions(xs:anyURI(concat($collection-path, '/', $resource-name)), $config:biblio-admin-user, $config:biblio-users-group, $config:public-resource-mode)
    )
};

declare function local:set-resource-permissions($resource-path as xs:anyURI, $user-name as xs:string, $group-name as xs:string, $permissions as xs:string) as empty() {
    (
        sm:chown($resource-path, $user-name),
        sm:chgrp($resource-path, $group-name),
        sm:chmod($resource-path, $permissions)        
    )
};

