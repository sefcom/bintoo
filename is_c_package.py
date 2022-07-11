# Check if a package has at least a C or C++ file

import sys
import os
import subprocess
import tempfile


def is_c_or_cpp_file(filename: str) -> bool:
    filename = filename.lower()
    return (filename.endswith(".c")
            or filename.endswith(".cpp")
            or filename.endswith(".cp")
            or filename.endswith(".cxx")
            or filename.endswith(".cc")
            or filename.endswith(".c++")
            or filename.endswith(".h")
            or filename.endswith(".hpp")
            or filename.endswith(".hxx")
            )


def main():
    package_name = sys.argv[1]
    ebuild_basedir = f"/var/db/repos/gentoo/{package_name}/"

    if not os.path.exists(ebuild_basedir):
        raise RuntimeError(f"Base directory {ebuild_basedir} for package {package_name} does not exist")

    # find the ebuild file
    for ebuild in os.listdir(ebuild_basedir):
        ebuild_path = os.path.join(ebuild_basedir, ebuild)
        # fetch the source
        proc = subprocess.Popen(["ebuild", ebuild_path, "fetch"],
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE,)
        stdout, stderr = proc.communicate()

        # parse the file name
        lines = stdout.split(b"\n")
        lines = [ line for line in lines if line.strip() ]
        for line in lines:
            if line.startswith(b" * "):
                filename = line[3:]
                filename = filename[: filename.index(b" ")]
                filename = filename.decode("utf-8")
            else:
                continue

            package_path = f"/var/cache/distfiles/{filename}"
            if not os.path.exists(package_path):
                sys.stderr.write(f"[-] Package file {package_path} does not exist.")
                continue

            # decompress it
            with tempfile.TemporaryDirectory() as d:
                if package_path.endswith(".tar.gz") or package_path.endswith(".tgz"):
                    subprocess.call(["tar", "-xzf", package_path],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                    cwd=d)
                elif package_path.endswith(".tar.xz") or package_path.endswith(".txz"):
                    subprocess.call(["tar", "-xJf", package_path],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                    cwd=d)
                elif package_path.endswith(".tar.bz2") or package_path.endswith(".tbz2"):
                    subprocess.call(["tar", "-xf", package_path],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                    cwd=d)
                elif package_path.endswith(".tar"):
                    subprocess.call(["tar", "-xf", package_path],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                    cwd=d)
                elif package_path.endswith(".tar.Z"):
                    subprocess.call(["tar", "-xzf", package_path],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                    cwd=d)
                elif package_path.endswith(".zip"):
                    subprocess.call(["unzip", package_path],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                    cwd=d)
                else:
                    sys.stderr.write(f"Unsupported compression file type {package_path}\n")

                for root, _, files in os.walk(d):
                    if any([is_c_or_cpp_file(fi) for fi in files]):
                        sys.exit(0)

    sys.exit(1)



if __name__ == "__main__":
    main()

