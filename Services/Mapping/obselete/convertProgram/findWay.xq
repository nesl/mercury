let $root := doc('/home/timestring/Documents/openStreetMap/maps/test.osm')/osm
return <result>{$root/way/tag[@k='name' and @v='Charing Cross Road']/..}</result>