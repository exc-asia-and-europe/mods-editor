xquery version "3.0";

(:TODO: change all 'monograph' to 'book' in tabs-data.xml and compact body files:)
(:TODO: Code related to MADS files.:)

declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace xf="http://www.w3.org/2002/xforms";
declare namespace ev="http://www.w3.org/2001/xml-events";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace ext="http://exist-db.org/mods/extension";
declare namespace mads="http://www.loc.gov/mads/";
declare namespace mods-editor = "http://hra.uni-heidelberg.de/ns/mods-editor/";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace html = "http://www.w3.org/1999/xhtml";

import module namespace config = "http://hra.uni-heidelberg.de/ns/mods-editor/config/" at "modules/config.xqm";

(:The following variables are used for a kind of dynamic theming.:)
(:declare variable $theme := substring-before(substring-after(request:get-url(), "/apps/"), "/hra-mods-editor/index.xq");:)
declare variable $theme := substring-before(substring-after(request:get-url(), "/apps/"), "/hra-mods-editor/index.xq");
declare variable $header-title := if ($theme eq "tamboti") then "Tamboti Metadata Framework - MODS Editor" else "eXist Bibliographical Demo - MODS Editor";
declare variable $tamboti-css := if ($theme eq "tamboti") then "tamboti.css" else ();
declare variable $img-left-src := if ($theme eq "tamboti") then "../../themes/tamboti/images/tamboti.png" else "../../themes/default/images/logo.jpg";
declare variable $img-left-title := if ($theme eq "tamboti") then "Tamboti Metadata Framework" else "eXist-db: Open Source Native XML Database";
declare variable $img-right-href := if ($theme eq "tamboti") then "http://www.asia-europe.uni-heidelberg.de/en/home.html" else "";
declare variable $img-right-src := if ($theme eq "tamboti") then "../../themes/tamboti/images/cluster_logo.png" else ();
declare variable $img-right-title := if ($theme eq "tamboti") then "The Cluster of Excellence &quot;Asia and Europe in a Global Context: Shifting Asymmetries in Cultural Flows&quot; at Heidelberg University" else ();
declare variable $img-right-width := if ($theme eq "tamboti") then "200" else ();
 
