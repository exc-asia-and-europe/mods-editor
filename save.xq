xquery version "3.0";

import module namespace config = "http://hra.uni-heidelberg.de/ns/mods-editor/config/" at "modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "xmldb:exist:///db/apps/tamboti/modules/search/security.xqm";
import module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils" at "xmldb:exist:///db/apps/tamboti/modules/utils/utils.xqm";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace ext="http://exist-db.org/mods/extension";

declare function local:do-updates($item, $doc) {
    (: This first checks to see if we have a titleInfo in the saved document.  
    If we do, then it first deletes any titleInfo in the saved document.
    Then it inserts all titleInfo in the incoming record in the saved document. 
    If name (the "next" element in the "canonical" order of MODS elements) occurs in the saved document, 
    titleInfo is inserted before name, maintaining order.
    If name does not occur, titleInfo is inserted at the default position, 
    i.e. at the end of the saved document.
    The (locally defined) canonical order is: titleInfo, name, originInfo, part, physicalDescription, targetAudience, typeOfResource, genre, subject, classification, abstract, tableOfContents, note, relatedItem, identifier, location, accessCondition, language, recordInfo, extension. 
    The same process is then repeated for the remaining elements, in the canonical order.:)
    
    if ($item/mods:titleInfo)
    then
        (
        update delete $doc/mods:titleInfo
        ,
        if ($doc/mods:name)
        then update insert $item/mods:titleInfo preceding $doc/mods:name[1]
        else update insert $item/mods:titleInfo into $doc
        )
    else ()
    ,
    
    if ($item/mods:name)
    then
        (
        update delete $doc/mods:name
        ,
        if ($doc/mods:originInfo)
        then update insert $item/mods:name preceding $doc/mods:originInfo[1]
        else update insert $item/mods:name into $doc
        )
      else ()
    ,
      
    if ($item/mods:originInfo)
    then
        (
        update delete $doc/mods:originInfo
        ,
        if ($doc/mods:part)
        then update insert $item/mods:originInfo preceding $doc/mods:part[1]
        else update insert $item/mods:originInfo into $doc
        )
      else ()
    ,
    
    if ($item/mods:part)
    then
        (
        update delete $doc/mods:part
        ,
        if ($doc/mods:physicalDescription)
        then update insert $item/mods:part preceding $doc/mods:physicalDescription[1]
        else update insert $item/mods:part into $doc
        )
      else ()
    ,
    
    if ($item/mods:physicalDescription)
    then
        (
        update delete $doc/mods:physicalDescription
        ,
        if ($doc/mods:targetAudience)
        then update insert $item/mods:physicalDescription preceding $doc/mods:targetAudience[1]
        else update insert $item/mods:physicalDescription into $doc
        )
    else ()
    ,
    
    if ($item/mods:targetAudience)
    then
        (
        update delete $doc/mods:targetAudience
        ,
        if ($doc/mods:typeOfResource)
        then update insert $item/mods:targetAudience preceding $doc/mods:typeOfResource[1]
        else update insert $item/mods:targetAudience into $doc
        )
    else ()
    ,      
    
    if ($item/mods:typeOfResource)
    then
        (
        update delete $doc/mods:typeOfResource,
        if ($doc/mods:genre)
        then update insert $item/mods:typeOfResource preceding $doc/mods:genre[1]
        else update insert $item/mods:typeOfResource into $doc
        )
    else ()
    ,
    
    if ($item/mods:genre)
    then
        (
        update delete $doc/mods:genre,
        if ($doc/mods:subject)
        then update insert $item/mods:genre preceding $doc/mods:subject[1]
        else update insert $item/mods:genre into $doc
        )
    else ()
    ,
    
    if ($item/mods:subject)
    then
        (
        update delete $doc/mods:subject
        ,
        if ($doc/mods:classification)
        then update insert $item/mods:subject preceding $doc/mods:classification[1]
        else
        update insert $item/mods:subject into $doc
        )
    else ()
    ,      
    
    if ($item/mods:classification)
    then
        (
        update delete $doc/mods:classification
        ,
        if ($doc/mods:abstract)
        then update insert $item/mods:classification preceding $doc/mods:abstract[1]
        else update insert $item/mods:classification into $doc
        )
    else ()
    ,     
    
    if ($item/mods:abstract)
    then
        (
        update delete $doc/mods:abstract
        ,
        if ($doc/mods:tableOfContents)
        then update insert $item/mods:abstract preceding $doc/mods:tableOfContents[1]
        else update insert $item/mods:abstract into $doc
        )
    else ()
    ,
    
    if ($item/mods:tableOfContents)
    then
        (
        update delete $doc/mods:tableOfContents
        ,
        if ($doc/mods:note)
        then update insert $item/mods:tableOfContents preceding $doc/mods:note[1]
        else update insert $item/mods:tableOfContents into $doc
        )
    else ()
    ,
      
    if ($item/mods:note)
    then
        (
        update delete $doc/mods:note
        ,
        if ($doc/mods:relatedItem)
        then update insert $item/mods:note preceding $doc/mods:relatedItem[1]
        else update insert $item/mods:note into $doc
        )
    else ()
    ,
      
    if ($item/mods:relatedItem)
    then
        (
        update delete $doc/mods:relatedItem
        ,
        if ($doc/mods:identifier)
        then update insert $item/mods:relatedItem preceding $doc/mods:identifier[1]
        else update insert $item/mods:relatedItem into $doc
        )
    else ()
    ,
    
    if ($item/mods:identifier)
    then
        (
        update delete $doc/mods:identifier
        ,
        if ($doc/mods:location)
        then update insert $item/mods:identifier preceding $doc/mods:location[1]
        else update insert $item/mods:identifier into $doc
        )
    else ()
    ,
    
    if ($item/mods:location)
    then
        (
        update delete $doc/mods:location
        ,
        if ($doc/mods:accessCondition)
        then update insert $item/mods:location preceding $doc/mods:accessCondition[1] 
        else update insert $item/mods:location into $doc
        )
    else ()
    ,

    if ($item/mods:accessCondition)
    then
        (
        update delete $doc/mods:accessCondition
        ,
        if ($doc/mods:language)
        then update insert $item/mods:accessCondition preceding $doc/mods:language[1] 
        else update insert $item/mods:accessCondition into $doc
        )
    else ()
    ,

    if ($item/mods:language)
    then
        (
        update delete $doc/mods:language
        ,
        if ($doc/mods:recordInfo)
        then update insert $item/mods:language preceding $doc/mods:recordInfo[1]
        else update insert $item/mods:language into $doc
        )
    else ()
    ,
    
    if ($item/mods:recordInfo)
    then
        (
        update delete $doc/mods:recordInfo
        ,
        if ($doc/mods:extension)
        then update insert $item/mods:recordInfo preceding $doc/mods:extension[1]
        else update insert $item/mods:recordInfo into $doc
        )
    else ()
    ,
    
    if ($item/mods:extension)
    then
        (
        update delete $doc/mods:extension
        ,
        update insert $item/mods:extension into $doc
        )
    else ()
    ,
    (:If there is an extension in $doc, check whether it has the required children and insert them if they are missing.:)
    if ($doc/mods:extension)
    then 
        (
        (:If there is no ext:catalogingStage in $doc/extension, insert one.:)
        if ($doc/mods:extension/ext:catalogingStage)
        then ()
        else
            update insert <ext:catalogingStage/>
            into $doc/mods:extension
        ,
        (:If there is no ext:transliterationOfResource in $doc/extension, insert one.:)
        if ($doc/mods:extension/ext:transliterationOfResource)
        then ()
        else
            update insert <ext:transliterationOfResource/>                    
            into $doc/mods:extension
        )
    (:If there is no extension at all in $doc, insert one with the required children.:)
    else
        update insert
            <extension xmlns="http://www.loc.gov/mods/v3" xmlns:ext="http://exist-db.org/mods/extension">
                <ext:transliterationOfResource/>
                <ext:catalogingStage/>
            </extension>        
        into $doc
    
};

