from importlib import import_module


def get_class(kls):
    """
    Create an instance of a specified class.

    Parameters
    ----------
    kls : package path
        For example, `get_class("cddp_fruit_app_customers.customer_2.master_transformation.Function")`


    Returns
    ----------
    instance
        instance of the specified class
    """
    parts = kls.split('.')
    module = ".".join(parts[:-1])
    m = __import__(module)
    for comp in parts[1:]:
        m = getattr(m, comp)
    return m


def find_class(module_name, class_name):
    """
    Import a specified module and create an instance of a specified class.
    For example,
    `find_class("cddp_fruit_app_customers.customer_2.master_transformation",
                "Function")`

    Parameters
    ----------
    module_name : str
        module name

    class_name : str
        class name


    Returns
    ----------
    instance
        instance of the specified class
    """

    globals()[module_name] = import_module(module_name)

    return get_class(module_name + "." + class_name)
