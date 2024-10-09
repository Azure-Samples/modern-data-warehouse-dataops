DROP TABLE IF EXISTS Alarm;
DROP TABLE IF EXISTS Asset;
DROP TABLE IF EXISTS Quality_System;

CREATE TABLE Alarm(ID INTEGER PRIMARY KEY, Alarm_Type VARCHAR(100)) AS NODE; 
CREATE TABLE Asset (ID INTEGER PRIMARY KEY,  Asset_ID VARCHAR(100)) AS NODE;
CREATE TABLE Quality_System (ID INTEGER PRIMARY KEY, Quality_ID VARCHAR(100)) AS NODE;

INSERT INTO Alarm (ID, Alarm_Type)
    VALUES  (1, 'Fire Warning'),
            (2, 'Flood Warning'),
            (3, 'Carbon Monoxide Warning');

INSERT INTO Asset (ID, Asset_ID)
    VALUES  (1, 'AE0520'),
            (2, 'AE0530'),
            (3, 'AE0690');

INSERT INTO Quality_System (ID, Quality_ID)
    VALUES  (1, 'MA_0520_001'),
            (2, 'MA_0530_002'),
            (3, 'MA_0690_003');

DROP TABLE IF EXISTS belongs_to;
CREATE TABLE belongs_to AS EDGE;


INSERT INTO [dbo].[belongs_to]
    VALUES  ((SELECT $node_id FROM Alarm WHERE ID = '1'), (SELECT $node_id FROM Quality_System WHERE Quality_ID = 'MA_0520_001')),
            ((SELECT $node_id FROM Alarm WHERE ID = '2'), (SELECT $node_id FROM Quality_System WHERE Quality_ID = 'MA_0530_002')),
            ((SELECT $node_id FROM Alarm WHERE ID = '3'), (SELECT $node_id FROM Quality_System WHERE Quality_ID = 'MA_0690_003'));

DROP TABLE IF EXISTS is_associated_with; 
CREATE TABLE is_associated_with AS EDGE;

INSERT INTO [dbo].[is_associated_with]
    VALUES  ((SELECT $node_id FROM Quality_System WHERE Quality_ID = 'MA_0520_001'), (SELECT $node_id FROM Asset WHERE ID = '1')),
            ((SELECT $node_id FROM Quality_System WHERE Quality_ID = 'MA_0530_002'), (SELECT $node_id FROM Asset WHERE ID = '2')),
            ((SELECT $node_id FROM Quality_System WHERE Quality_ID = 'MA_0690_003'), (SELECT $node_id FROM Asset WHERE ID = '3'));