declare function local:create-new-record($id as xs:string, $type-request as xs:string, $target-collection as xs:string) as empty() {
    (:Copy the template and store it with the ID as file name.:)
    (:First, get the right template, based on the type-request and the presence or absence of transliteration.:)
    let $transliterationOfResource := request:get-parameter("transliterationOfResource", '')
    let $template-request := 
        if ($type-request = '')
        then 'insert-templates'
        else
            if ($type-request = (
                        'suebs-tibetan', 
                        'suebs-chinese', 
                        'insert-templates', 
                        'new-instance', 
                        'mads'))
            (:These document types do not divide into latin and transliterated.:)
            then $type-request
            else
                (:Append '-transliterated' if there is transliteration, otherwise append '-latin'.:)
                if ($transliterationOfResource) 
                then concat($type-request, '-transliterated') 
                else concat($type-request, '-latin') 
    let $template := doc(concat($config:app-path, '/data-templates/', $template-request, '.xml'))
    
    (:Then give it a name based on a uuid, store it in the temp collection and set restrictive permissions on it.:)
    let $doc-name := concat($id, '.xml')
    let $stored := xmldb:store($config:data-path, $doc-name, $template)   

    (:Get the remaining parameters that are to be stored, in addition to transliterationOfResource (which was fetched above).:)
    let $scriptOfResource := request:get-parameter("scriptOfResource", '')
    let $languageOfResource := request:get-parameter("languageOfResource", '')
    let $languageOfCataloging := request:get-parameter("languageOfCataloging", '')
    let $scriptOfCataloging := request:get-parameter("scriptOfCataloging", '')           
    (:Parameter 'host' is used when related records with type "host" are created.:)
    let $host := request:get-parameter('host', '')
    
    let $doc := doc($stored)
    
    (:Note that we cannot use "update replace" if we want to keep the default namespace.:)
    return
       (
           (:Update the record with ID attribute.:)
           update insert attribute ID {$id} into $doc/mods:mods
           ,
           update insert attribute ID {$id} into $doc/mads:mads
      ,
      (:Save the language and script of the resource.:)
      (:If namespace is not applied in the updates, the elements will be in the empty namespace.:)
      let $language-insert :=
          <language xmlns="http://www.loc.gov/mods/v3">
              <languageTerm authority="iso639-2b" type="code">
                  {$languageOfResource}
              </languageTerm>
              <scriptTerm authority="iso15924" type="code">
                  {$scriptOfResource}
              </scriptTerm>
          </language>
      return
      update insert $language-insert into $doc/mods:mods
      ,
      (:Save the library reference, the creation date, and the language and script of cataloguing:)
      (:To simplify input, resource language and language of cataloging are identical be default.:) 
      let $recordInfo-insert :=
          <recordInfo xmlns="http://www.loc.gov/mods/v3" lang="eng" script="Latn">
              <recordContentSource authority="marcorg">DE-16-158</recordContentSource>
              <recordCreationDate encoding="w3cdtf">
                  {current-date()}
              </recordCreationDate>
              <recordChangeDate encoding="w3cdtf"/>
              <languageOfCataloging>
                  <languageTerm authority="iso639-2b" type="code">
                      {$languageOfResource}
                  </languageTerm>
                  <scriptTerm authority="iso15924" type="code">
                      {$scriptOfResource}
              </scriptTerm>
              </languageOfCataloging>
          </recordInfo>            
      return
      update insert $recordInfo-insert into $doc/mods:mods
      ,
      (:Save the name of the template used, transliteration scheme used, 
      and an empty catalogingStage into mods:extension.:)  
      update insert
          <extension xmlns="http://www.loc.gov/mods/v3" xmlns:ext="http://exist-db.org/mods/extension">
              <ext:transliterationOfResource>{$transliterationOfResource}</ext:transliterationOfResource>
              <ext:catalogingStage/>
          </extension>
      into $doc/mods:mods
      ,
      (:If the user requests to create a related record, 
      a record which refers to the record being browsed, 
      insert the ID into @xlink:href on the first empty <relatedItem> in the new record.:)
      if ($host)
      then
        (
            update value doc($stored)/mods:mods/mods:relatedItem[string-length(@type) eq 0][1]/@type with "host",
            update value doc($stored)/mods:mods/mods:relatedItem[@type eq 'host'][1]/@xlink:href with concat('#', $host)
        )
      else ()
      
    )
};