(: Find the collection containing the record with the uuid in question in the users collection and in the commons collection.
This means that any record temporarily in the temp collection is not found. :)
declare function local:find-live-collection-containing-uuid($uuid as xs:string) as xs:string? {
    let $live-record := collection($config:data-path)/mods:mods[@ID = $uuid][1]
    return
        if (not(empty($live-record))) 
        then replace(document-uri(root($live-record)), "(.*)/.*", "$1")
        else ()
};

(:MAIN:)
(: This is where the form "POSTS" documents to this XQuery using the POST method of a submission :)
(:$item contains the edits for the elements attached to a single tab, not a whole MODS record.:)
let $item := request:get-data()/element()
let $log := util:log("DEBUG", request:get-parameter('action', 'save')) 
let $log := util:log("DEBUG", $item) 
let $action := request:get-parameter('action', 'save')
let $incoming-id := $item/@ID/string()
let $incoming-id := if ($incoming-id = "id") then ("uuid-" || util:uuid()) else $incoming-id

(: If we do not have an ID, then throw an error. :) 
return
    if (string-length($incoming-id) eq 0)
    then
        <error>
            <message class="warning">ERROR! Attempted to save a record with no ID specified.</message>
        </error>
    else
        (: If there is an ID, we are doing an update to an existing file (unless the action is cancel). :)
        (:Locate the document in temp and and load it in $doc.:)
        let $file-to-update := concat($incoming-id, '.xml')
        
        let $updates := 
                if ($action eq 'close')
                (: If the user has finished editing. :)
                then
                    (:Get the target collection. If it's an edit to an existing document, we can find its location by means of its uuid.
                    If it is a new record, the target collection can be captured as the collection parameter passed in the URL. :)
