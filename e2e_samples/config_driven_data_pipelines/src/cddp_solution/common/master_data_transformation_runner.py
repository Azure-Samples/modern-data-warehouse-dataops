
from cddp_solution.common.utils.Config import Config
from cddp_solution.common.utils.module_helper import find_class
import sys


def main():
    source_system = sys.argv[1]
    customer_id = sys.argv[2]

    # Optional 3rd argument for resources base path
    try:
        resources_base_path = sys.argv[3]
    except IndexError:
        resources_base_path = None

    # Optional 4th argument('fruits_1, fruits_2') for replay targets datasets
    try:
        targets = sys.argv[4].split(",")
    except IndexError:
        targets = None

    metadata_configs = Config(source_system, customer_id, resources_base_path)
    config = metadata_configs.load_config()
    clz = find_class(f"{source_system}.master_data_transform", "MasterDataTransformation")
    transform = clz(config)

    transform.load_data()
    transform.transform(targets)
    transform.export()
    # data_list = transform.export()

    # for data_item in data_list:
    #     data_item.show()


if __name__ == "__main__":
    main()
