#define _GNU_SOURCE
#include <unistd.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>

// -g -O$O -fcf-protection=none -fno-eliminate-unused-debug-types -frecord-gcc-switches
//   -fno-lto -fno-inline-functions -fno-inline-small-functions
//   -fno-inline-functions-called-once -fno-inline

typedef ssize_t (*execve_func_t)(const char* filename, char* const argv[], char* const envp[]);
static execve_func_t old_execve = NULL;

int execve(const char* filename, char* const argv[], char* const envp[])
{
	bool found = false;
	char* enable = getenv("VARNAMES_ENABLE");
  char* opt = getenv("VARNAMES_OPT");
	// char* path_to_gcc = getenv("VARNAMES_gcc");
	// char *path_to_clang = getenv("VARNAMES_clang"); 
	// char prefix[38] = "--prefix=";
	
	if (enable != NULL && strcmp(enable, "true") == 0) {
#ifdef DEBUG
		int i = 0;
		while (argv[i] != NULL) {
			fprintf(stderr, "****++ argv[i] = %s\n", argv[i]);
			++i;
		}
		i = 0;
		while (envp[i] != NULL) {
			fprintf(stderr, "****-- envp[i] = %s\n", envp[i]);
			++i;
		}
#endif
		if (strlen(filename) >= 3
                && !strcmp(filename + strlen(filename) - 3, "gcc")) {
			found = true;
		}
		else if (strlen(filename) >= 3
                && !strcmp(filename + strlen(filename) - 3, "g++")) {
			found = true;
		}
		else if (strlen(filename) >= 5
                && !strcmp(filename + strlen(filename) - 5, "clang")) {
			found = true;
		}
        else if (strlen(filename) >= 8
                && (!strcmp(filename + strlen(filename) - 8, "clang-14") || 
                    !strcmp(filename + strlen(filename) - 8, "clang-13"))) {
			found = true;
		}
		else if (strlen(filename) >= 7
                && !strcmp(filename + strlen(filename) - 7, "clang++")) {
			found = true;
		}
	}
	
	// gcc or clang
	if (found) {
#ifdef DEBUG
		fprintf(stderr, "**** filename = %s\n", filename);
		fprintf(stderr, "**** opt = %s\n", opt);
#endif
		if (opt == NULL) {
			fprintf(stderr, "Error: VARNAMES_OPT is NULL\n");
			return -1;
		}
		
		// count number of arguments
		int argc = 0;
		while(argv[argc] && *argv[argc])
			++argc;
		
		//copy of argv
		char **copy;

		// argc + 1 + 10 (additional flags)
		copy = (char **) malloc((argc + 11) * sizeof(char *));
		memset(copy, 0, sizeof(char*) * (argc + 11));
		int copy_idx = 0;

		// copy argv[0]
		copy[copy_idx++] = argv[0];
		// add flags to copy of argv	
		copy[copy_idx++] = opt;
		copy[copy_idx++] = "-g";
		copy[copy_idx++] = "-fcf-protection=none";
		copy[copy_idx++] = "-fno-eliminate-unused-debug-types";
		copy[copy_idx++] = "-frecord-gcc-switches";
        copy[copy_idx++] = "-fno-lto";
        copy[copy_idx++] = "-fno-inline-functions";
        copy[copy_idx++] = "-fno-inline-small-functions";
        copy[copy_idx++] = "-fno-inline-functions-called-once";
        copy[copy_idx++] = "-fno-inline";

		for (int i = 1; argv[i] != NULL; i++) {
			if (strncmp(argv[i], "-O", 2) == 0) {
				// skip
				;
			}
			else {
				int len = strlen(argv[i]);
				copy[copy_idx] = (char *)malloc(len + 1);
				strcpy(copy[copy_idx++], argv[i]);
			}
		}

		copy[copy_idx++] = NULL;

#ifdef DEBUG
		for (int i = 0; i < copy_idx; ++i) {
			fprintf(stderr, "%d: %s\n", i, copy[i]);
		}
#endif

		old_execve = dlsym(RTLD_NEXT, "execve");    
		return old_execve(filename, copy, envp);
	}

	// not gcc or clang
	else {
		old_execve = dlsym(RTLD_NEXT, "execve");
		return old_execve(filename, argv, envp);
	}

	return 0;
}	