(:                    let $target-collection := local:find-live-collection-containing-uuid($incoming-id):)
                    let $target-collection := xmldb:encode-uri(request:get-parameter("collection", ""))
(:                    let $target-collection :=:)
(:                        if ($target-collection):)
(:                        then $target-collection:)
(:                        else $new-target-collection:)
                    (:If the user has created a related record with a record as host in a collection to which the user does not have write access,
                    save the record in the user's home folder. The user can then move it elsewhere.
                    If the user does have write access, save it in the collection that the host occurs in.:)
                    let $target-collection := 
                        if (security:can-write-collection($target-collection))
                        then $target-collection
                        else security:get-home-collection-uri(security:get-user-credential-from-session()[1])
                    let $record-path := xs:anyURI(concat($target-collection, '/', $file-to-update))

                    return
                    (
                        (:Update $doc (the document in temp) with $item (the new edits).:)
(:                        local:do-updates($item, $doc):)
(:                        ,:)
                        (:Move $doc from temp to target collection.:)
                        (:NB: To avoid potential problems with xmldb:move(), xmldb:store() and xmldb:remove() are used.
                        xmldb:move() is suspected to create zero byte "ghost" files in backups in __lost_and_found__.:)

                        (:Only attempt to delete the original record if it exists; 
                        if an attempt is made to delete a file which does not exist, the script will terminate. 
                        This means that no attempt is made to delete newly created records.:)                        
(:                        if (doc($record-path)) :)
(:                        then xmldb:remove($target-collection, $file-to-update) :)
(:                        else ():)
(:                        ,:)
                        (:Store $doc in the target collection, whether this is where the record originally was located or 
                        the collection chosen to store a new record.:)
(:                        xmldb:store($target-collection, $file-to-update, $doc):)

                        system:as-user($config:dba-credentials[1], $config:dba-credentials[2], 
                            (
                                xmldb:store($target-collection, $file-to-update, $item)
                                ,
                                update insert attribute ID {$incoming-id} into doc($record-path)//mods:mods 
                                ,   
                                util:log("DEBUG", "$record-path = " || $record-path) 
                                ,                                
                                util:log("DEBUG", sm:get-permissions($record-path))
                                ,
                                security:copy-owner-and-group($target-collection, $record-path)
                                ,
                                security:copy-collection-ace-to-resource-apply-modechange($target-collection, $record-path)
                                ,
                                sm:chmod($record-path, $config:resource-mode)
                                ,
                                util:log("DEBUG", sm:get-permissions($record-path))
                            )
                        )
                    )
                (:If action is 'save' (the default action):)
                (:Update $doc (the document in temp) with $item (the new edits).:)
                else ()
(:                    local:do-updates($item, $doc)    :)
        return ()
