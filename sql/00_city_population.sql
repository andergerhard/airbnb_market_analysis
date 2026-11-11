-- Official population by city (residents register, 1 January 2026)
-- Sources: Ajuntament de Barcelona (Padró), Amt für Statistik Berlin-Brandenburg
-- (Einwohnerregister, 31.12.2025), CBS (Amsterdam)
CREATE TABLE city_population (
    city        TEXT PRIMARY KEY,
    population  INTEGER NOT NULL
);

INSERT INTO city_population (city, population) VALUES
    ('Barcelona', 1729963),
    ('Berlin',    3913644),
    ('Amsterdam',  941927);