XQuery-i18n
===========

Performance enhanced implementation of i18n bundles in XQuery

Example XML Resources

````xml
<i18n xml:lang="en_US" id="general">
  <map:map xmlns:map="http://marklogic.com/xdmp/map" xmlns:xsi="
http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="
http://www.w3.org/2001/XMLSchema">
    <map:entry key="greeting">
      <map:value xsi:type="xs:string">hello</map:value>
    </map:entry>
    <map:entry key="farewell">
      <map:value xsi:type="xs:string">goodbye</map:value>
    </map:entry>
    <map:entry key="image-of">
      <map:value xsi:type="xs:string">image </map:value>
      <map:value><number-1/></map:value>
      <map:value xsi:type="xs:string"> of </map:value>
      <map:value><number-2/></map:value>
    </map:entry>
  </map:map>
</i18n>
````

Example XQuery Code

````xquery
bundle-entry('en_US', 'general', 'greeting'),
bundle-entry-with-arguments(
  'en_US', 
  'general', 
  'image-of', 
  map:map(<map:map xmlns:map="http://marklogic.com/xdmp/map" xmlns:xsi="
    http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="
    http://www.w3.org/2001/XMLSchema">
      <map:entry key="number-1">
        <map:value xsi:type="xs:integer">3</map:value>
      </map:entry>
      <map:entry key="number-2">
        <map:value xsi:type="xs:integer">64</map:value>
      </map:entry>
    </map:map>)
)
````
