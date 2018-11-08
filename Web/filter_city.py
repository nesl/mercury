data = [
        'East Los Angeles',34.0238889,-118.1711111,
        'Los Angeles',34.0522222,-118.2427778,
        'San Diego',32.7152778,-117.1563889,
        'San Francisco',37.7750000,-122.4183333,
        'San Jose',37.3394444,-121.8938889,
        'Chicago', 41.8500000, -87.6500000,
        'New York',40.7141667,-74.0063889,
        'Long Beach',33.7669444,-118.1883333,
        'Boston',42.3583333,-71.0602778,
        'Mesa',33.4222222,-111.8219444,
        'Phoenix',33.4483333,-112.0733333,
        'Tucson',32.2216667,-110.9258333,
        'Philadelphia',39.9522222,-75.1641667,
        'Houston',29.7630556,-95.3630556,
        'Memphis',35.1494444,-90.0488889,
        'Nashville',36.1658333,-86.7844444,
        'Austin',30.2669444,-97.7427778,
        'Dallas',32.7833333,-96.8000000,
        'El Paso',31.7586111,-106.4863889,
        'Fort Worth',32.7252778,-97.3205556,
        'San Antonio',29.4238889,-98.4933333,
        'Virginia Beach',36.8527778,-75.9783333,
        'Portland',45.5236111,-122.6750000,
        'Seattle',47.6063889,-122.3308333,
        'Milwaukee',43.0388889,-87.9063889,
        'Fresno',36.7477778,-119.7713889,
        'Sacramento',38.5816667,-121.4933333,
        'Denver',39.7391667,-104.9841667,
        'Washington',38.8950000,-77.0366667,
        'Jacksonville',30.3319444,-81.6558333,
        'Atlanta',33.7488889,-84.3880556,
        'Indianapolis',39.7683333,-86.1580556,
        'Kansas City',39.1141667,-94.6272222,
        'New Orleans',29.9544444,-90.0750000,
        'Baltimore',39.2902778,-76.6125000,
        'Detroit',42.3313889,-83.0458333,
        'Kansas City 2',39.0997222,-94.5783333,
        'Omaha',41.2586111,-95.9375000,
        'Las Vegas',36.1750000,-115.1363889,
        'Albuquerque', 35.0844444, -106.6505556,
        'Charlotte',35.2269444,-80.8433333,
        'Cleveland',41.4994444,-81.6955556,
        'Columbus',39.9611111,-82.9988889,
        'Oklahoma City',35.4675000,-97.5161111,
        'San Juan',18.4683333,-66.1061111,
]

accepted = [
        'Portland',
        'San Francisco',
        'Los Angeles',
        'Austin',
        'Atlanta',
        'Dallas',
        'San Juan',
        'Philadelphia',
        'Memphis',
        'Indianapolis',
        'Boston',
        'Phoenix',
        'Chicago',
        'Seattle',
        'San Diego',
        'Albuquerque',
        'Denver',
        'Washington',
        'Tucson',
        'San Antonio',
        'New York',
        'San Jose',
        'Long Beach',
        'Mesa',
        'Houston',
        'Virginia Beach'
]

keep = []

for city in accepted:
    idx = -1;
    for i in range(len(data)):
        if city == data[i]:
            idx = i
            break
    if idx == -1:
        print('Cannot find city ' + city)
    else:
        keep.append(data[idx:idx+3])

print(keep)
