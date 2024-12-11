# Databricks notebook source
# COMMAND ----------

import unittest

class Greeter:
    def __init__(self):
        self.message = "Hello Test Message from Dummy File!"

class TestGreeter(unittest.TestCase):
    def test_greeter_message(self):
        greeter = Greeter()
        self.assertEqual(greeter.message, "Hello Test Message from Dummy File!", "The message should be 'Hello world!'")

if __name__ == "__main__":
    unittest.main(argv=['first-arg-is-ignored'], exit=False)

# COMMAND ----------
