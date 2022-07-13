from abc import abstractmethod


class AbstractDataSchema():
    def __init__(self, app_config):
        self.app_config = app_config

    @abstractmethod
    def get_schema(self):
        pass
