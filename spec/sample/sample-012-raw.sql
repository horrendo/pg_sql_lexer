SELECT *
    FROM weather LEFT OUTER JOIN cities ON (weather.city = cities.name);