declare function local:create-xf-model($data-instance as node(), $target-collection as xs:string, $host as xs:string, $document-type as xs:string, $tabs as item()+) as element(xf:model) {
    let $transliterationOfResource := request:get-parameter("transliterationOfResource", '')
    
    return
        <xf:model id="m-main">
            <xf:instance id="i-configuration">
                <configuration xmlns="">
                    <current-username>{xmldb:get-current-user()}</current-username>
                    <languageOfResource>{request:get-parameter("languageOfResource", '')}</languageOfResource>
                    <scriptOfResource>{request:get-parameter("scriptOfResource", '')}</scriptOfResource>
                    <document-type>{$document-type}</document-type>
                    <host>{request:get-parameter('host', '')}</host>
                    <initial-ui-id>{substring($tabs//html:div[@id = 'tab-1']//html:li[1]/html:a/@href, 2)}</initial-ui-id>
                    <target-collection>{$target-collection}</target-collection>
                    <related-publication-title>{local:get-related-publication-title($data-instance)}</related-publication-title>
                </configuration>
            </xf:instance>   

            <xf:instance id="i-variables">
                <variables xmlns="">
                    <subform-relative-path />
                    <compact-name-delete />
                </variables>
            </xf:instance>            
            
           <xf:instance id="save-data">
                {$data-instance}
           </xf:instance>
         
           <!--The instance insert-templates contain an almost full embodiment of the MODS schema, version 3.5; 
           It is used mainly to insert attributes and uncommon elements, 
           but it can also be chosen as a template.-->
           <xf:instance xmlns:mods="http://www.loc.gov/mods/v3" src="data-templates/insert-templates.xml" id="insert-templates">
                <mods xmlns="http://www.loc.gov/mods/v3" />
           </xf:instance>
           
           <!--A basic selection of elements and attributes from the MODS schema, 
           used inserting basic elements, but it can also be chosen as a template.-->
           <xf:instance xmlns="http://www.loc.gov/mods/v3" src="data-templates/new-instance.xml" id="new-instance">
                <mods xmlns="http://www.loc.gov/mods/v3" />
           </xf:instance>
           
           <!--A selection of elements and attributes from the MADS schema used for default records.-->
           <!--not used at present-->
           <!--<xf:instance xmlns="http://www.loc.gov/mads/" src="data-templates/mads.xml" id='mads' readonly="true"/>-->
    
           <!--Elements and attributes for insertion of special configurations of elements into the compact forms.-->
           <xf:instance src="data-templates/compact-template.xml" id="compact-template"> 
                <mods xmlns="http://www.loc.gov/mods/v3" />
           </xf:instance>

           <xf:instance id="i-hint-codes" src="code-tables/hint.xml">
                <code-table xmlns="http://hra.uni-heidelberg.de/ns/mods-editor/" />
            </xf:instance>
            
           <xf:instance src="{concat('get-document-type-metadata.xq?document-type=', $document-type)}" id="i-document-type-metadata">
                <code-table xmlns="http://hra.uni-heidelberg.de/ns/mods-editor/" />
           </xf:instance>   

           <!--Having binds would prevent a tab from being saved when clicking on another tab, 
           so binds are not used.--> 
           <!--
           <xf:bind nodeset="instance('save-data')/mods:titleInfo/mods:title" required="true()"/>       
           -->
           
           <xf:bind id="b-compact-name" ref="instance('i-variables')/compact-name-delete" relevant="count(instance('save-data')/mods:name) &gt; 1"/>
           
           <!--Save in target collection-->
           <xf:submission 
                id="s-save" 
                method="post"
                ref="instance('save-data')"
                resource="save.xq?collection={$target-collection}&amp;action=close" replace="none">
                    <xf:action ev:event="xforms-submit-done">
                        <script type="text/javascript">
                            window.close();
                        </script>
                    </xf:action>
                    <xf:message ev:event="xforms-submit-error" level="modal">A submission error (<xf:output value="event('response-reason-phrase')"/>) occurred. Details: 'response-status-code' = '<xf:output value="event('response-status-code')"/>', 'resource-uri' = '<xf:output value="event('resource-uri')"/>'.</xf:message>
           </xf:submission>

            <xf:action ev:event="xforms-ready">
               <xf:load show="embed" targetid="user-interface-container">
                    <xf:resource value="concat('user-interfaces/', instance('i-configuration')/initial-ui-id, '.xml#user-interface-container')"/>
                </xf:load>
                <xf:setvalue ref="instance('save-data')/mods:language/mods:languageTerm" value="instance('i-configuration')/languageOfResource" />
                <xf:setvalue ref="instance('save-data')/mods:language/mods:scriptTerm" value="instance('i-configuration')/scriptOfResource" />
                <xf:setvalue ref="instance('save-data')/mods:recordInfo/mods:recordCreationDate" value="local-date()" />
                <xf:setvalue ref="instance('save-data')/mods:recordInfo/mods:languageOfCataloging/mods:languageTerm" value="instance('i-configuration')/languageOfResource" />
                <xf:setvalue ref="instance('save-data')/mods:recordInfo/mods:languageOfCataloging/mods:scriptTerm" value="instance('i-configuration')/scriptOfResource" />
                <xf:action if="string-length(instance('i-configuration')/host) > 0">
                    <xf:setvalue ref="instance('save-data')/mods:relatedItem[@type eq 'host'][1]/@xlink:href" value="concat('#', instance('i-configuration')/host)" />                
                </xf:action>
                <xf:setvalue if="instance('i-configuration')/document-type != 'insert-templates'" ref="instance('i-configuration')/document-type" value="replace(replace(instance('save-data')/@xsi:schemaLocation, 'http://www.loc.gov/mods/v3 http://cluster-schemas.uni-hd.de/mods-', ''), '.xsd', '')" />
            </xf:action>
            <xf:action ev:event="loadSubform" ev:observer="main-content">
                <xf:setvalue ref="instance('i-variables')/subform-relative-path" value="concat('user-interfaces/', event('subformId'), '.xml#user-interface-container')" />
                <xf:load show="embed" targetid="user-interface-container">
                    <xf:resource value="instance('i-variables')/subform-relative-path" />
                </xf:load>
            </xf:action>
        </xf:model>
};

declare function local:get-related-publication-title($data-instance as node()) {
    let $related-item-xlink := $data-instance/mods:mods/mods:relatedItem[@type = 'host'][1]/@xlink:href
    let $related-publication-id := 
        if ($related-item-xlink) 
        then replace($related-item-xlink[1]/string(), '^#?(.*)$', '$1') 
        else ()
    let $related-publication-title := 
        if ($related-publication-id) 
        then config:get-short-title(collection($config:data-path)//mods:mods[@ID eq $related-publication-id][1])
        else ()
    let $related-publication-title :=
        (:Check for no string contents - the count may still be 1.:)
        if ($related-item-xlink eq '')
        then ()
            else 
            if (count($related-item-xlink) eq 1)
            then
            (<span class="intro">The publication is included in </span>, <a href="../../modules/search/index.html?search-field=ID&amp;value={$related-publication-id}&amp;query-tabs=advanced-search-form&amp;default-operator=and" target="_blank">{$related-publication-title}</a>,<span class="intro">.</span>)
            else
                (:Can the following occur, given that only one xlink is retrieved?:)
                if (count($related-item-xlink) gt 1) 
                then (<span class="intro">The publication is included in more than one publication.</span>)
                else ()
                
    return $related-publication-title
};

declare function local:get-data-template-name($document-type as xs:string, $transliterationOfResource as xs:string) {
    if ($document-type = (
                'suebs-tibetan', 
                'suebs-chinese', 
                'insert-templates', 
                'new-instance', 
                'mads'))
    (:These document types do not divide into latin and transliterated.:)
    then $document-type
    else
        (:Append '-transliterated' if there is transliteration, otherwise append '-latin'.:)
        if ($transliterationOfResource) 
        then concat($document-type, '-transliterated') 
        else concat($document-type, '-latin') 
};

declare function local:get-data-instance($record-id as xs:string, $document-type as xs:string) {
    let $record := collection($config:data-path)//mods:mods[@ID = $record-id]

    return
        if (exists($record))
        then $record
        else
            let $data-template-name := local:get-data-template-name($document-type, request:get-parameter("transliterationOfResource", ''))
            
            return doc(concat($config:app-path, '/data-templates/', $data-template-name, '.xml'))    
};

declare function local:get-document-type($schema-location as xs:string?) {
    let $document-type := replace(replace(replace(substring-after($schema-location, "http://cluster-schemas.uni-hd.de/mods-"), '.xsd', ''), '-latin', ''), '-transliterated', '')
    let $document-type := if ($document-type = '') then 'insert-templates' else $document-type
    
    let $type-parameter := request:get-parameter('type', '')
    let $document-type := if ($type-parameter = '') then $document-type else $type-parameter
    
    return $document-type
};

declare function local:get-tabs($document-type as xs:string) {
    doc(concat($config:app-path, '/user-interfaces/tabs/', $document-type, '-stand-alone.xml'))/html:div
};

declare function local:get-content-blocks($record-id as xs:string, $document-type as xs:string) {
    let $data-instance := local:get-data-instance($record-id, $document-type)
    let $document-type := local:get-document-type($data-instance/@xsi:schemaLocation)
    
    return
        map {
            "data-instance": $data-instance,
            "tabs": local:get-tabs($document-type),
            "document-type": $document-type
        }
};
declare function local:get-target-collection($record-collection-path as xs:string) {
    let $target-collection := request:get-parameter("collection", "")

    return
        if ($target-collection != '')
        then $target-collection
        else $record-collection-path    
};

let $record-id := request:get-parameter('id', '')
let $document-type := request:get-parameter('type', 'insert-templates')

let $content-parts := local:get-content-blocks($record-id, $document-type)

let $target-collection := local:get-target-collection(util:collection-name($content-parts('data-instance')))
let $model := local:create-xf-model($content-parts('data-instance'), $target-collection, request:get-parameter('host', ''), $content-parts('document-type'), $content-parts('tabs'))

return
    
    (util:declare-option("exist:serialize", "method=xhtml5 media-type=text/html output-doctype=yes indent=yes encoding=utf-8")
    ,
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:ext="http://exist-db.org/mods/extension" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mods-editor="http://hra.uni-heidelberg.de/ns/mods-editor/">
        <head>
            <title>
                {$header-title}
            </title>
            <script type="text/javascript" src="resources/scripts/jquery-1.11.2/jquery-1.11.2.min.js">/**/</script>
            <script type="text/javascript" src="resources/scripts/jquery-ui-1.11.4/jquery-ui.min.js">/**/</script>
            <script type="text/javascript" src="editor.js">/**/</script>
            <link rel="stylesheet" type="text/css" href="resources/scripts/jquery-ui-1.11.4/jquery-ui.min.css" />
            <link rel="stylesheet" type="text/css" href="edit.css"/>
            <link rel="stylesheet" type="text/css" href="{$tamboti-css}"/>              
            {$model}
        </head>
        <body>
            <div id="page-head">
                <div id="page-head-left">
                    <a href="../.." style="text-decoration: none">
                        <img src="{$img-left-src}" title="{$img-left-title}" alt="{$img-left-title}" style="border-style: none;" width="250px"/>
                    </a>
                    <div class="documentation-link"><a href="../../docs/" style="text-decoration: none" target="_blank">Help</a></div>
                </div>
                <div id="page-head-right">
                    <a href="{$img-right-href}" target="_blank">
                        <img src="{$img-right-src}" title="{$img-right-title}" alt="{$img-right-title}" width="{$img-right-width}" style="border-style: none"/>
                    </a>
                </div>
            </div>
            <div>
            <div class="container">
                <div id="main-content" class="content">
                    <span class="info-line">
                        <xf:output value="'Editing record of type '" />
                        <xf:output value="instance('i-document-type-metadata')/mods-editor:label" class="hint-icon">
                            <xf:hint ref="instance('i-document-type-metadata')/mods-editor:hint" />
                        </xf:output>
                        <xf:output value="', with the title '" />
                        <strong>
                            <xf:output value="concat(instance('save-data')/mods:titleInfo[1]/mods:nonSort, ' ', instance('save-data')/mods:titleInfo[1]/mods:title)" />
                        </strong>
                        <xf:output value="', to be saved in '" />
                        <strong>
                            <xf:output value="concat(instance('i-configuration')/target-collection, '.')" />
                        </strong>              
                    </span>
                    {$content-parts('tabs')}
                    <div class="save-buttons-top">    
                         <xf:trigger>
                            <xf:label>
                                <xf:output value="'Finish Editing'" class="hint-icon">
                                    <xf:hint ref="id('hint-code_save',instance('i-hint-codes'))/*:help" />
                                </xf:output>
                            </xf:label>
                            <xf:send submission="s-save" />
                        </xf:trigger>
                        <span class="related-title">
                            <xf:output value="instance('i-configuration')/related-publication-title" />
                        </span>
                    </div>            
                    <div id="user-interface-container"/>
                    <div class="save-buttons-bottom">
                        <xf:trigger>
                            <xf:label>Cancel Editing</xf:label>
                            <xf:action ev:event="DOMActivate">
                                <script type="text/javascript">
                                    window.close();
                                </script>
                            </xf:action>
                         </xf:trigger>
                         <xf:trigger>
                            <xf:label>
                                <xf:output value="'Finish Editing'" class="hint-icon">
                                    <xf:hint ref="id('hint-code_save',instance('i-hint-codes'))/*:help" />
                                </xf:output>
                            </xf:label>
                            <xf:send submission="s-save" />
                        </xf:trigger>
                    </div>              
                </div>
            </div>
            </div>
        </body>
    </html>
)
