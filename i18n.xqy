xquery version "1.0-ml" ;

(:~
Copyright (c) 2012 Ryan Dew

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

This module facilitates having translated strings for your MarkLogic xQuery app.
Each of the public functions have an optional $query parameter at the end
if your application would want to restrict queries. 

@author Ryan Dew (ryan.j.dew@gmail.com)
@version 0.3

~:)

module namespace i18n = "http://maxdewpoint.blogspot.com/i18n";

declare namespace map = "http://marklogic.com/xdmp/map";

declare variable $current-bundles as map:map := map:map();

(: get the translated bundle entry :)
declare function bundle-entry(
  $locale as xs:string, 
  $bundle as xs:string, 
  $key as xs:string
) as item()* {
	bundle-entry($locale, $bundle, $key, ())
};

(: get the translated bundle entry with query restriction :)
declare function bundle-entry(
  $locale as xs:string, 
  $bundle as xs:string, 
  $key as xs:string, 
  $query as cts:query?
) as item()* {
	map:get(load-bundle($locale, $bundle, $query), $key)
};

(: get the translated bundle entry :)
declare function bundle-entry-with-arguments(
	$locale as xs:string, 
	$bundle as xs:string, 
	$key as xs:string,
  $arguments as map:map
) as item()* {
	bundle-entry-with-arguments($locale, $bundle, $key, $arguments,())
};

(: get the translated bundle entry with query restriction :)
declare function bundle-entry-with-arguments(
  $locale as xs:string, 
	$bundle as xs:string, 
	$key as xs:string, 
  $arguments as map:map,
	$query as cts:query?
) as item()* {
  fn:string-join(
	  for $item as item() in map:get(load-bundle($locale, $bundle, $query), $key)
    return
      typeswitch($item)
      case element() return
        fn:string(map:get($arguments,xdmp:key-from-QName(fn:node-name($item))))
      default return
        fn:string($item),
    ''
  )
};

declare function bundle(
  $locale as xs:string, 
  $bundle as xs:string
) as element(i18n)? {
	bundle($locale, $bundle, ())
};

(:
This finds an i18n bundle.
:)
declare function bundle(
  $locale as xs:string, 
  $bundle as xs:string, 
  $query as cts:query?
) as element(i18n)? {
	cts:search(/i18n[@xml:lang eq $locale and @id eq $bundle],
		if (fn:exists($query))
		then $query
		else cts:and-query(())
	)
};

declare function load-bundle(
  $locale as xs:string, 
  $bundle as xs:string
) as map:map {
	load-bundle($locale, $bundle, ())
};

(: This loads a bundle into memory. :)
declare function load-bundle(
  $locale as xs:string, 
  $bundle as xs:string, 
  $query as cts:query?
) as map:map {
	(: Calculate the key for the bundle which changes with every update to the bundle :)
	let $base-key as xs:string := 
    fn:concat('/resources/',
		  (:As of MarkLogic 4.2 the result of cts:register is always the same, provided the same query. So in this case we can use it to generate a unique id :)
		  if (fn:exists($query)) 
		  then fn:string(cts:register($query)) 
		  else 'default',
		  '/',$locale,'/',$bundle
    )
	return 
		if (fn:exists(map:get($current-bundles,$base-key)))
		then map:get($current-bundles,$base-key)
		else
			let $timestamp-key as xs:string := fn:concat($base-key,'/timestamp'),
				$timestamp as xs:string := fn:string(xdmp:get-server-field($timestamp-key))
			(: Try to retrieve bundle from memory. :)
			return
			(: If it exists in memory in a server field return it. :)
			if (fn:exists($timestamp) and fn:exists(cts:uris((),('limit=1'), 
								cts:and-query((
									cts:element-query(
										xs:QName('i18n'),
										cts:and-query((
											cts:element-attribute-value-query(xs:QName('i18n'),xs:QName('xml:lang'), $locale, 'exact'),
											cts:element-attribute-value-query(xs:QName('i18n'),xs:QName('id'), $bundle, 'exact')											
										))
									),
									$query,	
									cts:properties-query( 
										cts:element-value-query(xs:QName('prop:last-modified'),$timestamp,'exact')
									)
								))
						))) 
			then xdmp:get-server-field($base-key)
			(: Otherwise load it. :)
    	else (
				xdmp:set-server-field($base-key,map:map(bundle($locale, $bundle,$query)[xdmp:set-server-field($timestamp-key,property::prop:last-modified)]/map:map))[map:put($current-bundles,$base-key,.),fn:true()]
    	)
};
