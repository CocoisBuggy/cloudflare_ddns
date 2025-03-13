from setuptools import find_packages, setup

setup(
    name="coco-ddns",
    version="0.2.0",
    packages=find_packages(include=["coco_ddns", "coco_ddns.*"]),
    nclude_package_data=True,
    install_requires=["requests"],
    entry_points={
        "console_scripts": [
            "coco-ddns = coco_ddns.cli:main",
        ],
    },
)
