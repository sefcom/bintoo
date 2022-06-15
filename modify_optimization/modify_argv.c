#include <stdio.h>
#include <stdlib.h>

int foo(int argc, char **argv, char **env) 
{
	char* env_var = getenv("VARNAMES_OPT");
	if ((strncmp(argv[0], "gcc", 3) == 0) || (strncmp(argv[0], "clang", 5) == 0))
    {
		for(int i = 1; i < argc; i++)
		{	
			if (0 == strncmp(argv[i], "-O", 2))
			{
				argv[i] = env_var;
			}
		}   
	}
}
	    
__attribute__((section(".init_array"))) static void *foo_constructor = &foo;
//main(){}
