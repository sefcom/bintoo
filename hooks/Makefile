
all: hook_execve.so

hook_execve.so: hook_execve.c
	gcc hook_execve.c -fPIC -shared -ldl -o hook_execve.so

clean:
	rm -f hook_execve.so
