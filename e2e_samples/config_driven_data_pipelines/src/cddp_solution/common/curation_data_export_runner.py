
from cddp_solution.common.utils.Config import Config
from cddp_solution.common.utils.module_helper import find_class
import sys

source_system = sys.argv[1]
customer_id = sys.argv[2]

if __name__ == "__main__":

    metadata_configs = Config(source_system, customer_id)
    config = metadata_configs.load_config()
    clz = find_class(f"{source_system}.curation_data_export", "CurationDataExport")
    transform = clz(config)
    transform.export()
