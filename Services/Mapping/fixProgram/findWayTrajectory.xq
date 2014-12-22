let $inName := doc('/tmp/in')
let $root := doc($inName/in/text())/osm
return <result> {
    for $way in $root/way[tag/@k='name']
    order by $way/tag[@k='name']/@v
    return <way id='{$way/@id}'> {
        for $nd in $way/nd
        let $node := $root/node[@id = $nd/@ref]
        where count($node) > 0
        return <nd id='{$nd/@ref}' lat='{$node/@lat}' lon='{$node/@lon}' />
    }
    </way>
}</result>
