from azure.eventhub import EventHubProducerClient, EventData
from .env import get_evthub_connstr, get_evthub_name
import random
import time
import datetime


connectionString = get_evthub_connstr()
eventhub_name = get_evthub_name()
connection_str = connectionString
client = EventHubProducerClient.from_connection_string(connection_str, eventhub_name=eventhub_name)

event_data_batch = client.create_batch()
i = 0
while i < 100:
    i = i + 1
    try:
        ts = time.time()
        ct = datetime.datetime.now()
        event_str = "{\"id\":" + str(random.randint(1, 7)) + \
                    ", \"amount\":" + str(random.randint(1, 20)) + \
                    ", \"ts\":\"" + str(ct)+"\"}"
        print(event_str)
        event_data_batch.add(EventData(event_str))
        time.sleep(0.1)
    except ValueError:
        can_add = False  # EventDataBatch object reaches max_size.

with client:
    client.send_batch(event_data_batch)
