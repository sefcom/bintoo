#!/usr/bin/env python3

import os
import sys
from typing import Dict, List

# pip install ilock
from ilock import ILock


def colon_separated_string_to_dict(s: str) -> Dict[str,str]:
    lines = s.split("\n")
    d = { }
    for line in lines:
        if ":" not in line:
            continue
        first_colon = line.index(":")
        splitted = line[:first_colon], line[first_colon+1:]
        if len(splitted) != 2:
            print(f"[-] Unsupported line {line}. Ignore it.")
            continue
        d[splitted[0].strip(" ")] = splitted[1].strip(" ")
    return d


def dict_to_colon_separated_string(d: Dict[str,str]) -> str:
    lst = [ ]
    for key, value in d.items():
        lst.append(f"{key}: {value}")
    return "\n".join(lst)


def parse_package_index(data: str):
    lines = data.split("\n\n")

    # header
    header = lines[0]
    parsed_header = colon_separated_string_to_dict(header)

    # packages
    packages = lines[1:]
    parsed_packages = [ colon_separated_string_to_dict(package) for package in packages ]
    parsed_packages = [ d for d in parsed_packages if d ]

    return parsed_header, parsed_packages


def merge_packages(packages_0: List[Dict[str,str]], packages_1: List[Dict[str,str]]) -> List[Dict[str,str]]:
    # convert packages to dicts that are indexed by CPV
    p0, p1 = { }, { }
    for d in packages_0:
        p0[d['CPV']] = d
    for d in packages_1:
        p1[d['CPV']] = d

    # merge p0 and p1, but only update p0 for packages that do not exist in p0
    p0_keys = set(p0)
    p1_keys = set(p1)
    new_pkgs = p1_keys.difference(p0_keys)
    for new_key in new_pkgs:
        p0[new_key] = p1[new_key]

    # remove all virtual/ packages
    for key in list(p0.keys()):
        if "virtual/" in key:
            del p0[key]

    print(f"[.] Merged {len(new_pkgs)} new packages.")

    converted = [ ]
    # convert it back
    for _, value in p0.items():
        converted.append(value)

    return converted


def assemble_package_index(header: Dict[str,str], packages: List[Dict[str,str]]) -> str:
    lst = [ ]

    lst.append(dict_to_colon_separated_string(header))

    for pkg in packages:
        lst.append(dict_to_colon_separated_string(pkg))

    return "\n\n".join(lst)


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} src_package_file dst_package_file")
        return

    src, dst = sys.argv[1:3]
    print("[.] Loading source package index...")
    if not os.path.isfile(src):
        print(f"[-] Input file {src} is not found. Exiting.")
        return
    with open(src, "r") as f:
        src_header, src_packages = parse_package_index(f.read())

    if os.path.isfile(dst):
        print("[.] Loading destination package index...")
        with open(dst, "r") as f:
            dst_header, dst_packages = parse_package_index(f.read())
    else:
        print("[.] Destination package index does not exist.")
        dst_header, dst_packages = None, [ ]

    # merge them
    print("[.] Merging...")
    merged_packages = merge_packages(src_packages, dst_packages)

    if not dst_header:
        dst_header = src_header

    # convert them back
    print(f"[.] After merging: there are {len(merged_packages)} packages.")
    dst_header['PACKAGES'] = str(len(merged_packages))
    assembled = assemble_package_index(dst_header, merged_packages)

    # write it
    with open(dst, "w") as f:
        f.write(assembled)


if __name__ == "__main__":
    with ILock("bintoo-merge"):
        main()
