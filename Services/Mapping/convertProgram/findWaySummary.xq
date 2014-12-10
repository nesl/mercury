let $inName := doc('/tmp/in')
return <result> {
    for $way in doc($inName/in/text())/osm/way[tag/@k='name']
    order by $way/tag[@k='name']/@v
    return <rec id='{$way/@id}' name='{$way/tag[@k='name']/@v}' />
}</result>
