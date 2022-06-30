#define _GNU_SOURCE
#include <unistd.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>

// -g -O$O -fcf-protection=none -fno-eliminate-unused-debug-types -frecord-gcc-switches

typedef ssize_t (*execve_func_t)(const char* filename, char* const argv[], char* const envp[]);
static execve_func_t old_execve = NULL;

int execve(const char* filename, char* const argv[], char* const envp[])
{
	printf("Calling evecve!\n");
	bool found = false;
	char* enable = getenv("VARNAMES_ENABLE");
  char* opt = getenv("VARNAMES_OPT");
	// char* path_to_gcc = getenv("VARNAMES_gcc");
	// char *path_to_clang = getenv("VARNAMES_clang"); 
	// char prefix[38] = "--prefix=";
	
	if (enable != NULL && strcmp(enable, "true") == 0) {
		if (strstr(filename, "gcc") != NULL) {
			found = true;
			// strcat(prefix, path_to_gcc);
		}
		else if (strstr(filename, "clang") != NULL) {
			found = true;
			// strcat(prefix, path_to_clang);
		}
	}
	
	// gcc or clang
	if (found) {
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

		// argc + 1 + 4 (additional flags) + 1 (set path of gcc/clang with --prefix)
		copy = (char **) malloc((argc + 6) * sizeof(char *));
		memset(copy, 0, sizeof(char*) * (argc + 6));
		int copy_idx = 0;

		// copy argv[0]
		copy[copy_idx++] = argv[0];
		// add flags to copy of argv	
		copy[copy_idx++] = opt;
		copy[copy_idx++] = "-g";
		copy[copy_idx++] = "-fcf-protection=none";
		copy[copy_idx++] = "-fno-eliminate-unused-debug-types";
		copy[copy_idx++] = "-frecord-gcc-switches";

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

		for (int i = 0; i < copy_idx; ++i) {
			printf("%d: %s\n", i, copy[i]);
		}

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
