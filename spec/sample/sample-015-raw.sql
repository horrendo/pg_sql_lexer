SELECT city FROM weather
    WHERE temp_lo = (SELECT max(temp_lo) FROM weather);