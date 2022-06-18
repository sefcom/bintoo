#define _GNU_SOURCE
#include <unistd.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

// -g -O$O -fcf-protection=none -fno-eliminate-unused-debug-types -frecord-gcc-switches

typedef ssize_t (*execve_func_t)(const char* filename, char* const argv[], char* const envp[]);
static execve_func_t old_execve = NULL;
int execve(const char* filename, char* const argv[], char* const envp[]) {

	bool found = false;
        char* env_var = getenv("VARNAMES_OPT");
	char* path_to_gcc = getenv("VARNAMES_gcc"); // execve can find cc1
	char *path_to_clang = getenv("VARNAMES_clang"); 

	char prefix[38] = "--prefix=";
	
	if (strncmp(filename, "/usr/bin/gcc", 12) == 0 ){
		found = true;
		strcat(prefix, path_to_gcc);
	}
	if (strncmp(filename, "/usr/bin/clang", 14) == 0){
		found = true;
		strcat(prefix, path_to_clang);
	}
		
	
	// gcc or clang
	if (found){
		
		// count number of arguments
		int argc = 0;
		while(argv[argc] && *argv[argc])
			++argc;
		
		//copy of argv
		char **copy;

		// argc + 1 + 4 (additional flags) + 1 (set path of gcc/clang with --prefix)
		copy = (char **) malloc ((argc + 5) * sizeof (char *));
		for ( argc = 0; argv[argc] != NULL; argc++){
			int len = strlen (argv[argc]);
			copy[argc] = (char *) malloc (len + 1);

			if (0 == strncmp(argv[argc], "-O", 2))
				strcpy(copy[argc], env_var);
			else                       
				strcpy (copy[argc], argv[argc]);
		}

		// add flags to copy of argv	
		copy[argc] = "-g";
		copy[argc + 1] = "-fcf-protection=none";
		copy[argc + 2] = "-fno-eliminate-unused-debug-types";
		copy[argc + 3] = "-frecord-gcc-switches";
		copy[argc + 4] = prefix;
		copy[argc + 5] = NULL;


		old_execve = dlsym(RTLD_NEXT, "execve");    
		return old_execve(filename, copy, envp);
	}

	// not gcc or clang
	else{
		old_execve = dlsym(RTLD_NEXT, "execve");
		return old_execve(filename, argv, envp);
	}
}	
