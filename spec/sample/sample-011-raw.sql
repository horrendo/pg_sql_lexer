SELECT *
    FROM weather INNER JOIN cities ON (weather.city = cities.name);