class CddpException(Exception):
    """
    Exception raised for cddp errors.

    Attributes
    ----------
    message : explanation of the error

    """

    def __init__(self, message=None):
        """
        Init

        Parameters
        ----------
        message : str
            explanation of the error, by default None

        """
        self.message = message
        super().__init__(self.message)
